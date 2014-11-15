module C = Core.Core(Dummy_game.G)
module Main = Main.Juge(C)

let () =
  Random.self_init ();
  Main.run ()
