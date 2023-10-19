#!/bin/bash

LOG_PATH="/storage/log.d/smartctl"
log_view_csv="/tmp/smartctl_log_view.csv"

all_log_files=(${LOG_PATH}/*/*)

get_gib_written() {
	local log_file=$1
	local desription_string="Data Units Written"
        unit_written_block=`cat ${log_file} | grep "${desription_string}" \
		| sed -e "s/${desription_string}://g" \
		-e  's/^ *//g' \
		-e 's/\[[^][]*\]//g' \
		-e 's/,//g'`
        unit_written_GiB=$(( ${unit_written_block}*512/(1024*1024) ))
        echo ${unit_written_GiB}
}

get_gib_read() {
	local log_file=$1
	local desription_string="Data Units Read"
        unit_read_block=`cat ${log_file} | grep "${desription_string}" \
		| sed -e "s/${desription_string}://g" \
		-e  's/^ *//g' \
		-e 's/\[[^][]*\]//g' \
		-e 's/,//g'`
        unit_read_GiB=$(( ${unit_read_block}*512/(1024*1024) ))
        echo ${unit_read_GiB}
}

get_power_cycles() {
	local log_file=$1
	local desription_string="Power Cycles"
	cat ${log_file} | grep "${desription_string}" \
		| sed -e "s/${desription_string}://g" \
		-e  's/^ *//g' \
		-e 's/\[[^][]*\]//g' \
		-e 's/,//g'
}

get_power_on_hours() {
	local log_file=$1
	local desription_string="Power On Hours"
	cat ${log_file} | grep "${desription_string}" \
		| sed -e "s/${desription_string}://g" \
		-e  's/^ *//g' \
		-e 's/\[[^][]*\]//g' \
		-e 's/,//g'
}

get_unsafe_shutdowns() {
	local log_file=$1
	local desription_string="Unsafe Shutdowns"
	cat ${log_file} | grep "${desription_string}" \
		| sed -e "s/${desription_string}://g" \
		-e  's/^ *//g' \
		-e 's/\[[^][]*\]//g' \
		-e 's/,//g'
}


echo -e "DATE,DATA_WRITTEN(GiB),,DATA_READ(GiB),,POWER_CYCLE,POWER_ON_HOURS,UNSAFE_SHUTDOWN" > ${log_view_csv}
echo -e ",Total,Increased,Total,Increased" >> ${log_view_csv}
echo -e "" >> ${log_view_csv}

for ((log_file_count=0;log_file_count<$((${#all_log_files[@]} - 1));log_file_count++)); do
	log_file_fullname="${all_log_files[${log_file_count}]}"
	log_file_date=`basename -s .log ${log_file_fullname} | sed  's/smartctl_//g'`

	next_log_file_count=$(( ${log_file_count} + 1 ))

	log_file_gib_written=`get_gib_written ${all_log_files[${log_file_count}]}`
	next_log_file_gib_written=`get_gib_written ${all_log_files[${next_log_file_count}]}`
	gib_written_diff=$(( ${next_log_file_gib_written} - ${log_file_gib_written} ))

	log_file_gib_read=`get_gib_read ${all_log_files[${log_file_count}]}`
	next_log_file_gib_read=`get_gib_read ${all_log_files[${next_log_file_count}]}`
	gib_read_diff=$(( ${next_log_file_gib_read} - ${log_file_gib_read} ))

	power_cycles=`get_power_cycles ${all_log_files[${log_file_count}]}`
	power_on_hours=`get_power_on_hours ${all_log_files[${log_file_count}]}`
	unsafe_shutdowns=`get_unsafe_shutdowns ${all_log_files[${log_file_count}]}`

	echo -e "${log_file_date},${log_file_gib_written},${gib_written_diff},${log_file_gib_read},${gib_read_diff},${power_cycles},${power_on_hours},${unsafe_shutdowns}" >> ${log_view_csv}

done

column -s, -t < ${log_view_csv}
