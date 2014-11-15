
exception Invalid_message of string

type msg =
  | Hello of string   (* nom du jeu *)
  | YourTurn of float   (* nombre secondes pour jouer *)
  | Play of string    (* description textuelle du coup *)
  | OK          (* coup accepté *)
  | YouWin
  | YouLose
  | Tie
  | Eliminated
  | FairEnough

let decode = function
  | "OK" -> OK
  | "You win" -> YouWin
  | "You lose" -> YouLose
  | "Tie" -> Tie
  | "Eliminated" -> Eliminated
  | "Fair enough" -> FairEnough
  | s when String.sub s 0 6 = "Hello " ->
    Hello (String.sub s 6 (String.length s - 6))
  | s when String.sub s 0 10 = "Your turn " ->
    YourTurn (float_of_string (String.sub s 10 (String.length s - 10)))
  | s when String.sub s 0 5 = "Play " ->
    Play (String.sub s 5 (String.length s - 5))
  | s -> raise (Invalid_message s)

let encode = function
  | Hello x -> "Hello " ^ x
  | YourTurn n -> "Your turn " ^ (string_of_float n)
  | Play x -> "Play " ^ x
  | OK -> "OK"
  | YouWin -> "You win"
  | YouLose -> "You lose"
  | Tie -> "Tie"
  | Eliminated -> "Eliminated"
  | FairEnough -> "Fair enough"


