#!/bin/sh

###################################################################
#Script Name	: OS X Crash Report Symbolication
#Description	:
# Put the dSYM and crash log in same folder (dSYM may be placed in subfolder).
# from terminal exec ./sym.sh < crashlog.crash>
# Everything else script will do automaticaly.
# Tested on Sierra 10.12.6 (2018)
#Args          : filename of crashlog
#Author       	: Andrii Tishchenko
###################################################################

clear

if [[ -z "$1" ]]; then
   echo "No crashlog provided"
   exit;
fi

crash=`cat $1`

vers=$( echo "$crash" | grep "^Version:" | awk '{print $2}')
echo "Version: $vers"

rip=$(expr "$crash" : '.*rip: \([^ ]*\) ')
echo "RIP: $rip"

lines=$( echo "$crash" | grep "$rip" -A 5 | grep "+" )
echo "CRASH: $lines"

binary=$( echo "$lines" | awk 'NR==1{print $4}' )
echo "BIN: $binary"

shifts=$( echo "$lines" | awk -v ORS=" " '{print $3}'  )
echo "SHIFT: $shifts"

binary_name=$( echo "$lines" | awk 'NR==1{print $2}' )
echo "BIN_NAME: $binary_name"

bin_id=$( echo "$crash" | grep "+$binary_name" | awk 'NR==1{print $8}' | sed 's/[<>,]//g')
echo "BIN ID: $bin_id"

bin_path=$( mdfind -onlyin . "$bin_id" | grep ".dSYM" ) 
echo "BIN PATH: $bin_path"

if [[ -z "$bin_path" ]]; then
   echo "dSYM for UUID $bin_id not found."
   exit;
fi

arch=$( dwarfdump "$bin_path" -u | awk '{print $3}' | sed 's/[(),]//g')
echo "arch: $arch"

dwarf=$( dwarfdump "$bin_path" -u | cut -d " " -f 4- )
echo "dwarf: $dwarf"

echo "========================="
echo atos -arch "$arch" -o \"$dwarf\" -l "$binary" "$shifts"
echo "========================="

atos -arch "$arch" -o "$dwarf" -l $binary $shifts
