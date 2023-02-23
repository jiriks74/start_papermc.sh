# start_papermc.sh
A better script for running Paper Minecraft server with features such as automatic build updates, automatic downlading, interactive eula accepting, interactive updating, etc.

> **Warning**
>
> - This script is not made for migrating versions. If you're migrating versions, delete your old server's `.jar` file and change the version in the script's settings
> - I am not responsible for any lost data
> - If enough people request it (or someone creates a PR) I'll add this functionality

## Basic setup
> **Note**
>
> Everything mentioned below is modified at the top of the `start.sh` file

1. Clone this repository and enter the directory: `git clone https://github.com/jiriks74/start_papermc.sh minecraft_server && cd minecraft_server`
> **Note**
>
> If you want to have the server under some specific directory name, just change `minecraft_server` to something else

2. Open `star.sh` in your favorite editor *(eg. `nano start.sh)*

3. Change the `version` variable to the version you want
  ```bash
version="1.12.2"
```

4. If you want a specific build, set the `select_build` variable. Othervise the sript will download the latest build:
  ```bash
 select_build="1620"
```

5. Select how much memory you want your server to use ***(in megabytes)***:
  ```bash
initMem="1500M" #1.5G
maxMem="8000M" # 12G
```

6. Modify server parameters to your liking:
  ```bash
mc_launchoptions="-nogui"
```

7. Add some jvm (java) parameters to your liking ***(memory is set above, do not add it here)***:
  ```bash
 java_launchoptions=""
 ```
 > **Note**
 >
 > If you use quite old versions of minecraft you should change the defaults under the line above
 
8. Run the script with `./start.sh`
