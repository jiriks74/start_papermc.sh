# start_papermc.sh
A better script for running Paper Minecraft server with features such as automatic build updates and automatic downlading

## Basic setup
> **Note**
>
> Everything mentioned below is modified at the top of the `start.sh` file

1. Change the `version` variable to the version you want
  ```bash
version="1.12.2"
```

2. If you want a specific build, set the `select_build` variable. Othervise the sript will download the latest build:
  ```bash
 select_build="1620"
```

3. Select how much memory you want your server to use ***(in megabytes)***:
  ```bash
initMem="1500M" #1.5G
maxMem="8000M" # 12G
```

4. Modify server parameters to your liking:
  ```bash
mc_launchoptions="-nogui"
```

5. Add some jvm (java) parameters to your liking ***(memory is set above, do not add it here)***:
  ```bash
 java_launchoptions=""
 ```
 > **Note**
 >
 > If you use quite old versions of minecraft you should change the defaults under the line above
 
6. Run the script with `./start.sh`
