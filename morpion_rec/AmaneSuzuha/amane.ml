
module Amane : Player.IA = struct

  module G = Morpion_rec.G
  open Core

  let take_random cc =
    List.nth cc
      (Random.int (List.length cc))

  let won_game g = match G.s g with Won _ -> true | _ -> false

  let play g =
    let cc = G.possibilities g in
    match List.partition
      (fun act -> won_game (G.play g act))
      cc
    with
    | win::_, _ -> win
    | [], other ->
      let o' = List.filter
        (fun act ->
          try
            let g' = G.play g act in
            let adv_win =
              G.possibilities g'
              |> List.map (G.play g')
              |> List.exists won_game
            in not adv_win
          with _ -> true)
        other
      in
      if List.length o' > 0 then
        take_random o'
      else
        take_random other

end

module P = Player.P(Amane)

let () =
  Random.self_init();
  P.run()
