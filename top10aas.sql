with aas as (
	select begin_snap_id, end_snap_id, aas, dbid, instance_number, rownum my_rownum
	from (
      select 
         begin_snap_id
         , lead(s.snap_id,1) over (partition by h.dbid, h.instance_number order by h.begin_snap_id) end_snap_id
         , h.dbid
         , h.instance_number
			, h.max_aas aas
      from (
			-- get max AAS per snap_id
         select
            snap_id begin_snap_id
            , instance_number
				, dbid
            --, round(avg(value),0) avg_aas
            ,max(value) max_aas
         from dba_hist_sysmetric_history
         where metric_name = 'Average Active Sessions'
         group by snap_id,instance_number, dbid
      )  h
		-- join is to get the next snap_id via lead()
		join dba_hist_snapshot s on s.instance_number = h.instance_number
			and s.snap_id = h.begin_snap_id
      order by max_aas desc
	)
),
top10 as (
	select 
		sn.begin_interval_time begin_time
		, aas.instance_number
		, aas.begin_snap_id
		, aas.end_snap_id
		, aas.aas
		, aas.dbid
	from aas
	join dba_hist_snapshot sn on sn.snap_id = aas.begin_snap_id
		and sn.instance_number = aas.instance_number
	where my_rownum <= 10
	order by aas desc
)
