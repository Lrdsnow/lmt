# Please Note: This Will Depend On Old Functions For A While:
if [ ! -f ~/.lmt/oldfunc.sh ]; then
  echo "Downloading Required Files..."
  if [ ! -d ~/.lmt ]; then
    mkdir ~/.lmt
  fi
  wget "https://raw.githubusercontent.com/Lrdsnow/lmt/main/lmt/element/oldfunc.sh" -q -O ~/.lmt/oldfunc.sh && exists=True || exists=False
  if [[ $exists = False ]]; then
    echo "Could Not Reach Server Exiting."
    exit 1
  fi
fi
source ~/.lmt/oldfunc.sh

# Install Script
install() {
  check_dist
  check_repo
  update=False
  if [ -f ~/.lmt/pkgs/$pkg/info ]; then
    echo "Package '$pkg' Already Installed"
    echo "Checking For Updates..."
    source ~/.lmt/pkgs/$pkg/info
    over=$ver
    update=True
  fi
  if [[ $update = False ]]; then
    rm -rf ~/.lmt/pkgs/$pkg/*
    rm -rf ~/.lmt/pkgs/$pkg
    if [ ! -d ~/.lmt ] || [ ! -d ~/.lmt/pkgs ]; then
      #older funcs aready create .lmt
      #mkdir ~/.lmt
      mkdir ~/.lmt/pkgs
    fi
    mkdir ~/.lmt/pkgs/$pkg
  fi
  wget "$src/$pkg/element/info" -q -O ~/.lmt/pkgs/$pkg/info && exists=True || exists=False
  if [[ $exists = False ]]; then
    if [[ $update = False ]]; then
      echo "Package '$pkg' Does Not Exist"
      rm -rf ~/.lmt/pkgs/$pkg/*
      rm -rf ~/.lmt/pkgs/$pkg
    else
      echo "$pkg does not exist on any server."
    fi
  else
    source ~/.lmt/pkgs/$pkg/info
    if [[ $update = False ]]; then
      echo "Installing $pkg"
      if [[ $zip = False ]]; then
        wget "$src/$pkg/element/$bin" -q -O ~/.lmt/pkgs/$pkg/$bin && exists=True || exists=False
        if [[ $distc = "darwin" ]]; then
          if [[ $darwin = True ]]; then
            $dsetup
            if [ $? -eq 0 ]; then
              echo "Package '$pkg' Succsessfuly installed"
            else
              rm -rf ~/.lmt/pkgs/$pkg/*
              rm -rf ~/.lmt/pkgs/$pkg
              echo "Package '$pkg' Failed to install"
            fi
          else
            echo "MacOS Unsupported, Exitting."
            exit 1
          fi
        else
          $setup
          if [ $? -eq 0 ]; then
            echo "Package '$pkg' Succsessfuly installed"
          else
            rm -rf ~/.lmt/pkgs/$pkg/*
            rm -rf ~/.lmt/pkgs/$pkg
            echo "Package '$pkg' Failed to install"
          fi
        fi
      else
        echo "temp"
      fi
    else
      if [[ $over = $ver ]]; then
        echo "No update needed, Latest version installed."
      else
        rm -rf ~/.lmt/pkgs/$pkg/*
        rm -rf ~/.lmt/pkgs/$pkg
        mkdir ~/.lmt/pkgs/$pkg
        echo "Update needed"
        install
      fi
    fi
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
    printf "Package Info:\nName: $pkg\nFull Name: $fname\nSupports MacOS?: $darwin\nCompressed?: $zip\nBinary: $bin\nCompatible Distros: $linux\n"
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
while getopts 'uvhi:c:' flag; do
  case "${flag}" in
    u) rm -rf ~/.lmt;;
    i) pkg=$OPTARG && uninstall=False && install;;
    h) print_usage;;
    c) pkg=$OPTARG && check;;
    v) verbose="Y";;
    *) print_usage
       exit 1 ;;
  esac
done
