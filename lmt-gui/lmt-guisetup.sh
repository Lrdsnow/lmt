touch ~/$pkg && echo "cd ~/.lmt/pkgs/$pkg && python3 ~/.lmt/pkgs/$pkg/main.py" > ~/$pkg && sudo chmod 755 ~/$pkg && sudo mv ~/$pkg /bin/$pkg
