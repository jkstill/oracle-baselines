with top10 as (
	select 
		aas.begin_time
		, aas.instance_number 
		, aas.snap_id begin_snap_id
		-- include end snap ID
		--, lead(h.snap_id,1) over (partition by aas.dbid, aas.instance_number order by h.snap_id) end_snap_id
		, aas.aas value
		, aas.dbid
		, rownum rnum
	from (
		select /*+ dynamic_sampling(4) full(h) full(s)  */
       	min(h.snap_id) snap_id,
       	to_char(trunc(min(s.begin_interval_time), 'hh'), 'yyyy-mm-dd hh24:mi') begin_time,
			h.dbid,
			h.instance_number,
       	round(sum(10 / 3600), 3) aas
  	from dba_hist_active_sess_history h
	jOIN dba_hist_snapshot s on s.snap_id = h.snap_id 
		and s.dbid = h.dbid
		and s.instance_number = h.instance_number
 	group by h.snap_id , h.dbid, h.instance_number
 	order by 5 desc
	) aas
	join dba_hist_snapshot h on h.snap_id = aas.snap_id
	order by rownum
)
select * from top10 where rnum <= 10
/
