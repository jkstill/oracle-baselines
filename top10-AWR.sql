with max_snap_id as (
	select /*+ no_merge */ min(snap_id) snap_id
	from (
		select instance_number, max(snap_id) snap_id
		from dba_hist_snapshot
		group by instance_number
	)
),
aas as (
	select begin_snap_id, end_snap_id, value, snap_count, dbid, instance_number, rownum my_rownum
	from (
		select  begin_snap_id, end_snap_id, value, snap_count, dbid, instance_number
		from (
			select distinct
				--to_char(begin_time,'yyyy-mm-dd hh24:mi:ss') begin_time
				h.snap_id begin_snap_id
				, h.snap_id + 1 end_snap_id
				, trunc(avg(h.value) over (partition by snap_id, instance_number order by snap_id),1) value
				, count(h.value) over (partition by snap_id, instance_number order by snap_id) snap_count
				, h.dbid
				, h.instance_number
			from dba_hist_sysmetric_history h
			where metric_name = 'Average Active Sessions'
			and h.snap_id  < ( select snap_id from max_snap_id)
			-- if the very last snap_id were chosen as the begining of a report
			-- there would be no ending snap_id, which would result in an error when calling the report or creating the baseline
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
		--, aas.snap_count
		, aas.dbid
	from aas
	join dba_hist_snapshot sn on sn.snap_id = aas.begin_snap_id
		and sn.dbid = aas.dbid
		and sn.instance_number = aas.instance_number
	where my_rownum <= 10
	order by value desc
)
