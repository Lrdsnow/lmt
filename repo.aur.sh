gpg --recv-keys 65EDE4B7341D9DAB2C0A17D5F7B90064E0A4307C
wget "https://raw.githubusercontent.com/Lrdsnow/lmt/main/aur/KEY.gpg" -O ~/KEY.gpg
sudo pacman-key --add ~/KEY.gpg
repo="[lmt]
SigLevel = Optional TrustAll
Server = https://lrdsnow.github.io/lmt/aur/x86_64"
sudo echo $repo >> /etc/pacman.conf
sudo pacman -Syy
