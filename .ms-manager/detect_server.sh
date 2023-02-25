#!/bin/bash

# Detect the server type
function get_existing_server {
  if ls paper-*.jar 1> /dev/null 2>&1; then
    existing_server_type="paper"
    get_existing_paper
  # TODO: Add support for other server types
  # elif ls fabric-*.jar 1> /dev/null 2>&1; then
  #   existing_server_type="fabric"
  # elif ls spigot-*.jar 1> /dev/null 2>&1; then
  #   existing_server_type="spigot"
  # elif ls craftbukkit-*.jar 1> /dev/null 2>&1; then
  #   existing_server_type="craftbukkit"
  # elif ls vanilla-*.jar 1> /dev/null 2>&1; then
  #   existing_server_type="vanilla"
  else
    if ! ls *.jar 1> /dev/null 2>&1; then
      echo "No server file found."
      echo
      echo
      existing_server_type=false
      server_file=false
    else
      >&2 echo "$(ls *.jar) file was found."
      >&2 echo "Unknown server type."
      exit 10
      # TODO: Ask the user if they want to continue
    fi
  fi
}

# Get existing version and build of paper
function get_existing_paper {
  # Get the current server file name
  server_file=$(basename ./paper-*.jar)

  # Extract the version and build number using cut command
  current_version=$(echo "$server_file" | cut -d'-' -f2)
  current_build=$(echo "$server_file" | cut -d'-' -f3)
  # Remove the rest of the file names
  current_version="${current_version%-*}"
  current_build="${current_build%.jar}"

  echo "Current server file: $server_file"
  echo "  - Version $current_version"
  echo "  - Build $current_build"
  echo
  echo
}

