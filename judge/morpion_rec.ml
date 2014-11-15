open Core
open Main


module G = struct
  
  exception Invalid_pos

  type loc1 = int * int
  type loc = loc1 * loc1

  type c =      (* P1 <-> X || P2 <-> O *)
      | Empty
      | X
      | O
      | T

  type 'a r = 'a * 'a * 'a
  type 'a morpion = ('a r * 'a r * 'a r) * c

  (* On enregistre dans une grille de morpion le résultat
      pour cette grille : non attribué (Empty), X, O, ou nul (T)
     Pour y acceder, utiliser reduct : 'a morpion -> c *)
  let reduct (_, r) = r

  type game = game_status * c morpion morpion * loc1 option

  (* all_p1 : loc1 list *)
  let all_p1 = [ 1,1; 1,2; 1,3; 2,1; 2,2; 2,3; 3,1; 3,2; 3,3 ]
  (* all_w_s : loc1 list list *)
  let all_w_p1l = [
      [ 1,1; 1,2; 1,3 ];
      [ 2,1; 2,2; 2,3 ];
      [ 3,1; 3,2; 3,3 ];
      [ 1,1; 2,1; 3,1 ];
      [ 1,2; 2,2; 3,2 ];
      [ 1,3; 2,3; 3,3 ];
      [ 1,1; 2,2; 3,3 ];
      [ 1,3; 2,2; 3,1 ];
    ]

  (* encode : loc -> string *)
  let encode ((xg, yg), (xp, yp)) =
    Format.sprintf "%d %d %d %d" xg yg xp yp
  (* decode : string -> loc *)
  let decode s =
    Scanf.sscanf s "%d %d %d %d"
      (fun xg yg xp yp -> (xg, yg), (xp, yp))

  (* getp0 : ('a, 'a, 'a) -> int -> 'a *)
  let getp0 (a, b, c) x = match x with
    | 1 -> a | 2 -> b | 3 -> c
    | _ -> raise Invalid_pos
  (* getp1 : 'a morpion -> loc1 -> 'a *)
  let getp1 (m, _) (px, py) =
    getp0 (getp0 m px) py
  (* getp : 'a morpion morpion -> loc2 -> 'a *)
  let getp m (pg, pp) =
    getp1 (getp1 m pg) pp

  (* reduce_m : ('a -> c) -> 'a morpion -> c *)
  let reduce_m rf m =
    match
      all_w_p1l
      |> List.map (List.map (fun x -> rf (getp1 m x)))
      |> List.map (function
            | l when List.for_all ((=) X) l -> X
            | l when List.for_all ((=) O) l -> O
            | l when List.exists ((=) X) l && List.exists ((=) O) l -> T
            | l when List.exists ((=) T) l -> T
            | _ -> Empty)
    with
    | l when List.exists ((=) X) l -> X
    | l when List.exists ((=) O) l -> O
    | l when List.exists ((=) Empty) l -> Empty
    | _ -> T

  (* setp0 : ('a, 'a, 'a) -> int -> 'a -> ('a, 'a, 'a) *)
  let setp0 (a, b, c) x v = match x with
    | 1 -> (v, b, c)
    | 2 -> (a, v, c)
    | 3 -> (a, b, v)
    | _ -> raise Invalid_pos

  (* setp1 : 'a morpion -> loc1 -> 'a -> ('a -> 'c) -> 'a morpion *)
  let setp1 (m, r) (px, py) v rf =
    let k = setp0 m px (setp0 (getp0 m px) py v) in
    (k, if r = Empty then reduce_m rf (k, r) else r)
    (* pourquoi ce if ? parce que si quelqu'un a déjà gagné un petit morpion,
      alors même si l'adversaire aligne trois cases dedans APRES,
      le petit morpion reste attribué à la même personne. *)

  (* setp : 'a morpion morpion -> loc2 -> 'a -> 'a morpion morpion *)
  let setp m (pg, pp) v =
    let im = setp1 (getp1 m pg) pp v (fun x -> x) in
    let om = setp1 m pg im reduct in
    om

  (* r : 'a -> ('a, 'a, 'a) *)
  let r x = (x, x, x)

  (* *************************** *)
  (* Début du code intéressant ! *)

  let id = "morpion_rec"
  let name = "Morpion récursif!"

  let new_game = 
    TurnOf P1, (r (r (r (r Empty), Empty)), Empty), None

  let full_pm m =
    List.for_all (fun p -> getp1 m p <> Empty) all_p1

  let possibilities (s, m, lg) =
    let pg_poss = match lg with
      | None -> all_p1
      | Some x -> [x]
    in
    List.flatten
      (List.map (fun pg ->
          all_p1
          |> List.filter (fun pp -> getp m (pg, pp) = Empty)
          |> List.map (fun pp -> (pg, pp)))
        pg_poss)
    |> List.map encode


  let play (gs, m, pgo) act =
    let (pg, pp) = decode act in
    match gs with
    | TurnOf player when
        (match pgo with
          | None -> true
          | Some x -> pg = x)
        && getp m (pg, pp) = Empty 
      ->
        let op = other_player player in
        let new_m = setp m (pg, pp) (match player with P1 -> X | P2 -> O) in
        let new_s = match reduct new_m with
          | Empty -> TurnOf op
          | X -> Won P1
          | O -> Won P2
          | T -> Tie
        in
        (new_s, new_m, if full_pm (getp1 new_m pp) then None else Some pp)
    | TurnOf x -> (Eliminated x, m, pgo)
    | _ -> raise (Eliminated_ex "not someone's turn!")

  let s (s, _, _) = s


  (* ************************* *)
  (* Visualisation graphique ! *)

  open Graphics
  open Main
  open G_util

  let subpos (x1, y1, x2, y2) (l, c) =
    let dx, dy = (x2 - x1) / 3, (y2 - y1) / 3 in
    x1 + (l-1) * dx, y1 + (c-1) * dy, x1 + l * dx, y1 + c * dy
  let margin (x1, y1, x2, y2) m =
    (x1+m, y1+m, x2-m, y2-m)

  let disp_l lw pos =
    let x1, y1, x2, y2 = pos in
    function
    | X ->
      set_line_width lw;
      set_color p1c;
      draw_segments
        [| x1, y1, x2, y2;
           x1, y2, x2, y1 |];
      set_line_width 1
    | O ->
      set_line_width lw;
      set_color p2c;
      draw_circle ((x1+x2)/2) ((y1+y2)/2) (min (x2-x1) (y2-y1) / 2);
      set_line_width 1
    | _ -> ()

  let disp_r sdf box mor =
    let x1, y1, x2, y2 = box in
    let dx, dy = (x2 - x1) / 3, (y2 - y1) / 3 in
    let x12, x23 = x1 + dx, x1 + 2 * dx in
    let y12, y23 = y1 + dy, y1 + 2 * dy in
    set_color black;
    draw_segments
      [| x12, y1, x12, y2;
         x23, y1, x23, y2;
         x1, y12, x2, y12;
         x1, y23, x2, y23 |];
    List.iter (fun p -> sdf (margin (subpos box p) 6) (getp1 mor p)) all_p1;
    disp_l 2 box (reduct mor)

  let display_game (s, mor, q) (pn1, pn2) =
    let cx, cy = center() in
    let box = cx - 200, cy - 200, cx + 200, cy + 200 in
    disp_r (disp_r (disp_l 1)) box mor;
    begin match q, s with
    | Some p, TurnOf player ->
      let x1, y1, x2, y2 = margin (subpos box p) 3 in
      set_color (pc player);
      draw_rect x1 y1 (x2-x1) (y2-y1)
    | _ -> ()
    end


end

