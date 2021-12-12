#!/bin/bash
pkge=""
src="https://mc.lrdsnow.repl.co/pkgs"
fsrc="N"
nsrcs="REPO1"
cdsrcs=1
allpkgs=99

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
        exit 1
      fi
    fi
  done
}

deb() {
  if [[ -f $repo/lmt.repo ]]; then
    :
  else
    touch $repo/lmt.repo
    echo "NOD=0" >> $repo/lmt.repo
    echo "NAME=LMTREPO" >> $repo/lmt.repo
  fi
  source $repo/lmt.repo
  rpkgn=$ipkgn"_"
  pkgn=$(echo $repo/$rpkgn*.deb)
  pkgn=$(echo $pkgn | tr / : | sed 's/.*://')
  pkgn=$(echo $repol/$pkgn)
  fvar NOD $(($NOD + 1)) $repo/lmt.repo
  NOD=$(($NOD + 1))
  pkg="$ipkgn=$pkgn"
  echo "$pkg" >> $repo/lmt.repo
}

autodeb() {
  if [[ -f $repo/lmt.repo ]]; then
    :
  else
    touch $repo/lmt.repo
    echo "NOD=0" >> $repo/lmt.repo
  fi
  rpkg=1
  pkgs=$(echo $repo/*.deb)
  allpkgs=$(echo "$pkgs" | wc -l)
  source $repo/lmt.repo
  while :; do
    pkgn=`echo "${pkgs}" | head -$rpkg`
    echo $pkgn
    fvar NOD $(($NOD + 1)) $repo/lmt.repo
    NOD=$(($NOD + 1))
    pkg="PKG$NOD=$pkgn"
    echo "$pkg" >> $repo/lmt.repo
    rpkg=$(($rpkg + 1))
    if [[ $rpkg -ge allpkgs ]]; then
      exit 1
    fi
  done
}

while getopts 'a:ui:r:d:l:' flag; do
  case "${flag}" in
    l) repol=$OPTARG;;
    r) repo=$OPTARG;; #&& autodeb;;
    d) ipkgn=$OPTARG && deb;;
    i) pkg=$OPTARG && check-repo;;
    a) nwrepol=$OPTARG && check-to-add-repo
       exit 1 ;;
  esac
done
