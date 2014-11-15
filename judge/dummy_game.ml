open Core
open Main

module G : GAME = struct

  type game = int * (player * string) list * game_status

  let new_game = (10, [], TurnOf P1)

  let play (g, l, s0) xx =
    match s0 with
    | TurnOf p when g > 0 ->
      let op = other_player p in
      (g-1, l@[p, xx], 
        if g - 1 = 0 then
          if Random.int 10 = 0 then Eliminated p
          else if Random.int 2 = 0 then Won p
          else if Random.int 2 = 0 then Won op
          else Tie
        else
          TurnOf op
      )
    | TurnOf x -> (g, l, Eliminated x)
    | _ -> raise (Eliminated_ex "not someone's turn!")

  let s (_, _, s) = s

  let display_game (cr, cs, t) (p1n, p2n) =
    let open Graphics in
    let open G_util in
    let pt = function P1 -> p1n | P2 -> p2n in
    List.iteri
      (fun i (p, x) ->
        text2 (i+4) black (string_of_int i);
        text3 (i+4) (pc p) x)
      cs;
    text2 (List.length cs + 4) black ("... " ^ string_of_int cr);
    let c, t = match t with
        | TurnOf x -> pc x, "... " ^ pt x
        | Won x -> pc x, pt x ^ " WON"
        | Tie -> black, "TIE"
        | Eliminated x -> pc x, pt x ^ " ELIM"
    in
    text3 (List.length cs + 4) c t

  let id = "dummy_game"
  let name = "Dummy game for testing purposes"

end
