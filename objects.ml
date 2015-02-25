open CamomileLibrary.UChar
open LTerm_key
open LTerm_geom

open Utils
  
class rocket =
object(self)
  inherit LTerm_widget.t "rocket"
  (* method draw ctx focused_widget = *)
  (*   LTerm_draw.fill ctx (of_char 'a') *)
        
 end

class game_frame =
object(self)
  inherit LTerm_widget.frame as super
  method draw ctx f_widget =
    super#draw ctx f_widget;
end 

(* I HATE that you can't downcast *)
class defender (parent: LTerm_widget.vbox) =
  object(self)
    inherit LTerm_widget.t "defender" as super

    val mutable init = false
    val mutable previous_location = None
    val defender_style = LTerm_style.({bold = None;
                                       underline = None;
                                       blink = None;
                                       reverse = None;
                                       foreground = Some lblue;
                                       background = Some lgreen})
                                       
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
                LTerm_draw.draw_styled ctx 0 0
                                       ~style:defender_style
                                       (LTerm_text.of_string "λ")
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
      log "Firing the rocket";
      parent#add (new rocket)
          
      (* self#parent |> (function *)
      (*                  | Some p -> *)
      (*                     p#add (new rocket); *)
      (*                     (\* List.length p#children |> string_of_int |> log ; *\) *)
      (*                  | None -> () *)
      (*                ) *)
        
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
