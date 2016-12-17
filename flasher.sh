#!/bin/bash

#colors
red=$(tput setaf 1)             #  red
grn=$(tput setaf 2)             #  green
blu=$(tput setaf 4)             #  blue
cya=$(tput setaf 6)             #  cyan
txtrst=$(tput sgr0)             #  Reset

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG="$DIR/log.txt"
Flashfile="$1"

dependencies (){
        check="$(command -v fastboot)"
        if [ ! $check ]; then
                echo "fastboot requiered"
                exit 1
        else
                toolkit
        fi
}

header (){
        local write="$@"
        echo 
        echo ToolKit By Magdeoz
        echo ${write} Menu
        echo 
        if [ $write == Stock ]; then
                echo "Se eliminaran apps, fotos, videos, musica"
                echo "almacenada en la memoria interna"
                echo "Haga una copia de sus datos antes de continuar"
        fi
}

toolkit (){
        clear
        header Main
        echo "[1] - ${grn}Boot TWRP (No flash)${txtrst}"
        echo "[2] - ${grn}Reboot Phone${txtrst}"
        echo "[3] - ${grn}Check MD5sum stock ROM${txtrst}"
        echo "[4] - ${red}Flash TWRP${txtrst}"
        echo "[5] - ${red}Flash Stock Rom${txtrst}"
        echo "[Q/q] - Exit"
        echo
        echo -n "> "
        read OPT
        case $OPT in
                1) TWRP boot ;;
                2) reboot ;;
                3) check ;;
                4) TWRP flash ;;
                5) Stock ;;
                q) exit ;;
                Q) exit ;;
                *) echo "Error! option: '$OPT' invalid" && sleep 1s && clear && toolkit ;;
        esac
}

TWRP (){
        header TWRP
        case $1 in 
                flash) echo "Installing TWRP recovery"
                        adb reboot bootloader
                        fastboot flash recovery twrp-3.0.2-0-athene.img
                        check_result failed completed
                        toolkit
                        ;;
                boot) echo "Booting TWRP recovery"
                        adb reboot bootloader
                        fastboot boot twrp-3.0.2-0-athene.img
                        check_result failed completed
                        toolkit
                        ;;
        esac
}

reboot (){
        clear
        header Recovery
        echo "[1] Reboot"
        echo "[2] Reboot recovery mode"
        echo "[3] Reboot bootloader mode"
        echo "[4] Reboot fast"
        echo "[c] cancel"
        echo ""
        echo -n "> "
        read OPTR
        case $OPTR in
                1) adb reboot
                        toolkit
                        ;;
                2) adb reboot recovery
                        toolkit
                        ;;
                3) adb reboot bootloader 
                        toolkit
                        ;;
                4) adb reboot fast 
                        toolkit
                        ;;
                c) toolkit
                        ;;
                C) toolkit
                        ;; 
                *) echo "Invalid Option" && sleep 1s && clear
                        reboot 
                        ;;
        esac
}

#verific files 
usage(){
        echo
        echo "-----------------------------------"
        echo ""
        echo -e ${grn}" Usage: ./$0 [XML file]"${txtrst}
        echo ""
        echo -e " Example: $0 flashfile.xml"
        echo ""
        echo "-----------------------------------"
        if [ $# -ne 0 ]; then
                echo -e ${red}"$1" $2
        fi
        echo ""
        exit 1
}

if [ "$#" -ne 1 ]; then
        usage
fi

if [ -f $1 ]; then
        ext=$(echo $1 | cut -d '.' -f 2)
        if [ $ext = xml ]; then
                verific=$(grep 'xml' $1 | sed "s/.*$2=\"\([^\"]*\).*/\1/")
                if [ $verific != '1.0' ]; then
                        echo "File XML no Valid!"
                        exit 1 
                fi
        else
                usage "'.$ext'" "unsupported file format"
        fi
else
        usage $1 "File does not exist"
fi

#Flasher

MD5SUM="md5sum"
filexml=$(echo $1)
software=$(grep software_version $filexml | sed "s/.*$2=\"\([^\"]*\).*/\1/")
phone=$(grep phone_model $filexml | sed "s/.*$2=\"\([^\"]*\).*/\1/")
value=$(grep sparsing $filexml | sed "s/.*$2=\"\([^\"]*\).*/\1/")
spar=$(grep 'sparsing' $filexml | awk '{print $2}' | cut -d '=' -f 2 | cut -d '"' -f 2)

Value(){
        val=$(echo "$1" | sed "s/.*$2=\"\([^\"]*\).*/\1/")
        echo "$val" | grep -q " "
        if [ $? -ne 1 ];then
                val=""
        fi
        echo "$val"
}

check_result () {
        if [ $? -ne 0 ]; then
                echo ""
                echo -e " [ERROR]: $1 -- ABORTING!" 1>&2
                exit 1
        else
                echo -e "[DONE]: $2 -- SUCCESS!" 
        fi
}

echo
echo "Software Version: $software"
echo "Phone Model: $phone"
echo
read -p 'Press any key for continue...'
clear


check (){
        clear
        header MD5
        cat "$Flashfile" | grep filename | while read -r line;do
        MD5=$(Value "$line" "MD5")
        file=$(Value "$line" "filename");
        if [ "$MD5" != "" ];then
                fileMD5=$($MD5SUM "$file" | sed 's/ \(.*\)//');
                if [ "$MD5" != "$fileMD5" ];then
                        echo "$file: ${red}MD5 mismatch${txtrst}"
                        exit 1;
                else
                        echo "$file: ${grn}MD5 match${txtrst}"
                fi
        fi
done
read -p 'Press any key ...'
toolkit
}



Stock (){
        clear
        header Stock
        echo
        echo "[1] - Continue"
        echo "[c/C] - Cancel"
        echo
        echo -n "> "
        read OPTS
        case $OPTS in
                1) #adb reboot bootloader
                        sleep 10s
                        cat "$Flashfile" | grep step[^s] | while read -r line;do
                        MD5=$(Value "$line" "MD5")
                        file=$(Value "$line" "filename");
                        op=$(Value "$line" "operation");
                        part=$(Value "$line" "partition");
                        var=$(Value "$line" "var");
                        if [ $op == getvar ]; then
                                if [[ $spar == true ]]; then
                                        value=$(grep sparsing $filexml | sed "s/.*$2=\"\([^\"]*\).*/\1/")
                                        echo "Starting Flasher..."
                                        echo fastboot $op $var
                                        check_result "Check for errors" "Completed"
                                        echo ""
                                        sleep 1
                                else
                        
                                        echo "No image sparsing"
                                        sleep 1
                                fi
                        elif [ $op == flash ]; then
                                echo "${grn}Flashing${txtrst}: $file"
                                echo fastboot $op $part $file
                                check_result "Check for errors" "Completed"
                                echo ""
                                sleep 1
                        elif [ $op == erase ]; then
                                echo "${grn}Erasing${txtrst}: $part"
                                echo fastboot $op $part
                                check_result "Check for errors" "Completed"
                                echo ""
                                sleep 1 
                        elif [ $op == oem ]; then
                                if [ $var == fb_mode_set ]; then
                                        echo "Set fastboot mode"
                                        echo fastboot $op $var
                                        check_result "Check for errors" "Completed"
                                        echo ""
                                        sleep 1
                                else
                                        echo "Fastboot mode clear"
                                        echo fastboot $op $var
                                        check_result "Check for errors" "Completed"
                                        echo ""
                                        sleep 1
                                fi
                        fi
                done
                echo fastboot reboot
                ;;
        c) toolkit
                ;;
        C) tookit;;
esac
toolkit
}
#dependencies
toolkit
