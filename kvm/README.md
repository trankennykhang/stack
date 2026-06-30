# KVM Ubuntu VM Cloning Utility

A collection of utility scripts and templates to automate and streamline the cloning of Ubuntu virtual machines within a KVM/libvirt environment.

## Overview

The primary tool is `clone-ubuntu.sh`, which automates the creation of a new VM from an existing base template. It configures network settings (static IP), injects custom cloud-init configurations via a temporary ISO, clones the storage disk, and starts the VM.

## Features

- **OS Verification**: The script ensures it is running on a supported platform (**Ubuntu** or **Arch Linux**).
- **Automatic Dependency Check**: Automatically checks for and installs `cloud-image-utils` (providing `cloud-localds`) using the native package manager (`apt` or `pacman`).
- **Interactive Initial Configuration**: Prompts for settings on the first run and persists them to a local `config` file.
- **Dynamic IP Configuration**: Easily specify the last octet/suffix of the IP address, and the script builds the full IP address using the configured network gateway prefix.
- **Custom Cloud-Init Seed Generation**:
  - Generates custom `user-data` from `user-data.template` to configure users, passwords, and SSH keys.
  - Automatically calculates unique `instance-id` metadata to force the cloned VM's Cloud-Init process to run on its first boot.
  - Formulates a custom network configuration (static IP, netmask, gateway, and nameservers).
  - Packs these configurations into a temporary seed ISO attached to the VM.
- **Automatic VM Cloning & Boot**: Clones VM hardware configs, clones the qcow2 disk, attaches the seed ISO, and starts the new domain via `virsh`.

---

## File Structure

- **`clone-ubuntu.sh`**: The main automation script.
- **`user-data.template`**: Cloud-init template configuration. Used to provision the default user (`kenny`), disable password-based SSH authentication, and add authorized SSH public keys.
- **`config`**: Local configuration file containing variables (`TEMPLATE`, `VM_PATH`, `GATEWAY`).
- **`setup-mysql.yml`**: An optional Ansible playbook to automate post-provisioning steps such as installing and configuring MySQL.

---

## Getting Started

### 1. Prerequisites

Ensure you have a KVM hypervisor set up with `libvirt`, `virt-clone`, and `virsh` tools installed, as well as an existing base VM template (e.g. `ubuntu2404_template`).

### 2. Initial Setup

On the first run, the script will notice the absence of a `config` file and will prompt you to set one up:

```bash
./clone-ubuntu.sh node-01 51
```

You will be asked to enter:
- **TEMPLATE**: The name of your source virtual machine template (e.g., `ubuntu2404_template`).
- **PATH**: The destination directory where VM disk images are stored (e.g., `/var/lib/libvirt/images`).
- **GATEWAY**: The gateway IP address of your VM network bridge (e.g., `192.168.122.1`).

These inputs will be saved to a persistent `config` file in the same directory. You can edit this file directly at any time.

### 3. Script Usage

To clone a VM, execute the script with the desired VM name and the host IP suffix:

```bash
./clone-ubuntu.sh <vm-name> <ip-suffix>
```

#### Example

```bash
./clone-ubuntu.sh node-01 51
```

This will:
1. Clone the template VM `ubuntu2404_template` to a new VM named `node-01`.
2. Assign it a static IP address based on your gateway configuration (e.g. `192.168.122.51`).
3. Inject the hostname `node-01` and authorized SSH keys from `user-data.template`.
4. Start the VM.
