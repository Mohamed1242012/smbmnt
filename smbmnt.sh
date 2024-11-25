#!/bin/bash

set -e  # Exit the script if any command fails

# Create a config directory and a config file for samba mounts
mkdir -p ~/.config/smbmnt
touch ~/.config/smbmnt/config.yaml

# Function to check dependencies required by the script
check_dependencies() {
  # Check if 'yq' (for YAML parsing) is installed
  if ! command -v yq &>/dev/null; then
    echo "Error: yq is not installed. Please install it first."
    exit 1
  fi

  # Check if 'mount' command is available
  if ! command -v mount &>/dev/null; then
    echo "Error: mount command is not available."
    exit 1
  fi

  # Check if 'sudo' is available
  if ! command -v sudo &>/dev/null; then
    echo "Error: sudo command is not available."
    exit 1
  fi
}

# Function to show usage information
usage() {
  echo "Usage: $0 [server_name]"
  echo "Mount samba shares on Linux easily."
  echo "The config YAML file contains all the information, located at ~/.config/smbmnt/config.yaml."
  echo
  echo "Options:"
  echo "  -u, --usage, --help    Show this usage information."
  echo "  -v, --version          Display the script version."
  echo
  echo "Provide a server name as an argument to mount a server from the configuration file."
  exit 0
}

# Function to display the script version
version() {
  echo "smbmnt Version 1.0"
  echo "Mount samba shares on Linux easily."
  echo "Configuration is stored in ~/.config/smbmnt/config.yaml."
  exit 0
}

# Check if any arguments are provided
if [ $# -eq 0 ]; then
  usage
fi


# Handle command-line options for usage and version
case "$1" in
  -u|--usage|--help)
    usage
    ;;
  -v|--version)
    version
    ;;
esac

# Call the dependency check function
check_dependencies

# Check if the server is specified in the config file
if ! yq -e ".servers.$1" ~/.config/smbmnt/config.yaml > /dev/null 2>&1; then
  echo "'$1' not found in the config file."
  echo "--help for more information"
  exit 1
fi

# Extract configuration values for the specified server from the YAML file
SHARE=$(yq -r ".servers.$1.share" ~/.config/smbmnt/config.yaml)
IP="//$(yq -r ".servers.$1.ip" ~/.config/smbmnt/config.yaml)/$SHARE"
USER=$(yq -r ".servers.$1.user" ~/.config/smbmnt/config.yaml)
VERSION=$(yq -r ".servers.$1.version" ~/.config/smbmnt/config.yaml)
MOUNT_POINT=$(yq -r ".servers.$1.mnt" ~/.config/smbmnt/config.yaml)

# Check if any essential configuration values are missing
if [ -z "$SHARE" ] || [ -z "$IP" ] || [ -z "$USER" ] || [ -z "$VERSION" ] || [ -z "$MOUNT_POINT" ]; then
  echo "Error: Missing required configuration in ~/.config/smbmnt/config.yaml for '$1'."
  echo "Please ensure 'share', 'ip', 'user', 'version', and 'mnt' are all defined."
  exit 1
fi

# Optionally handle the password from the config file
PASSWORD=$(yq -r ".servers.$1.password" ~/.config/smbmnt/config.yaml)

# Permissions setup (file mode, dir mode, uid, gid)
file_mode=$(yq -r ".servers.$1.permissions.file_mode" ~/.config/smbmnt/config.yaml)
dir_mode=$(yq -r ".servers.$1.permissions.dir_mode" ~/.config/smbmnt/config.yaml)
uid=$(yq -r ".servers.$1.permissions.uid" ~/.config/smbmnt/config.yaml)
gid=$(yq -r ".servers.$1.permissions.gid" ~/.config/smbmnt/config.yaml)

# Other configuration values
dmp=$(yq -r ".servers.$1.dmp" ~/.config/smbmnt/config.yaml)
uim=$(yq -r ".servers.$1.uim" ~/.config/smbmnt/config.yaml)
cd=$(yq -r ".servers.$1.cd" ~/.config/smbmnt/config.yaml)

# Check again if server exists in the config file (redundant, probably a copy-paste error)
if ! yq -e ".servers.$1" ~/.config/smbmnt/config.yaml > /dev/null 2>&1; then
  echo "'$1' not found in the config file."
  echo "--help for more information"
  exit 1
fi

# If the mount point is already mounted, unmount it (if required)
if mountpoint -q "$MOUNT_POINT"; then
  echo "Mount point $MOUNT_POINT is already mounted."
  if [ "$uim" = "true" ]; then
    echo "Unmounting $MOUNT_POINT..."
    sudo umount "$MOUNT_POINT" || { echo "Failed to unmount $MOUNT_POINT"; exit 1; }
    if [ $dmp = "true" ]; then
      sudo rmdir "$MOUNT_POINT" || { echo "Failed to remove $MOUNT_POINT"; exit 1;}
    fi
    echo "Successfully unmounted $MOUNT_POINT."
  fi
else
  # If the mount point is not mounted, create and mount it
  echo "Mount point $MOUNT_POINT is not mounted. Creating mount point..."
  sudo mkdir -p "$MOUNT_POINT" || { echo "Failed to create mount point"; exit 1; }
  echo "Mount point $MOUNT_POINT created successfully."

  echo "Mounting $MOUNT_POINT..."
  # Prompt for the password if not provided in the config
  if [ -z "$PASSWORD" ]; then
    read -s -p "Enter the password for $1: " PASSWORD
    echo
  fi

  # Attempt to mount the samba share
  if ! sudo mount -t cifs "$IP" "$MOUNT_POINT" -o username="$USER",password="$PASSWORD",vers="$VERSION",file_mode=$file_mode,dir_mode=$dir_mode,uid=$uid,gid=$gid 2>/tmp/mount_error.log; then
    # If mount fails, show error details and clean up
    echo "Failed to mount $MOUNT_POINT."
    echo "Error details:"
    cat /tmp/mount_error.log
    echo "Cleaning up: Removing mount point $MOUNT_POINT..."
    sudo rmdir "$MOUNT_POINT" || echo "Failed to remove $MOUNT_POINT. Please clean up manually."
    rm /tmp/mount_error.log
    exit 1
  fi

  # Optionally change directory to the mount point
  if [ $cd = "true" ]; then
    cd "$MOUNT_POINT"
  fi

  # Success message
  echo "Successfully mounted $MOUNT_POINT."
fi
