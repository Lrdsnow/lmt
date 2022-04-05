#
# OLD FUNCTIONS
#

# Old Values
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

# Old Repository Checker
check_repo() {
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
      fsrc="Y"
      #exit 1
    else
      cdsrcs=$(($cdsrcs + 1))
      nsrcs="REPO"$cdsrcs
      if [[ $NOR < $cdsrcs ]]; then
        fsrc="Y"
        #check_deb
        #exit 1
      fi
    fi
  done
}

# Old Distro Checker
check_dist() {
    unameOut="$(uname -s)"
    case "${unameOut}" in
      Linux*)     machine=Linux;;
      Darwin*)    machine=Mac;;
      CYGWIN*)    machine=Cygwin;;
      MINGW*)     machine=MinGw;;
      *)          machine="UNKNOWN:${unameOut}"
    esac
    if [[ $machine = "Mac" ]]; then
      dist="m"
    elif [[ $machine = "Linux" ]]; then
        distc="$(awk '/^ID=/' /etc/*-release | awk -F'=' '{ print tolower($2) }')"
        if [[ $distc = "ubuntu" ]] || [[ $distc = "debian" ]] || [[ $distc = "linux mint" ]] || [[ $distc = "mint" ]] || [[ $distc = "zorin" ]]; then
            dist="u"
        elif [[ $distc = "alpine" ]]; then
            dist="a"
        elif [[ $distc = "arch" ]] || [[ $distc = "manjaro" ]]; then
            dist="aur"
        else
            dist="unkown"
            echo "Could Not Detect Linux Distro. (But Linux Was Detected)"
        fi
    else
      echo "Unsupported Operating System!"
      exit 0
    fi
}

# Old Mac Installer
mmcginstall() {
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
  check_dist
  if [[ $dist = "u" ]]; then
    pkgsetup=$pkg"setup".sh
  elif [[ $dist = "aur" ]]; then
    pkgsetup=$pkg"setup.aur".sh
  elif [[ $dist = "m" ]]; then
    pkgsetup=$pkg"setup.mac".sh
  else
    echo "Distro Specific Setup Not Found For $distc"
    pkgsetup=""
  fi
  wget "$src/$pkg/$pkgsetup" -O ~/.lmt/pkgs/$pkg/$pkg'setup'.sh -q && st="Y" || rm ~/.lmt/pkgs/$pkg/$pkg'setup'.sh
  if [[ $st = "Y" ]]; then
    sudo chmod 755 ~/.lmt/pkgs/$pkg/$pkg'setup'.sh
    cd ~/.lmt/pkgs/$pkg/ && ./$pkg'setup'.sh
  fi
  echo "Succsessfuly Installed $pkg ($pkgver)"
}
