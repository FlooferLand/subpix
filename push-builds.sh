#!/bin/bash

alias godot="/usr/bin/godot"
version=$(awk -F "=" '/config\/version/ {print $2}' < "project.godot" | tr -d '"')

start_build() {
    godot --headless --export-release "$1"
}
push_build() {
    channel="$1"
    path="$2"
    printf "\n\nPushing %s build\n" "$channel"
    butler push "$path" "flooferland/subpix:$channel" --fix-permissions --userversion "$version"
}

# Web build
start_build "Web"
rm builds/web/index.png
push_build web builds/web

# Linux build
start_build "Linux"
push_build linux builds/linux

# Windows build
start_build "Windows Desktop"
push_build windows builds/windows
