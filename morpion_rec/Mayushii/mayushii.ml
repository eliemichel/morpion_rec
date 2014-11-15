
module Mayushii : Player.IA = struct

  module G = Morpion_rec.G

  let play g =
    let cc = G.possibilities g in
    List.hd cc

end

module P = Player.P(Mayushii)

let () = P.run()
