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

let gframe_handler exit_ show_help =
  (fun event ->
     match event with
     | LTerm_event.Key
         {meta = true; code = LTerm_key.Char ch}
       when ch = of_char 'h' ->
       show_help ();
       true
     | LTerm_event.Key
         {code = LTerm_key.Char ch}
       when ch = of_char 'q' ->
       exit_ ();
       true
     | _ -> false)

lwt () =
   let do_run, push_layer, pop_layer, exit_ = LTerm_widget.prepare_simple_run () in
   (* let root_box = new game_box in *)
   let help_modal = new LTerm_widget.modal_frame in
   let game_frame = new game_frame exit_ (push_layer help_modal)in 
   
   do_run game_frame
