#!/bin/bash
# Function to validate if input is a float
validate_float() {
    if [[ $1 =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        return 0
    else
        return 1
    fi
}
# Function to validate arch
validate_arch() {
    valid_archs=("i386" "x86_64" "arm32" "armhf" "arm64" "all")
    for arch in "${valid_archs[@]}"; do
        if [[ "$1" == "$arch" ]]; then
            return 0
        fi
    done
    return 1
}
while true; do
    read -p "Name of package: " name

    read -p "Package version: " version
    while ! validate_float "$version"; do
        read -p "Package version (must be a float): " version
    done

    read -p "Is the package launchable? (Y/n): " game
    if [[ "$game" == "Y" || "$game" == "y" ]]; then
        game="true"
    fi

    echo "Type of package:"
    echo "1. Web Package (Download's a .zip from the internet and extracts it to ~/.lmt/data and makes a shortcut in ~/.lmt/bin)"
    echo "2. Script Package (Copy's a script to ~/.lmt/bin)"
    read -p "Enter your choice: " choice

    case $choice in
    1)
        while true; do
            read -p "Enter the url for the .zip: " url
            read -p "Enter the executable name in the .zip: " exe
            read -p "Enter the executable architecture (or 'all' for all architectures): " arch
            while ! validate_arch "$arch"; do
                read -p "Enter a valid architecture (or 'all'): " arch
            done

            if [[ "$arch" == "all" ]]; then
                echo "Running action for all architectures"
                # Add your code for running the action for all architectures here
                break
            else
                perform_action "$arch"
            fi

            read -p "Enter 'exit' if no more .zips or press any key to continue: " choice
            if [[ "$choice" == "exit" ]]; then
                break
            fi
        done
        ;;
    2)
        echo "Executing code for Script Package with name: $name, version: $version"
        # Add your code for Script Package here
        break
        ;;
    *)
        echo "Invalid choice. Please try again."
        ;;
    esac
done
