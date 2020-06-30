
-- create top10 awr baselines
-- at the same time create a script to generate AWR reports
-- for RAC this will be a report for that instance only
--
-- the AWR reports are based on script awr_defined.sql
-- to report clusterwide, see awr_RAC_defined.sql


set serveroutput on size unlimited

@@config

-- set view_loc as '', AWR_ROOT or AWR_PDB
@@set-view-loc

var view_loc varchar2(10);

exec :view_loc := '&view_loc'

set pause off echo off term on pagesize 0 linesize 200 trimspool on 
set feed off timing off

spool top10-awrrpt.sql

prompt host mkdir -p awr-reports

declare

	v_instance_name varchar2(30);
	v_db_name varchar2(30);

	v_report_pfx varchar2(30) := 'AWR-Top10'; -- used for reporting
	v_report_name varchar2(128);

	i_expire_days integer := :n_expire_days;

	e_baseline_exists exception;
	pragma exception_init(e_baseline_exists, -13528);

	v_report_sfx varchar2(5);

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

if :v_report_type = 'text' then
	v_report_sfx := '.txt';
else
	v_report_sfx := '.html';
end if;

dbms_output.put_line('--' || lpad('=',30,'='));

for aasrec in (
select
	baseline_name
	, dbid
	, baseline_type
	, start_snap_id begin_snap_id
	, start_snap_time begin_time
	, end_snap_id
	-- dba_hist_baseline does not store an instance number
	-- hence it is encoded into the baseline name
	-- the metric value used to determine the top 10 is also encoded in the name
	, substr(
		baseline_name, 
		instr(baseline_name,'_',1,2)+1, -- start of instance number
		1 -- length
	) instance_number
	, substr(
		baseline_name, 
		instr(baseline_name,'_',1,3)+1, -- start of metric value
		instr(baseline_name,'_',1,4) - instr(baseline_name,'_',1,3) -1 -- length
	) metric
from dba_hist_baseline
where baseline_name like 'AWR-Top10%'
order by creation_time
)
loop

		v_report_name := v_report_pfx || '_'
			|| to_char(aasrec.begin_snap_id) || '_'
			|| to_char(aasrec.instance_number) || '_'
			|| to_char(aasrec.metric) || '_'
			|| to_char(aasrec.begin_time,'yyyymmdd-hh24mi') --  bug requires max name of 30 bytes
			|| v_report_sfx;

	pl('-- Baseline Name: ' || aasrec.baseline_name);
	pl('--   Report Name: ' || v_report_name);

	pl('--    begin_time: ' || aasrec.begin_time);
	pl('-- begin snap_id: ' || aasrec.begin_snap_id);
	pl('--   end snap_id: ' || aasrec.end_snap_id);

	-- create the baselines
	-- catch errors if already exists

	select name into v_db_name from v$database;
	select instance_name into v_instance_name from gv$instance where instance_number = aasrec.instance_number;

	pl('define  inst_name    = ' || v_instance_name);
	pl('define  inst_num  = ' || '''' || aasrec.instance_number || '''');

	pl('define  num_days     = 0');
	pl('define  db_name      = ' || v_db_name);
	pl('define  dbid         = ' || to_char(aasrec.dbid));
	pl('define  begin_snap   = ' || to_char(aasrec.begin_snap_id));
	pl('define  end_snap     = ' || to_char(aasrec.end_snap_id));
	pl('define  report_type  = ' || :v_report_type);
	pl('define  view_loc     = ' || :view_loc);

	--pl('define  report_name  =  awr-reports/AWR-Top10_' || to_char(aasrec.instance_number) || '_' || to_char(aasrec.begin_snap_id) || '_'  || to_char(aasrec.end_snap_id) || '.html');
	pl('define  report_name  =  awr-reports/' || v_report_name);

	pl('@?/rdbms/admin/awrrpti');


	pl('-- ' || lpad('=',30,'='));

end loop;

end;
/

spool off

set pagesize 60

set feed on
set timing on

prompt
prompt Now run AWR reports with top10-awrrpt.sql
prompt 

