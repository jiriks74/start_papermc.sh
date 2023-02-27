#!/bin/bash
set -e
# Setup Java
function setup_java {
  # Get the required Java version for the Minecraft version
  get_required_java

  # Check if java was downloaded by the script
  check_script_java

  # Check if java is installed
  if [[ $java_version == false ]]; then
    check_java_exec
    if [[ $java_version != false ]]; then
      echo "System Java $java_version will be used."
    fi
  fi

  if [[ $java_version == false ]]; then
    >&2 echo "Java $required_java is not installed."
    >&2 echo "Java $required_java is required to run Minecraft $version."
    # Ask the user if they want to download Adoptium JRE
    ask_jre
  fi
  echo
  echo
}

# Ask the user if they want to download Adoptium JRE
function ask_jre {
  echo "This script can download the correct Adoptium JRE into '$(echo $HOME)/.adoptium_java' for you."
  echo "You have 15 seconds to confirm or the script will exit."
  read -t 12 -p "Do you want to download Adoptium JRE? (y/N)" download_java

  if [[ $download_java == "y" ]] || [[ $download_java == "Y" ]]; then
    get_os_arch
    download_jre
    check_script_java
    if [[ $java_version == false ]]; then
      >&2 echo "Java $required_java was not downloaded correctly."
      >&2 echo "Please install Java $required_java manually."
      exit 4
    fi
  else
    >&2 echo "Please install Java $required_java and run this script again."
    exit 12
  fi
}

# Check if java was downloaded by the script
function check_script_java {
  if [[ -d "$(echo $HOME)/.adoptium_java" ]]; then
    if [[ $required_java == "8" ]]; then
      if [[ -d "$(echo $HOME)/.adoptium_java/jre8" ]]; then
        java_version=8
        if [[ -f "$(echo $HOME).adoptium_java/jre8/bin/java" ]]; then
          PATH="$(echo $HOME)/.adoptium_java/jre8/bin:$PATH"
        fi
      fi
    elif [[ $required_java == "11" ]]; then
      if [[ -d "$(echo $HOME)/.adoptium_java/jre11" ]]; then
        java_version=11
        PATH="$(echo $HOME)/.adoptium_java/jre11/bin:$PATH"
      fi
    elif [[ $required_java == "16" ]]; then
      if [[ -d "$(echo $HOME)/.adoptium_java/jre16" ]]; then
        java_version=16
        PATH="$(echo $HOME)/.adoptium_java/jre16/bin:$PATH"
      fi
    elif [[ $required_java == "17" ]]; then
      if [[ -d "$(echo $HOME)/.adoptium_java/jre17" ]]; then
        java_version=17
        PATH="$(echo $HOME)/.adoptium_java/jre17/bin:$PATH"
      fi
    fi
    check_java_exec
    if [[ $java_version == $required_java ]]; then
      echo "Java $java_version detected in '$(echo $HOME)/.adoptium_java/jre$(echo $java_version)/bin/java.' will be used."
    else
      java_version=false
    fi
  else
    java_version=false
  fi
}

# Get the system Java version
function check_java_exec {
# Check if java is installed
  if ! command -v java &> /dev/null
  then
      java_version=false
  fi

  # If java is installed, get the version (the java_version won't be 0)
  if [[ $java_version != false ]]; then
    # Get the current Java version and extract the build number
    java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F '.' '{print $1}')
  fi
}

# Get the required Java version for the Minecraft version
# For version 1.8 to 1.11 use java 8
# For version 1.12 to 1.16.4 use java 11
# For version 1.16.5 use java 16
# For version 1.17.1 to 1.18.1+ use java 17
function get_required_java {
  # Extract the middle number of the Minecraft version
  minecraft_middle=$(echo "$version" | awk -F '.' '{print $2}')


  # Get the java version for the defined server version
  if (( 8 <= minecraft_middle && minecraft_middle <= 11 )); then
    if ! [[ $java_version -eq 8 ]]; then
      required_java=8
    fi
  elif (( 12 <= minecraft_middle && minecraft_middle <= 16 )); then
    if ! [[ $java_version -eq 11 ]]; then
      required_java=11
    fi
  elif (( minecraft_middle == 17 )); then
    if ! [[ $java_version -eq 16 ]]; then
      required_java=16
    fi
  elif (( 18 <= minecraft_middle )); then
    if ! [[ $java_version -eq 17 ]]; then
      required_java=17
    fi
  else
    >&2 echo "Unsupported Minecraft version $select_version."
  fi
}

# Check host architecture
function get_os_arch {
  if [[ $(uname -m) == "x86_64" ]]; then
    arch="x64"
  elif [[ $(uname -m) == "aarch64" ]]; then
    arch="aarch64"
  else
    >&2 echo "Unsupported architecture $(uname -m)."
    >&2 echo "Please install Java $required_java manually."
    exit 3
  fi
}

# Download openjdk jre
function download_jre {
  # Check if .java folder exists
  if ! [[ -d "$(echo $HOME)/.adoptium_java" ]]; then
    echo "Creating $(echo $HOME)/.adoptium_java folder"
    mkdir "$(echo $HOME)/.adoptium_java"
  fi
  # Download the correct version of Java
  if [[ $required_java == "8" ]]; then
    echo "Downloading Adoptium JRE 8"
    curl -L -o java.tar.gz "https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u362-b09/OpenJDK8U-jre_$(echo $arch)_linux_hotspot_8u362b09.tar.gz"
    echo "Extracting Java 8"
    tar -xzf java.tar.gz
    echo "Moving Java 8 to $(echo $HOME)/.adoptium_java/jre8"
    mv jdk8u362-b09-jre "$(echo $HOME)/.adoptium_java/jre8"
    echo "Removing temporary files"
    rm java.tar.gz
  elif [[ $required_java == "11" ]]; then
    echo "Downloading Adoptium JRE 11"
    curl -L -o java.tar.gz "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.18%2B10/OpenJDK11U-jre_$(echo $arch)_linux_hotspot_11.0.18_10.tar.gz"
    echo "Extracting Java 11"
    tar -xzf java.tar.gz
    echo "Moving Java 11 to $(echo $HOME)/.adoptium_java/jre11"
    mv jdk-11.0.18+10-jre "$(echo $HOME)/.adoptium_java/jre11"
    echo "Removing temporary files"
    rm java.tar.gz
  elif [[ $required_java == "16" ]]; then
    echo "Downloading Java 16"
    curl -L -o java.tar.gz "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.18%2B10/OpenJDK11U-jre_$(echo $arch)_linux_hotspot_16.0.2_7.tar.gz"
    echo "Extracting Java 16"
    tar -xzf java.tar.gz
    echo "Moving Java 16 to $(echo $HOME)/.adoptium_java/jre16"
    mv jdk-16.0.2+7-jre "$(echo $HOME)/.adoptium_java/jre16"
    echo "Removing temporary files"
    rm java.tar.gz
  elif [[ $required_java == "17" ]]; then
    echo "Downloading Java 17"
    curl -L -o java.tar.gz "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.6%2B10/OpenJDK17U-jre_$(echo $arch)_linux_hotspot_17.0.6_10.tar.gz"
    echo "Extracting Java 17"
    tar -xzf java.tar.gz
    echo "Moving Java 17 to $(echo $HOME)/.adoptium_java/jre17"
    mv jdk-17.0.6+10-jre "$(echo $HOME)/.adoptium_java/jre17"
    echo "Removing temporary files"
    rm java.tar.gz
  fi
}
