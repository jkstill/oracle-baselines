#!/usr/bin/env bash

declare csvDir=csv-aas-by-instance

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

		@clear_for_spool
		set term off
		spool ${csvDir}/${dbName}.csv
		prompt timestamp,node_1,node_2,node_3,total
		@$script
		exit
EOF

}


mkdir -p $csvDir

for psid in $(grep -Ev '^\s*$|^#|^-MGM|^\+ASM' /etc/oratab| cut -f1 -d:)
do
	localInst=$(getInstance $psid)

	echo 
	echo "  database: $psid"	
	echo "  instance: $localInst"
	echo 

	export ORACLE_SID=$localInst

	# run just this line for testing the script
	#runSQL $psid $localInst showdb

	runSQL $psid $localInst aas-csv-by-instance

	echo "======================================================"

done


