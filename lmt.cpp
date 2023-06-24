#include <iomanip>
#include <iostream>
#include <cmath>
#include <fstream>
#include <sstream>
#include <vector>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <curl/curl.h>
#include <json/json.h>
#include <filesystem>  // Add this line for std::filesystem support

namespace fs = std::filesystem;  // Add this line for namespace alias

// Variables
bool verbose = false;
std::string flags = "-q";
std::string home = getenv("HOME") + std::string("/.lmt");

// Basic Setup
void setup() {
    mkdir(home.c_str(), S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
    mkdir((home + "/bin").c_str(), S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
    mkdir((home + "/temp").c_str(), S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
    mkdir((home + "/data").c_str(), S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
}

// Execute Command With Result:
std::string executeCommand(const char* command) {
    std::string result;
    char buffer[128];
    FILE* pipe = popen(command, "r");

    if (!pipe) {
        std::cerr << "Error executing command." << std::endl;
        return "";
    }

    while (fgets(buffer, sizeof(buffer), pipe) != nullptr)
        result += buffer;

    pclose(pipe);
    return result;
}

// Repository's
void update() {
    std::string repos_conf_path = home + "/config/repos.json";
    if (access(repos_conf_path.c_str(), F_OK) != 0) {
        mkdir((home + "/config").c_str(), S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
        mkdir((home + "/repos").c_str(), S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
        Json::Value data;
        data["repos"].append("https://raw.githubusercontent.com/Lrdsnow/lmt/main/repo");
        data["cpkgs"] = Json::Value(Json::arrayValue);
        data["games"] = Json::Value(Json::arrayValue);  // New 'games' array
        data["tools"] = Json::Value(Json::arrayValue);  // New 'tools' array
        std::ofstream file(repos_conf_path);
        file << data;
        file.close();
        if (std::string(getenv("PATH")).find(home + "/bin") == std::string::npos) {
            std::ofstream bashrcFile(getenv("HOME") + std::string("/.bashrc"), std::ios_base::app);
            bashrcFile << "export PATH=\"$PATH:" << home << "/bin\"\n";
            bashrcFile.close();
        }
    }
    std::ifstream file(repos_conf_path);
    Json::Value data;
    file >> data;
    file.close();
    Json::Value repos = data["repos"];
    if (repos.size() == 0) {
        std::cout << "Failed, No repositories available" << std::endl;
        exit(1);
    }
    for (const auto& src : repos) {
        std::cout << "Checking " << src << "/repo.json..." << std::endl;
        std::string repo_json_url = src.asString() + "/repo.json";
        std::string temp_repo_json = home + "/temp/repo.json";
        std::string wget_command = "wget " + flags + " -O " + temp_repo_json + " " + repo_json_url;
        if (system(wget_command.c_str()) == 0) {
            std::ifstream repoFile(temp_repo_json);
            Json::Value repo_data;
            repoFile >> repo_data;
            repoFile.close();
            std::string repo_name = repo_data["name"].asString();
            std::string dest_repo_json = home + "/repos/" + repo_name + ".json";
            rename(temp_repo_json.c_str(), dest_repo_json.c_str());
            std::cout << "Successfully downloaded repository file" << std::endl;
        } else {
            std::cout << "Failed to download repository file" << std::endl;
        }
    }
    for (const auto& repo : std::filesystem::directory_iterator(home + "/repos")) {
        std::string repo_filename = repo.path().filename().string();
        if (repo_filename.find(".json") != std::string::npos) {
            std::cout << "Found " << repo_filename << std::endl;
            std::ifstream repoFile(repo.path());
            Json::Value repo_data;
            repoFile >> repo_data;
            repoFile.close();
            std::ifstream pkgsFile(home + "/config/repos.json");
            Json::Value pkgs_data;
            pkgsFile >> pkgs_data;
            pkgsFile.close();
            Json::Value cpkgs = pkgs_data.get("cpkgs", Json::Value(Json::arrayValue));
            Json::Value pkgs = repo_data.get("pkgs", Json::Value(Json::arrayValue));
            pkgs_data["cpkgs"] = cpkgs;
            for (const auto& pkg : pkgs) {
                bool found = false;
                for (const auto& cpkg : cpkgs) {
                    if (pkg == cpkg) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    pkgs_data["cpkgs"].append(pkg);
                }
            }
            // Merge "games" arrays
            Json::Value games = repo_data.get("games", Json::Value(Json::arrayValue));
            for (const auto& game : games) {
                bool found = false;
                for (const auto& existing_game : pkgs_data["games"]) {
                    if (game == existing_game) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    pkgs_data["games"].append(game);
                }
            }
            // Merge "tools" arrays
            Json::Value tools = repo_data.get("tools", Json::Value(Json::arrayValue));
            for (const auto& tool : tools) {
                bool found = false;
                for (const auto& existing_tool : pkgs_data["tools"]) {
                    if (tool == existing_tool) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    pkgs_data["tools"].append(tool);
                }
            }
            std::ofstream outfile(home + "/config/repos.json");
            outfile << pkgs_data;
            outfile.close();
            std::cout << "Successfully Refreshed Repo '" << repo_data["name"].asString() << "'" << std::endl;
        } else if (verbose) {
            std::cout << "Skipping " << repo_filename << std::endl;
        }
    }
}


void install_package(const std::string& package) {
    mkdir((home + "/temp/unpkged").c_str(), S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
    std::string unzip_command = "unzip " + flags + " " + package + " -d " + home + "/temp/unpkged/";
    system(unzip_command.c_str());
    std::string cwd = getcwd(NULL, 0);
    chdir((home + "/temp/unpkged/").c_str());
    std::string preinst_script = "bash preinst.sh";
    system(preinst_script.c_str());
    std::ifstream infoFile("info.json");
    Json::Value info_data;
    infoFile >> info_data;
    infoFile.close();
    std::string name = info_data["name"].asString();
    auto version = info_data["version"].asFloat();
    std::string system_arch = executeCommand("uname -p");
    system_arch.erase(system_arch.find_last_not_of("\n") + 1);
    Json::Value arch_list = info_data["arch"];
    for (const auto& arch : arch_list) {
        if (arch.isString() && (arch.asString() == "all" || arch.asString() == system_arch)) {
            std::cout << std::setprecision(3) << version;
            std::cout << "Installing " << name << "@" << version << "..." << std::endl;
            std::string inst_script = "bash inst.sh";
            if (system(inst_script.c_str()) == 0) {
                std::cout << "Successfully installed " << name << "@" << version << std::endl;
            } else {
                std::cout << "Failed to install " << name << std::endl;
            }
            chdir(cwd.c_str());
            system(("rm -rf " + home + "/temp/unpkged").c_str());
        } else {
            std::cout << "Failed to install " << name << "@" << version << ", Incompatible With System " << system_arch << "!" << std::endl;
        }
    }
    
}

// Function to get a list of packages
std::vector<std::string> getPackageList() {
    std::string repos_conf_path = home + "/config/repos.json";
    std::ifstream file(repos_conf_path);
    Json::Value data;
    file >> data;
    file.close();
    Json::Value cpkgs = data.get("cpkgs", Json::Value(Json::arrayValue));

    std::vector<std::string> packageList;
    for (const auto& pkg : cpkgs) {
        packageList.push_back(pkg.asString());
    }
    
    return packageList;
}

bool search_package(const std::string& package) {
    std::string pkgs_file = home + "/config/repos.json";
    if (access(pkgs_file.c_str(), F_OK) == 0) {
        std::ifstream file(pkgs_file);
        Json::Value data;
        file >> data;
        file.close();
        Json::Value cpkgs = data.get("cpkgs", Json::Value(Json::arrayValue));
        for (const auto& cpkg : cpkgs) {
            if (cpkg.asString() == package) {
                return true;
            }
        }
    }
    std::cout << "Failed, No packages found!" << std::endl;
    return false;
}

bool download_package(const std::string& package) {
    for (const auto& repo : std::filesystem::directory_iterator(home + "/repos")) {
        std::string repo_filename = repo.path().filename().string();
        if (repo_filename.find(".json") != std::string::npos) {
            std::ifstream repoFile(repo.path());
            Json::Value repo_data;
            repoFile >> repo_data;
            repoFile.close();
            Json::Value pkgs = repo_data["pkgs"];
            for (const auto& pkg : pkgs) {
                if (pkg.asString() == package) {
                    std::string package_url = repo_data["url"].asString() + "/pkgs/" + package + ".lmt";
                    std::string temp_package_file = home + "/temp/" + package + ".lmt";
                    std::string wget_command = "wget " + flags + " --show-progress -O " + temp_package_file + " " + package_url;
                    if (system(wget_command.c_str()) == 0) {
                        return true;
                    } else {
                        return false;
                    }
                }
            }
        } else if (verbose) {
            std::cout << "Skipping " << repo_filename << std::endl;
        }
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
                    std::string dpkg_command = "sudo dpkg -i " + p;
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
                std::string apt_search_command = "apt search ^" + p + "$ -qq";
                if (system(apt_search_command.c_str()) == 0) {
                    std::string apt_install_command = "sudo apt install " + p;
                    system(apt_install_command.c_str());
                } else {
                    std::cout << "Failed, " << p << " not found" << std::endl;
                }
            }
        }
    }
}

// Function to check if a package is installed
bool isPackageInstalled(const std::string& package) {
    std::string homeDir = std::getenv("HOME");
    std::string filePath = homeDir + "/.lmt/bin/" + package;
    std::ifstream file(filePath);
    return file.good();
}

// Function to check the installation status of a specific package
void checkPackageInstallation(const std::string& package, bool verbose) {
    bool isInstalled = isPackageInstalled(package);
    if (verbose) {
        std::cout << isInstalled << std::endl;
    } else {
        std::cout << "Checking installation status of package: " << package << std::endl;
        std::cout << package << ": " << (isInstalled ? "Installed" : "Not Installed") << std::endl;
    }
}


// Usage
void print_usage() {
    std::cout << "install (-i): Install Package(s)" << std::endl;
    std::cout << "update (-u): Update/Refreshes Repositories" << std::endl;
    std::cout << "help (-h): Displays This Help Message" << std::endl;
    std::cout << "-p: Lists all avalible packages" << std::endl;
    std::cout << "-v: Verbose mode" << std::endl;
}


// Grab flags
std::vector<std::string> parse_arguments(int argc, char* argv[]) {
    std::vector<std::string> args;
    for (int i = 1; i < argc; i++) {
        std::string flag = argv[i];
        if (flag == "-v" or flag == "-vc") {
            verbose = true;
        }
        if (flag == "-c" or flag == "-vc") {
            if (i + 1 < argc) {
                std::string packageName = argv[i + 1];
                checkPackageInstallation(packageName, verbose);
                i++;  // Increment i to skip the package name
            } else {
                std::cerr << "Error: Package name not specified." << std::endl;
                exit(1);
            }
        } else if (flag == "-i") {
            i++;
            while (i < argc) {
                args.push_back(argv[i]);
                i++;
            }
            install(args);
        } else if (flag == "-u") {
            update();
        } else if (flag == "-h") {
            print_usage();
        } else if (flag == "-p") {
            std::vector<std::string> packages = getPackageList();
            for (const auto& package : packages) {
                std::cout << package << std::endl;
            }
        } else {
            args.push_back(flag);  // Add non-flag arguments to the vector
        }
    }
    return args;
}

int main(int argc, char* argv[]) {
    setup();

    if (argc < 2) {
        print_usage();
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
        std::vector<std::string> args = parse_arguments(argc, argv);
    }

    return 0;
}

