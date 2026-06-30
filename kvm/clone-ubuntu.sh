#!/bin/bash

# Usage: ./clone-ubuntu.sh node-01 51

# clear the template
#sudo cloud-init clean --logs

# Check for cloud-localds and install if missing
if ! command -v cloud-localds &> /dev/null; then
    echo "cloud-localds not found. Installing cloud-image-utils..."
    sudo apt-get update && sudo apt-get install -y cloud-image-utils
fi

# Check and load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found. Let's set it up."
    read -p "Enter TEMPLATE (e.g. ubuntu24.04_template): " INPUT_TEMPLATE
    read -p "Enter PATH (e.g. /var/lib/libvirt/images): " INPUT_PATH
    read -p "Enter GATEWAY (e.g. 192.168.1.1): " INPUT_GATEWAY
    
    # Save to config file (using VM_PATH to avoid overriding system PATH)
    cat <<EOF > "$CONFIG_FILE"
TEMPLATE="$INPUT_TEMPLATE"
VM_PATH="$INPUT_PATH"
GATEWAY="$INPUT_GATEWAY"
EOF
    echo "Configuration saved to $CONFIG_FILE"
fi

# Source configuration
. "$CONFIG_FILE"

# Validate configuration
if [ -z "$TEMPLATE" ] || [ -z "$VM_PATH" ] || [ -z "$GATEWAY" ]; then
    echo "Error: TEMPLATE, VM_PATH or GATEWAY is not set in $CONFIG_FILE" >&2
    exit 1
fi

NAME=$1
IP_SUFFIX=$2
IP_PREFIX="${GATEWAY%.*}"
IP_ADDR="$IP_PREFIX.$IP_SUFFIX"
USER_DATA_FILE="user-data-$NAME.yaml"
META_DATA_FILE="meta-data-$NAME.tmp"

# Create a temporary network config file
cat <<EOF > network-config-$NAME.tmp
version: 2
ethernets:
  enp1s0:
    dhcp4: no
    addresses: [$IP_ADDR/24]
    gateway4: $GATEWAY
    nameservers:
      addresses: [8.8.8.8, 1.1.1.1]
EOF

# Create a temporary metadata file to force cloud-init to run (using unique instance-id)
cat <<EOF > "$META_DATA_FILE"
instance-id: i-$NAME
local-hostname: $NAME
EOF

# Variables
DISK_PATH="$VM_PATH/$NAME.qcow2"
CONFIG_ISO="$VM_PATH/$NAME-config.iso"

# 1. Generate the specific user-data from the template
sed -e "s/__HOSTNAME__/$NAME/g" \
    -e "s/__IP__/$IP_ADDR/g" \
    user-data.template > "$USER_DATA_FILE"

# 1. Create a Cloud-Init ISO (injects the config)
# You may need to install 'cloud-image-utils' for cloud-localds
cloud-localds -N network-config-$NAME.tmp "$CONFIG_ISO" "$USER_DATA_FILE" "$META_DATA_FILE"

# Clean up temporary configuration files
rm -f network-config-$NAME.tmp "$META_DATA_FILE" "$USER_DATA_FILE"

# 2. Clone the VM hardware and disk
virt-clone --original $TEMPLATE --name $NAME --file $DISK_PATH

# 3. Attach the config ISO and start
# We attach the ISO as a CDROM so Cloud-Init can read it
virsh attach-disk $NAME $CONFIG_ISO sdb --type cdrom --mode readonly --config
virsh start $NAME

echo "------------------------------------------------"
echo "Done! $NAME is booting."
echo "IP: $IP_ADDR"
echo "Config saved to: $USER_DATA_FILE"
