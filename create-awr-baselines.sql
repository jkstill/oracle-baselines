
-- create top10 awr baselines
-- at the same time create a script to generate AWR reports
-- for RAC this will be a report for that instance only
--
-- the AWR reports are based on script awr_defined.sql
-- to report clusterwide, see awr_RAC_defined.sql


set serveroutput on size unlimited

var n_expire_days number

-- change to something sensible for real use
exec :n_expire_days := 1

set pause off echo off term on pagesize 0 linesize 200 trimspool on 
set feed off timing off


spool top10-awrrpt.sql

prompt host mkdir -p awr-reports

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

dbms_output.put_line(lpad('=',30,'='));

for aasrec in (
	@@top10
	select  begin_time, instance_number, begin_snap_id, end_snap_id, value, dbid
	from top10
)
loop
	pl('--    begin_time: ' || aasrec.begin_time);
	pl('-- begin snap_id: ' || aasrec.begin_snap_id);
	pl('--   end snap_id: ' || aasrec.end_snap_id);
	pl('--  Metric Value: ' || aasrec.value);

	-- create the baselines
	-- catch errors if already exists

	select instance_name into v_instance_name from gv$instance where instance_number = aasrec.instance_number;
	select name into v_db_name from gv$database where inst_id = aasrec.instance_number;

	pl('define  inst_num    = ' || to_char(aasrec.instance_number));
	pl('define  inst_name    = ' || v_instance_name);

	pl('define  num_days     = 1');
	pl('define  db_name      = ' || v_db_name);
	pl('define  dbid         = ' || to_char(aasrec.dbid));
	pl('define  begin_snap   = ' || to_char(aasrec.begin_snap_id));
	pl('define  end_snap     = ' || to_char(aasrec.end_snap_id));
	pl('define  report_type  = html');

	pl('define  report_name  =  awr-reports/AWR-Top10_' || to_char(aasrec.instance_number) || '_' || to_char(aasrec.begin_snap_id) || '_'  || to_char(aasrec.end_snap_id) || '.html');

	pl('@?/rdbms/admin/awrrpti');

	--/*

	begin
		v_baseline_name := v_baseline_pfx || '_'
			|| to_char(aasrec.begin_snap_id) || '_'
			|| to_char(aasrec.begin_time,'yyyymmdd-hh24mi'); --  bug requires max name of 30 bytes

		pl('-- Baseline Name: ' || v_baseline_name);
		--/*
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

	--*/

	pl('-- ' || lpad('=',30,'='));

end loop;

end;
/

spool off

set pagesize 60

set feed on
set timing on

