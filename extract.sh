#!/bin/sh

usage(){
        echo -e "Usage: $0 [file]"
        exit 1
}

if [ "$#" -ne 1 ]; then
      usage
fi

if [ -e $1 ]; then
	finder=$(grep color0 $1 | awk '{print $2}')
        colors=$(grep color[0-9] $1 | awk '{print $2}')
        bg=$(grep 'background' $1 | awk '{print $2}')
        fg=$(grep 'foreground' $1 | awk '{print $2}')
        if [[ $finder == '#'[a-z-0-9][a-z-0-9][a-z-0-9][a-z-0-9][a-z-0-9][a-z-0-9] ]]; then
                echo " Colors found: "
                echo "$fg" | hex2col
                echo "$bg" | hex2col
                echo "$colors" | hex2col
        else
                echo "No found results "
                exit 1
        fi
else
        echo "File: '$1' not found!"
        exit 1
fi
