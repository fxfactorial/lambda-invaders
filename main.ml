open CamomileLibrary.UChar
open LTerm_key
open LTerm_geom

open Objects

let (>>=) = Lwt.(>>=)

(* TODO Maybe find a way to use this instead of the single char of
   lambda *)
let lambda =
"     _ 
    /   \ 
   /     \
          \ 
         / \ 
        /   \ 
       /     \\__ 
"

lwt () =
   let do_run, push_layer, pop_layer, exit_ = LTerm_widget.prepare_simple_run () in

   let splash_modal = new LTerm_widget.modal_frame in
   let help_modal = new LTerm_widget.modal_frame in
   let speed_modal = new LTerm_widget.modal_frame in

   let game_frame = new game_frame exit_ (push_layer help_modal) in
   ignore (Lwt_engine.on_timer 0.1 true (fun e -> game_frame#queue_draw));

   (* push_layer splash_modal (); *)
   do_run game_frame
