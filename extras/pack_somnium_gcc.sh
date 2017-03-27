#!/usr/bin/env bash


# Copyright (c) 2016 StefanSch
# 
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# build and install Somnium GCC toolchain for MSP430-Energia
#
# prerequisites
# - bash
# - wget, GNU patch, GNU make
# - things needed to build binutils, GCC and GDB
#

set -e

gcc_ver="6.2.1.16"
mspgcc_ver="latest"
mspsupport_ver="1.198"


TAR="${G}tar" 


m_download()
{
	local fn
	# SF directlinks
	fn="$( basename "${1%}" )"
	# check if already there
	[ -f download/"${fn}" ] && return
	wget --content-disposition -qO download/"${fn}" "${1}"
}

m_extract()
{
	local fn="${1}"
	local dn="${2}"
	local command="echo no valid extension"
	echo Extracting: "${fn}"
	expr "${fn}" : '.*\.gz$' >/dev/null && command="${G}tar -xzf "
	expr "${fn}" : '.*\.bz2$' >/dev/null && command="${G}tar -xjf "
	expr "${fn}" : '.*\.zip$' >/dev/null && command="${G}unzip -q "
	pushd "${dn}" >/dev/null
	${command} ../download/"${fn}"
	popd >/dev/null
} 

m_pack()
{
	local fn="${1}"
	local en="${2}"
	local dn="${3}"
	local an="${4}"
	local command="echo no valid extension"
	echo Packing: "${fn}"
	expr "${en}" : '.*\.gz$' >/dev/null && command="${G}tar -czf "
	expr "${en}" : '.*\.bz2$' >/dev/null && command="${G}tar -cjf "
	expr "${en}" : '.*\.zip$' >/dev/null && command="${G}zip -q -r "
	pushd "${dn}" >/dev/null
	cp -r ${an} ${fn}/
    echo energia.msp430-gcc=${gcc_ver} >>${fn}/builtin_tools_versions.txt
    echo energia.mspdebug=0.22 >>${fn}/builtin_tools_versions.txt
    echo energia.msp430-gcc=4.6.3 >>${fn}/builtin_tools_versions.txt
	[ -d "msp430" ] && rm -rf msp430/
	mkdir msp430
	cd "${fn}"
	cp -r * ../msp430
	cd ..
	${command} "${fn}${en}" msp430
	sha256sum --tag "${fn}${en}" >"${fn}${en}".sha256
	rm -rf msp430/
	rm -rf "${fn}"/
	popd >/dev/null
} 



echo '!!! fetch files'
[ -d "download" ] || mkdir download 
m_download "http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPGCC/${mspgcc_ver}/exports/msp430-gcc-${gcc_ver}_linux32.tar.bz2"
m_download "http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPGCC/${mspgcc_ver}/exports/msp430-gcc-${gcc_ver}_linux64.tar.bz2"
m_download "http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPGCC/${mspgcc_ver}/exports/msp430-gcc-${gcc_ver}_osx.tar.bz2"
m_download "http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPGCC/${mspgcc_ver}/exports/msp430-gcc-${gcc_ver}_win32.zip"
m_download "http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPGCC/${mspgcc_ver}/exports/msp430-gcc-support-files-${mspsupport_ver}.zip"
m_download "http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPGCC/${mspgcc_ver}/exports/md5sum.txt"
cd download
md5sum.exe --check --ignore-missing md5sum.txt
cd ..


echo '!!! untar+patch packages'

[ -d "build" ] && rm -rf build 
mkdir build
m_extract "msp430-gcc-${gcc_ver}_linux32.tar.bz2" "build"
m_extract "msp430-gcc-${gcc_ver}_linux64.tar.bz2" "build"
m_extract "msp430-gcc-${gcc_ver}_osx.tar.bz2" "build"
m_extract "msp430-gcc-${gcc_ver}_win32.zip" "build"
m_extract "msp430-gcc-support-files-${mspsupport_ver}.zip" "build"

echo '!!! add support files'
m_pack "msp430-gcc-${gcc_ver}_linux32" ".tar.bz2" "build" "msp430-gcc-support-files"
m_pack "msp430-gcc-${gcc_ver}_linux64" ".tar.bz2" "build" "msp430-gcc-support-files"
m_pack "msp430-gcc-${gcc_ver}_osx" ".tar.bz2" "build" "msp430-gcc-support-files"
m_pack "msp430-gcc-${gcc_ver}_win32" ".zip" "build" "msp430-gcc-support-files"

rm -rf "build/msp430-gcc-support-files/"

