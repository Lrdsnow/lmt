touch ~/moros.sh
echo "cd ~/.lmt/pkgs/moros && ./moros.exe" > moros.sh
sudo mv ~/moros.sh /bin/moros
sudo chmod 755 ~/.lmt/pkgs/moros/moros.exe
