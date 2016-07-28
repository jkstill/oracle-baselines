
<pre>

<h3>Top 10 AWR Baselines</h3>

Here's a method to find the periods of top activity in AWR and create a baseline for the top 10 periods.

The baseline can be made to expire after a set number of days so that you can just set them and forget them.

Use a reasonable value (30 days?) after which the baselines will just expire.

Be sure to allow enough time to ensure you will be done with them.

This code looks for the top 10 AAS (Average Active Sessions) periods and creates a baseline for each.

The same idea could be used to find top PGA usage, CPU, IO, etc.

<h3>Files</h3>

<h4>top10aas.sql</h4>

This is a script fragment that is called from create-baselines.sql.

Its purpose is to find the top 10 AWR Snapshots in terms of maximum AAS (Average Active Sessions)

<h4>create-baselines.sql</h4>

This script creates AWR baselines based on the findings from top10aas.sql.

The retention period is set by the sqlplus variable :n_expire_days, and is currently set to 1 day

The call to top10aas.sql could be replaced with any similar SQL fragment that finds the top N snap_id's based on PGA usage, IO, etc.

<h4>show-awr-baselines.sql</h4>

Displays entries in DBA_HIST_BASELINE

</pre>
