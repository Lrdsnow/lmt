touch ~/lmt-gui.sh
echo "cd ~/.lmt/pkgs/lmt-gui && python3 ~/.lmt/pkgs/lmt-gui/main.py" > ~/lmt-gui.sh
sudo chmod 755 ~/lmt-gui.sh
sudo mv ~/lmt-gui.sh /bin/lmt-gui
sudo pacman -S python3 python-pip python-pygame -qq > /dev/null
sudo python3 -m pip install pygame-gui > /dev/null
