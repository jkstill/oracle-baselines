with aas as (
	select begin_snap_id, end_snap_id, value, dbid, instance_number, rownum my_rownum
	from (
		select begin_snap_id
			, lead(begin_snap_id,1) over (partition by dbid, instance_number order by begin_snap_id) end_snap_id
			, round(db_time / elapsed_time,1)  value
			, dbid
			, instance_number
		from (
			select distinct h.snap_id begin_snap_id
				, h.instance_number
				, h.dbid
				, count(*) over (partition by h.snap_id, h.instance_number) * 10 db_time
				, (extract( day from (s.end_interval_time - s.begin_interval_time) )*24*60*60)+
					(extract( hour from (s.end_interval_time - s.begin_interval_time) )*60*60)+
					(extract( minute from (s.end_interval_time - s.begin_interval_time) )*60)+
					(extract( second from (s.end_interval_time - s.begin_interval_time)))
				elapsed_time
			from dba_hist_active_sess_history h
			join dba_hist_snapshot s on s.snap_id = h.snap_id
				and s.instance_number = h.instance_number
				and  (
					h.wait_class is null  -- on CPU
					or h.wait_class != 'Idle' -- wait events - ignore idle events
				)
				-- these predicates are useful if you have some idea of the date range
				--
				-- most recent 5 days
				-- and s.end_interval_time > systimestamp - 5 
				--
				-- or maybe a range
				-- and s.end_interval_time between timestamp '2016-08-01 00:00:01' and timestamp '2016-08-02 23:59:59'
		)
		order by value desc
	)
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
	where my_rownum <= 10
	order by value desc
)
