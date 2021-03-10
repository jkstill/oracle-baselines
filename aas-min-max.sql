

select
	min(value) min_value
	, max(value) max_value
	, avg(value) avg_value
from dba_hist_sysmetric_history h
where h.metric_name = 'Average Active Sessions'
and trunc(h.begin_time) = trunc(sysdate - 1)
order by snap_id, begin_time
/
