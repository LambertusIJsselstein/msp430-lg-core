#!/usr/bin/env bash


# Copyright (c) 2018 StefanSch
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

# build and install Mito GCC toolchain for MSP430-Energia
#
# prerequisites
# - bash
# - wget, GNU patch, GNU make
# - things needed to build binutils, GCC and GDB
#

set -e

# web page: http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPGCC/6_00_00_900/index_FDS.html

gcc_ver="7.3.1.24"
#mspgcc_ver="6_00_01_000"
mspgcc_ver="latest"
mspsupport_ver="1.205"


TAR="${G}tar" 


m_download()
{
	local fn
	# SF directlinks
	fn="$( basename "${1%}" )"
	# check if already there
	[ -f extras/download/"${fn}" ] && return
	echo Fetching: "${fn}"
	wget --content-disposition -qO extras/download/"${fn}" "${1}"
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
	#echo energia.msp430-gcc-elf=${gcc_ver} >>${fn}/builtin_tools_versions.txt
	#echo energia.mspdebug=0.22 >>${fn}/builtin_tools_versions.txt
	#echo energia.msp430-gcc=4.6.3 >>${fn}/builtin_tools_versions.txt
	[ -f ${fn}/version.properties ] && rm ${fn}/version.properties
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
[ -d "extras/download" ] || mkdir extras/download 
m_download "http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPGCC/${mspgcc_ver}/exports/msp430-gcc-${gcc_ver}_linux32.tar.bz2"
m_download "http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPGCC/${mspgcc_ver}/exports/msp430-gcc-${gcc_ver}_linux64.tar.bz2"
m_download "http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPGCC/${mspgcc_ver}/exports/msp430-gcc-${gcc_ver}_macos.tar.bz2"
m_download "http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPGCC/${mspgcc_ver}/exports/msp430-gcc-${gcc_ver}_win32.zip"
m_download "http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPGCC/${mspgcc_ver}/exports/msp430-gcc-${gcc_ver}_win64.zip"
m_download "http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPGCC/${mspgcc_ver}/exports/msp430-gcc-support-files-${mspsupport_ver}.zip"
m_download "http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPGCC/${mspgcc_ver}/exports/md5sum.txt"
cd extras/download
sed -i '/md5sum/d' ./md5sum.txt
md5sum.exe --check --ignore-missing md5sum.txt
cd ../..


echo '!!! untar+patch packages'

[ -d "extras/build" ] && rm -rf extras/build 
mkdir extras/build
m_extract "msp430-gcc-${gcc_ver}_linux32.tar.bz2" "extras/build"
m_extract "msp430-gcc-${gcc_ver}_linux64.tar.bz2" "extras/build"
m_extract "msp430-gcc-${gcc_ver}_macos.tar.bz2" "extras/build"
m_extract "msp430-gcc-${gcc_ver}_win32.zip" "extras/build"
m_extract "msp430-gcc-support-files-${mspsupport_ver}.zip" "extras/build"

echo '!!! rename to elf'
cd extras/build
rename -v  msp430-gcc-${gcc_ver} msp430-elf-gcc-${gcc_ver} *
cd ../..

echo '!!! add support files'
m_pack "msp430-elf-gcc-${gcc_ver}_linux32" ".tar.bz2" "extras/build" "msp430-gcc-support-files"
m_pack "msp430-elf-gcc-${gcc_ver}_linux64" ".tar.bz2" "extras/build" "msp430-gcc-support-files"
m_pack "msp430-elf-gcc-${gcc_ver}_macos"     ".tar.bz2" "extras/build" "msp430-gcc-support-files"
m_pack "msp430-elf-gcc-${gcc_ver}_win32"   ".zip"     "extras/build" "msp430-gcc-support-files"

rm -rf "extras/build/msp430-elf-gcc-support-files/"
rm -rf "extras/build/msp430-gcc-support-files/"

