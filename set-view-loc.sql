
-- set-view-loc.sql
-- the define variable view_loc determines if this is legacy, cdb or pdb

set term on feed on

set serveroutput on size 1000000

var u_container varchar2(10)

col view_loc new_value view_loc noprint

define view_loc=''

set feed off

declare
	legacy_db_err exception;
	pragma exception_init(legacy_db_err,-2003);

begin
	select sys_context('userenv','con_name') into :u_container from dual;
exception
when legacy_db_err then
	:u_container := 'LEGACY';
end;
/

set term off feed off head off
select 
	case :u_container 
	when 'LEGACY' then ''
	when 'CDB$ROOT' then 'AWR_ROOT'
	else 'AWR_PDB'
	end view_loc 
from dual;

set term on feed on head on

select 'view_loc: &view_loc' view_location from dual;

