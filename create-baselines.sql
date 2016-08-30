
set serveroutput on size unlimited

var n_expire_days number

-- change to something sensible for real use
exec :n_expire_days := 1

declare

	v_baseline_pfx varchar2(30) := 'dw'; -- tag as Data Warehouse
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
	pl('   begin_time: ' || aasrec.begin_time);
	pl('begin snap_id: ' || aasrec.begin_snap_id);
	pl('  end snap_id: ' || aasrec.end_snap_id);
	pl(' Metric Value: ' || aasrec.value);


	-- create the baselines
	-- catch errors if already exists

	begin
		v_baseline_name := v_baseline_pfx || '_'
			|| to_char(aasrec.begin_snap_id) || '_'
			|| to_char(aasrec.begin_time,'yyyymmdd-hh24:mi:ss');

		pl('Baseline Name: ' || v_baseline_name);
		--/*
		dbms_workload_repository.create_baseline(
			start_snap_id => aasrec.begin_snap_id,
			end_snap_id => aasrec.end_snap_id,
			baseline_name => v_baseline_name,
			dbid => aasrec.dbid, 
			expiration => i_expire_days
		);
		--*/

	exception
	when e_baseline_exists then
		pl('!!Baseline ' || v_baseline_name || ' already exists');
	when others then 
		raise;
	end;

	pl(lpad('=',30,'='));

end loop;

end;
/

