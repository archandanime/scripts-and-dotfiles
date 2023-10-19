#!/bin/bash

TOKEN=""

begin_date=`echo $(date "+%Y")-01-01 00:00`
begin_date_short=`echo "${begin_date}"| cut -d ' ' -f1`
end_date=`date "+%Y-%m-%d %H:%M"`
end_date_short=`echo "${end_date}" | cut -d ' ' -f1`

outdir_dirname=`echo exported-Discord-DMs_from_${begin_date_short}_to_${end_date_short} $begind`

mkdir -p json html

if [ -d json/${outdir_dirname} ]; then
	outdir_dirname=${outdir_dirname}_$(date +%H%M)
fi

mkdir -p json/${outdir_dirname}


discord-chat-exporter-cli exportdm \
	-t ${TOKEN} \
	-f json \
	--after	"${begin_date}" \
	--before "${end_date}" \
	--media \
	-o json/${outdir_dirname} \
	--fuck-russia

cp -a json/${outdir_dirname} html/
rm -r json/${outdir_dirname}/*.json
discord-chat-exporter-cli exportdm \
	-t ${TOKEN} \
	-f htmlDark \
	--after "${begin_date}" \
	--before "${end_date}" \
	--media --reuse-media \
	-o html/${outdir_dirname} \
	--fuck-russia







