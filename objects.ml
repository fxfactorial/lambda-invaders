open CamomileLibrary.UChar
open LTerm_key
open LTerm_geom
open LTerm_widget
open L_utils

type alien = {index:(int * int);
              coord:coord}
               
class game_frame exit_ show_help =
  object(self)
    inherit LTerm_widget.frame as super

    val mutable init = false
    val mutable previous_location = None
    val mutable rockets = [||]
    val mutable aliens = Array.make_matrix 5 5 None

    val defender_style = LTerm_style.({bold = None;
                                       underline = None;
                                       blink = None;
                                       reverse = None;
                                       foreground = Some lblue;
                                       background = Some lgreen})

    method draw ctx focused_widget =
      (* Calling super just for that frame wrapping, aka the |_| *)
      (* Make sure that row1 is smaller than row2 
         and that col1 is smaller than col2, it goes:       
                          row1
                      col1    col2
                          row2 *)
      LTerm_draw.clear ctx;
      super#draw ctx focused_widget;

      if not init
      then
        begin
          let this_size = LTerm_draw.size ctx in
          init <- true;
          let alien_ctx = LTerm_draw.sub ctx {row1 = 1;
                                              col1 = 3;
                                              row2 = 6;
                                              col2 = 8} in
          (* Aliens is not done *)
          LTerm_draw.fill alien_ctx (of_char 'a');
          
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
              (* let s = " Index: " ^ string_of_int index in *)
              (* log ((string_of_coord roc) ^ s); *)

          Array.iter (fun (index, roc) ->
              let ctx = LTerm_draw.sub ctx {row1 = roc.row - 2;
                                            col1 = roc.col;
                                            row2 = roc.row - 1;
                                            col2 = roc.col + 1} in
              LTerm_draw.draw_styled ctx 0 0 (LTerm_text.of_string "↥");
              Array.set rockets index (index , {roc with row = roc.row - 1})
                     )
                     (* Need the copy otherwise mutating the array as
                     you're iterating over it, a bug *)
                     (Array.copy rockets)
        end 

    method move_left =
      previous_location |>
      (function
        | Some p -> 
          previous_location <- Some {p with col = p.col - 2}
        | None -> ()
      )

    method move_right =
      previous_location |>
      (function
        | Some p ->
          previous_location <- Some {p with col = p.col + 2}
        | None -> ()
      )

    method fire_rocket =
      previous_location |>
      (function
        | Some p ->
          rockets <- Array.append [|(Array.length rockets, p)|] rockets
        | None -> ());
      self#queue_draw;

    initializer
      self#on_event
        (function
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
