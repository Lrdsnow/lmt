$src = "https://raw.githubusercontent.com/Lrdsnow/lmt/main"

$i = $args[0]
$pkg = $args[1]

function run-func {
  $pkgexe=$pkg + ".ps1"
  if (Test-Path %Appdata%\lmt\pkgs\$pkg\$pkgexe -PathType Leaf) {
    $cl=Get-Location
    cd %Appdata%\lmt\pkgs\$pkg
    pwsh $pkgexe
    cd $cl
  } else {
    "E: Unable to run '$pkg'"
  }
}

function remove-func {
  if (Test-Path %Appdata%\lmt\pkgs\$pkg) {
     Remove-Item -Recurse -Force %Appdata%\lmt\pkgs\$pkg
    "Uninstalled $pkg"
  } else {
    "E: Package Not Installed $pkg"
  }
}

function install-func {
  $pkgver = $pkg + ".ver.txt"
  $pkgexe = $pkg + ".ps1"
  if (curl --fail -sL "$src/$pkg/win/$pkgver" -s) {
    if (-NOT (Test-Path %Appdata%\lmt\pkgs\$pkg\$pkgexe -PathType Leaf)) {
      curl $src/$pkg/win/$pkgver --output $pkgver -s
      $ver = Get-Content .\$pkgver -Raw
      $ver = [string]::join("",($ver.Split("`n")))
      "Installing $pkg ($ver)"
      New-Item -ItemType "directory" -Path "%Appdata%\lmt\pkgs\$pkg" > /dev/null
      curl $src/$pkg/win/$pkgexe --output %Appdata%\lmt\pkgs\$pkg\$pkgexe -s
      "Installed $pkg ($ver), Run It With 'lmt -R $pkg'"
    } else {
      "E: Package Already Installed '$pkg'"
    }
  } else {
    "E: Unable to locate package $pkg"
  }

}

if (-NOT ($i -eq $false)) {
  if (-NOT ($i -eq "") -or ($i -eq " ")) {
    if ($i -eq "-R") {
      run-func
    } else {
      if ($i -eq "-i") {
        install-func
      } else {
        if ($i -eq "-rm") {
          remove-func
        }
      }
    }
  }
}
