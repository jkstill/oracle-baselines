
-- aas-4.sql
-- top times based on dba_hist_sys_time_model DB Time + DB CPU

with data as (
	select
		m. snap_id
		, m.dbid
		, m.stat_name
		, m.instance_number
		, sum(m.value) value
	from DBA_HIST_SYS_TIME_MODEL m
	where m.stat_name in ('DB CPU', 'DB time')
	group by
		m. snap_id
		, m.dbid
		, m.stat_name
		, m.instance_number
	order by m.snap_id, m.instance_number
),
aas as (
	select
		m.dbid
		, m.snap_id begin_snap_id
		, m.snap_id + 1 end_snap_id -- obviously this can fail if it is the most recent snapshot
		, s.begin_interval_time
		, m.instance_number
		, m.value - lag(m.value,1) over (partition by m.instance_number order by m.snap_id) value
	from data m
	join dba_hist_snapshot s on s.snap_id = m.snap_id
		and s.instance_number = m.instance_number
	order by value desc nulls last
),
top10 as (
	select
		sn.begin_interval_time begin_time
		, aas.instance_number
		, aas.begin_snap_id
		, aas.end_snap_id
		, aas.value
		, aas.dbid
	from aas
	join dba_hist_snapshot sn on sn.snap_id = aas.begin_snap_id
		and sn.dbid = aas.dbid
		and sn.instance_number = aas.instance_number
	where rownum <= 10
	order by value desc
)
select * from top10
/
