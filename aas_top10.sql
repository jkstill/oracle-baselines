aas as (
	select snap_id, value, dbid, instance_number, rownum my_rownum
	from (
   	select distinct snap_id, dbid, instance_number, max(value) over (partition by snap_id order by snap_id) value
   	from dba_hist_sysmetric_history
   	where metric_name = 'Average Active Sessions'
   	--and begin_time >= (sysdate - 31)
   	and begin_time >= (sysdate - 20)
   	and begin_time between (trunc(begin_time) + &&business_start_time) and ( trunc(begin_time) + &&business_end_time )
   	order by value desc
	)
),
top10aas as (
	select 
		sn.begin_interval_time begin_time
		, aas.instance_number
		, aas.snap_id
		, aas.value
		, aas.dbid
	from aas
	join dba_hist_snapshot sn on sn.snap_id = aas.snap_id
		and sn.instance_number = aas.instance_number
	where my_rownum <= 10
	order by value desc
)
