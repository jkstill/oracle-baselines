
-- create top10 awr baselines

set serveroutput on size unlimited

@@config

set pause off echo off term on pagesize 0 linesize 200 trimspool on 
set feed off timing off


declare

	v_instance_name varchar2(30);
	v_db_name varchar2(30);

	v_baseline_pfx varchar2(30) := 'AWR-Top10'; -- used for reporting
	v_baseline_name varchar2(128);

	i_expire_days integer := :n_expire_days;

	e_baseline_exists exception;
	pragma exception_init(e_baseline_exists, -13528);

	procedure p ( p_in varchar2)
	is 
	begin
		dbms_output.put(p_in);
	end;

	procedure pl ( p_in varchar2)
	is 
	begin
		p(p_in);
		dbms_output.put_line(null);
	end;

begin


for aasrec in (
	@@top10
	select  begin_time, instance_number, begin_snap_id, end_snap_id, value, dbid
	from top10
)
loop
	v_baseline_name := v_baseline_pfx || '_'
		|| to_char(aasrec.begin_snap_id) || '_'
		|| to_char(aasrec.instance_number) || '_'
		|| to_char(aasrec.value) || '_'
		|| to_char(aasrec.begin_time,'yyyymmdd-hh24mi'); --  bug requires max name of 30 bytes

	pl(lpad('=',30,'='));
	pl('-- Baseline Name: ' || v_baseline_name);
	pl('--      instance: ' || aasrec.instance_number);
	pl('--    begin_time: ' || aasrec.begin_time);
	pl('-- begin snap_id: ' || aasrec.begin_snap_id);
	pl('--   end snap_id: ' || aasrec.end_snap_id);
	pl('--  Metric Value: ' || aasrec.value);

	-- create the baselines
	-- catch errors if already exists

	select instance_name into v_instance_name from gv$instance where instance_number = aasrec.instance_number;
	select name into v_db_name from gv$database where inst_id = aasrec.instance_number;

	begin

		dbms_workload_repository.create_baseline(
			start_snap_id => aasrec.begin_snap_id,
			end_snap_id => aasrec.end_snap_id,
			baseline_name => v_baseline_name,
			dbid => aasrec.dbid, 
			expiration => i_expire_days
		);


	exception
	when e_baseline_exists then
		pl('-- !!Baseline ' || v_baseline_name || ' already exists');
	when others then 
		raise;
	end;


end loop;

end;
/


set pagesize 60

set feed on
set timing on

