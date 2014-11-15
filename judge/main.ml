open Core
open Graphics

(* ****************** *)
(* The user interface *)
(* ****************** *)

exception Exit_judge

module UI (C : CORE) : sig

  val init : unit -> unit
  val close : unit -> unit
  val handle_events : unit -> bool
  val display : unit -> unit

end = struct

  module G = C.G

  open G_util

  (* Init/Close *)
  let init () =
    open_graph " 800x600";
    set_font "-misc-fixed-bold-r-normal--15-120-90--c-90-iso8859-1";
    auto_synchronize false;
    display_mode false;
    remember_mode true;
    fullscreen_msg "Starting up..."

  let close () =
    close_graph ()

  (* View types *)
  type view =
    | ScoreBoard
    | MatchList of bool
    | ViewLastGame
    | NavGame of C.game * int
    | Question of string * (unit -> unit) * view

  let rec handle_events () =
    let usefull = ref false in
    while key_pressed () do
      usefull := true;
      match !curr_view, read_key() with
      | ScoreBoard, '\t' -> curr_view := MatchList false
      | MatchList _, '\t' -> curr_view := ScoreBoard
      | MatchList e, 'f' -> curr_view := MatchList (not e)
      | MatchList _, 'r' -> curr_view := Question(
          "Launch new round?",
          (fun () -> C.add_rounds(); curr_view := MatchList false),
          !curr_view
        )
      | MatchList _, 'v' when C.games () <> [] -> curr_view := ViewLastGame
      | MatchList _, 'n' when C.games () <> [] ->
        let g = List.hd (C.games()) in
        curr_view := NavGame (g, -1)
      | NavGame (g, _), 'n' ->
        let rec dx = function
          | gg::pg::_ when pg == g -> curr_view := NavGame (gg, -1)
          | _::l -> dx l
          | [] -> ()
        in dx (C.games())
      | NavGame (g, _), 'p' ->
        let rec dx = function
          | pg::gg::_ when pg == g -> curr_view := NavGame (gg, -1)
          | _::l -> dx l
          | [] -> ()
        in dx (C.games())
      | NavGame (g, n), 'b' when n > 0 ->
        curr_view := NavGame (g, n-1)
      | NavGame (g, n), 'b' when n = -1 ->
        curr_view := NavGame (g, List.length (C.hist g) - 1)
      | NavGame (g, n), 'f' when n < List.length (C.hist g) - 1 && n <> -1 ->
        curr_view := NavGame (g, n+1)
      | NavGame (g, n), 'f' when n = List.length (C.hist g) - 1 ->
        curr_view := NavGame (g, -1)
      | NavGame(g, _), 'a' -> curr_view := NavGame(g, 0)
      | NavGame(g, _), 'z' -> curr_view := NavGame(g, -1)
      | ViewLastGame, '\t' | NavGame _, '\t' -> curr_view := MatchList false
      | Question(_, y, n), 'y' -> y()
      | Question(_, y, n), 'n' -> curr_view := n
      | v, 'q' ->
        curr_view := Question(
          "Really quit?",
          (fun () ->
            fullscreen_msg "Exiting...";
            raise Exit_judge),
          v)
      | _ -> ()
    done;
    !usefull

  and display () =
    clear_graph ();
    begin match !curr_view with
    | ScoreBoard -> scoreboard_disp ()
    | MatchList f -> matchlist_disp f
    | ViewLastGame -> last_game_disp ()
    | NavGame (g, n) -> nav_game_disp g n
    | Question (q, _, _) -> fullscreen_msg (q ^ " (y/n)")
    end;
    synchronize ()

  and curr_view = ref ScoreBoard

  (* Scoreboard view *)
  and scoreboard_disp () =
    text1 1 black "score board";
    text4 1 grey "match list >";
    hl();
    let scores = List.sort
      (fun (_, sc) (_, sc') -> sc' - sc)
      (C.scores())
    in
    let p_sc = ref (-199028109) in
    let show_sc i (n, s) =
      if s <> !p_sc then
        text2 (i+4) black (string_of_int (i+1)^". ");
      p_sc := s;
      text3 (i+4) black n;
      text4 (i+4) black (string_of_int s)
    in
    List.iteri show_sc scores

  (* Match list view *)
  and matchlist_disp show_only_running =
    text1 1 black "match list";
    text2 1 black "queued matches:";
    text3 1 black (string_of_int (C.ql ()));
    text4 1 grey "score board >";
    hl();
    let games =
      if show_only_running then
        List.filter
          (fun g -> match C.p1 g, C.p2 g with Dead, Dead -> false | _ -> true)
          (C.games())
      else C.games()
    in
    let time = Unix.gettimeofday() in
    let print_g i g =
      let cp1, cp2 = match C.s g with
      | TurnOf _ -> black, black
      | Won P1 -> green, red
      | Won P2 -> red, green
      | Tie -> grey, grey
      | Eliminated P1 -> orange, grey
      | Eliminated P2 -> grey, orange
      in
      let mp = function
        | Loading -> grey, "-> []"
        | Saving -> grey, "[] ->"
        | Dead -> black, ""
        | StandBy t -> grey, Format.sprintf "%.2f" t
        | Thinking (t, tb) -> black,
          Format.sprintf "[ %.2f ]" (t -. (time -. tb))
      in
      let p1n, p2n = C.pn g in
      let c, m = mp (C.p1 g) in text1 (i+4) c m;
      text2 (i+4) cp1 p1n;
      text3 (i+4) cp2 p2n;
      let c, m = mp (C.p2 g) in text4 (i+4) c m
    in
    List.iteri print_g games

  (* Game view *)
  and last_game_disp () =
    match C.games () with
    | g::_ ->
      let p1n, p2n = C.pn g in
      text1 1 p1c p1n;
      text2 1 p2c p2n;
      text4 1 grey "match list >";
      hl();
      G.display_game (C.g g) (p1n, p2n)
    | _ -> ()
  and nav_game_disp g n =
    let p1n, p2n = C.pn g in
    text1 1 p1c p1n;
    text2 1 p2c p2n;
    text4 1 grey "match list >";
    hl();
    let n = if n = -1 then List.length (C.hist g) -1 else n in
    let put_st i g =
      let ni = (size_x() - 60) / 12 + 1 in
      let cx = 12 * (i mod ni) + 30 in
      let cy = size_y () - 60 - (20 * (i / ni)) in
      begin match G.s g with
        | TurnOf p ->
          set_color (pc p);
          draw_circle cx cy 2
        | Won p -> 
          set_color (pc p);
          draw_circle cx cy 2;
          draw_circle cx cy 4
        | Tie ->
          set_color black;
          draw_circle cx cy 4
        | Eliminated p ->
          set_color (pc p);
          draw_segments [| cx - 3, cy - 3, cx + 4, cy + 4; cx - 3, cy + 3, cx + 4, cy - 4 |]
      end;
      if i = n then begin
        set_color black;
        fill_circle cx (cy-10) 2;
        G.display_game g (p1n, p2n)
      end
    in
    List.iteri put_st (List.rev (C.hist g))

end

(* ************* *)
(* The main loop *)
(* ************* *)

module Juge (C : CORE) : sig

  val run : unit -> unit

end = struct

  module UI = UI(C)

  let run () =
    UI.init();
    C.init();
    let last_r = ref 0.0 in
    begin try while true do
      let a = C.handle_events () in
      let b = UI.handle_events () in
      if a || b || Unix.gettimeofday() -. !last_r > 0.1 then begin
        UI.display ();
        last_r := Unix.gettimeofday()
      end
    done with
      Exit_judge ->
        C.finish ();
        UI.close ()
    end

end
