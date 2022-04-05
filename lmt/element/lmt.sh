# Please Note: This Will Depend On Old Functions For A While:
source $(dirname "$0")/oldfunc.sh

# Install Script
install() {
  check_dist
  check_repo
  rm -rf ~/.lmt/pkgs/$pkg/*
  rm -rf ~/.lmt/pkgs/$pkg
  mkdir ~/.lmt/pkgs/$pkg
  wget "$src/$pkg/element/info" -q -O ~/.lmt/pkgs/$pkg/info && exists=True || exists=False
  if [[ $exists = False ]]; then
    echo "Package '$pkg' Does Not Exist"
    rm -rf ~/.lmt/pkgs/$pkg/*
    rm -rf ~/.lmt/pkgs/$pkg
  else
    source ~/.lmt/pkgs/$pkg/info
    printf ""
  fi
}

# Checking Script
check() {
  check_dist
  check_repo
  rm -rf ~/.lmt/pkgs/$pkg/*
  rm -rf ~/.lmt/pkgs/$pkg
  mkdir ~/.lmt/pkgs/$pkg
  wget "$src/$pkg/element/info" -q -O ~/.lmt/pkgs/$pkg/info && exists=True || exists=False
  if [[ $exists = "True" ]]; then
    source ~/.lmt/pkgs/$pkg/info
    printf "Package Info:\nName: $pkg\nFull Name: $fname\nSupports MacOS?: $darwin\nCompressed?: $zip\nBinary: $bin\n"
  else
    echo "Package '$pkg' Does Not Exist"
  fi
  rm -rf ~/.lmt/pkgs/$pkg/*
  rm -rf ~/.lmt/pkgs/$pkg
}


# Usage
print_usage() {
  echo "-i: Install Package"
  echo "-h: Displays This Help Message"
}

# Grab Flags
while getopts 'vhi:c:' flag; do
  case "${flag}" in
    i) pkg=$OPTARG && install;;
    h) print_usage;;
    c) pkg=$OPTARG && check;;
    v) verbose="Y";;
    *) print_usage
       exit 1 ;;
  esac
done
