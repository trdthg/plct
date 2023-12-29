#!/usr/bin/env bash

shopt -s globstar nullglob
for file in find ./**/*.rst; do
    echo "$file"
    final_path="../../docs/docs/${file%.*}.md"
    folder_path="$(dirname "$final_path")"
    echo "$folder_path"
    echo "$final_path"
    mkdir -p "$folder_path"

    rm "$final_path"
    pandoc -s -o "$final_path" "$file"
    autocorrect --fix "$final_path"
    # touch "$final_path"
done