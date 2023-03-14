#!/bin/bash
# Variables
verbose=0
# Repository's
update() {
  mkdir -p ~/.lmt
  echo "$src/repo.rlmt"
  if wget "$src/repo.rlmt" -q -O ~/.lmt/$repo.rlmt; then
    echo Succsess
  else
    echo Failed
  fi
}
# Install
install() {
    for p in $@; do
      echo $p
    done
}
# Usage
print_usage() {
  echo "install (-i): Install Package(s)"
  echo "update (-u): Update/Refreshes Repositorys"
  echo "help (-h): Displays This Help Message"
  echo "-v: Verbose mode"
}
# Grab flags
while getopts 'vhi:u:' flag; do # Get flags (With inputs) from beginning
  case "${flag}" in
    i) install $OPTARG;;
    u) update;;
    h) print_usage;;
    v) verbose=1;;
  esac
done
for i in "$@"; do # Get Flags from anywhere
  case "${i:1}" in
    h) print_usage;;
    v) verbose=1;;
  esac
done
# Parse arguments
args=(${@##-*})
case "${args[0]}" in
    install) install "${args[@]:1}";;
    update) update;;
    help) print_usage;;
esac