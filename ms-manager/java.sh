#!/bin/bash

# Check if the correct version of Java is installed
# For version 1.8 to 1.11 use java 8
# For version 1.12 to 1.16.4 use java 11
# For version 1.16.5 use java 16
# For version 1.17.1 to 1.18.1+ use java 17
function check_java {
# Check if java is installed
  if ! command -v java &> /dev/null
  then
      >&2 echo "Error: Java is not installed"
      java_version="0"
  fi

  # Extract the middle number of the Minecraft version
  minecraft_middle=$(echo "$version" | awk -F '.' '{print $2}')

  # If java is installed, get the version (the java_version won't be 0)
  if [[ $java_version != "0" ]]; then
    # Get the current Java version and extract the build number
    java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F '.' '{print $1}')
    echo "Java $java_version is installed."
  fi

  # Check if the correct version of java is installed
  if (( 8 <= minecraft_middle && minecraft_middle <= 11 )); then
    if ! [[ $java_version -eq 8 ]]; then
      >&2 echo "Java 8 is required for Minecraft version $select_version. Please install Java 8."
      if [[ $java_version == 0 ]]; then
        exit 3
      fi
      ask_continue
    fi
  elif (( 12 <= minecraft_middle && minecraft_middle <= 16 )); then
    if ! [[ $java_version -eq 11 ]]; then
      >&2 echo "Java 11 is required for Minecraft version $select_version. Please install Java 11."
      if [[ $java_version == 0 ]]; then
        exit 3
      fi
      ask_continue
    fi
  elif (( minecraft_middle == 17 )); then
    if ! [[ $java_version -eq 16 ]]; then
      >&2 echo "Java 16 is required for Minecraft version $select_version. Please install Java 16."
      if [[ $java_version == 0 ]]; then
        exit 3
      fi
      ask_continue
    fi
  elif (( 18 <= minecraft_middle )); then
    if ! [[ $java_version -eq 17 ]]; then
      >&2 echo "Java 17 is required for Minecraft version $select_version. Please install Java 17."
      if [[ $java_version == 0 ]]; then
        exit 3
      fi
      ask_continue
    fi
  else
    >&2 echo "Unsupported Minecraft version $select_version."
    if [[ $java_version == 0 ]]; then
      exit 3
    fi
    ask_continue
  fi
}
