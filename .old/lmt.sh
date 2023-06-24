#!/bin/bash
# Variables
verbose=0
flags="-q"
home=~/.lmt
# Basic Setup
mkdir -p $home
mkdir -p $home/bin
mkdir -p $home/temp
# Repository's
update() {
  if [ ! -f $home/config/repos.conf ]; then
    mkdir -p $home/config
    mkdir -p $home/repos
    echo 'repos=("https://raw.githubusercontent.com/Lrdsnow/lmt/main/repo")' > $home/config/repos.conf
    echo 'cpkgs=()' > $home/config/pkgs.conf
    if [[ ! ":$PATH:" == *":$home/bin:"* ]]; then
      echo 'export PATH="$PATH:$home/bin"' >> ~/.bashrc
    fi
  fi
  . $home/config/repos.conf
  if [ "${#repos[@]}" == "0" ]; then
    echo "Failed, No repositorys avalible"
    exit 1
  fi
  for src in $repos; do
    echo "Checking $src/repo.rlmt..."
    if wget "$src/repo.rlmt" $flags -O $home/temp/repo.rlmt; then
      . $home/temp/repo.rlmt
      mv $home/temp/repo.rlmt $home/repos/$name.rlmt
      echo Succsesfully downloaded repository file
    else
      echo Failed to download repository file
    fi
  done
  for repo in $home/repos/*; do
    if [[ "$repo" == *.rlmt ]]; then
      echo "Found $repo"
      . $repo
      . $home/config/pkgs.conf
      echo "cpkgs=($cpkgs $pkgs)" > $home/config/pkgs.conf
      echo "Succsessfully Refreshed Repo '$name'"
    else
      echo "Skipped $repo"
    fi
  done
}
search_package() {
  if [ -f $home/config/pkgs.conf ]; then
    . $home/config/pkgs.conf
    if [[ " ${cpkgs[*]} " =~ " $1 " ]]; then
      return 0
    else
      return 1
    fi
  else
    echo "Failed, No packages found!"
    return 1
  fi
}
download_package() {
  for repo in $home/repos/*; do
    if [[ "$repo" == *.rlmt ]]; then
      . $repo
      if [[ " ${pkgs[*]} " =~ " $1 " ]]; then
        echo "Downloading $1..."
        if wget "$url/pkgs/$1.lmt" $flags --show-progress -O $home/temp/$1.lmt; then
          return 0
        else
          return 1
        fi
      fi
    else
      if [[ verbose == 1 ]]; then
        echo "Skipped $repo"
      fi
    fi
  done
  return 1
}
# Install
install() {
  for p in $@; do
    if [[ "$p" == *"/"* ]] || [[ "$p" == *"."* ]]; then
      if [ -f $p ]; then
        if [ ! "${p#*.}" == ".deb" ]; then
          install_package $p
        else
          sudo dpkg install $p
        fi
      else
        echo "Failed, file not found"
      fi
    else
      if search_package $p; then
        if download_package $p; then
          install_package $home/temp/$p.lmt
        else
          echo "Failed, Download failed"
        fi
      else
        if apt search "^$p$" -qq; then
          sudo apt install $p
        else
          echo "Failed, $p not found"
        fi
      fi
    fi
  done
}
install_package() {
  mkdir -p $home/temp/unpkged
  unzip $flags $1 -d $home/temp/unpkged/
  cwd="$PWD"
  cd $home/temp/unpkged/
  . preinst.sh
  . info.rlmt
  echo "Installing $name@$version..."
  if . inst.sh; then
    echo "Succsesfully installed $name@$version"
  else
    echo "Failed to install $name"
  fi
  cd "$cwd"
  rm -rf $home/temp/unpkged
}
# Usage
print_usage() {
  echo "install (-i): Install Package(s)"
  echo "update (-u): Update/Refreshes Repositorys"
  echo "help (-h): Displays This Help Message"
  echo "-v: Verbose mode"
}
# Grab flags
while getopts 'vuhi:' flag; do # Get flags (With inputs) from beginning
  case "${flag}" in
    i) install $OPTARG;;
    u) update;;
    h) print_usage;;
    v) verbose=1 && flags="";;
  esac
done
for i in "$@"; do # Get Flags from anywhere
  case "${i:1}" in
    h) print_usage;;
    v) verbose=1 && flags="";;
  esac
done
# Parse arguments
args=(${@##-*})
case "${args[0]}" in
    install) install "${args[@]:1}";;
    update) update;;
    help) print_usage;;
esac
# Cleanup 
rm -rf $home/temp