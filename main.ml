open CamomileLibrary.UChar
open LTerm_key
open LTerm_geom

open Objects

lwt () =
   let do_run, push_layer, pop_layer, exit_ = LTerm_widget.prepare_simple_run () in

   let end_game = new LTerm_widget.modal_frame in
   end_game#on_event
     (function
       | LTerm_event.Key  {code = LTerm_key.Char ch}
         when ch = of_char 'q' ->
         exit_ ();
         false
       | _ -> false );

   end_game#set (new LTerm_widget.label "End game, press 'q' to quit");

   let help_modal = new LTerm_widget.modal_frame in
   let speed_modal = new LTerm_widget.modal_frame in

   let game_frame = new game_frame exit_
     (push_layer help_modal)
     (push_layer end_game) in
   
   ignore (Lwt_engine.on_timer 0.01 true (fun e -> game_frame#queue_event_draw e));

   do_run game_frame
