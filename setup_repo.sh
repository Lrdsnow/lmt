# Repo Setup
if [ ! -f "repo/repo.json" ]; then
    mkdir -p repo/pkgs
    mkdir -p repo/pkgsinfo
    mkdir -p repo/pkgs_src
    echo "Repo name: "
    read name
    echo "Repo url: "
    read url
    echo "{
        \"name\":\"$name\",
        \"pkgs\":[],
        \"games\":[],
        \"tools\":[],
        \"url\":\"$url\"
    }" > repo/repo.json
    echo "Repo setup, Put Packages (.lmt) or Folders (in .lmt format) in repo/pkgs_src to add packages and rerun the script to refresh the repo"
else
    json_data=$(cat repo/repo.json)
    name=$(echo "$json_data" | jq -r '.name')
    url=$(echo "$json_data" | jq -r '.url')
    mkdir repo/temp
    rm -rf repo/pkgs/*
    rm -rf repo/pkgsinfo/*
    for file in "repo/pkgs_src"/*; do
        if [ -f "$file" ]; then
            cp $file repo/pkgs
            unzip $file -d repo/temp
            filename=$(basename "$file")
            mv repo/temp/info.json repo/pkgsinfo/${filename%.*}.json 
            rm -rf repo/temp/*
        elif [ -d "$file" ]; then
            filename=$(basename "$file")
            cp $file/info.json repo/pkgsinfo/${filename%.*}.json
            cwd="$PWD"
            cd $file
            zip -r $cwd/repo/pkgs/${filename%.*}.lmt *
            cd $cwd
        else
            echo "Warning Unrecognized File: $file"
        fi
    done
    for file in "repo/pkgsinfo"/*; do
        if [ -f "$file" ]; then
            app_data=$(cat $file)
            pkgname=$(echo "$app_data" | jq -r '.name')
            game=$(echo "$app_data" | jq -r '.game')
            pkgs+=($pkgname)
            if [ "$game" ] && [[ "$game" == "true" ]]; then
                games+=($pkgname)
            else
                tools+=($pkgname)
            fi
        fi
    done
    repo_data="{ \"name\":\"$name\", \"pkgs\":$(jq -n --argjson array "$(printf '%s\n' "${pkgs[@]}" | jq -R . | jq -s .)" '$array'), \"games\":$(jq -n --argjson array "$(printf '%s\n' "${games[@]}" | jq -R . | jq -s .)" '$array'), \"tools\":$(jq -n --argjson array "$(printf '%s\n' "${tools[@]}" | jq -R . | jq -s .)" '$array'), \"url\":\"$url\" }"
    echo "$repo_data" > repo/repo.json
    rm -rf repo/temp
    echo "Updated Repo Sucsessfully!"
fi