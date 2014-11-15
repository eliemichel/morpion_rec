
module Feirisu : Player.IA = struct

  module G = Morpion_rec.G

  let play g =
    let cc = G.possibilities g in
    List.nth cc
      (Random.int (List.length cc))

end

module P = Player.P(Feirisu)

let () =
  Random.self_init();
  P.run()
