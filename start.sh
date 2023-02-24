#!/bin/bash
#############################################################################################################
#                                Auto Update & Run PaperMC server script                                    #
#                                              by jiriks74                                                  #
#                             https://github.com/jiriks74/start_papermc.sh                                  #
#  This script is under GPLv3, if you want to distribute changes you have to do so under the same license   #
#                            and acknowledge the original script and author.                                #
#############################################################################################################

CURRENT_VERSION="v1.0.3"

# --------------------------------------------------
# You shouldn't need to change anything in this file
# Settings are located in 'launch.cfg'
# --------------------------------------------------
#
# The url of the script (used for updating)
REPO_OWNER="jiriks74"
REPO_NAME="start_papermc.sh"

# Check for dependencies
function check_dependencies {
  # Check if curl is installed
  if ! command -v curl &> /dev/null
  then
      echo "Error: Curl is not installed"
      exit 1
  fi

  # Check if jq is installed
  if ! command -v jq &> /dev/null
  then
      echo "Error: jq is not installed"
      exit 1
  fi

  # Check if awk is installed
  if ! command -v awk &> /dev/null
  then
      echo "Error: awk is not installed"
      exit 1
  fi
}

# Check if the version and build are valid
function check_version_valid {
  if curl -s "$api_url" | grep -q '{"error":"Version not found."}'; then
    echo "Error: Invalid version selected: $select_version"
    exit 2
  else
    # Check if selected build exists
    if [ ! -z "$select_build" ]; then
      if curl -Is "https://api.papermc.io/v2/projects/paper/versions/$select_version/builds/$select_build/downloads/paper-$select_version-$select_build.jar" | grep "HTTP/2 404" >/dev/null; then
        echo "Error: Invalid build selected: $select_build"
        exit 2
      fi
    fi
  fi
}

# Ask if the user wants to continue anyway
# If the user doesn't answer in 15 seconds, the script will exit
function ask_continue {
  if [[ $java_version_override != true ]]; then
    answer=""
    echo "You have 15 seconds to respond before the script exits."
    read -t 15 -p "Do you want to continue anyway? [y/N]: " answer
    if [[ $answer != "y" ]] && [[ $answer != "Y" ]]; then
        echo "Exiting..."
        exit 1
    fi
  fi
}

# Check if the correct version of Java is installed
# For version 1.8 to 1.11 use java 8
# For version 1.12 to 1.16.4 use java 11
# For version 1.16.5 use java 16
# For version 1.17.1 to 1.18.1+ use java 17
function check_java {
# Check if java is installed
  if ! command -v java &> /dev/null
  then
      echo "Error: Java is not installed"
      java_version="0"
  fi

  # Extract the middle number of the Minecraft version
  minecraft_middle=$(echo "$select_version" | awk -F '.' '{print $2}')

  # If java is installed, get the version (the java_version won't be 0)
  if [[ $java_version != "0" ]]; then
    # Get the current Java version and extract the build number
    java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F '.' '{print $1}')
  fi

  # Check if the correct version of java is installed
  if (( 8 <= minecraft_middle && minecraft_middle <= 11 )); then
    if ! [[ $java_version -eq 8 ]]; then
      echo "Java $java_version is installed."
      echo "Java 8 is required for Minecraft version $select_version. Please install Java 8."
      if [[ $java_version == 0 ]]; then
        exit 3
      fi
      ask_continue
    fi
  elif (( 12 <= minecraft_middle && minecraft_middle <= 16 )); then
    if ! [[ $java_version -eq 11 ]]; then
      echo "Java $java_version is installed."
      echo "Java 11 is required for Minecraft version $select_version. Please install Java 11."
      if [[ $java_version == 0 ]]; then
        exit 3
      fi
      ask_continue
    fi
  elif (( minecraft_middle == 17 )); then
    if ! [[ $java_version -eq 16 ]]; then
      echo "Java $java_version is installed."
      echo "Java 16 is required for Minecraft version $select_version. Please install Java 16."
      if [[ $java_version == 0 ]]; then
        exit 3
      fi
      ask_continue
    fi
  elif (( 18 <= minecraft_middle )); then
    if ! [[ $java_version -eq 17 ]]; then
      echo "Java $java_version is installed."
      echo "Java 17 is required for Minecraft version $select_version. Please install Java 17."
      if [[ $java_version == 0 ]]; then
        exit 3
      fi
      ask_continue
    fi
  else
    echo "Unsupported Minecraft version $select_version."
    if [[ $java_version == 0 ]]; then
      exit 3
    fi
    ask_continue
  fi
}

# Get existing version and build
function get_existing_version {
  if ls paper-*.jar 1> /dev/null 2>&1; then
    # Get the current server file name
    server_file=$(basename ./paper-*.jar)

    # Extract the version and build number using cut command
    current_version=$(echo "$server_file" | cut -d'-' -f2)
    current_build=$(echo "$server_file" | cut -d'-' -f3)
    current_version="${current_version%-*}"
    current_build="${current_build%.jar}"
    echo "Current server file: $server_file"
    echo "  - Version $current_version"
    echo "  - Build $current_build"
  else
    echo "No old server file found."
    server_file=false
  fi
}

# Download server set by $select_version and $download_build
function download_server {
  # Download the server
  echo "Downloading PaperMC server..."
  echo "  - Version $select_version"
  echo "  - Build $download_build"
  curl -s "https://api.papermc.io/v2/projects/paper/versions/$select_version/builds/$download_build/downloads/paper-$select_version-$download_build.jar" -o "./paper-$select_version-$download_build.jar"
  echo "Download complete."
}

# Delete old server file with name $old_server_file
function delete_old_server {
  # Delete the old server file
  echo "Deleting old server file $server_file..."
  rm "$old_server_file"
  echo "Old server file deleted."
}

# Set arguments for java
function set_java_args {
  # Check if $override_flags is not true
  if [[ $override_flags != true ]]; then
    if [[ "${mem%M}" -gt 12000 ]]; then
      G1NewSize=40
      G1MaxNewSize=50
      G1HeapRegionSize=16M
      G1Reserve=15
      InitiatingHeapOccupancy=20
    else
      G1NewSize=30
      G1MaxNewSize=40
      G1HeapRegionSize=8M
      G1Reserve=20
      InitiatingHeapOccupancy=15
    fi
    # Aikar's flags are used by default
    # See https://docs.papermc.io/paper/aikars-flags
    java_launchoptions="-Xms$mem -Xmx$mem -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=$G1NewSize -XX:G1MaxNewSizePercent=$G1MaxNewSize -XX:G1HeapRegionSize=$G1HeapRegionSize -XX:G1ReservePercent=$G1Reserve -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=$InitiatingHeapOccupancy -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true"
  fi
}

# Ask if the new server version differs from the old one
function ask_version_differs {
  echo
  echo
  echo "The server version differs from the one you selected."
  echo "The server version is $current_version and the selected version is $select_version."
  echo "Do you want to update the server version?"
  echo "This can cause many issues if you don't know what you are doing."
  echo
  echo "I am not responsible for any damage caused by updating the server version."
  echo
  echo "You have 15 seconds to respond, or the script will exit"
  read -t 15 -p "Do you want to update the server version? [y/N] " version_differs

  if [ "$version_differs" != "y" ] && [ "$version_differs" != "Y" ]; then
    echo "Server version not updated."
    echo "To start the server again with the current version, change the version in the config to $current_version."
    exit 4
  fi

  if [ "$version_differs" == "y" ] || [ "$version_differs" == "Y" ]; then
    read -t 15 -p "Are you sure you want to update the server version? [y/N] " version_differs
    if [ "$version_differs" != "y" ] && [ "$version_differs" != "Y" ]; then
      echo "Server version not updated."
      echo "To start the server again with the current version, change the version in the config to $current_version."
      exit 4
    fi
  fi
}

# Check if up to date
function check_up_to_date {
  if [[ $server_file == false ]]; then
    download_build=$latest_build
    update_version=true
    update_build=true
  fi

  # Check if $select_build is empty
  if [[ -z $select_build ]]; then
    # Check if the current version is the same as the one selected
    if [[ $current_version == $select_version ]]; then
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
    if [[ $current_version == $select_version ]]; then
      # Check if the current build is the same as the one selected
      if [[ $current_build == $select_build ]]; then
        echo "Server is up to date."
      else
        echo "Server is not up to date."
        download_build=$select_build
        update_build=true
      fi
    else
      # Check if $server_file is false
      if [[ $server_file != false ]]; then
        ask_version_differs
        echo "Server is not up to date."
        download_build=$select_build
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
  # Get current version and build
  get_existing_version

  echo Checking for updates...
  # Get the latest build number
  get_latest_build

  # Check if the current version is up to date
  check_up_to_date

  # Check if $build_update is true or $version_update is true
  if [[ $update_build == true ]] || [[ $update_version == true ]]; then
    if [[ $server_file != false ]]; then
      old_server_file=$server_file
      server_file="paper-$select_version-$download_build.jar"
      download_server 
      # Delete the old server file
      delete_old_server
    else
      server_file="paper-$select_version-$download_build.jar"
      download_server
    fi
  fi
}

# Accept EULA
function accept_eula {
  if test "$(cat eula.txt 2>/dev/null)" != "eula=true"; then
    echo
    echo
    echo "'eula.txt' does not exist or EULA is not accepted"
    echo "You have to accept the Minecraft EULA to run the server"
    echo "By entering 'y' you are indicating your agreement to Minecraft's EULA (https://aka.ms/MinecraftEULA)."
    echo "You have 15 seconds to respond, or the script will exit"
    read -t 15 -p "Do you agree to the Minecraft EULA? [y/N] " eula_agreed

    if [ "$eula_agreed" == "y" ] || [ "$eula_agreed" == "Y" ]; then
      if [ ! -f eula.txt ]; then
        echo "eula=true" > eula.txt
      else
        rm eula.txt
        echo "eula=true" > eula.txt
      fi
      echo
      echo
      echo "EULA accepted"
    else
      echo
      echo
      echo "You did not agree to the Minecraft EULA"
      echo "Exiting..."
      exit 1
    fi
  fi
}

# Launch the server
function launch_server {
  echo
  echo
  echo "Starting the server..."
  echo
  echo
  java $java_launchoptions -jar "$(basename ./paper-*.jar)" $mc_launchoptions
}

# Download the update for the script
function self_update {
  # Download the latest version of the script
  echo "Updating script..."
  # Download the file into start_new.sh
  curl -sLJ -w '%{http_code}\n' "https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/$LATEST_VERSION/start.sh" > start_new.sh
  # Check if the download was successful by checking the last line of the file for 200
  if [[ $(cat start_new.sh | tail -n 1) == 200 ]]; then
    # Remove the last line of the file
    sed -i '$d' start_new.sh
    # Make the file executable
    chmod +x start_new.sh
    # Remove the old script
    rm start.sh
    echo "Removed old script"
    # Rename the new script
    mv start_new.sh start.sh
    echo "Renamed new script"
    echo "Script updated successfully."
    echo
    read -p "Do you want to restart the script? [y/N] " restart
    if [ "$restart" == "y" ] || [ "$restart" == "Y" ]; then
      echo "Restarting..."
      # Execute the new script
      exec "./start.sh" "$@"
      exit 0
    else
      echo "Exiting..."
      exit 0
    fi
  else
    echo "Failed to update script."
    rm start_new.sh
    exit 5
  fi
}

# Function to update the script
function check_self_update {
  # Send a request to the GitHub API to retrieve the latest release
  response=$(curl -sL "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest")

  if [[ $response =~ "API rate limit exceeded" ]]; then
    echo "API limit exceeded. Will not check for updates."
  else
    # Extract the latest version from the response
    LATEST_VERSION=$(echo $response | jq -r ".tag_name")

    # Compare the current version with the latest version
    if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
      echo "An update is available!"
      echo "Current version: $CURRENT_VERSION"
      echo "Latest version: $LATEST_VERSION"
      echo
      echo "The script will continue without updating in 15 seconds."
      echo "If you decide to update it is your responsibility to check the release notes for any breaking changes."
      read -t 15 -p "Do you want to read the release notes? [y/N]"
      if [ "$REPLY" == "y" ] || [ "$REPLY" == "Y" ]; then
        # Extract the release notes from the response
        RELEASE_NOTES=$(echo "$response" | jq -r ".body")

        # Print the release notes
        echo "$RELEASE_NOTES" | less

        # Ask the user if they want to update
        echo
        echo "The script will continue without updating in 15 seconds."
        echo "If you decide to update it is your responsibility to check the release notes for any breaking changes."
        read -t 15 -p "Do you want to update? [y/N] " update
        if [ "$update" == "y" ] || [ "$update" == "Y" ]; then
          self_update
        else
          echo "Skipping update."
          return
        fi
      fi
    fi
  fi
}

# Load config
function load_config {
  # Check if the config file exists
  if [ ! -f launch.cfg ]; then
    echo "Config file does not exist."
    echo "Downloading the default config file..."
    # Download the default config file for the current version
    curl -sLJ -w '%{http_code}' "https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/$CURRENT_VERSION/launch.cfg" > launch.cfg
    # Check if the download was successful by checking the last line of the file for 200
    if [[ $(cat launch.cfg | tail -n 1) == 200 ]]; then
      # Remove the last line of the file
      sed -i '$d' launch.cfg

      echo
      read -p "Do you want to edit the config file? [y/N] " edit_config
      if [ "$edit_config" == "y" ] || [ "$edit_config" == "Y" ]; then
        if [ -z "$EDITOR" ]; then
          echo "EDITOR is not set."
          echo "Open 'launch.cfg' manually."
          echo "Exiting..."
          exit 1
        else
          echo "Opening the config file in $EDITOR..."
          $EDITOR launch.cfg
        fi
      fi
    else
      echo "Failed to download the default config file."
      echo "Go to the GitHub repository for more information:"
      echo "https://github.com/$REPO_OWNER/$REPO_NAME"
      echo "Exiting..."
      exit 1
    fi
  fi

  # Load config
  source launch.cfg
  # API URL
  api_url="https://api.papermc.io/v2/projects/paper/versions/$select_version/builds"
}

# Main function
function main {
  # Check dependencies
  check_dependencies
  
  # Load config
  load_config
  
  if [[ $check_self_update == true ]]; then
    # Check for script updates
    check_self_update
  else
    echo "Skipping script update check."
  fi

  # Check if the version and build are valid
  check_version_valid

  # Check if the correct java version is installed
  check_java

  # Check if the server is up to date and if not, update it
  check_and_update

  # Accept EULA
  accept_eula

  # Launch the server
  launch_server
}

# Check for updates on GitHub
if [[ "$1" == "--redownload" ]]; then
  self_update
fi
if [[ "$1" == "--help" ]]; then
  echo "Usage: ./script.sh [OPTION]"
  echo "Starts the Minecraft server."
  echo
  echo "Options:"
  echo "  --redownload  Redownloads the script from GitHub."
  echo "  --help        Show this help message."
  echo
  echo "To change the settings of the script, edit the 'launch.cfg' file."
  echo "If the file does not exist, it will be downloaded automatically when the script is run and you will be asked if you want to edit it."
  echo
  echo "For more information, see:"
  echo "https://github.com/$REPO_OWNER/$REPO_NAME"
  exit 0
else
  # Run the main function
  main
fi
