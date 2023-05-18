#!/usr/bin/env python3
import os
import shutil
import subprocess
import sys


# Variables
verbose = False
flags = "-q"
home = os.path.expanduser("~/.lmt")


# Basic Setup
def setup():
    os.makedirs(home, exist_ok=True)
    os.makedirs(os.path.join(home, "bin"), exist_ok=True)
    os.makedirs(os.path.join(home, "temp"), exist_ok=True)


# Repository's
def update():
    repos_conf_path = os.path.join(home, "config/repos.conf")
    if not os.path.isfile(repos_conf_path):
        os.makedirs(os.path.join(home, "config"), exist_ok=True)
        os.makedirs(os.path.join(home, "repos"), exist_ok=True)
        with open(repos_conf_path, "w") as f:
            f.write('repos=["https://raw.githubusercontent.com/Lrdsnow/lmt/main/repo"]\n')
            f.write("cpkgs=[]\n")
        if home+"/bin" not in os.environ["PATH"]:
            with open(os.path.expanduser("~/.bashrc"), "a") as f:
                f.write('export PATH="$PATH:{}"\n'.format(home+"/bin"))
    repos = []
    exec(open(repos_conf_path).read())
    if len(repos) == 0:
        print("Failed, No repositories available")
        sys.exit(1)
    for src in repos:
        print("Checking {}/repo.rlmt...".format(src))
        if subprocess.run(["wget", "{}repo.rlmt".format(src), flags, "-O", os.path.join(home, "temp/repo.rlmt")]).returncode == 0:
            exec(open(os.path.join(home, "temp/repo.rlmt")).read())
            shutil.move(os.path.join(home, "temp/repo.rlmt"), os.path.join(home, "repos/{}.rlmt".format(name)))
            print("Successfully downloaded repository file")
        else:
            print("Failed to download repository file")
    for repo in os.listdir(os.path.join(home, "repos")):
        print("Found {}".format(repo))
        exec(open(os.path.join(home, "repos", repo)).read())
        exec(open(os.path.join(home, "config/pkgs.conf")).read())
        with open(os.path.join(home, "config/pkgs.conf"), "w") as f:
            f.write("cpkgs={} {}\n".format(cpkgs, pkgs))
        print("Successfully Refreshed Repo '{}'".format(name))


def search_package(package):
    pkgs_conf_path = os.path.join(home, "config/pkgs.conf")
    if os.path.isfile(pkgs_conf_path):
        exec(open(pkgs_conf_path).read())
        if package in cpkgs:
            return True
    print("Failed, No packages found!")
    return False


def download_package(package):
    for repo in os.listdir(os.path.join(home, "repos")):
        exec(open(os.path.join(home, "repos", repo)).read())
        if package in pkgs:
            print("Downloading {}...".format(package))
            if subprocess.run(["wget", "{}/pkgs/{}.lmt".format(url, package), flags, "--show-progress", "-O", os.path.join(home, "temp/{}.lmt".format(package))]).returncode == 0:
                return True
            else:
                return False
    return False


# Install
def install(args):
    for p in args:
        if "/" in p or "." in p:
            if os.path.isfile(p):
                if not p.endswith(".deb"):
                    install_package(p)
                else:
                    subprocess.run(["sudo", "dpkg", "install", p])
            else:
                print("Failed, file not found")
        else:
            if search_package(p):
                if download_package(p):
                    install_package(os.path.join(home, "temp/{}.lmt".format(p)))
                else:
                    print("Failed, Download failed")
            else:
                if subprocess.run(["apt", "search", "^{}$".format(p), "-qq"]).returncode == 0:
                    subprocess.run(["sudo", "apt", "install", p])
                else:
                    print("Failed, {} not found".format(p))


def install_package(package):
    temp_dir = os.path.join(home, "temp/unpkged")
    os.makedirs(temp_dir, exist_ok=True)
    subprocess.run(["unzip", flags, package, "-d", temp_dir])
    cwd = os.getcwd()
    os.chdir(temp_dir)
    exec(open("preinst.sh").read())
    exec(open("info.rlmt").read())
    print("Installing {}@{}...".format(name, version))
    if exec(open("inst.sh").read()):
        print("Successfully installed {}@{}".format(name, version))
    else:
        print("Failed to install {}".format(name))
    os.chdir(cwd)
    shutil.rmtree(temp_dir)


# Usage
def print_usage():
    print("install (-i): Install Package(s)")
    print("update (-u): Update/Refreshes Repositories")
    print("help (-h): Displays This Help Message")
    print("-v: Verbose mode")


# Grab flags
def parse_arguments():
    args = sys.argv[1:]
    while args:
        flag = args.pop(0)
        if flag == "-i":
            install(args.pop(0).split())
        elif flag == "-u":
            update()
        elif flag == "-h":
            print_usage()
        elif flag == "-v":
            global verbose, flags
            verbose = True
            flags = ""
        else:
            args.insert(0, flag)
            break
    else:
        args = []
    return args


def main():
    setup()
    args = parse_arguments()
    if args:
        command = args.pop(0)
        if command == "install":
            install(args)
        elif command == "update":
            update()
        elif command == "help":
            print_usage()


if __name__ == "__main__":
    main()

# Cleanup
shutil.rmtree(os.path.join(home, "temp"))
