open CamomileLibrary.UChar
open LTerm_key
open LTerm_geom

let (>>=) = Lwt.(>>=)


let lambda =
"     _ 
    /   \ 
   /     \
          \ 
         / \ 
        /   \ 
       /     \\__ 
"

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


class defender =
  object(self)
    inherit LTerm_widget.t "defender" as super

    val mutable init = false
    val mutable previous_location = None
    
    method can_focus =
      true

    method draw ctx focused_widget =
      if not init
      then
        begin
          let this_size = LTerm_draw.size ctx in
          init <- true;
          previous_location <- Some {row = this_size.rows - 1;
                                    col = (this_size.cols / 2)};
          let ctx = LTerm_draw.sub ctx {row1 = this_size.rows - 1;
                                        col1 = (this_size.cols / 2);
                                        row2 = this_size.rows;
                                        col2 = (this_size.cols / 2) + 1} in 
          (* NOTE Drawing outside of your context is a no op *)
          LTerm_draw.draw_string ctx 0 0 "λ"
        end
      else
        begin
          (* TODO Prevent out of bounds errors when widget goes off
          the edge of screen *)
          previous_location |> (function 
              | Some c ->
                let ctx = LTerm_draw.sub ctx {row1 = c.row;
                                              col1 = c.col;
                                              row2 = c.row + 1;
                                              col2 = c.col + 1 } in
                LTerm_draw.clear ctx;
                LTerm_draw.draw_styled ctx 0 0 (LTerm_text.of_string "λ")
              | None -> () )
        end 
          
    (* LTerm_geom.( *)
      (*   ignore (Lazy.force LTerm.stdout >>= (fun term -> *)
      (*       let t_size = LTerm.size term in *)
      (*       (\* log (string_of_size t_size); *\) *)
      (*       LTerm_draw.draw_string ctx (t_size.rows - 3) (t_size.cols / 2) "λ"; *)
      (*       Lwt.return ()))) *)
      (* LTerm_draw.fill ctx (of_char 'a')  *)

    (* TODO Refactor this to use polymorphic variants, perhaps a task for
       Gina *)
    method move_left =
      previous_location |> (function
          | Some p -> 
            previous_location <- Some {p with col = p.col - 2}
          | None -> ()
        );
        self#queue_draw

    method move_right =
      previous_location |> (function
          | Some p ->
            previous_location <- Some {p with col = p.col + 2}
          | None -> ()
        );
        self#queue_draw

    method fire_rocket =
      log "Firing the rocket"
        
    initializer
      self#on_event (function
          | LTerm_event.Key {code = Left} ->
            self#move_left;
            true
          | LTerm_event.Key {code = Right} ->
            self#move_right;
            true
          | LTerm_event.Key
              {code = LTerm_key.Char ch}
            when ch = of_char ' ' ->
            self#fire_rocket;
            true
            (* false will propogate the event downward *)
          | _ -> false)
  end

class alien =
  object(self)
    inherit LTerm_widget.t "alien"

    method can_focus =
      true

    method draw ctx focused_widget =
      LTerm_draw.fill ctx (of_char 'c');
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

     
   (* root_box#add (new alien); *)
   root_box#add (new defender);
   (* List.length root_box#children |> string_of_int |> log; *)
   game_frame#set root_box;
   game_frame#on_event (gframe_handler exit_ (push_layer help_modal));
   do_run game_frame

