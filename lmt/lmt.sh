#!/bin/bash

dist=""
pkg=""
ru="N"
mcgp=""
mcgpn=""
ver="v0"
cver=""
distc=""

check_dist() {
  distc="$(awk '/^ID=/' /etc/*-release | awk -F'=' '{ print tolower($2) }')"
  if [[ $distc = "ubuntu" ]]; then
    dist="u"
  elif [[ $distc = "alpine" ]]; then
    dist="a"
  fi
}

print_usage() {
  printf "Usage:\n Flags:\n -a: alpine linux\n -u: ubuntu linux\n Commands:\n -i <app>: installs app"
}

upgrade() {
  rm ~/ver
  touch ~/ver
  wget "https://raw.githubusercontent.com/Lrdsnow/lmt/main/ver" -O ~/ver
  cver="$(grep -o 'v[^"]*' ~/ver)"
  rm ~/ver
  if [[ $ru != "Y" ]]; then
    if [[ $ver != $cver ]]; then
      touch ~/lmt
      wget "https://github.com/lrdsnow/lmt/releases/latest/download/lmt.sh" -O ~/lmt
      sudo mv ~/lmt /bin/lmt
      sudo chmod 755 /bin/lmt
    fi
  fi
}

lmt-gui_install() {
  gui=~/.lmt/pkgs/lmt_gui/main.py
  if [[ -f "$gui" ]]; then
    guiver="$(grep -o 'v[^"]*' ~/.lmt/pkgs/lmt_gui/version.txt)"
    echo "package already installed, lmt-gui.$guiver"
  else
    if [[ -d "~/.lmt" ]]; then
      echo "~/.lmt Exists"
    else
      mkdir ~/.lmt
      mkdir ~/.lmt/pkgs
      mkdir ~/.lmt/pkgs/lmt_gui
    fi
    wget "https://github.com/lrdsnow/lmt/releases/latest/download/lmt-gui.zip" -O ~/lmt-gui.zip
    unzip ~/lmt-gui.zip -d ~/.lmt/pkgs/lmt_gui/
    wget "https://raw.githubusercontent.com/Lrdsnow/lmt/main/guiver" -O ~/.lmt/pkgs/lmt_gui/version.txt
    touch ~/lmt-gui && echo "python3 ~/.lmt/pkgs/lmt_gui/main.py" > ~/lmt-gui && sudo chmod 755 ~/lmt-gui && sudo mv ~/lmt-gui /bin/lmt-gui
    guiver="$(grep -o 'v[^"]*' ~/.lmt/pkgs/lmt_gui/version.txt)"
    echo "Succsessfuly Installed lmt-gui.$guiver"
  fi
}

mcginstall() {
  if [[ $mcgpn = "mcgl" ]]; then
    echo "Currently Unavailable"
  elif [[ $mcgpn = "mcd" ]]; then
    echo "Currently Unavailable"
  elif [[ $mcgp = "N" ]]; then
    upgrade
  elif [[ $mcgpn = "lmt-gui" ]]; then
    echo "GUI Unavailable (Only) For First Version"
  else
    echo "Error"
  fi
}

install() {
  if [[ $dist = "u" ]]
  then
    if [[ $ru = "N" ]]
    then
      sudo apt install -y $pkg
    elif [[ $ru = "Y" ]]
    then
      apt install -y $pkg
    else
      echo "Error"
    fi
  elif [[ $dist = "a" ]]
  then
    if [[ $ru = "N" ]]
    then
      sudo apk add $pkg
    elif [[ $ru = "Y" ]]
    then
      apk add $pkg
    else
      echo "Error"
    fi
  else
    printf "No Distro Selected\n"
  fi
}

preinstall() {
  #printf "$pkg\n"
  if [[ $pkg = "mcd" ]] || [[ $pkg = "morcomdeveloper" ]]
  then
    mcgp="Y"
    mcgpn="mcd"
    mcginstall
  elif [[ $pkg = "mcgl" ]] || [[ $pkg = "morcomgameslauncher" ]]; then
    mcgp="Y"
    mcgpn="mcgl"
    mcginstall
  elif [[ $pkg = "upgrade" ]] || [[ $pkg = "upg" ]] || [[ $pkg = "lmt" ]] || [[ $pkg = "install" ]]; then
    mcgp="N"
    mcgpn="lmt"
    mcginstall
  elif [[ $pkg = "gui" ]] || [[ $pkg = "lmt-gui" ]] || [[ $pkg = "lmt_gui" ]]; then
    mcgp="Y"
    mcgpn="lmt-gui"
    mcginstall
  else
    install
  fi
}

gui() {
  gui=~/.lmt/pkgs/lmt_gui/main.py
  if [[ -f "$gui" ]]; then
    echo "GUI Files exist..."
  else
    echo 'GUI Is Not installed Please Install It With "lmt -i lmt-gui"'
    exit 1
  fi
  echo "Continuing"
}

check_dist
while getopts 'guari:' flag; do
  case "${flag}" in
    a) dist="a";;
    u) dist="u";;
    i) pkg=$OPTARG && preinstall;;
    r) ru="Y";;
    g) gui;;
    *) print_usage
       exit 1 ;;
  esac
done
