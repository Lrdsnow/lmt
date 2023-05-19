#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <algorithm>
#include <iterator>
#include <sys/stat.h>
#include <unistd.h>
#include <cstdlib>
#include <cstdio>
#include <string>
#include <vector>
#include <cstring>
#include <dirent.h>
#include "deps/json.hpp"

// Variables
int verbose = 0;
std::string flags = "-q";
std::string home = std::string(getenv("HOME")) + "/.lmt";

using json = nlohmann::json;

// Basic Setup
void setup() {
    mkdir(home.c_str(), 0755);
    mkdir((home + "/bin").c_str(), 0755);
    mkdir((home + "/temp").c_str(), 0755);
}

// Repository's
void update() {
    std::string repos_conf_path = home + "/config/repos.json";
    std::ifstream repos_conf_file(repos_conf_path);
    if (!repos_conf_file.good()) {
        mkdir((home + "/config").c_str(), 0755);
        mkdir((home + "/repos").c_str(), 0755);
        std::ofstream new_repos_conf_file(repos_conf_path);
        new_repos_conf_file << R"(
{
    "repos": ["https://raw.githubusercontent.com/Lrdsnow/lmt/main/repo"],
    "cpkgs": []
}
)";
        new_repos_conf_file.close();
        std::string path_env = std::string(getenv("PATH"));
        if (path_env.find(home + "/bin") == std::string::npos) {
            std::ofstream bashrc_file(std::string(getenv("HOME")) + "/.bashrc", std::ios::app);
            bashrc_file << "export PATH=\"$PATH:" << home << "/bin\"\n";
            bashrc_file.close();
        }
    }
    std::ifstream repos_conf_input(repos_conf_path);
    std::stringstream repos_conf_ss;
    repos_conf_ss << repos_conf_input.rdbuf();
    std::string repos_conf_data = repos_conf_ss.str();
    repos_conf_input.close();

    json repos_conf_json = json::parse(repos_conf_data);
    std::vector<std::string> repos = repos_conf_json["repos"];

    if (repos.empty()) {
        std::cout << "Failed, No repositories available" << std::endl;
        exit(1);
    }

    for (const auto& src : repos) {
        std::cout << "Checking " << src << "/repo.json..." << std::endl;
        std::string repo_json_url = src + "/repo.json";
        std::string temp_repo_json_path = home + "/temp/repo.json";
        std::string wget_command = "wget \"" + repo_json_url + "\" " + flags + " -O " + temp_repo_json_path;

        int wget_return_code = system(wget_command.c_str());
        if (wget_return_code == 0) {
            std::ifstream repo_json_file(temp_repo_json_path);
            std::stringstream repo_json_ss;
            repo_json_ss << repo_json_file.rdbuf();
            std::string repo_json_data = repo_json_ss.str();
            repo_json_file.close();

            std::ofstream repo_json_dest(home + "/repos/" + repo_json_data + ".json");
            repo_json_dest << repo_json_data;
            repo_json_dest.close();

            std::cout << "Successfully downloaded repository file" << std::endl;
        } else {
            std::cout << "Failed to download repository file" << std::endl;
        }
    }

    std::string repos_dir = home + "/repos";
    DIR* dir;
    struct dirent* ent;
    if ((dir = opendir(repos_dir.c_str())) != nullptr) {
        while ((ent = readdir(dir)) != nullptr) {
            std::string repo_filename = ent->d_name;
            if (repo_filename.find(".json") != std::string::npos) {
                std::cout << "Found " << repo_filename << std::endl;
                std::ifstream repo_file(home + "/repos/" + repo_filename);
                std::stringstream repo_ss;
                repo_ss << repo_file.rdbuf();
                std::string repo_data = repo_ss.str();
                repo_file.close();

                std::ifstream pkgs_data_file(repos_conf_path);
                std::stringstream pkgs_data_ss;
                pkgs_data_ss << pkgs_data_file.rdbuf();
                std::string pkgs_data = pkgs_data_ss.str();
                pkgs_data_file.close();

                std::string cpkgs = pkgs_data.substr(pkgs_data.find("\"cpkgs\": [") + 11);
                cpkgs = cpkgs.substr(0, cpkgs.find_first_of("]"));
                cpkgs.erase(std::remove_if(cpkgs.begin(), cpkgs.end(), ::isspace), cpkgs.end());

                std::string pkgs = repo_data.substr(repo_data.find("\"pkgs\": [") + 10);
                pkgs = pkgs.substr(0, pkgs.find_first_of("]"));
                pkgs.erase(std::remove_if(pkgs.begin(), pkgs.end(), ::isspace), pkgs.end());

                pkgs_data.replace(pkgs_data.find("\"cpkgs\": [") + 11, cpkgs.length(), cpkgs + pkgs);

                std::ofstream pkgs_data_dest(repos_conf_path);
                pkgs_data_dest << pkgs_data;
                pkgs_data_dest.close();

                std::cout << "Successfully Refreshed Repo '" << repo_data << "'" << std::endl;
            } else if (verbose) {
                std::cout << "Skipping " << repo_filename << std::endl;
            }
        }
        closedir(dir);
    }
}

// Packages


void install_package(const std::string& package) {
    mkdir((home + "/temp/unpkged").c_str(), 0755);
    std::string unzip_command = "unzip " + flags + " " + package + " -d " + home + "/temp/unpkged/";
    system(unzip_command.c_str());

    std::string cwd = get_current_dir_name();
    chdir((home + "/temp/unpkged/").c_str());

    std::string preinst_command = "bash preinst.sh";
    system(preinst_command.c_str());

    std::ifstream info_json_file("info.json");
    std::stringstream info_json_ss;
    info_json_ss << info_json_file.rdbuf();
    std::string info_json_data = info_json_ss.str();
    info_json_file.close();

    std::string pkg_name = info_json_data;

    std::string install_command = "sudo cp -R bin/ /usr/local/";
    system(install_command.c_str());

    std::string postinst_command = "bash postinst.sh";
    system(postinst_command.c_str());

    std::string cleanup_command = "sudo rm -rf /usr/local/bin/" + pkg_name;
    system(cleanup_command.c_str());

    chdir(cwd.c_str());
    system(("rm -rf " + home + "/temp/unpkged").c_str());

    std::cout << "Successfully installed " << package << std::endl;
}

bool search_package(const std::string& package) {
    std::string pkgs_file = home + "/config/repos.json";
    std::ifstream pkgs_file_input(pkgs_file);
    std::stringstream pkgs_file_ss;
    pkgs_file_ss << pkgs_file_input.rdbuf();
    std::string pkgs_file_data = pkgs_file_ss.str();
    pkgs_file_input.close();

    std::istringstream iss(pkgs_file_data);
    std::string line;
    while (std::getline(iss, line)) {
        if (line.find("\"cpkgs\": [") != std::string::npos) {
            std::istringstream cpkgs_line_ss(line);
            std::string cpkg;
            while (std::getline(cpkgs_line_ss, cpkg, ',')) {
                if (cpkg.find(package) != std::string::npos) {
                    return true;
                }
            }
        }
    }

    std::cout << "Failed, No packages found!" << std::endl;
    return false;
}

bool download_package(const std::string& package) {
    std::string repos_dir = home + "/repos";
    DIR* dir;
    struct dirent* ent;
    if ((dir = opendir(repos_dir.c_str())) != nullptr) {
        while ((ent = readdir(dir)) != nullptr) {
            std::string repo_filename = ent->d_name;
            if (repo_filename.find(".json") != std::string::npos) {
                std::ifstream repo_file(home + "/repos/" + repo_filename);
                std::stringstream repo_ss;
                repo_ss << repo_file.rdbuf();
                std::string repo_data = repo_ss.str();
                repo_file.close();

                if (repo_data.find(package) != std::string::npos) {
                    std::string package_url = repo_data + "/pkgs/" + package + ".lmt";
                    std::string temp_package_path = home + "/temp/" + package + ".lmt";
                    std::string wget_command = "wget \"" + package_url + "\" " + flags + " --show-progress -O " + temp_package_path;

                    int wget_return_code = system(wget_command.c_str());
                    if (wget_return_code == 0) {
                        return true;
                    } else {
                        return false;
                    }
                }
            } else if (verbose) {
                std::cout << "Skipping " << repo_filename << std::endl;
            }
        }
        closedir(dir);
    }
    return false;
}

// Install
void install(const std::vector<std::string>& args) {
    for (const auto& p : args) {
        if (p.find("/") != std::string::npos || p.find(".") != std::string::npos) {
            if (access(p.c_str(), F_OK) == 0) {
                if (p.find(".deb") == std::string::npos) {
                    install_package(p);
                } else {
                    std::string dpkg_command = "sudo dpkg install " + p;
                    system(dpkg_command.c_str());
                }
            } else {
                std::cout << "Failed, file not found" << std::endl;
            }
        } else {
            if (search_package(p)) {
                if (download_package(p)) {
                    install_package(home + "/temp/" + p + ".lmt");
                } else {
                    std::cout << "Failed, Download failed" << std::endl;
                }
            } else {
                std::string apt_search_command = "apt search \"^" + p + "$\" -qq";
                int apt_search_return_code = system(apt_search_command.c_str());
                if (apt_search_return_code == 0) {
                    std::string apt_install_command = "sudo apt install " + p;
                    system(apt_install_command.c_str());
                } else {
                    std::cout << "Failed, " << p << " not found" << std::endl;
                }
            }
        }
    }
}

int main(int argc, char* argv[]) {
    setup();

    if (argc < 2) {
        std::cout << "No command specified" << std::endl;
        return 0;
    }

    std::string command = argv[1];
    if (command == "update") {
        update();
    } else if (command == "install") {
        std::vector<std::string> args;
        for (int i = 2; i < argc; i++) {
            args.push_back(argv[i]);
        }
        install(args);
    } else {
        std::cout << "Invalid command" << std::endl;
    }

    return 0;
}
