#!/bin/bash

export b="$(tput bold)"
export cyan="$(tput setaf 6)"
export green="$(tput setaf 2)"
export purple="$(tput setaf 5)"
export red="$(tput setaf 1)"
export white="$(tput setaf 7)"
export reset="$(tput sgr0)"

msg_head() {
        printf "${b}${cyan}%s${reset} ${b}%s${reset}\\n" "::" " ${@}"
}

msg() {
        printf "${purple}%s${reset} %s${reset}\\n" "[msg] ${@}"
}

info() {
        printf "${b}${cyan}%s${reset} ${b}%s${reset}\\n" "[info] ${@}"
}

succeed() {
        printf "${b}${green}%s${reset} %s\\n" "[OK] " "${@}"
}

fail() {
        printf "${red}%s${reset}\\n" "[ERR] $*" >&2
}

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Please run as root"
    exit
fi

INFILE="${1}"

[ ! -f ${INFILE} ] && { fail "Input file does not exist"; exit 1; }

INFILE_basename=`basename -s .sqsh ${INFILE}`
block_size_count=`du -B 512 ${INFILE} | cut -f1`

msg "Creating container"
dd if=/dev/zero of=${INFILE_basename}.img count=${block_size_count} status=progress && succeed "Creation succeeded" || { fail "Creation failed"; exit 1; }

info "Generating keyfile"
tr -dc 'a-f0-9' < /dev/urandom | head -c64 > ${INFILE_basename}.txt && succeed "Generation succeeded" || { fail "Generation failed"; exit 1; }

info "Openning container"
cryptsetup plainOpen ${INFILE_basename}.img --cipher=aes-xts-plain64 --key-size=512 --key-file=${INFILE_basename}.txt ${INFILE_basename} && succeed "Open succeeded" || { fail "Open failed"; exit 1; }

info "Writing to container"
dd if=${INFILE} of=/dev/mapper/${INFILE_basename} status=progress && succeed "Writing succeeded" || { fail "Writing failed"; exit 1; }

info "Closing container"
cryptsetup close ${INFILE_basename} && succeed "Closing succeeded" || { fail "Closing failed"; exit 1; }

info "Calculation sha256 value"
append_sha256=`sha256sum ${INFILE_basename}.img | cut -f1 | cut -c 1-8` && succeed "Calculation succeeded" || { fail "Calculation failed"; exit 1; }

info "Appending sha256 value to encrypted container"
mv ${INFILE_basename}.img ${INFILE_basename}-${append_sha256}.img && succeed "Appending succeeded" || { fail "Appending failed"; exit 1; }

info "Appending sha256 value to keyfile"
mv ${INFILE_basename}.txt ${INFILE_basename}-${append_sha256}.txt && succeed "Appending succeeded" || { fail "Appending failed"; exit 1; }


