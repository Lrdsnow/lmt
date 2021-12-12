$i = $args[0]
$pkg = $args[1]
$src = "https://raw.githubusercontent.com/Lrdsnow/lmt/main"

if (curl --fail -sL "$src/$pkg/win/$pkgver") {
  "found!"
} else {
  "E: Unable to locate package $pkg"
}
