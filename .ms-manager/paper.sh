#!/bin/bash
set -e
# API URL
api_url="https://api.papermc.io/v2/projects/paper/versions/$version/builds"

# Check if the version and build are valid
function check_version_valid {
  if curl -s "$api_url" | grep -q '{"error":"Version not found."}'; then
    >&2 echo "Error: Invalid version selected: $version"
    exit 2
  else
    # Check if selected build exists
    if [ ! -z "$build" ]; then
      # WARNING: Check if the shortened versin works
      # if curl -Is "https://api.papermc.io/v2/projects/paper/versions/$version/builds/$build/downloads/paper-$version-$build.jar" | grep "HTTP/2 404" >/dev/null; then
      if curl -Is "$api_url/$build/downloads/paper-$version-$build.jar" | grep "HTTP/2 404" >/dev/null; then
        >&2 echo "Error: Invalid build selected: $build"
        exit 2
      fi
    fi
  fi
}

# Download server set by $version and $download_build
function download_server {
  # Download the server
  echo "Downloading PaperMC server..."
  echo "  - Version $version"
  echo "  - Build $download_build"
  curl "https://api.papermc.io/v2/projects/paper/versions/$version/builds/$download_build/downloads/paper-$version-$download_build.jar" -o "./paper-$version-$download_build.jar"
  echo "Download complete."
}

# Check if up to date
function check_updates {
  if [[ $server_file == false ]]; then
    download_build=$latest_build
    update_version=true
    update_build=true
  fi

  # Check if $build is empty
  if [[ -z $build ]]; then
    # Check if the current version is the same as the one selected
    if [[ $current_version == $version ]]; then
      # Check if the current build is the same as the one selected
      if [[ $current_build == $latest_build ]]; then
        echo "Server is up to date."
      else
        echo "Server is not up to date."
        download_build=$latest_build
        update_build=true
      fi
    else
      # Check if $server_file is false
      if [[ $server_file != false ]]; then
        ask_version_differs
        echo "Server is not up to date."
        download_build=$latest_build
        update_version=true
      fi
    fi
  else
    # Check if the current version is the same as the one selected
    if [[ $current_version == $version ]]; then
      # Check if the current build is the same as the one selected
      if [[ $current_build == $build ]]; then
        echo "Server is up to date."
      else
        echo "Server is not up to date."
        download_build=$build
        update_build=true
      fi
    else
      # Check if $server_file is false
      if [[ $server_file != false ]]; then
        ask_version_differs
        echo "Server is not up to date."
        download_build=$build
        update_version=true
      fi
    fi
  fi
}

# Get the latest build number
function get_latest_build {
    # Get the latest build number
    latest_build=$(curl -s $api_url | jq '.builds[-1].build')
}

# Check for updates
function check_and_update {
  if [[ $server_file == false ]]; then
    download_build=$latest_build
    update_version=true
    update_build=true
  else
    echo Checking for updates...
  fi

  # Get the latest build number
  get_latest_build

  # Check if the current version is up to date
  check_updates

  # Check if $build_update is true or $version_update is true
  if [[ $update_build == true ]] || [[ $update_version == true ]]; then
    if [[ $server_file != false ]]; then
      old_server_file=$server_file
      server_file="paper-$version-$download_build.jar"
      download_server
      # Delete the old server file
      delete_old_server
    else
      server_file="paper-$version-$download_build.jar"
      download_server
    fi
  fi
  echo
  echo
}

