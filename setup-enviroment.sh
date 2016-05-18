#!/bin/bash

load (){
        for ((i = 0; i < $1; i++)); do echo -n "."; sleep 0.04; done; echo -e '][\033[00;32mCOMPLETE\033[00;0m]';sleep 0.6
}

TOOLS(){
        sudo apt-get -y install git-core python gnupg flex bison gperf libsdl1.2-dev libesd0-dev libwxgtk2.8-dev \
                squashfs-tools build-essential zip curl libncurses5-dev zlib1g-dev pngcrush \
                schedtool libxml2 libxml2-utils xsltproc lzop libc6-dev schedtool g++-multilib lib32z1-dev lib32ncurses5-dev \
                gcc-multilib liblz4-* pngquant ncurses-dev texinfo gcc gperf patch libtool \
                automake g++ gawk subversion expat libexpat1-dev python-all-dev binutils-static bc libcloog-isl-dev \
                libcap-dev autoconf libgmp-dev build-essential gcc-multilib g++-multilib pkg-config libmpc-dev libmpfr-dev lzma* \
                liblzma* w3m phablet-tools android-tools-adb ccache maven
}

SETDEV(){
        echo "Installing JAVA (openjdk)"
        sudo apt-get -y install openjdk-7-jdk openjdk-7-jre
        echo "Installing Tools..."
        TOOLS
        if [ ! $TOOLS ]; then
                echo " Updating System"
                sudo apt-get -y update
                sudo apt-get -y upgrade
                echo ""
                echo "Trying again..."
                echo ""
                TOOLS
                if [ $? -ne 0 ]; then
                        echo "ERROR: Not installing toosl"
                        exit 1
                fi
        fi
        sudo ln -s /usr/lib/i386-linux-gnu/mesa/libGL.so.1 /usr/lib/i386-linux-gnu/libGL.so
        echo "Downloading repo bin... "
        mkdir ~/bin && curl http://commondatastorage.googleapis.com/git-repo-downloads/repo > ~/bin/repo && chmod a+x ~/bin/repo
        echo -n "Set Path        [" 
        load 20
        echo "export PATH=~/bin:$PATH" >> ${HOME}/.bashrc
        echo -n "Updating Bashrc [" 
        load 20
        source ~/.bashrc 
        echo "  C  o  m  p  l  e  t  e  d "
}

SETGIT()
{
        echo ""
        echo "ENTER EMAIL GITHUB"
        echo ""
        read -p 'EMAIL: ' mail
        git config --global user.email "'"'$mail'"'"
        echo ""
        echo "ENTER USERNAME GITHUB"
        echo ""
        read -p 'USERNAME: ' user
        git config --global user.name "'"'$user'"'"
        echo "C o m p l e t  e d "
}

Menug()
{
        clear
        echo "  * Optional *  "
        echo ""
        echo "  S e t u p   a n d   C o n f i g   g i t ?"
        echo ""
        echo " [Y]  Yes"
        echo " [N]  No"
        echo ""
        read -p 'Select: ' OPT
        if [[ ! $OPT == "Y" ]]; then
                if [[ ! $OPT == "y" ]]; then
                        if [[ ! $OPT == "N" ]]; then
                                if [[ ! $OPT == "n" ]]; then
                                        echo ""
                                        echo "option invalid"
                                        echo ""
                                        sleep 1.5s
                                        clear
                                        Menug
                                fi
                        fi
                fi
        fi
        case $OPT in
                Y) SETGIT ;;
                y) SETGIT ;;
                N) clear; echo "Goodbye"; sleep 1s; clear; exit ;;
                n) clear; echo "Goodbye"; sleep 1s; clear; exit ;;
        esac
}

clear
SETDEV
Menug
