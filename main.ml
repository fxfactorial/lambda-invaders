open CamomileLibrary.UChar
open LTerm_key


let (>>=) = Lwt.(>>=)

let get_time () =
  let localtime = Unix.localtime (Unix.time ()) in
  Printf.sprintf "[%02u:%02u:%02u]: "
    localtime.Unix.tm_hour
    localtime.Unix.tm_min
    localtime.Unix.tm_sec

let log message =
  let open Core.Std in
  let oc = open_out_gen [Open_wronly;
                         Open_creat;
                         Open_append] 0o666 "log" in
  output_string oc ((get_time ()) ^ message ^ "\n");
  Out_channel.close oc

(* let fire_rocket coord = *)
  (* let ctx = LTerm_draw.context (LTerm_draw.make_matrix {rows = 1; cols = 1}) in *)
(*   log_message "Fired"; *)
  (* ignore (Lwt_engine.on_timer 0.3 true (fun _ -> log_message "Fired")) *)

(* let fire_rocket ui = *)
(*   let ctx = LTerm_draw.context *)
(*       (LTerm_draw.make_matrix {rows=10; cols=10}) *)
(*       ({rows = 10; cols = 10}) in *)
(*   LTerm_draw.fill ctx (of_char 'h'); *)
  (* LTerm_draw.draw_frame ctx {row1 = 10; *)
  (*                            col1 = 10; *)
  (*                            row2 = 10; *)
  (*                            col2 = 10} LTerm_draw.Heavy; *)
  (* LTerm_draw.draw_string ctx 0 0 "Hello"; *)
  (* LTerm_draw.draw_styled ctx 10 10  *)
  (*   (eval [B_fg LTerm_style.lyellow; S"Hello";E_fg]); *)
(*   log_message "Finished rocket" *)
    
(* let rec loop ui coord = *)
(*     LTerm_ui.wait ui >>= function *)
(*     | LTerm_event.Key {code = LTerm_key.Char ch } *)
(*       when ch = of_char ' ' -> *)
(*       LTerm_ui.draw ui; *)
(*       fire_rocket ui; *)
(*       loop ui coord *)
(*     | LTerm_event.Key{ code = Left } -> *)
(*       coord := { !coord with col = !coord.col - 3 }; *)
(*       LTerm_ui.draw ui; *)
(*       loop ui coord *)
(*     | LTerm_event.Key{ code = Right } -> *)
(*       coord := { !coord with col = !coord.col + 3 }; *)
(*       LTerm_ui.draw ui; *)
(*       loop ui coord *)
(*     | LTerm_event.Key {code = LTerm_key.Char ch} *)
(*       when ch = of_char 'q' -> *)
(*       return () *)
(*     | LTerm_event.Key{ code = Escape } -> *)
(*       return () *)
(*     | ev -> *)
(*       loop ui coord *)

(* let draw ui matrix coord = *)
(*   let size = LTerm_ui.size ui in *)
(*   let ctx = LTerm_draw.context matrix size in *)
(*   (\* log_message (string_of_int size.rows ^ ":" ^ string_of_int size.cols); *\) *)
(*   LTerm_draw.clear ctx; *)
(*   LTerm_draw.draw_frame ctx { row1 = 0; *)
(*                               col1 = 0; *)
(*                               row2 = size.rows; *)
(*                               col2 = size.cols } LTerm_draw.Light; *)
(*   (\* log_message (string_of_int coord.row ^ " " ^ string_of_int coord.col); *\) *)

(* (\* original *\) *)
(*   (\* if size.rows > 2 && size.cols > 2 *\) *)
(*   if coord.col > 3 && *)
(*      coord.col <= (size.cols - 3) *)
(*   then *)
(*     begin *)
(*       (\* This determines where its position is *\) *)
(*       let ctx = LTerm_draw.sub ctx { row1 = 1; *)
(*                                      col1 = 1; *)
(*                                      row2 = size.rows - 1; *)
(*                                      col2 = size.cols - 1 } in *)
(*       log_message (string_of_coord coord); *)
(*       LTerm_draw.draw_styled ctx coord.row coord.col *)
(*         (eval [B_fg LTerm_style.lblue; S "λ"; E_fg]) *)
(*     end *)
(* lwt () = *)
(*     lwt term = Lazy.force LTerm.stdout in *)
(*     let size_ = LTerm.size term in *)
(*     let coord = ref { row = size_.rows - 3; col = size_.cols / 2 } in *)

(*     lwt ui = LTerm_ui.create term (fun ui matrix -> *)
(*                                    draw ui matrix !coord) in *)
(*     try_lwt *)
(*       loop ui coord *)
(*     finally *)
(*       LTerm_ui.quit ui *)

class defender =
  object(self)
    inherit LTerm_widget.t "defender" as super

    (* val mutable current_ctx =  *)
    method can_focus =
      true

    method draw ctx focused_widget =
      (* Do I need to call the super classes' methods *)
      (* super#draw ctx focused_widget; *)
      LTerm_geom.(
      ignore (Lazy.force LTerm.stdout >>= (fun term -> 
          let t_size = LTerm.size term in 
          LTerm_draw.draw_string ctx (t_size.rows - 3) (t_size.cols / 2) "λ";
          Lwt.return ())))

    initializer
      self#on_event (function
          | LTerm_event.Key {code = Left} ->
            log "Hit left";
            true
          | LTerm_event.Key {code = Right} ->
            log "Hit Right";
            true
            (* false will propogate the event downward *)
          | _ -> false)
  end 

let gframe_handler exit_ show_help =
  (fun event ->
     match event with
     | LTerm_event.Key
         {meta = true; code = LTerm_key.Char ch}
       when ch = of_char 'h' ->
       show_help ();
       false
     | LTerm_event.Key
         {code = LTerm_key.Char ch}
       when ch = of_char 'q' ->
       exit_ ();
       false
     | _ -> true)

lwt () =
   let do_run, push_layer, pop_layer, exit_ = LTerm_widget.prepare_simple_run () in
   let root_box = new LTerm_widget.vbox in
   let game_frame = new LTerm_widget.frame in
   let help_modal = new LTerm_widget.modal_frame in 
   
   (* root_box#on_event  *)
   (* root_box#add game_frame; *)
   root_box#add (new defender);
   game_frame#set root_box;
   game_frame#on_event (gframe_handler exit_ (push_layer help_modal));
   do_run game_frame
