let get_time () =
  let localtime = Unix.localtime (Unix.time ()) in
  Printf.sprintf "[%02u:%02u:%02u]: "
    localtime.Unix.tm_hour
    localtime.Unix.tm_min
    localtime.Unix.tm_sec

(* let log message = *)
(*   let open Core.Std in *)
(*   let oc = open_out_gen [Open_wronly; *)
(*                          Open_creat; *)
(*                          Open_append] 0o666 "log" in *)
(*   output_string oc ((get_time ()) ^ message ^ "\n"); *)
(*   Out_channel.close oc *)

