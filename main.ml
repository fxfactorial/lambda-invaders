open CamomileLibrary.UChar
open LTerm_key
open LTerm_geom

open Objects

lwt () =
   let do_run, push_layer, pop_layer, exit_ = LTerm_widget.prepare_simple_run () in

   let help_modal = new LTerm_widget.modal_frame in
   let speed_modal = new LTerm_widget.modal_frame in

   let game_frame = new game_frame exit_ (push_layer help_modal) in
   ignore (Lwt_engine.on_timer 0.10 true (fun e -> game_frame#queue_draw));

   do_run game_frame
