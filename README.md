# Lrdsnows MultiTool

This Is My Multitool 

## Install Instructions:

### Via LMT:

1. Download lmt.sh<br />
2. Open A Terminal In The Folder That lmt.sh is in<br />
3. Execute <code>sudo chmod 755 lmt.sh && sudo ./lmt.sh -n</code>

### Via APT:

1. Execute <code>curl -s --compressed "https://lrdsnow.github.io/lmt/ppa/KEY.gpg" | sudo apt-key add -</code>
2. Execute <code>sudo curl -s --compressed -o /etc/apt/sources.list.d/my_list_file.list "https://lrdsnow.github.io/lmt/ppa/lmtppa.list"</code>
3. Execute <code>sudo apt update</code>
4. Then You Execute <code>sudo apt install lmt</code> To Install LMT (you can use this to install lmt-gui and lmt-repo-tools too)

### Via PACMAN:
1. Download repo.aur.sh
2. Execute <code>sudo chmod 755 lmt.sh && sudo ./repo.aur.sh</code>
3. Then Install LMT With <code>sudo pacman -S lmt</code> (again this method works with lmt-gui and lmt-repo-tools too) 

## Usage:

### GUI:

<code>lmt -g</code>

### Install Apps:

Normal Install (mcg):<br />
<code>lmt -i app</code><br />
Install With Built In Package Manager (apt/apk/pacman):<br />
<code>lmt -ui app</code><br />


## Avalible MCG Apps:

Lrdsnow's MultiTool:<br />
<code>lmt -i lmt</code><br />
Lrdsnow's MultiTool GUI:<br />
<code>lmt -i lmt-gui</code><br />
Lrdsnow's MultiTool Repository Manager:<br />
<code>lmt -i lmt-repo-tools</code><br />
