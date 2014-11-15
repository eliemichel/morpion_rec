open Unix

open Protocol

let ( |> ) x f = f x

(* Description of data structures *)

exception Eliminated_ex of string

type player = P1 | P2
let other_player = function P1 -> P2 | P2 -> P1

type game_status =
  | TurnOf of player
  | Won of player
  | Tie
  | Eliminated of player

type player_proc_status =
  | Loading
  | StandBy of float        (* temps restant sur toute la partie *)
  | Thinking of (float * float) (* temps restant ; heure de début de réflexion *)
  | Saving
  | Dead

module type GAME = sig
  type game   (* immutable structure *)

  val name : string (* ex: Morpion récursif *)
  val id   : string   (* ex: morpion_rec *)

  val new_game : game

  val play : game -> string -> game
  val s    : game -> game_status

  val display_game : game -> (string * string) -> unit
end

module type CORE = sig
  module G : GAME

  type game
  val p1 : game -> player_proc_status
  val p2 : game -> player_proc_status
  val pn : game -> string * string
  val s : game -> game_status
  val g : game -> G.game
  val hist : game -> G.game list  (* head: same as g g *)

  val init : unit -> unit
  val finish : unit -> unit

  val handle_events : unit -> bool   (* is anything happening ? *)

  val add_rounds : unit -> unit      (* adds one game of everyone against everyone *)

  val ql : unit -> int
  val scores : unit -> (string * int) list
  val games : unit -> game list

end

(* ****************************************** *)
(*           BEGIN IMPLEMENTATION             *)
(* ****************************************** *)

module Core (G: GAME) : CORE = struct
  module G : GAME = G

  type player = {
    name: string;
    binary: string;
    dir: string;
    log_out: file_descr;
    mutable score: int;
    mutable running: player_proc option;
  }

  and player_proc = {
    pid: int;
    cfd: file_descr list;
    p: player;
    i: in_channel;
    o: out_channel;
    mutable s: player_proc_status;
  }

  type game = {
    mutable hist: G.game list;
    p1: player_proc;
    p2: player_proc;
    mutable s: game_status;
  }
  let p1 g = g.p1.s
  let p2 g = g.p2.s
  let pn g = (g.p1.p.name, g.p2.p.name)
  let s g = g.s
  let g g = List.hd g.hist
  let hist g = g.hist

  let players = Hashtbl.create 12
  let planned_games = ref []
  let r_games = ref []

  let ql () = List.length !planned_games

  (* program paremeters *)
  let par_games = ref 2       (* default: launch two simultaneous games *)
  let game_time = ref 30.0    (* default: 30 sec for each player *)
  let pt_win = ref 3          (* default: on win, score += 3 *)
  let pt_tie = ref 1          (* default: on tie, score += 1 *)
  let pt_lose = ref 0         (* default: on lose, score does not change *)
  let pt_elim = ref (-1)      (* default: on eliminated, score -= 1 *)
  let log_games = ref false   (* default: do not log games *)

  let scores () =
    Hashtbl.fold (fun _ p l -> (p.name, p.score)::l) players []
  let games () = !r_games

  let init () =
    (* 1. PARSE ARGUMENTS *)
    let game_dir = ref "" in
    let args = [
      "-p", Arg.Set_int par_games, "How many games to run in parallel (2)";
      "-s", Arg.Set_float game_time,
        "Time (seconds) allotted to each player for a game (30)";
      "-w", Arg.Set_int pt_win, "Points granted on win (+3)";
      "-t", Arg.Set_int pt_tie, "Points granted on tie (+1)";
      "-l", Arg.Set_int pt_lose, "Points granted on lose (0)";
      "-e", Arg.Set_int pt_elim, "Points granted on eliminated (-1)";
      "-v", Arg.Set log_games, "Log all games (false)";

    ] in
    Arg.parse args (fun s -> game_dir := s)
      "Usage: judge <game_directory>";
    if !game_dir = "" then begin
      Format.eprintf "Error: no game directory specified.@.";
      exit 1
    end;
    if Filename.is_relative !game_dir then
      game_dir := Filename.concat (Unix.getcwd()) !game_dir;
    let date =
      let d = Unix.gmtime (Unix.gettimeofday ()) in
      Format.sprintf "%04d%02d%02d%02d%02d" (d.tm_year+1900) (d.tm_mon+1) d.tm_mday d.tm_hour d.tm_min
    in

    (* 2. REDIRECT STDOUT TO LOG FILE *)
    let log_file = Filename.concat !game_dir (date^".log") in
    Format.printf "Juge for '%s' starting up...@." G.name;
    Format.printf "Redirecting standard output to '%s'.@." log_file;
    flush Pervasives.stdout;
    begin try
      let log_out = Unix.openfile log_file [O_APPEND; O_CREAT; O_WRONLY] 0o644 in
      dup2 log_out Unix.stdout
    with _ ->
      Format.eprintf "Could not open log output file.@.";
      exit 1
    end;
    Format.printf "Juge for '%s' starting up...@." G.name;
    Format.printf "Session: %s@." date;

    (* 3. LOAD PLAYER LIST *)
    Format.printf "Loading player list...@.";
    let fd = try opendir !game_dir with _ ->
      Format.printf "Could not open directory %s for listing.@." !game_dir;
      exit 1
    in
    let rec rd () =
      try let s = readdir fd in
        begin try
          let dir = Filename.concat !game_dir s in
          let b = Filename.concat dir "player" in
          let st =  Unix.stat b in
          if (st.st_kind = S_REG || st.st_kind = S_LNK)
              && (st.st_perm land 0o100 <> 0) then begin
            Format.printf "- %s@." s;
            (* open log output for player *)
            let p_log_file = Filename.concat dir "stderr.log" in
            let p_log_out = Unix.openfile p_log_file [O_APPEND; O_CREAT; O_WRONLY] 0o644 in
            let f = Format.formatter_of_out_channel (out_channel_of_descr p_log_out) in
            Format.fprintf f "---- Begin session %s@." date;
            Hashtbl.add players s
              { name = s;
                binary = b;
                dir;
                log_out = p_log_out;
                score = 0;
                running = None; }
          end
        with _ -> () end;
        rd()
      with End_of_file -> ()
    in rd (); closedir fd
  
  let finish () =
    (* TODO :
      - save scores
    *)
    let childs = ref [] in
    List.iter
      (fun g ->
        if g.p1.s <> Dead then childs := g.p1.pid::!childs;
        if g.p2.s <> Dead then childs := g.p2.pid::!childs)
      !r_games;
    List.iter (fun pid -> kill pid Sys.sigterm) !childs;
    while !childs <> [] do
      try
        let pid, _ = waitpid [] (-1) in
        childs := List.filter (( <> ) pid) !childs
      with _ -> ()
    done
  
  let add_rounds () =
    Hashtbl.iter
      (fun p _ -> Hashtbl.iter
        (fun q _ -> if p <> q then planned_games := (p, q)::!planned_games)
        players)
      players

  let send_m (pp : player_proc) m =
    if pp.s <> Dead then begin
      let m = encode m in
      if !log_games then Format.printf ">%s< %s@." pp.p.name m;
      output_string pp.o (m ^ "\n");
      flush pp.o
    end

  let handle_events () =
    let usefull = ref false in
    (* 1. IF NOT ENOUGH MATCHES ARE RUNING, LAUNCH ONE *)
    let matches_in_progress =
          !r_games
        |> List.filter (fun g -> match g.p1.s, g.p2.s with Dead, Dead -> false | _ -> true)
        |> List.length
    in
    let launch_match p1 p2 =
      Format.printf "Launching match: %s vs. %s@." p1 p2;

      let open_c p =
        let f = Format.formatter_of_out_channel (out_channel_of_descr p.log_out) in
        Format.fprintf f "--- Begin game (%s vs. %s)@." p1 p2;
        let (j2p_i, j2p_o) = pipe () in
        let (p2j_i, p2j_o) = pipe () in
        let pid = fork() in
        if pid = 0 then begin
          chdir p.dir;
          dup2 j2p_i stdin;
          dup2 p2j_o stdout;
          dup2 p.log_out stderr;
          execvp p.binary [| p.binary |];
        end;
        Format.printf "[%s start, pid: %d]@." p.name pid;
        let pl = { pid; p;
          i = in_channel_of_descr p2j_i;
          o = out_channel_of_descr j2p_o;
          cfd = [p2j_i; p2j_o; j2p_i; j2p_o];
          s = Loading } in
        p.running <- Some pl;
        send_m pl (Hello G.id);
        pl
      in
      let p1 = open_c (Hashtbl.find players p1) in
      let p2 = open_c (Hashtbl.find players p2) in
      let g = G.new_game in
      let g = { p1; p2; hist = [g]; s = G.s g } in
      r_games := g::(!r_games);
      usefull := true
    in
    let can_launch, cannot_launch = List.partition
      (fun (p1, p2) ->
        (Hashtbl.find players p1).running = None
          && (Hashtbl.find players p2).running = None)
      !planned_games
    in
    begin match can_launch with
      | (p1, p2)::q when matches_in_progress < !par_games ->
        launch_match p1 p2;
        planned_games := q @ cannot_launch
      | _ -> ()
    end;
    (* 2. LOOK IF ANYBODY IS TELLING US SOMETHING - IF SO, REACT
          (wait max. 0.01 sec) *)
    let in_fd_x = List.fold_left
      (fun l g ->
        let l = if g.p1.s = Dead then l
          else (Unix.descr_of_in_channel g.p1.i, (g, g.p1))::l
        in if g.p2.s = Dead then l
          else (Unix.descr_of_in_channel g.p2.i, (g, g.p2))::l)
      [] !r_games
    in
    let in_fd, _, _ =
      try select (List.map fst in_fd_x) [] [] 0.01
      with Unix_error (EINTR, _, _) -> [], [], []
    in
    let do_fd fd =
      let (g, p) = List.assoc fd in_fd_x in
      let pi = if p == g.p1 then P1 else P2 in
      let op = match pi with P1 -> g.p2 | P2 -> g.p1 in
      begin try
        let l = input_line p.i in
        if !log_games then Format.printf "<%s> %s@." p.p.name l;
        match decode l, p.s with
        | Hello x, Loading when x = G.id ->
          p.s <- StandBy !game_time;
        | Play act, Thinking (time, beg_r) ->
          let end_r = Unix.gettimeofday () in
          if G.s (List.hd g.hist) <> TurnOf pi then
            raise (Eliminated_ex "not your turn (assert failed)");
          let new_g = G.play (List.hd g.hist) act in
          let new_s = G.s new_g in
          send_m p OK;
          send_m op (Play act);
          g.s <- new_s;
          g.hist <- new_g::g.hist;
          let finished = match new_s with
            | Tie ->
              send_m p Tie;
              send_m op Tie;
              Format.printf "%s vs. %s: tie!@." g.p1.p.name g.p2.p.name;
              p.p.score <- p.p.score + !pt_tie;
              op.p.score <- op.p.score + !pt_tie;
              true
            | Won x ->
              let (w, l) = if x = P1 then (g.p1, g.p2) else (g.p2, g.p1) in
              send_m w YouWin;
              send_m l YouLose;
              Format.printf "%s vs. %s: %s wins!@." g.p1.p.name g.p2.p.name w.p.name;
              w.p.score <- w.p.score + !pt_win;
              l.p.score <- l.p.score + !pt_lose;
              true
            | TurnOf _ ->
              p.s <- StandBy (time -. (end_r -. beg_r));
              false
            | Eliminated _ -> raise (Eliminated_ex ("invalid move: " ^ act))
          in
          if finished then begin
            p.s <- Saving;
            if op.s <> Dead then op.s <- Saving;
          end
        | FairEnough, Saving ->
          kill p.pid Sys.sigterm;
        | _, Saving ->
          ()  (* player may be anywhere in its protocol state, we don't care*)
        | bad_m, _ -> raise (Eliminated_ex ("unexpected message: '" ^ encode bad_m ^ "'"))
        | exception Invalid_message m -> raise (Eliminated_ex ("invalid message: '" ^ m ^"'"))
        | exception _ -> raise (Eliminated_ex "exception when reading message")
      with
        | Eliminated_ex r ->
          send_m p Eliminated;
          send_m op YouWin;
          (* since process is not respecting the protocol, we cannot assume
            it is doing anything reasonable, so we kill it now rather than later... *)
          kill p.pid Sys.sigterm;
          Format.printf "%s vs. %s: %s eliminated (%s)!@." g.p1.p.name g.p2.p.name p.p.name r;
          p.p.score <- p.p.score + !pt_elim;
          if op.s <> Dead then op.s <- Saving;
          p.s <- Saving;
          g.s <- Eliminated pi
      end;
      begin match g.s, g.p1.s, g.p2.s, g.p1, g.p2 with
        | TurnOf P1, StandBy t, StandBy _, p, _
        | TurnOf P2, StandBy _, StandBy t, _, p ->
          send_m p (YourTurn t);
          p.s <- Thinking (t, Unix.gettimeofday());
        | _ -> ()
      end;
      usefull := true
    in List.iter do_fd in_fd;
    (* Check if somebody has timed out *)
    let check_timeout g =
      match g.p1.s, g.p2.s, g.p1, g.p2 with
      | Thinking(t, st), _, l, w
      | _, Thinking(t, st), w, l ->
        if t -. (Unix.gettimeofday() -. st) < 0. then begin
          send_m w YouWin;
          send_m l YouLose;
          Format.printf "%s vs. %s: %s wins! (time out for %s)@." g.p1.p.name g.p2.p.name w.p.name l.p.name;
          w.p.score <- w.p.score + !pt_win;
          l.p.score <- l.p.score + !pt_lose;
          w.s <- Saving;
          if l.s <> Dead then l.s <- Saving;
          usefull := true
        end
      | _ -> ()
    in List.iter check_timeout !r_games;
    (* Check if somebody has died on us *)
    begin try
      let pid, _ = waitpid [WNOHANG] (-1) in
      if pid <> 0 then begin
          let g = List.find
            (fun g ->
              (g.p1.s <> Dead && g.p1.pid = pid)
              || (g.p2.s <> Dead && g.p2.pid = pid))
            !r_games
          in
          let pi = if g.p1.pid = pid then P1 else P2 in
          let p, op = if g.p1.pid = pid then g.p1, g.p2 else g.p2, g.p1 in
          Format.printf "[%s (%d) died.]@." p.p.name pid;
          if p.s <> Saving then begin
            (* YOU DIE -> ELIMINATED! *)
            send_m op YouWin;
            Format.printf "%s vs. %s: %s eliminated (died...)!@." g.p1.p.name g.p2.p.name p.p.name;
            p.p.score <- p.p.score + !pt_elim;
            if op.s <> Dead then op.s <- Saving;
            g.s <- Eliminated pi
          end;
          p.s <- Dead;
          p.p.running <- None;
          List.iter close p.cfd;
          usefull := true
      end
    with _ -> () end;
  (* return value *)
  !usefull
  
end
