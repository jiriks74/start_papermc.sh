#!/bin/bash
#############################################################################################################
#                                Auto Update & Run PaperMC server script                                    #
#                                              by jiriks74                                                  #
#                             https://github.com/jiriks74/start_papermc.sh                                  #
#  This script is under GPLv3, if you want to distribute changes you have to do so under the same license   #
#############################################################################################################

############
# Settings #
############

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
# This script is not made for migrating versions.                  #
# If you're migrating versions, delete your old server's .jar file #
# and change the version below.                                    #
# I am not responsible for any loss of data                        #
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
# If enough people request it (or someone creates a PR) I'll add this functionality
version="1.19.3"
# Leave blank to use the latest build
select_build=""

# Memory settings
initMem="2000M" # Minimum memory used
maxMem="6000M" # Maximum memory allowed to be used

# Options for the server
mc_launchoptions="-nogui"

# G1GC settings - leave the defaults if you're unsure
g1HeapMem="32M" # Memory used by G1
g1NewSize="20" # In %
g1Reserve"20" # In %
umaxGCpause="50" # In millis

# Aditional options for the java runtime
java_launchoptions=""

# Change the defaults if you use older version of minecraft or just want to use something else
java_launchoptions="-Xms$initMem -Xmx$maxMem -XX:G1HeapRegionSize=$g1HeapMem -XX:+UseG1GC -XX:G1NewSizePercent=$g1NewSize -XX:G1ReservePercent=$g1Reserve -XX:MaxGCPauseMillis=$maxGCpause  $java_launchoptions"

# You shouldn't need to change anything below this line
# -----------------------------------------------------

# Api url
url="https://api.papermc.io/v2/projects/paper/versions/$version/builds"

# Check if selected version exists
if curl -s "$url" | grep -q '{"error":"Version not found."}'; then
  echo "Error: Invalid version selected: $version"
  exit 1
else
  # Check if selected build exists
  if [ ! -z "$select_build" ]; then
    if curl -Is "https://api.papermc.io/v2/projects/paper/versions/$version/builds/$select_build/downloads/paper-$version-$select_build.jar" | grep "HTTP/2 404" >/dev/null; then
      echo "Error: Invalid build selected: $select_build"
      exit 1
    fi
  fi
fi

# Check if some server already exists
if ls paper-*.jar 1> /dev/null 2>&1; then
  # Get the current server file name
  server_file=$(basename ./paper-*.jar)

  # Extract the build number using cut command
  current_build=$(echo "$server_file" | cut -d'-' -f3)
  current_build="${current_build%.jar}"

  # Check if select_build variable is set
  if [ -z "$select_build" ]; then
    echo "Checking for newer build..."
    json_response=$(curl -s "$url") # Get all the versions from the paper api

    # Get the latest build number
    latest_build=$(curl -s $url | jq '.builds[-1].build')

      # Check if the latest build is newer than the current build
      if [ "$latest_build" -gt "$current_build" ]; then
          echo "Newer build available: $latest_build"

          # Ask the user if they want to download and install the new build
          echo
          echo
          echo "You have 15 seconds to answer, then the new build will be downloaded automatically"
          read -t 15 -p "Do you want to download and install the new build? (Y/n) " answer
          # If the user doesn't answer set the answer to "y"
          if [ -z "$answer" ]; then
              answer="y"
          fi
          if [ "$answer" == "y" ]; then
              # Download the new build
              echo "Downloading the new build..."
              curl -s "https://api.papermc.io/v2/projects/paper/versions/$version/builds/$latest_build/downloads/paper-$version-$latest_build.jar" -o "./paper-$version-$latest_build.jar"
              echo "Download complete"

              # Remove the old server file
              echo "Removing the old server file..."
              rm "$server_file"
              echo "Old server file removed"

              server_file=$(basename ./paper-*.jar) 
          else
              echo "Skipping download and installation"
          fi
          
      else
          echo "Server is up to date"
      fi

  else
    if [ "$current_build" -ne "$select_build" ]; then
      echo "The current build is not the selected build"
      echo "Downloading the selected build..."
      curl -s "https://api.papermc.io/v2/projects/paper/versions/$version/builds/$select_build/downloads/paper-$version-$select_build.jar" -o "./paper-$version-$select_build.jar"
      echo "Download complete"

      echo "Removing the old server file..."
      rm "$server_file"
      echo "Old server file removed"
      server_file=$(basename ./paper-*.jar)
    fi
  fi

# If no server file exists
else
  # Check if select_build variable is set
  if [ -z "$select_build" ]; then
    echo "Downloading the latest build of version $version..."
    json_response=$(curl -s "$url")
    # Get the latest build number
    latest_build=$(curl -s $url | jq '.builds[-1].build')

    curl -s "https://api.papermc.io/v2/projects/paper/versions/$version/builds/$latest_build/downloads/paper-$version-$latest_build.jar" -o "./paper-$version-$latest_build.jar"
    echo "Download complete"

  else
    echo "Downloading version $version build $select_build..."
    curl -s "https://api.papermc.io/v2/projects/paper/versions/$version/builds/$select_build/downloads/paper-$version-$select_build.jar" -o "./paper-$version-$select_build.jar"
    echo "Download complete"
  fi
fi

if test "$(cat eula.txt 2>/dev/null)" != "eula=true"; then
  echo
  echo
  echo "'eula.txt' does not exist or is not accepted"
  echo "Please agree to the Minecraft EULA by entering 'y'"
  echo "By entering 'y' you are indicating your agreement to Minecraft's EULA (https://aka.ms/MinecraftEULA)."
  echo "You have 15 seconds to respond, or the script will exit"
  read -t 15 -p "Do you agree to the Minecraft EULA? [y/N] " eula_agreed

  if [ "$eula_agreed" == "y" ]; then
    if [ ! -f eula.txt ]; then
      # Write eula_agreed to eula.txt
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

# Run the server
echo
echo
echo "Starting the server..."
java $java_launchoptions -jar "$(basename ./paper-*.jar)" $mc_launchoptions
