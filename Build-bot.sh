#!/bin/bash

# colors
red=$(tput setaf 1)             #  red
grn=$(tput setaf 2)             #  green
blu=$(tput setaf 4)             #  blue
cya=$(tput setaf 6)             #  cyan
txtbld=$(tput bold)             #  Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldgrn=${txtbld}$(tput setaf 2) #  green
bldblu=${txtbld}$(tput setaf 4) #  blue
bldcya=${txtbld}$(tput setaf 6) #  cyan
txtrst=$(tput sgr0)             #  Reset

## FTP ANDROID FILE HOST Dates
HOST="uploads.androidfilehost.com"
USER="USER"          #User AFH
PASS="PASS"     #Password AFH
CPU=$(grep "^processor" /proc/cpuinfo | wc -l)

## script begins
usage (){
        echo "-----------------------------------"
        echo ""
        echo -e ${grn}" Usage: $0 [options] DEVICE"${txtrst}
        echo ""
        echo -e ${bldgrn}"  OPTIONS: "${txtrst}
        echo "    -c# - Cleanin option"
        echo "          1 - Clean build"
        echo "          2 - Dirty build"
        echo "    -s - Sync before build"
        echo "    -u - Upload to AFH"
        echo ""
        echo -e ${blagrn}"  Example${txtrst}: $0 -c1 -s -u condor"
        echo ""
        echo "-----------------------------------"
        echo -e " $1 "
        exit 1
}

opt_clean=0
opt_sync=0
opt_upload=0

while getopts "c:us" opt; do
        case "$opt" in
                c) opt_clean="$OPTARG" ;;
                s) opt_sync=1 ;;
                u) opt_upload=1 ;;
                *) usage
        esac
done

shift $((OPTIND-1))

check_result () {
        if [ $? -ne 0 ]; then
                echo ""
                echo -e ${red}" [ERROR]${txtrst}: $1 -- ABORTING!" 1>&2
                exit 1
        fi
}

if [ "$#" -ne 1 ]; then
    usage
fi

DEVICE="$1"
OUT="out/target/product/$DEVICE"

#make
if [[ "$opt_clean" -eq 0 ]]; then
        echo ""
        echo -e ${red}"Use a fucking flag loser"${txtrst}
        echo ""
        exit 1
elif [ "$opt_clean" -eq 1 ]; then
        echo ""
        echo "M a k e   c l e a n . . . "
        make clean >/dev/null
        echo ""
elif [ "$opt_clean" -eq 2 ]; then
        echo ""
        echo "M a k e   D i r t y . . ."
        make dirty >/dev/null
        echo ""
elif [[ "$opt_clean" -ne 1 && $opt_clean -ne 2 ]]; then
        usage "${red} Invaild Flag [$opt_clean] -- ABORTING${txtrst}"
fi

#sync
if [ "$opt_sync" -eq 1 ]; then
        if [ ! -d ".repo" ]; then
                echo ""
                echo ${red}" No .repo directory found. !!"${txtrst}
                echo ""
                exit 1
        else
                repo sync -j"$CPU"
                echo ""
        fi
fi

source build/envsetup.sh
make clobber
check_result "Make Clober Failed."
brunch $DEVICE

if [ $? -ne 0 ]; then
        STATED="${red}"Failure"${txtrst}"
else
        STATED="${bldgrn}"Success"${txtrst}"
fi


if [ "$opt_upload" -eq 1 ]; then
        if [ "$STATED" == "${bldgrn}"Success"${txtrst}" ]; then
                echo ""
                echo "FTP: Upload Build"
                echo -e "Build Status: [ $STATED ]"
                echo -e "FTP: Connecting from host [ $HOST ]"
                echo -e "FTP: Connecting with configuration [ $USER ]"
                curl -ftp-pasv -T $OUT/*$DEVICE*.zip ftp://$USER:$PASS@$HOST
                if [ $? -ne 0 ]; then
                        up="${red}"Fail"${txtrst}"
                        echo -e "FTP: Failed to upload"
                else
                        up="${bldgrn}"OK"${txtrst}"
                        echo -e ${bldgrn}"Completed"${txtrst}
                fi
                echo -e "FTP: Transferred file [ $up ] "
                echo "Finished: $STATED"
        else
                echo ""
                echo "FTP: Upload Build"
                echo -e "Build Status: [$STATED]"
                echo "FTP: Current build result is [$STATED], not going to run."
                echo "Finished: $STATED"
                exit 1
        fi
else
        echo ""
        echo "FTP: No build up"
        echo "Build Status: [ $STATED ]"
        if [ "$STATED" == "${bldgrn}"Success"${txtrst}" ]; then
                echo "completed success"
                exit 0
        else
                echo "Fail Build"
                exit 1
        fi
fi
