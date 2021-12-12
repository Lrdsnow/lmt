#!/bin/bash

dist=""
pkg=""
ru="N"
mcgp=""
mcgpn=""
ver="v1"
cver=""
distc=""
urda=""
pkgver=$pkg"ver"
dpkgver=$pkgver".txt"
sc="N"
install="N"
src="https://raw.githubusercontent.com/Lrdsnow/lmt/main"
fsrc="N"
nsrcs="REPO1"
cdsrcs=1
pkge=""
allpkgs=99
deb="N"

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
        echo "E: Unable to locate package $pkg"
        exit 1
      fi
    fi
  done
}

debinstall() {
  wget "$src/lmt.repo" -q -O ~/lmt.repo
  links=$(cat ~/lmt.repo | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | sort -u) && links=(${links[@]}) && link=$(echo "${links[$linkint]}")
  names=$(sed 1,2d ~/lmt.repo | cut -f1 -d"=") && names=(${names[@]}) && name=$(echo "${names[$nameint]}")
  wget "$link" -q -O ~/.lmt/pkgs/$pkg.deb
  sudo dpkg -i ~/.lmt/pkgs/$pkg.deb && rm ~/.lmt/pkgs/$pkg.deb && exit
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
        echo "E: Unable to locate package $pkg"
        exit
      fi
    fi
  done
}

check_dist() {
  distc="$(awk '/^ID=/' /etc/*-release | awk -F'=' '{ print tolower($2) }')"
  if [[ $distc = "ubuntu" ]] || [[ $distc = "debian" ]] || [[ $distc = "linux mint" ]] || [[ $distc = "mint" ]]; then
    dist="u"
  elif [[ $distc = "alpine" ]]; then
    dist="a"
  fi
}

print_usage() {
  printf "Usage:\n-u: use built in package manager\n-r: do not use sudo (for root users)\n-i <app>: installs app\n-a <link>: adds repo\n"
}

fvar () {
    variable="${1}"
    content="${2}"
    file="${3}"

    if [ ! -f "${file}" ]; then
        echo "lmt: file doesn't exist: ${file}"
        exit 1
    fi

    sed -i "s/^${variable}\=.*/${variable}=\"${content}\"/" "${file}"
}

check-to-add-repo() {
  while [[ $fsrc = "N" ]]; do
    source ~/.lmt/srcs/srcs.sh
    csrc=${!nsrcs}
    if [[ $csrc = $nwrepol ]]; then
      echo "Repo Already Being Used!"
      exit 1
    else
      cdsrcs=$(($cdsrcs + 1))
      nsrcs="REPO"$cdsrcs
      if [[ $NOR < $cdsrcs ]]; then
        add-repo
        exit 1
      fi
    fi
  done
}

add-repo() {
  source ~/.lmt/srcs/srcs.sh
  fvar NOR $(($NOR + 1)) ~/.lmt/srcs/srcs.sh
  NOR=$(($NOR + 1))
  nwrepo="REPO$NOR=$nwrepol"
  echo "$nwrepo" >> ~/.lmt/srcs/srcs.sh
}

check-repo() {
  if [[ -d ~/.lmt/srcs ]]; then
    :
  else
    mkdir ~/.lmt
    mkdir ~/.lmt/srcs
    touch ~/.lmt/srcs/srcs.sh
    echo "NOR=1" > ~/.lmt/srcs/srcs.sh
    echo "REPO1=https://raw.githubusercontent.com/Lrdsnow/lmt/main" >> ~/.lmt/srcs/srcs.sh
  fi
  while [[ $fsrc = "N" ]]; do
    if [[ $verbose = "Y" ]]; then
      echo "$cdsrcs $csrc $nsrcs"
    fi
    source ~/.lmt/srcs/srcs.sh
    csrc=${!nsrcs}
    pkgver=$pkg"ver"
    dpkgver=$pkgver".txt"
    wget "$csrc/$pkg/$dpkgver" -q -O ~/test.txt && pkge="y" || pkge="n"
    if [[ $pkge = "y" ]]; then
      src=$csrc
      premcginstall
      exit 1
    else
      cdsrcs=$(($cdsrcs + 1))
      nsrcs="REPO"$cdsrcs
      if [[ $NOR < $cdsrcs ]]; then
        check_deb
        exit 1
      fi
    fi
  done
}

mcginstall() {
  if [[ -d ~/.lmt/pkgs ]]; then
    if [[ -d ~/.lmt/pkgs/$pkg ]]; then
      rm -rf ~/.lmt/pkgs/$pkg
    fi
    mkdir ~/.lmt/pkgs/$pkg
  else
    mkdir ~/.lmt/pkgs
    mkdir ~/.lmt/pkgs/$pkg
  fi
  pkgver=$pkg"ver"
  dpkgver=$pkgver".txt"
  wget "$src/$pkg/$dpkgver" -q -O ~/.lmt/pkgs/$pkg/version.txt && pkge="y" || pkge="n"
  if [[ $pkge != "y" ]]; then
    echo "E: Unable to locate package $pkg"
    rm -rf ~/.lmt/pkgs/$pkg
    exit
  else
    pkgver="$(grep -o 'v[^"]*' ~/.lmt/pkgs/$pkg/version.txt)"
    echo "Installing $pkg ($pkgver) ..."
  fi
  wget "$src/$pkg/$pkg.zip" -O ~/$pkg.zip -q
  unzip -qq ~/$pkg.zip -d ~/.lmt/pkgs/$pkg/
  rm ~/$pkg.zip
  pkgsetup=$pkg"setup".sh
  wget "$src/$pkg/$pkgsetup" -O ~/.lmt/pkgs/$pkg/$pkg'setup'.sh -q && st="Y" || rm ~/.lmt/pkgs/$pkg/$pkg'setup'.sh
  if [[ $st = "Y" ]]; then
    sudo chmod 755 ~/.lmt/pkgs/$pkg/$pkg'setup'.sh
    cd ~/.lmt/pkgs/$pkg/ && ./$pkg'setup'.sh
  fi
  echo "Succsessfuly Installed $pkg ($pkgver)"
}

premcginstall() {
  if [[ -d ~/.lmt/pkgs/$pkg ]] && [[ -f ~/.lmt/pkgs/$pkg/version.txt ]]; then
    mkdir ~/.lmt/tmp
    pkgver=$pkg"ver"
    dpkgver=$pkgver".txt"
    wget "$src/$pkg/$dpkgver" -q -O ~/.lmt/tmp/v.txt
    cpkgver="$(grep -o 'v[^"]*' ~/.lmt/tmp/v.txt)"
    pkgver="$(grep -o 'v[^"]*' ~/.lmt/pkgs/$pkg/version.txt)"
    if command -v $cmd &> /dev/null; then
      if [[ $cpkgver = $pkgver ]]; then
        echo "$pkg is already the newest version ($pkgver)."
      else
        rm -rf ~/.lmt/tmp
        mcginstall
      fi
    else
        if [[ $cpkgver = $pkgver ]]; then
          echo "$pkg is already the newest version ($pkgver)."
        else
          rm -rf ~/.lmt/tmp
          mcginstall
        fi
    fi
    rm -rf ~/.lmt/tmp
  else
    mcginstall
  fi
}

install() {
  if [[ $verbose = "Y" ]]; then
    printf "user is using built in package manager "
  fi
  if [[ $dist = "u" ]]
  then
    if [[ $verbose = "Y" ]]; then
      printf "(APT)\n"
    fi
    if [[ $ru = "N" ]]
    then
      sudo apt-get install -y $pkg -qq > /dev/null
    elif [[ $ru = "Y" ]]
    then
      apt install -y $pkg -qq > /dev/null
    else
      echo "Error"
    fi
  elif [[ $dist = "a" ]]
  then
    if [[ $verbose = "Y" ]]; then
      printf "(APK)\n"
    fi
    if [[ $ru = "N" ]]
    then
      sudo apk add $pkg
    elif [[ $ru = "Y" ]]; then
      apk add $pkg
    else
      echo "Error"
    fi
  else
    if [[ $verbose = "Y" ]]; then
      printf "(Unknown)\n"
    fi
    printf "Could Not Recognize This Distro\n"
  fi
}

upg() {
  if command -v $cmd &> /dev/null; then
    echo "Installing LMT..."
    if [[ $verbose = "Y" ]]; then
      sudo cp ./lmt.sh /bin/lmt
    else
      sudo mv ./lmt.sh /bin/lmt
    fi
    sudo chmod 755 /bin/lmt
    echo "LMT installed."
  else
    echo "LMT Already Installed Upgrade From There"
  fi
}

preinstall() {
  if [[ $verbose = "Y" ]]; then
    printf "user is installing $pkg\n"
  fi
  if [[ $urda = "Y" ]];  then
    if [[ $verbose = "Y" ]]; then
      echo "Native Install"
    fi
    install
  elif [[ $install = "Y" ]]; then
    if [[ $verbose = "Y" ]]; then
      echo "Installing LMT"
    fi
    upg
  else
    if [[ $verbose = "Y" ]]; then
      echo "MCG Installer"
    fi
    check-repo
  fi
}

rm-pkg() {
  if [[ -d ~/.lmt/pkgs/$pkg ]]; then
    rm -rf ~/.lmt/pkgs/$pkg > /dev/null
    echo "$pkg Succsessfuly Uninstalled"
  else
    echo "$pkg Not Installed."
  fi
}

repo-mng() {
  if [[ -f ~/.lmt/pkgs/lmt-repo-tools/lmt-repo-tools.sh ]] || [[ -f /usr/bin/lmt-repo-tools ]]; then
    if [[ $inputrepo != "clear" ]]; then
      if [[ -f /usr/bin/lmt-repo-tools ]]; then
        lmt-repo-tools -a $inputrepo
      else
        cd ~/.lmt/pkgs/lmt-repo-tools/ && ./lmt-repo-tools.sh -a $inputrepo
      fi
    else
      if [[ -d ~/.lmt/srcs ]]; then
        rm -rf ~/.lmt/srcs
        mkdir ~/.lmt/srcs
        touch ~/.lmt/srcs/srcs.sh
        echo "NOR=1" > ~/.lmt/srcs/srcs.sh
        echo "REPO1=https://raw.githubusercontent.com/Lrdsnow/lmt/main" >> ~/.lmt/srcs/srcs.sh
      fi
    fi
  else
    echo "Repo Tools Are Not Installed. Install Them With 'lmt -i lmt-repo-tools'"
  fi
}

gui() {
  gui=~/.lmt/pkgs/lmt-gui/main.py
  if [[ -f "$gui" ]] || [[ -f "/usr/lmt-gui" ]]; then
    lmt-gui
  else
    echo 'GUI Is Not installed Please Install It With "lmt -i lmt-gui"'
  fi
}

while getopts 'hnguvi:s:a:r:' flag; do
  case "${flag}" in
    u) sc="Y" && check_dist && urda="Y";;
    i) sc="Y" && pkg=$OPTARG && preinstall;;
    r) sc="Y" && pkg=$OPTARG && rm-pkg;;
    g) sc="Y" && gui;;
    v) sc="Y" && verbose="Y";;
    n) sc="Y" && pkg="lmt" && install="Y" && preinstall;;
    s) sc="Y" && src=$OPTARG;;
    a) sc="Y" && inputrepo=$OPTARG && repo-mng;;
    h) sc="Y" && print_usage;;
    *) sc="Y" && print_usage
       exit 1 ;;
  esac
done

if [[ $sc != "Y" ]]; then
  print_usage
fi
