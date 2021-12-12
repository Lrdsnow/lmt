#!/bin/bash
pkge=""
src="https://mc.lrdsnow.repl.co/pkgs"
fsrc="N"
nsrcs="REPO1"
cdsrcs=1
allpkgs=99
deb="N"

check_cmd() {
  if command -v $cmd &> /dev/null
  then
    echo "$cmd could not be found"
    exit
  else
    echo "$cmd exists"
  fi
}

check_deb() {
  fsrc="N"
  pkge=""
  src="https://mc.lrdsnow.repl.co/pkgs"
  fsrc="N"
  nsrcs="REPO1"
  cdsrcs=1
  allpkgs=99
  deb="N"
  while [[ $fsrc = "N" ]]; do
    source ~/.lmt/srcs/srcs.sh
    csrc=${!nsrcs}
    wget "$csrc/lmt.repo" -q -O ~/test.txt && pkge="y" || pkge="n"
    if [[ $pkge = "y" ]]; then
      deb="Y"
      src=$csrc
      check_deb_repo
      rm ~/test.txt
      exit 1
    else
      cdsrcs=$(($cdsrcs + 1))
      nsrcs="REPO"$cdsrcs
      if [[ $NOR < $cdsrcs ]]; then
        fsrc="Y"
        echo "$pkg does not exist"
        exit 1
      fi
    fi
  done
}

debinstall() {
  echo "Installing $pkg ($pkgver) ..."
  wget "$src/lmt.repo" -q -O ~/lmt.repo
  links=$(cat ~/lmt.repo | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | sort -u) && links=(${links[@]}) && link=$(echo "${links[$linkint]}")
  names=$(sed 1,2d ~/lmt.repo | cut -f1 -d"=") && names=(${names[@]}) && name=$(echo "${names[$nameint]}")
  wget "$link" -q -O ~/.lmt/pkgs/$pkg.deb
  sudo dpkg -i ~/.lmt/pkgs/$pkg.deb
}

check_deb_repo() {
  nameint=-1
  while :; do
    nameint=$(($nameint + 1))
    names=$(sed 1,2d ~/lmt.repo | cut -f1 -d"=") && names=(${names[@]}) && name=$(echo "${names[$nameint]}")
    if [[ $pkg = $name ]]; then
      linkint=$nameint
      debinstall
    else
      if [[ $name = "" ]]; then
        echo "$pkg does not exist"
        exit
      fi
    fi
  done
}

allinstall() {
  pkgver=$pkg"ver"
  dpkgver=$pkgver".txt"
  wget "$src/$pkg/$dpkgver" -q -O ~/test.txt && pkge="y" || pkge="n"
  if [[ $pkge = "y" ]]; then
    echo "successful"
  else
    echo "failed"
  fi
  rm ~/test.txt
}

check-repo() {
  while [[ $fsrc = "N" ]]; do
    source ~/.lmt/srcs/srcs.sh
    csrc=${!nsrcs}
    pkgver=$pkg"ver"
    dpkgver=$pkgver".txt"
    wget "$csrc/$pkg/$dpkgver" -q -O ~/test.txt && pkge="y" || pkge="n"
    if [[ $pkge = "y" ]]; then
      src=$csrc
      allinstall
      exit 1
    else
      cdsrcs=$(($cdsrcs + 1))
      nsrcs="REPO"$cdsrcs
      if [[ $NOR < $cdsrcs ]]; then
        fsrc="Y"
        check_deb
        exit 1
      fi
    fi
  done
}

while getopts 'i:a:c:' flag; do
  case "${flag}" in
    c) cmd=$OPTARG && check_cmd;;
    i) pkg=$OPTARG && check-repo
       exit 1 ;;
  esac
done
