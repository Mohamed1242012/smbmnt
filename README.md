# **smbmnt: Mount Samba Shares on Linux**

`smbmnt` is a simple shell script to mount Samba shares on Linux, making it easy to access shared folders from a remote server using configuration values stored in a YAML file. The script can also unmount shares, create mount points, and change directories to the mount point after a successful mount.

---

## **Table of Contents**

- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
  - [Adding Multiple Servers](#adding-multiple-servers)
- [Options](#options)
- [Error Handling](#error-handling)
- [Accessing Mounted Files](#accessing-mounted-files)
- [License](#license)
- [Contributing](#contributing)

## **Installation**

To use the `smbmnt` script, you need to install `yq` (YAML processor) and ensure you have the required permissions to mount and unmount network shares. The script can be used on any Linux system.

### Prerequisites:

1. **yq** - Install `yq` for reading and parsing YAML files.
   - On Debian/Ubuntu-based systems: 
     ```bash
     sudo apt-get install yq
     ```
   - On Arch Linux-based systems:
     ```bash
     sudo pacman -S yq
     ```
2. **CIFS Utils** - Install `cifs-utils` to enable CIFS mounting.
   - On Debian/Ubuntu-based systems:
     ```bash
     sudo apt-get install cifs-utils
     ```
   - On Arch Linux-based systems:
     ```bash
     sudo pacman -S cifs-utils
     ```

3. **sudo** - Ensure that `sudo` is installed and that you have sudo permissions to execute commands that require elevated privileges (e.g., creating directories, mounting/unmounting).
   - On Debian/Ubuntu-based systems:
     ```bash
     sudo apt-get install sudo
     ```
   - On Arch Linux-based systems:
     ```bash
     sudo pacman -S sudo
     ```

4. **Permissions** - Ensure you have the necessary permissions to mount and unmount network shares.


### Git clone

```bash
git clone https://github.com/mohamed1242012/smbmnt.git
cd smbmnt.git
./install.sh
```

---

## **Usage**

The `smbmnt.sh` script is designed to mount Samba shares by reading configuration details from a YAML file. It supports multiple options and checks for missing or incorrect configurations.

### Basic Command

```bash
./smbmnt.sh [server_name]
```

Replace `[server_name]` with the name of the server as defined in the configuration file.

### Options

- **-u, --usage, --help**  
  Displays usage instructions and exits.

  ```bash
  ./smbmnt.sh --help
  ```

- **-v, --version**  
  Displays the version information of the script.

  ```bash
  ./smbmnt.sh --version
  ```

---

## **Configuration**

The configuration is stored in the `config.yaml` file located in `~/.config/smbmnt/config.yaml`. Each server entry should be structured under the `servers` key.

### Example Configuration:

```yaml
servers:
  myserver:
    ip: '192.168.1.30'   # The IP address of the Samba server
    share: 'myfiles'      # The shared folder name
    user: 'superuser'     # The username to authenticate with the Samba server
    password: ''          # The password (optional, can be left empty for security reasons)
    version: '2.0'        # Samba version (don't edit unless necessary)
    mnt: '/mnt/smbmnt'    # The local mount point
    dmp: 'true'           # Delete mount point after unmounting (true/false)
    uim: 'true'           # Automatically unmount if mounted (true/false)
    cd: 'true'            # Change to the mount point directory after mounting (true/false)
    permissions:          # File and directory permissions (advanced)
      file_mode: '0777'
      dir_mode: '0777'
      uid: '1000'
      gid: '1000'
```

### Explanation of Configuration Fields:

- **ip**: The IP address of the Samba server.
- **share**: The name of the shared folder on the server.
- **user**: The username for authentication with the Samba server.
- **password**: The password for authentication (optional, can be left empty for security reasons).
- **version**: The version of Samba to use (typically `2.0` or `3.0`).
- **mnt**: The local mount point on the system where the share will be mounted.
- **dmp**: If set to `true`, the mount point will be deleted after unmounting.
- **uim**: If set to `true`, the mount point will automatically be unmounted if it is already mounted.
- **cd**: If set to `true`, the script will change to the mount point directory after successfully mounting.

### **Adding Multiple Servers**

You can define multiple servers in the `config.yaml` file under the `servers` key. Each server should have its own unique identifier (e.g., `myserver`, `another_server`), and the script will use the name provided in the command to look up the corresponding configuration.

#### Example with Multiple Servers:

```yaml
servers:
  myserver:
    ip: '192.168.1.30'
    share: 'myfiles'
    user: 'superuser'
    password: ''
    version: '2.0'
    mnt: '/mnt/smbmnt'
    dmp: 'true'
    uim: 'true'
    cd: 'true'
    permissions:
      file_mode: '0777'
      dir_mode: '0777'
      uid: '1000'
      gid: '1000'
  another_server:
    ip: '192.168.1.31'
    share: 'documents'
    user: 'admin'
    password: 'password123'
    version: '3.0'
    mnt: '/mnt/another_smbmnt'
    dmp: 'false'
    uim: 'false'
    cd: 'false'
    permissions:
      file_mode: '0775'
      dir_mode: '0775'
      uid: '1001'
      gid: '1001'
```

To mount a share from **myserver**, run:

```bash
./smbmnt.sh myserver
```

To mount a share from **another_server**, run:

```bash
./smbmnt.sh another_server
```

The script will look up the server name in the `config.yaml` file, read the associated configuration, and proceed with mounting the share.

---

## **Error Handling**

The script includes various error handling mechanisms:

- **Missing Configuration**: If essential fields such as `share`, `ip`, `user`, `version`, or `mnt` are missing from the configuration, the script will display an error and exit.
- **Mount Point Already Mounted**: If the mount point is already mounted, the script will check the `uim` option to see if it should unmount the share first.
- **Failed Mounting**: If the mount operation fails, the script will display an error message and attempt to clean up by removing the mount point.

---

## **Accessing Mounted Files**

Once the Samba share is successfully mounted, you can access the shared files through the specified mount point directory.

### **Manual Access**

After running the script and mounting the Samba share, you can access the mounted files from the local mount point directory defined in the configuration file (e.g., `/mnt/smbmnt`). 

```bash
cd /mnt/smbmnt
```

You can then list the files and directories:

```bash
ls -l
```

### **Automatic Directory Change**

If the configuration option `cd` is set to `true`, the script will automatically change to the mount point directory after a successful mount.

### **Example:**

```bash
./smbmnt.sh myserver
```

After the mount operation completes, if `cd` is set to `true`, you will be automatically switched to the `/mnt/smbmnt` directory. You can then use the mounted files as if they were local files.

---

## **License**

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.

---

## **Contributing**

Feel free to fork this repository, open issues, and submit pull requests. Contributions are welcome!
