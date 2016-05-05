#!/bin/bash

HOST="uploads.androidfilehost.com"
USER="USER"          #User AFH
PASS="PASS"          #Password AFH
VERSION="$(grep '^#define TW_VERSION_STR' bootable/recovery/variables.h | cut -c 38-44)"
CPUS=$(grep "^processor" /proc/cpuinfo | wc -l)

#________________ E N D V A R _______________________

usage (){
        echo "|";
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
        echo "|";
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
        usage
fi

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
        echo "M a k e   c l e a n . . . "
        make clean >/dev/null
        echo ""
elif [ "$opt_clean" -eq 2 ]; then
        echo ""
        echo "M a k e   D i r t y . . ."
        make dirty >/dev/null
        echo ""
elif [[ "$opt_clean" -ne 1 && $opt_clean -ne 2 ]]; then
        echo ""
        echo -e ${red}" Invalid flag! -- [ $opt_clean ]"${txtrst}
        usage
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
$PACKAGE
source build/envsetup.sh
lunch omni_"$DEVICE"-userdebug
make -j"$CPU" recoveryimage

if [ $? -ne 0 ]; then
        STATED="Failure"
else
        STATED="Success"
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
