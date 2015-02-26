open CamomileLibrary.UChar
open LTerm_key
open LTerm_geom
open LTerm_widget
open L_utils


type action = Fire_rocket of coord
            | Move_left
            | Move_right

class game_frame exit_ show_help =
object(self)
  inherit LTerm_widget.frame as super

  val mutable init = false
  val mutable previous_location = None
  val mutable do_action = None

  val defender_style = LTerm_style.({bold = None;
                                     underline = None;
                                     blink = None;
                                     reverse = None;
                                     foreground = Some lblue;
                                     background = Some lgreen})
  method draw ctx focused_widget =
    (* Calling super just for that frame wrapping, aka the |_| *)
    super#draw ctx focused_widget;
    if not init
    then
      begin
        let this_size = LTerm_draw.size ctx in
        init <- true;
        previous_location <- Some {row = this_size.rows - 1;
                                   col = (this_size.cols / 2)};
        let ctx = LTerm_draw.sub ctx {row1 = this_size.rows - 2;
                                      col1 = (this_size.cols / 2);
                                      row2 = this_size.rows - 1;
                                      col2 = (this_size.cols / 2) + 1} in 
        (* NOTE Drawing outside of your context is a no op *)
        LTerm_draw.draw_string ctx 0 0 "λ"
      end
    else
      begin
        (* TODO Prevent out of bounds errors when widget goes off
             the edge of screen *)
        previous_location |>
          (function 
            | Some c ->
               let ctx = LTerm_draw.sub ctx {row1 = c.row - 1;
                                             col1 = c.col;
                                             row2 = c.row ;
                                             col2 = c.col + 1 } in
               LTerm_draw.clear ctx;
               LTerm_draw.draw_styled ctx 0 0
                                      ~style:defender_style
                                      (LTerm_text.of_string "λ")
            | None -> () );

        do_action |>
          (function
            | Some action ->
               (match action with
                | Fire_rocket loc ->
                   loc |> string_of_coord |> log;
                   let ctx = LTerm_draw.sub ctx {row1 = 0;
                                                 col1 = loc.col;
                                                 row2 = loc.row - 1;
                                                 col2 = loc.col + 1} in
                   (* let rec rocket_painter loc  *)
  (* ignore (Lwt_engine.on_timer 1.0 true 
(fun _ -> clock#set_text (get_time ()))); *)
                   LTerm_draw.fill ctx (of_char 'a')
                   (* LTerm_draw.draw_styled ctx 0 0 *)
                   (*                        (LTerm_text.of_string "↥"); *)
                | _ -> ())
            | None -> () )
      end 

  method move_left =
    log "Move left called";
    do_action <- Some Move_left;
    previous_location |>
      (function
        | Some p -> 
           previous_location <- Some {p with col = p.col - 2}
        | None -> ()
      );
    self#queue_draw

  method move_right =
    do_action <- Some Move_right;
    previous_location |>
      (function
        | Some p ->
           previous_location <- Some {p with col = p.col + 2}
        | None -> ()
      );
    self#queue_draw

  method fire_rocket =
    log "Firing the rocket";
    previous_location |>
      (function
        | Some p ->
           do_action <- Some (Fire_rocket p);
        | None -> ());
    self#queue_draw

  initializer
    self#on_event
           (function
             | LTerm_event.Key {code = Left} ->
                log "Move left ";
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
end
