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

HOST="uploads.androidfilehost.com"
USER="USER"          #User AFH
PASS="PASS"          #Password AFH
VERSION="$(grep '^#define TW_VERSION_STR' bootable/recovery/variables.h | cut -c 38-44)"
CPUS=$(grep "^processor" /proc/cpuinfo | wc -l)

#________________ E N D V A R _______________________

usage (){
        clear
        echo "||";
        echo "||     Usage: ./$0 [OPTIONS] DEVICE";
        echo "||";
        echo "||     Example: ./$0 -c1 -s -u condor";
        echo "||"
        echo "|| [-c#] = make 1-clean 2-dirty";
        echo "||"
        echo "|| [-s] = sync before build"
        echo "||"
        echo "|| [-u] = To up build to AFH (optional)";
        echo "||";
        echo "|| [Device] = Device codename: condor, otus, falcon, clark...";
        echo "||";
        echo "|| $1"
        exit 1;
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

if [ "$#" -ne 1 ]; then
        usage "No Options specific"
fi

check_result () {
        if [ $? -ne 0 ]; then
                echo ""
                echo -e ${red}" [ERROR]${txtrst}: $1 -- ABORTING!" 1>&2
                exit 1
        fi
}

DEVICE="$1"
OUT="out/target/product/$DEVICE"
PACKAGE="twrp-"$VERSION"-"$DEVICE".img"

if [[ "$opt_clean" -eq 0 ]]; then
        echo ""
        echo -e ${red}"Use a fucking flag loser"${txtrst}
        echo ""
        exit 1
elif [ "$opt_clean" -eq 1 ]; then
        echo ""
        echo "Make clean. . . "
        make clean >/dev/null
        check_result "Make Clean Failed."
        echo ""
elif [ "$opt_clean" -eq 2 ]; then
        echo ""
        echo "M a k e   D i r t y . . ."
        make dirty >/dev/null
        check_result "Make Dirty Failed."
        echo ""
elif [[ "$opt_clean" -ne 1 && $opt_clean -ne 2 ]]; then
        usage "ERROR: Invalid Flag! [$opt_clean] -- aborting!"
fi

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

echo "      Out Package Name: $PACKAGE"
source build/envsetup.sh
lunch omni_"$DEVICE"-userdebug
check_result "Lunch Failed."
make -j"$CPU" recoveryimage
check_result "Make Build Failed."

if [ $? -ne 0 ]; then
        STATED="Failure"
else
        STATED="Success"
        mv $OUT/recovery.img $PACKAGE
fi

if [ "$opt_upload" -eq 1 ]; then
        if [ "$STATED" == "Success" ]; then
                echo ""
                echo "FTP: Upload Build"
                echo -e "Build Status: [ $STATED ]"
                echo -e "FTP: Connecting from host [ $HOST ]"
                curl -ftp-pasv -T $OUT/$PACKAGE ftp://$USER:$PASS@$HOST
                if [ $? -ne 0 ]; then
                        up="Fail"
                        echo "FTP: Failed to upload"
                else
                        up="OK"
                        echo "Completed"
                fi
                echo "FTP: Transferred file [ $up ] "
        else
                echo "Build Status: [ $STATED ]"
                exit 1
        fi
else
        echo ""
        echo "FTP: No build up"
        echo "Build Status: [ $STATED ]"
        if [ "$STATED" == "Success" ]; then
                echo "completed success"
                exit 0
        else
                echo "Fail Build"
                exit 1
        fi
fi
