open Core

module type IA = sig

  module G : GAME

  val play : G.game -> string

end

module P (W : IA) : sig

  val run : unit -> unit

end = struct

  module G = W.G

  let expect mgs =
    let l = read_line () in
    begin try
    let (s, f) = List.find
      (fun (s, _) ->
         String.length l >= String.length s
      && String.sub l 0 (String.length s) = s)
      mgs
    in f (String.sub l (String.length s)
        (String.length l - String.length s))
    with
    Not_found ->
      Format.eprintf "Unexpected '%s'.@." l;
      exit 1
    end

  let finished _ =
    print_string "Fair enough\n"

  let rec turn g _ =
    expect [
      "Your turn",
        (fun _ ->
        let act = W.play g in
        Format.printf "Play %s@." act;
        let g' = G.play g act in
        expect [ "OK", turn g' ]);
      "Play ", (fun act -> turn (G.play g act) "");
      "Tie", finished;
      "You win", finished;
      "You lose", finished;
      "Eliminated", finished
    ]

  let run () =
    Random.self_init ();
    expect [
    "Hello " ^ G.id,
    (fun _ -> Format.printf "Hello %s@." G.id;
      turn (G.new_game) "")
    ];

end
