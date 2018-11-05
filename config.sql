
var n_expire_days number
-- change to something sensible for real use
exec :n_expire_days := 1


var v_report_type varchar2(4)
-- valid choices are html and text
exec :v_report_type := 'text'

