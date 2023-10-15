#!/bin/bash

CONFIG=/boot/config.txt
DATESTAMP=$(date "+%Y-%m-%d-%H-%M-%S")
CONFIG_BACKUP=false
APT_HAS_UPDATED=false
USER_HOME=/home/$SUDO_USER
RESOURCES_TOP_DIR=$USER_HOME/Pimoroni
WD=$(pwd)
USAGE="sudo ./install.sh (--unstable)"
POSITIONAL_ARGS=()
UNSTABLE=false
CODENAME=$(lsb_release -sc)

if [[ $CODENAME == "bullseye" ]]; then
    bash ./install-bullseye.sh
    exit $?
fi

user_check() {
    if [ $(id -u) -ne 0 ]; then
        printf "Script must be run as root. Try 'sudo ./install.sh'\n"
        exit 1
    fi
}

confirm() {
    if [ "$FORCE" == '-y' ]; then
        true
    else
        read -r -p "$1 [y/N] " response < /dev/tty
        if [[ $response =~ ^(yes|y|Y)$ ]]; then
            true
        else
            false
        fi
    fi
}

prompt() {
    read -r -p "$1 [y/N] " response < /dev/tty
    if [[ $response =~ ^(yes|y|Y)$ ]]; then
        true
    else
        false
    fi
}

success() {
    echo -e "$(tput setaf 2)$1$(tput sgr0)"
}

inform() {
    echo -e "$(tput setaf 6)$1$(tput sgr0)"
}

warning() {
    echo -e "$(tput setaf 1)$1$(tput sgr0)"
}

function do_config_backup {
    if [ ! $CONFIG_BACKUP == true ]; then
        CONFIG_BACKUP=true
        FILENAME="config.preinstall-$LIBRARY_NAME-$DATESTAMP.txt"
        inform "Backing up $CONFIG to /boot/$FILENAME\n"
        cp $CONFIG /boot/$FILENAME
        mkdir -p $RESOURCES_TOP_DIR/config-backups/
        cp $CONFIG $RESOURCES_TOP_DIR/config-backups/$FILENAME
        if [ -f "$UNINSTALLER" ]; then
            echo "cp $RESOURCES_TOP_DIR/config-backups/$FILENAME $CONFIG" >> $UNINSTALLER
        fi
    fi
}

function apt_pkg_install {
    PACKAGES=()
    PACKAGES_IN=("$@")
    for ((i = 0; i < ${#PACKAGES_IN[@]}; i++)); do
        PACKAGE="${PACKAGES_IN[$i]}"
        if [ "$PACKAGE" == "" ]; then continue; fi
        printf "Checking for $PACKAGE\n"
        dpkg -L $PACKAGE > /dev/null 2>&1
        if [ "$?" == "1" ]; then
            PACKAGES+=("$PACKAGE")
        fi
    done
    PACKAGES="${PACKAGES[@]}"
    if ! [ "$PACKAGES" == "" ]; then
        echo "Installing missing packages: $PACKAGES"
        if [ ! $APT_HAS_UPDATED ]; then
            apt update
            APT_HAS_UPDATED=true
        fi
        apt install -y $PACKAGES
        if [ -f "$UNINSTALLER" ]; then
            echo "apt uninstall -y $PACKAGES"
        fi
    fi
}

while [[ $# -gt 0 ]]; do
    K="$1"
    case $K in
        -u|--unstable)
            UNSTABLE=true
            shift
            ;;
        *)
            if [[ $1 == -* ]]; then
                printf "Unrecognised option: $1\n";
                printf "Usage: $USAGE\n";
                exit 1
            fi
            POSITIONAL_ARGS+=("$1")
            shift
    esac
done

user_check

# Check if the 'python3-configparser' package is installed
if ! dpkg-query -W -f='${Status}' python3-configparser 2>/dev/null | grep -q "install ok installed"; then
    warning "The 'python3-configparser' package is not installed. Attempting to install it now...\n"
    apt-get update
    apt-get install -y python3-configparser
    if [ $? -eq 0 ]; then
        success "Package 'python3-configparser' has been installed successfully!\n"
    else
        warning "Failed to install 'python3-configparser' package. You may need to install it manually.\n"
    fi
fi

# The rest of the script remains unchanged
# ...

# End of the script
