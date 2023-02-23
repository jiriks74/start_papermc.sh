# start_papermc.sh

A better script for running Paper Minecraft server with features such as
version downlading, automatic build update, interactive eula accepting, protection
against accidental version update, Aikar's flags out of the box, etc.

## Table of contents

<!-- TOC start -->
- [Dependencies](#dependencies)
- [Basic setup](#basic-setup)
- [Updating](#updating)
  - [Builds](#builds)
  - [Versions](#versions)
- [Default JVM flags used](#default-jvm-flags-used)
<!-- TOC end -->
<!-- TOC --><a name="start_papermcsh"></a>


<!-- TOC --><a name="dependencies"></a>
## Dependencies

- `jq`
- `awk`
- `curl`

Most, if not all, of these should be already available on your system if you're running something like Ubuntu.

<!-- TOC --><a name="basic-setup"></a>
## Basic setup

> **Note**
>
> Everything mentioned below is modified at the top of the `start.sh` file

1. Clone this repository and enter the directory:

```bash
git clone https://github.com/jiriks74/start_papermc.sh minecraft_server && cd minecraft_server
```

> **Note**
>
> If you want to have the server under some specific directory name, just change
`minecraft_server` to something else

2. Open `start.sh` in your favorite editor *(eg. `nano start.sh`)*

3. Change the `select_version` variable to the version you want

```bash
select_version="1.12.2"
```

4. If you want a specific build, set the `select_build` variable. Othervise the sript will download the latest build:

```bash
 select_build="1620"
```

5. Select how much memory you want your server to use ***(in megabytes)***:

```bash
mem="8000M"
```

6. Add execute flag to the script:

```bash
chmod +x start.sh
```

7. Start the script

```bash
./start.sh
```

<!-- TOC --><a name="updating"></a>
## Updating

<!-- TOC --><a name="builds"></a>
### Builds

This script can automatically update to the latest papermc build available for the
Minecraft version you selected. If you want this behaviour, leave the `select_build`
veriable empty.
Otherwise select the build you want and the script will download it for you.

<!-- TOC --><a name="versions"></a>
### Versions

> **Warning**
>
> - This script is not made for migrating versions. It won't make sure your plugins
are working or that your worlds won't get corrupted. It only downloads a new server
file, nothing else.
> - **I am not responsible for any lost data**

This script is able to update/downgrade versions as you please. Just change the
`select_version` variable to the version you want and the script will download
it for you.

<!-- TOC --><a name="default-jvm-flags-used"></a>
## Default JVM flags used

By default this script uses [Aikar's Flags](https://docs.papermc.io/paper/aikars-flags). It's set up so that it automatically modifies them if over
12GB of memory is set for the server so you shouldn't need to change them unless you want to swap them out for something else.
