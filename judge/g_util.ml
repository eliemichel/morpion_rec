open Graphics
open Core

(* Graphic helpers *)
let grey = rgb 112 112 112
let red = rgb 200 0 0
let green = rgb 0 150 0
let orange = rgb 200 140 0

let p1c = blue
let p2c = red

let pc = function P1 -> p1c | P2 -> p2c

let center () = size_x () / 2, size_y () / 2

let fullscreen_msg m =
  clear_graph();
  let tx, ty = text_size m in
  let cx, cy = center () in
  let w, h = tx/2, ty/2 in
  set_color black;
  let cr d =
    draw_rect (cx - w - d) (cy - h - d)
              (2 * (w + d)) (2 * (h + d))
  in cr 20; cr 22;
  moveto (cx - w) (cy - h);
  draw_string m;
  synchronize ()

let tw m = fst (text_size m)

let text_l l x c m =
  set_color c;
  moveto x (size_y() - ((l+1) * 20));
  draw_string m

let text1 l c m =
  text_l l 30 c m
let text2 l c m =
  text_l l (size_x()/2 - 30 - tw m) c m
let text3 l c m =
  text_l l (size_x()/2 + 30) c m
let text4 l c m =
  text_l l (size_x() - 30 - tw m) c m

let hl () =
  draw_poly_line
    [| 10, size_y() - 50;
       size_x() - 10, size_y() - 50 |]
