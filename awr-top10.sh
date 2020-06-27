#!/usr/bin/env bash

: <<'TOPTEN'

 generate the Run the AWR top ten baselines per database
 then generate the SQL for both text and html reports

 create the baselines
	create-awr-baselines.sql

 generate report.sql

	setRptType text
	gen-awr-reports.sql
	top10-awrrpt.sql

	setRptType html
	gen-awr-reports.sql
	top10-awrrpt.sql

 move reports to	new directory

	 mkdir awr-reports-$psid

	 mv awr-reports/* awr-reports-$psid


 loop to next db


 zip up when done


TOPTEN

mkdir -p awr-reports

setRptType () {
	local rptType=$1	# text or html

	sed -ie "s/'....'/'$rptType'/" config.sql
}

getInstance () {

	local pinst=$1

	[ -z "$pinst" ] && {
		echo "getInstance: pinst arg is empty" 1>&2
		echo ''
		return
	}

	# return instance name if pmon exists
	# there are 3 nodes, so make it generic

	declare testIns


	# space if standalone
	# digit for RAC - checks up to 4 nodes

	for orainst in ' ' 1 2 3 4
	do
		testInst=$(ps -eo cmd | grep "[o]ra_pmon_${pinst}${orainst}$")
		if [[ -n $testInst ]]; then
			echo ${pinst}${orainst}
			return
		fi
	done

	echo ''
	return
}

runSQL () {

	local dbName=$1
	local instName=$2
	local script=$3

	. oraenv <<< $psid > /dev/null
	export ORACLE_SID=$instName

	sqlplus -s -L / as sysdba <<-EOF

		set timing on
		set pause off echo off
		set linesize 200 trimspool on
		set pagesize 5000

		@$script
		exit
EOF

}

declare rptDir=awr-reports

for psid in $(grep -Ev '^\s*$|^#|^-MGM|^\+ASM' /etc/oratab| cut -f1 -d:)
do
	localInst=$(getInstance $psid)

	echo "  database: $psid"
	echo "  instance: $localInst"
	echo


	export ORACLE_SID=$localInst

	# run just this line for testing the script
	#runSQL $psid $localInst showdb

	runSQL $psid $localInst create-awr-baselines.sql

	setRptType text
	runSQL $psid $localInst gen-awr-reports.sql
	runSQL $psid $localInst top10-awrrpt.sql

	setRptType html
	runSQL $psid $localInst gen-awr-reports.sql
	runSQL $psid $localInst top10-awrrpt.sql

	 declare newRptDir=${rptDir}-${psid}
	 mkdir -p $newRptDir

	 mv $rptDir/* $newRptDir

done

zip -r awr-top-10-all-db.zip awr-reports-*

