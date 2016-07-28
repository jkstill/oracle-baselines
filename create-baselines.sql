
set serveroutput on size unlimited

begin
for aasrec in (
	@@top10aas
	select  begin_time, instance_number, begin_snap_id, aas, dbid
	from top10
)
loop
	dbms_output.put_line('   begin_time: ' || aasrec.begin_time);
	dbms_output.put_line('begin snap_id: ' || aasrec.begin_snap_id);
	dbms_output.put_line(lpad('=',30,'='));
end loop;
end;
/

