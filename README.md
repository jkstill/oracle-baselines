
# Top 10 AWR Baselines

Here's a method to find the periods of top activity in AWR and create a baseline for the top 10 periods.

The baseline can be made to expire after a set number of days so that you can just set them and forget them.

Use a reasonable value (30 days?) after which the baselines will just expire.

Be sure to allow enough time to ensure you will be done with them.

This code looks for the top 10 AAS (Average Active Sessions) periods and creates a baseline for each.

The same idea could be used to find top PGA usage, CPU, IO, etc.

## Files

### config.sql

Edit the values in this script before running _create-awr-baselines.sql_ or _gen-awr-reports.sql_.

The AWR Baseline retention period is set by the sqlplus variable _:n_expire_days_, and is currently set to 1 day

Set the AWR report type to either Text or HTML by changing the value of _:v_report_type_ to 'text' or 'html'

### top10.sql

This is a script fragment that is called from create-awr-baselines.sql.

Its purpose is to find the top 10 AWR Snapshots in terms of maximum AAS (Average Active Sessions)

### create-awr-baselines.sql

This script creates AWR baselines based on the findings from top10aas.sql.

The baselines will be named with a prefix of _AWR-Top10_

The call to top10aas.sql could be replaced with any similar SQL fragment that finds the top N snap_id's based on PGA usage, IO, etc.

This script will also generate the SQL script _top10-awrrpt.sql_ which can be used to generate an AWR report for each of the baselines.

These AWR reports are instance specific, so on a RAC system the report will be generated for the specific instance where the top db activity was found.

As DBA_HIST_BASELINE does not store an instance number, the instance number for each baseline as well as the metric value (used to determine Top 10) are both encoded into the Baseline name

For instance, the following report is for instance 2, and a Metric of 77.2 AAS was used to determine its place in the top 10 AWR periods.

```
AWR-Top10_3662_2_77.2_20181104-0100
               ^ instance
                 ^^^^ metric
```

### gen-awr-reports.sql

This script will use the list of baselines that have a prefix of AWR-Top10 to generate the script _top10-awrrpt.sql_.

So to create the AWR reports

```sql

@@gen-awr-reports
@@top10-awrrpt.sql

```

### show-awr-baselines.sql

Displays the _AWR-Top10_ entries in DBA_HIST_BASELINE

### drop-awr-baseline.sql

This script drops all baselines named with a prefix of  _AWR-Top10_

### aas-[1234].sql

Examples of different methods that may be used to determine the top 10 AWR snapshots to examine.

### awr_defined.sql

An example of the setup used for non-interactive AWR report generation.

### awr_RAC_defined.sql

An example of the setup used for non-interactive RAC AWR report generation.

## awr-top10.sh

This script will attempt login to all databases found in /etc/oratab, generate baselines and create text and html reports.

The script will detect which of up to 4 RAC nodes it may be on and adjust ORACLE_SID accordingly.

It will also work for standalone non-RAC databases.

All the report files will be oranized into directories named per database, and put in a zip file.


## Test Run

### Create the baselines

```sql

SQL> @create-awr-baselines

PL/SQL procedure successfully completed.

==============================
-- Baseline Name: AWR-Top10_3662_2_77.2_20181104-0100
--      instance: 2
--    begin_time: 04-NOV-18 01.00.36.657 AM
-- begin snap_id: 3662
--   end snap_id: 3663
--  Metric Value: 77.2
==============================
-- Baseline Name: AWR-Top10_3662_1_59.7_20181104-0100
--      instance: 1
--    begin_time: 04-NOV-18 01.00.36.714 AM
-- begin snap_id: 3662
--   end snap_id: 3663
--  Metric Value: 59.7
==============================
-- Baseline Name: AWR-Top10_3605_2_1.1_20181101-1600
--      instance: 2
--    begin_time: 01-NOV-18 04.00.08.552 PM
-- begin snap_id: 3605
--   end snap_id: 3606
--  Metric Value: 1.1
==============================
-- Baseline Name: AWR-Top10_3654_2_.6_20181103-1700
--      instance: 2
--    begin_time: 03-NOV-18 05.00.23.270 PM
-- begin snap_id: 3654
--   end snap_id: 3655
--  Metric Value: .6
==============================
-- Baseline Name: AWR-Top10_3678_1_.6_20181104-1600
--      instance: 1
--    begin_time: 04-NOV-18 04.00.31.030 PM
-- begin snap_id: 3678
--   end snap_id: 3679
--  Metric Value: .6
==============================
-- Baseline Name: AWR-Top10_3675_2_.5_20181104-1300
--      instance: 2
--    begin_time: 04-NOV-18 01.00.22.811 PM
-- begin snap_id: 3675
--   end snap_id: 3676
--  Metric Value: .5
==============================
-- Baseline Name: AWR-Top10_3603_2_.5_20181101-1400
--      instance: 2
--    begin_time: 01-NOV-18 02.00.10.154 PM
-- begin snap_id: 3603
--   end snap_id: 3604
--  Metric Value: .5
==============================
-- Baseline Name: AWR-Top10_3563_2_.5_20181030-2200
--      instance: 2
--    begin_time: 30-OCT-18 10.00.30.026 PM
-- begin snap_id: 3563
--   end snap_id: 3564
--  Metric Value: .5
==============================
-- Baseline Name: AWR-Top10_3602_1_.5_20181101-1300
--      instance: 1
--    begin_time: 01-NOV-18 01.00.51.305 PM
-- begin snap_id: 3602
--   end snap_id: 3603
--  Metric Value: .5
==============================
-- Baseline Name: AWR-Top10_3675_1_.5_20181104-1300
--      instance: 1
--    begin_time: 04-NOV-18 01.00.22.899 PM
-- begin snap_id: 3675
--   end snap_id: 3676
--  Metric Value: .5

```

### Now show the newly created AWR Baselines

```sql

SQL> @show-awr-baselines


START                                      END
BASELINE_NAME                                      BASELINE TYPE     SNAP ID IN METRIC START_SNAP_TIME        SNAP ID END_SNAP_TIME        EXPIRATION
-------------------------------------------------- --------------- --------- -- ------ -------------------- --------- -------------------- --------------------
AWR-Top10_3662_2_77.2_20181104-0100                STATIC               3662 2  77.2   2018-11-04 01:00:55       3663 2018-11-04 02:00:04  2018-11-06 15:05:46
AWR-Top10_3675_2_.5_20181104-1300                  STATIC               3675 2  .5     2018-11-04 14:00:09       3676 2018-11-04 15:00:08  2018-11-06 15:05:47
AWR-Top10_3602_1_.5_20181101-1300                  STATIC               3602 1  .5     2018-11-01 14:00:09       3603 2018-11-01 15:00:20  2018-11-06 15:05:47
AWR-Top10_3675_1_.5_20181104-1300                  STATIC               3675 1  .5     2018-11-04 14:00:09       3676 2018-11-04 15:00:08  2018-11-06 15:05:47
AWR-Top10_3678_1_.6_20181104-1600                  STATIC               3678 1  .6     2018-11-04 17:00:42       3679 2018-11-04 18:00:19  2018-11-06 15:05:47
AWR-Top10_3563_2_.5_20181030-2200                  STATIC               3563 2  .5     2018-10-30 23:00:39       3564 2018-10-31 00:00:17  2018-11-06 15:05:47
AWR-Top10_3662_1_59.7_20181104-0100                STATIC               3662 1  59.7   2018-11-04 01:00:55       3663 2018-11-04 02:00:04  2018-11-06 15:05:47
AWR-Top10_3603_2_.5_20181101-1400                  STATIC               3603 2  .5     2018-11-01 15:00:20       3604 2018-11-01 16:00:08  2018-11-06 15:05:47
AWR-Top10_3605_2_1.1_20181101-1600                 STATIC               3605 2  1.1    2018-11-01 17:00:43       3606 2018-11-01 18:00:05  2018-11-06 15:05:47
AWR-Top10_3654_2_.6_20181103-1700                  STATIC               3654 2  .6     2018-11-03 18:00:05       3655 2018-11-03 19:00:27  2018-11-06 15:05:47

10 rows selected.


```

### Generate AWR reports.


Either TEXT or HTML reports may be created.

```sql

SQL> @gen-awr-reports

PL/SQL procedure successfully completed.

Elapsed: 00:00:00.00

PL/SQL procedure successfully completed.

Elapsed: 00:00:00.00
host mkdir -p awr-reports
==============================
-- Baseline Name: AWR-Top10_3662_2_77.2_20181104-0100
--   Report Name: AWR-Top10_3662_2_77.2_20181104-0100.txt
--    begin_time: 04-NOV-18 01.00.55.463 AM
-- begin snap_id: 3662
--   end snap_id: 3663
define  inst_name    = js122a2
define  inst_num  = '2'
define  num_days     = 0
define  db_name      = JS122A
define  dbid         = 1789584727
define  begin_snap   = 3662
define  end_snap     = 3663
define  report_type  = text
define  report_name  =  awr-reports/AWR-Top10_3662_2_77.2_20181104-0100.txt
@?/rdbms/admin/awrrpti
-- ==============================
-- Baseline Name: AWR-Top10_3675_2_.5_20181104-1300
--   Report Name: AWR-Top10_3675_2_.5_20181104-1400.txt
--    begin_time: 04-NOV-18 02.00.09.905 PM
-- begin snap_id: 3675
--   end snap_id: 3676
define  inst_name    = js122a2
define  inst_num  = '2'
define  num_days     = 0
define  db_name      = JS122A
define  dbid         = 1789584727
define  begin_snap   = 3675
define  end_snap     = 3676
define  report_type  = text
define  report_name  =  awr-reports/AWR-Top10_3675_2_.5_20181104-1400.txt
@?/rdbms/admin/awrrpti
-- ==============================
-- Baseline Name: AWR-Top10_3602_1_.5_20181101-1300
--   Report Name: AWR-Top10_3602_1_.5_20181101-1400.txt
--    begin_time: 01-NOV-18 02.00.09.375 PM
-- begin snap_id: 3602
--   end snap_id: 3603
define  inst_name    = js122a1
define  inst_num  = '1'
define  num_days     = 0
define  db_name      = JS122A
define  dbid         = 1789584727
define  begin_snap   = 3602
define  end_snap     = 3603
define  report_type  = text
define  report_name  =  awr-reports/AWR-Top10_3602_1_.5_20181101-1400.txt
@?/rdbms/admin/awrrpti
-- ==============================
-- Baseline Name: AWR-Top10_3675_1_.5_20181104-1300
--   Report Name: AWR-Top10_3675_1_.5_20181104-1400.txt
--    begin_time: 04-NOV-18 02.00.09.905 PM
-- begin snap_id: 3675
--   end snap_id: 3676
define  inst_name    = js122a1
define  inst_num  = '1'
define  num_days     = 0
define  db_name      = JS122A
define  dbid         = 1789584727
define  begin_snap   = 3675
define  end_snap     = 3676
define  report_type  = text
define  report_name  =  awr-reports/AWR-Top10_3675_1_.5_20181104-1400.txt
@?/rdbms/admin/awrrpti
-- ==============================
-- Baseline Name: AWR-Top10_3678_1_.6_20181104-1600
--   Report Name: AWR-Top10_3678_1_.6_20181104-1700.txt
--    begin_time: 04-NOV-18 05.00.42.850 PM
-- begin snap_id: 3678
--   end snap_id: 3679
define  inst_name    = js122a1
define  inst_num  = '1'
define  num_days     = 0
define  db_name      = JS122A
define  dbid         = 1789584727
define  begin_snap   = 3678
define  end_snap     = 3679
define  report_type  = text
define  report_name  =  awr-reports/AWR-Top10_3678_1_.6_20181104-1700.txt
@?/rdbms/admin/awrrpti
-- ==============================
-- Baseline Name: AWR-Top10_3563_2_.5_20181030-2200
--   Report Name: AWR-Top10_3563_2_.5_20181030-2300.txt
--    begin_time: 30-OCT-18 11.00.39.281 PM
-- begin snap_id: 3563
--   end snap_id: 3564
define  inst_name    = js122a2
define  inst_num  = '2'
define  num_days     = 0
define  db_name      = JS122A
define  dbid         = 1789584727
define  begin_snap   = 3563
define  end_snap     = 3564
define  report_type  = text
define  report_name  =  awr-reports/AWR-Top10_3563_2_.5_20181030-2300.txt
@?/rdbms/admin/awrrpti
-- ==============================
-- Baseline Name: AWR-Top10_3662_1_59.7_20181104-0100
--   Report Name: AWR-Top10_3662_1_59.7_20181104-0100.txt
--    begin_time: 04-NOV-18 01.00.55.463 AM
-- begin snap_id: 3662
--   end snap_id: 3663
define  inst_name    = js122a1
define  inst_num  = '1'
define  num_days     = 0
define  db_name      = JS122A
define  dbid         = 1789584727
define  begin_snap   = 3662
define  end_snap     = 3663
define  report_type  = text
define  report_name  =  awr-reports/AWR-Top10_3662_1_59.7_20181104-0100.txt
@?/rdbms/admin/awrrpti
-- ==============================
-- Baseline Name: AWR-Top10_3603_2_.5_20181101-1400
--   Report Name: AWR-Top10_3603_2_.5_20181101-1500.txt
--    begin_time: 01-NOV-18 03.00.20.656 PM
-- begin snap_id: 3603
--   end snap_id: 3604
define  inst_name    = js122a2
define  inst_num  = '2'
define  num_days     = 0
define  db_name      = JS122A
define  dbid         = 1789584727
define  begin_snap   = 3603
define  end_snap     = 3604
define  report_type  = text
define  report_name  =  awr-reports/AWR-Top10_3603_2_.5_20181101-1500.txt
@?/rdbms/admin/awrrpti
-- ==============================
-- Baseline Name: AWR-Top10_3605_2_1.1_20181101-1600
--   Report Name: AWR-Top10_3605_2_1.1_20181101-1700.txt
--    begin_time: 01-NOV-18 05.00.43.495 PM
-- begin snap_id: 3605
--   end snap_id: 3606
define  inst_name    = js122a2
define  inst_num  = '2'
define  num_days     = 0
define  db_name      = JS122A
define  dbid         = 1789584727
define  begin_snap   = 3605
define  end_snap     = 3606
define  report_type  = text
define  report_name  =  awr-reports/AWR-Top10_3605_2_1.1_20181101-1700.txt
@?/rdbms/admin/awrrpti
-- ==============================
-- Baseline Name: AWR-Top10_3654_2_.6_20181103-1700
--   Report Name: AWR-Top10_3654_2_.6_20181103-1800.txt
--    begin_time: 03-NOV-18 06.00.05.848 PM
-- begin snap_id: 3654
--   end snap_id: 3655
define  inst_name    = js122a2
define  inst_num  = '2'
define  num_days     = 0
define  db_name      = JS122A
define  dbid         = 1789584727
define  begin_snap   = 3654
define  end_snap     = 3655
define  report_type  = text
define  report_name  =  awr-reports/AWR-Top10_3654_2_.6_20181103-1800.txt
@?/rdbms/admin/awrrpti
-- ==============================

```

Now run the generated SQL

```sql

SQL> @top10-awrrpt.sql


Specify the Report Type
~~~~~~~~~~~~~~~~~~~~~~~
AWR reports can be generated in the following formats.  Please enter the
name of the format at the prompt.  Default value is 'html'.

'html'          HTML format (default)
'text'          Text format
'active-html'   Includes Performance Hub active report


Type Specified:  text
Elapsed: 00:00:00.00


Instances in this Workload Repository schema
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   DB Id     Inst Num DB Name      Instance     Host
------------ -------- ------------ ------------ ------------
* 1789584727        1 JS122A       js122a1      ora122rac01.
                                                jks.com
  1789584727        2 JS122A       js122a2      ora122rac02.
                                                jks.com

Using 1789584727 for database Id
Using 2 for instance number

...

```

This may take a few minutes.

Once complete, check for AWR reports in the awr-reports directory.

```bash
$ ls -l awr-reports
total 4764
-rw-r--r-- 1 jkstill dba 347427 Nov  5 15:20 AWR-Top10_3563_2_.5_20181030-2300.txt
-rw-r--r-- 1 jkstill dba 350737 Nov  5 15:19 AWR-Top10_3602_1_.5_20181101-1400.txt
-rw-r--r-- 1 jkstill dba 449711 Nov  5 15:20 AWR-Top10_3603_2_.5_20181101-1500.txt
-rw-r--r-- 1 jkstill dba 371308 Nov  5 15:20 AWR-Top10_3605_2_1.1_20181101-1700.txt
-rw-r--r-- 1 jkstill dba 350158 Nov  5 15:20 AWR-Top10_3654_2_.6_20181103-1800.txt
-rw-r--r-- 1 jkstill dba 370068 Nov  5 15:20 AWR-Top10_3662_1_59.7_20181104-0100.txt
-rw-r--r-- 1 jkstill dba 367478 Nov  5 15:19 AWR-Top10_3662_2_77.2_20181104-0100.txt
-rw-r--r-- 1 jkstill dba 373371 Nov  5 14:59 AWR-Top10_3671_1_.5_20181104-1000.txt
-rw-r--r-- 1 jkstill dba 370357 Nov  5 14:59 AWR-Top10_3674_1_.5_20181104-1300.txt
-rw-r--r-- 1 jkstill dba 376325 Nov  5 15:20 AWR-Top10_3675_1_.5_20181104-1400.txt
-rw-r--r-- 1 jkstill dba 411821 Nov  5 15:19 AWR-Top10_3675_2_.5_20181104-1400.txt
-rw-r--r-- 1 jkstill dba 365833 Nov  5 15:20 AWR-Top10_3678_1_.6_20181104-1700.txt
-rw-r--r-- 1 jkstill dba 348327 Nov  5 14:59 AWR-Top10_3679_2_.5_20181104-1800.txt
```








