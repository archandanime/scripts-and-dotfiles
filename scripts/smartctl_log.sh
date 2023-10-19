#!/bin/bash

LOG_DIR_BASE="/storage/log.d/smartctl/"
LOG_DIR_MONTH=`date +%Y-%m`
LOG_DIR_PATH="${LOG_DIR_BASE}/${LOG_DIR_MONTH}"

LOG_DATE_YYYY_MM_DD=`date +%Y-%m-%d`
LOG_FILE="${LOG_DIR_PATH}/smartctl_${LOG_DATE_YYYY_MM_DD}.log"

[ ! -d ${LOG_DIR_PATH} ] &&  mkdir ${LOG_DIR_PATH}

if [ ! -f ${LOG_FILE} ]; then
	smartctl -a /dev/nvme0n1 | tee ${LOG_FILE}
	echo "[info] Log file is ${LOG_FILE}"
else
	echo "[info] There is already log for today"
fi
