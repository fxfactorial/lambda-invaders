open CamomileLibrary.UChar
open LTerm_key
open LTerm_geom
open LTerm_widget
open L_utils

module Opt = Batteries.Option

class game_frame exit_ show_help show_endgame =
  object(self)
    inherit LTerm_widget.frame as super

    val mutable init = false
    val mutable previous_location = None
    val mutable rockets = [||]
    val mutable aliens = [||]
    val hits = ref 0
    val go_down = ref 0 
    (* 0 is down, 1 is left, 2 is right *)
    val direction = ref 1
    val max_cols = ref 0
    val mutable current_event = None

    val defender_style = LTerm_style.({bold = None;
                                       underline = None;
                                       blink = None;
                                       reverse = None;
                                       foreground = Some lblue;
                                       background = Some lgreen})

    val rocket_style = LTerm_style.({bold = None;
                                     underline = None;
                                     blink = None;
                                     reverse = None;
                                     foreground = Some lred;
                                     background = None})

    (* Not sure why this doesn't compile without the explicit type
       signature *)
    method queue_event_draw (event : Lwt_engine.event) =
      current_event <- Some event;
      self#queue_draw

    method draw ctx focused_widget =
      (* Calling super just for that frame wrapping, aka the |_| *)
      (* Make sure that row1 is smaller than row2 
         and that col1 is smaller than col2, it goes:       
                          row1
                      col1    col2
                          row2 *)
      LTerm_draw.clear ctx;
      super#draw ctx focused_widget;
      LTerm_draw.draw_string ctx 0 0 ("Hits: " ^ (string_of_int !hits));
      LTerm_draw.draw_string ctx 13 0 ~style:LTerm_style.({bold = None;
                                                    underline = None;
                                                    blink = Some true;
                                                    reverse = None;
                                                    foreground = Some lyellow;
                                                    background = None})
        "Game Over Line";

      if not init
      then
        begin
          let this_size = LTerm_draw.size ctx in
          init <- true;
          max_cols := this_size.cols;
          
          previous_location <- Some {row = this_size.rows - 1;
                                     col = (this_size.cols / 2)};
          
          let ctx_ = LTerm_draw.sub ctx {row1 = this_size.rows - 2;
                                        col1 = (this_size.cols / 2);
                                        row2 = this_size.rows - 1;
                                        col2 = (this_size.cols / 2) + 1} in

          (* NOTE Drawing outside of your context is a no op *)
          LTerm_draw.draw_string ctx_ 0 0 "λ";
          (* TODO Pick smarter values as a function of terminal size? *)

          (* Rows*)
          for i = 3 to 10 do
            (* Columns *)
            for j = 10 to 44 do
              if (i mod 2 > 0) && (j mod 2 > 0)
              then
                aliens <- Array.append [|Some (Array.length aliens, (i, j))|] aliens;
                LTerm_draw.draw_string ctx i j "A"
            done
          done 
                
        end
      else
        if (fst (snd (Opt.get (Array.get aliens 51)))) = 12
        then current_event |> (function
            | Some e ->
              Lwt_engine.stop_event e;
              self#show_endgame_modal ()
            | None -> ());
      
        begin
          (* Drawing the lambda defender *)
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
            | None -> ());

          begin 
          (* Aliens drawing *)
            let cp = Array.copy aliens in
            match !direction with
            (* 2 is right, 1 is left, 0 is down *)
            | 0 ->
              Array.iter (fun a ->
                  match a with
                  | Some (index, (i, j)) ->
                    Array.set aliens index (Some (index, ((i + 1), j)));
                    LTerm_draw.draw_string ctx (i + 1) j "A"
                  | None -> ())
                cp;
               go_down := !go_down mod 3;
               direction := !direction + 1;
            | 1 ->
              Array.iter (fun a ->
                  match a with
                  | Some (index, (i, j)) ->
                    Array.set aliens index (Some (index, (i, (j - 1))));
                    LTerm_draw.draw_string ctx i (j - 1) "A"
                  | None -> ())
                cp;
            | 2 ->
              Array.iter (fun a ->
                  match a with
                  | Some (index, (i, j)) ->
                    Array.set aliens index (Some (index, (i, (j + 1))));
                    LTerm_draw.draw_string ctx i (j + 1) "A"
                  | None -> ())
                cp;
            | _ -> ();

              (* Change directions *)
          end ;
          (* Setting the direction *)
          if !go_down = 3
          then
            direction := 0;

          begin 
            match Array.get aliens 0 with
            | (Some (index, (row, column))) -> 
              if column = 1
              then
                (direction := 2;
                 go_down := !go_down + 1)
              else if (match Array.get aliens ((Array.length aliens) - 1) with 
                           | Some (index, (row, column)) ->
                             column = ((LTerm_draw.size ctx).cols - 2)
                           | None -> false)
              then
                (direction := 1;
                 go_down := !go_down +1);
            | None -> ()
          end;

          (*   | None -> () *)
          (* end ; *)
          (*   begin *)
          (*     match Array.get aliens ((Array.length aliens) - 1) with *)
          (*     | Some (index, (row, column)) -> *)
          (*       if ((LTerm_draw.size ctx).cols - 2) = column *)
          (*       then *)
          (*         (direction := 1; *)
          (*          go_down := !go_down +1) *)
          (*     | None -> () *)
          (*   end ; *)


          (* Rockets drawing *)
          Array.iter (fun (index, roc) ->
              let ctx = LTerm_draw.sub ctx {row1 = roc.row - 1;
                                            col1 = roc.col;
                                            row2 = roc.row;
                                            col2 = roc.col + 1} in
              (* Regular exception handling doesn't work cause
                         it needs to be something like try_lwt *)
              if roc.row > 1 then
                begin
                  (* Array.iter (fun (Some (index, (row, column))) -> *)
                  Array.iter (fun r ->
                      match r with
                      | Some (index, (row, column)) -> 
                        if (roc.row = row) &&
                           (roc.col = column)
                        then
                          begin 
                            Array.set aliens index None;
                            hits := !hits + 1
                          end
                      | None -> ()
                    )
                    aliens;
                  LTerm_draw.draw_styled ctx 0 0 ~style:rocket_style
                    (LTerm_text.of_string "↥");
                  Array.set rockets index (index , {roc with row = roc.row - 1})
                end
              else
                  Array.set rockets index (index , roc))
                     (* Need the copy otherwise mutating the array as
                        you're iterating over it, a bug *)
                     (Array.copy rockets)
        end

    method show_endgame_modal () =
      show_endgame ()

    method move_left =
      previous_location |>
      (function
        | Some p ->
          if p.col > 2 then
          previous_location <- Some {p with col = p.col - 2}
        | None -> ()
      )

    method move_right =
      previous_location |>
      (function
        | Some p ->
          if p.col < !max_cols - 3 then
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
