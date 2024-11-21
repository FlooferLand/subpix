#!/bin/bash

version=$(awk -F "=" '/config\/version/ {print $2}' < "project.godot" | tr -d '"')

push_build() {
    channel="$1"
    path="$2"
    printf "\n\nPushing %s build\n" "$channel"
    butler push "$path" "flooferland/subpix:$channel" --fix-permissions --userversion "$version"
}

# Web build
rm builds/web/index.png
push_build web builds/web

# Desktop build
push_build linux builds/linux
push_build windows builds/windows
