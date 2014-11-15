
let words = [|
      "banane"; "hippopotame"; "poivron";
      "pourquoi???"; "un ange passe"; "television";
      "ceci n'est pas..."; "environ 12"; "septante";
      "Philipp Glass"; "nyaaa"; "tu crois ?"; "hallo";
      "mange ton muesli"; "va te coucher"; "MAMAAAAN!!";
      "meme pas peur"; "python FTW"; "savanne!";
      "le lion mange le lion"; "canard"; "tennis";
      "sauve qui peut!"; "bref..."; "j'approuve.";
      "I AM YOUR FATHER!"; "j'aime les patates";
      "viens au tableau s'il te plait!";
      "je suis contre"; "j'approuve"; "horreur";
      "consternation"; "mensonge!"; "ah la honte!";
      "s'pas faux..."; "tigre du bengale"; "c'est la guerre!";
      "Hitler"; "Staline"; "Nazi!"; "Communiste!";
      "Le Pen au pouvoir!"; "deux anges passent"; "radio";
      "j'ai une grosse courgette"; "bouilloire"; "morning coffee";
  |]

module Dummy_IA : Player.IA = struct

  module G = Dummy_game.G

  let play _ =
    if Random.int 2 = 0 then Unix.sleep 1;
    words.(Random.int (Array.length words))

end

module Dummy = Player.P(Dummy_IA)

let () =
  Random.self_init ();
  Dummy.run()
