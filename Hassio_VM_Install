#!/bin/bash
# ==============================================================
# Home Assistant OS VM Setup Script (Headless / libvirt)
# Author: FastColors
# Version: 1.1
# ==============================================================

set -euo pipefail

# ===== CONFIGURATION =====
QCOW_URL="https://github.com/home-assistant/operating-system/releases/download/16.3/haos_ova-16.3.qcow2.xz"
QCOW_NAME="haos_ova-16.3.qcow2"
DOWNLOAD_DIR="/var/lib/libvirt/images"
VM_NAME="homeassistant"
RAM_MB=2048
VCPUS=2
BRIDGE_NAME="br0"
UEFI_LOADER="/usr/share/edk2/ovmf/OVMF_CODE.fd"
# ==========================

# ===== COLORS =====
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# ===== HELPER =====
log() { echo -e "${GREEN}✅ $1${RESET}"; }
warn() { echo -e "${YELLOW}⚠️  $1${RESET}"; }
err() { echo -e "${RED}❌ $1${RESET}" >&2; }

# ===== CHECK ROOT =====
if [[ $EUID -ne 0 ]]; then
  err "Please run this script as root (sudo)."
  exit 1
fi

# ===== STEP 0: PREREQUISITES =====
log "Installing required packages..."
apt update -qq
apt install -y -qq qemu-kvm libvirt-daemon-system libvirt-clients virtinst bridge-utils xz-utils network-manager wget

# ===== STEP 1: LIST PHYSICAL NICS =====
echo
echo "=== Available network interfaces ==="
mapfile -t NICS < <(ip -o link show | awk -F': ' '{print $2}' | grep -vE 'lo|vir|br|docker')

if [[ ${#NICS[@]} -eq 0 ]]; then
  err "No suitable physical NICs found."
  exit 1
fi

for i in "${!NICS[@]}"; do
  echo "$i) ${NICS[$i]}"
done

read -rp "Select the NIC to use for the bridge [0-${#NICS[@]}): " NIC_INDEX
NIC_NAME="${NICS[$NIC_INDEX]:-}"

if [[ -z "$NIC_NAME" ]]; then
  err "Invalid selection."
  exit 1
fi
log "Selected NIC: $NIC_NAME"

# ===== STEP 2: DOWNLOAD QCOW2 =====
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

if [[ ! -f "$QCOW_NAME" ]]; then
  log "Downloading Home Assistant OS image..."
  wget -q --show-progress -O "$QCOW_NAME.xz" "$QCOW_URL"
  log "Extracting image..."
  xz -d "$QCOW_NAME.xz"
else
  warn "$QCOW_NAME already exists, skipping download."
fi

# Fix permissions
chown libvirt-qemu:kvm "$DOWNLOAD_DIR/$QCOW_NAME"
chmod 640 "$DOWNLOAD_DIR/$QCOW_NAME"
log "Image ready at $DOWNLOAD_DIR/$QCOW_NAME"

# ===== STEP 3: CREATE BRIDGE =====
log "Creating bridge $BRIDGE_NAME via NetworkManager..."

# Remove existing configs
nmcli connection delete "$BRIDGE_NAME" 2>/dev/null || true
nmcli connection delete "$NIC_NAME" 2>/dev/null || true

# Create and bring up the bridge
nmcli connection add type bridge ifname "$BRIDGE_NAME" con-name "$BRIDGE_NAME" stp no
nmcli connection add type ethernet ifname "$NIC_NAME" master "$BRIDGE_NAME" slave-type bridge
nmcli connection modify "$BRIDGE_NAME" ipv4.method auto ipv6.method ignore
nmcli connection up "$BRIDGE_NAME"

log "Bridge $BRIDGE_NAME is active."

# ===== STEP 4: CREATE VM =====
if virsh list --all | grep -q "$VM_NAME"; then
  warn "VM '$VM_NAME' already exists. Skipping creation."
else
  log "Creating VM '$VM_NAME'..."
  virt-install \
    --name "$VM_NAME" \
    --ram "$RAM_MB" \
    --vcpus "$VCPUS" \
    --import \
    --disk path="$DOWNLOAD_DIR/$QCOW_NAME",format=qcow2,bus=virtio \
    --os-variant generic \
    --network bridge="$BRIDGE_NAME" \
    --graphics none \
    --boot uefi,loader="$UEFI_LOADER" \
    --channel unix,name=org.qemu.guest_agent.0,target_type=virtio \
    --noautoconsole \
    --quiet
fi

# ===== STEP 5: ENABLE AUTO-START =====
log "Setting VM autostart..."
virsh autostart "$VM_NAME"

# ===== STEP 6: VERIFY AND START =====
log "Starting VM..."
virsh start "$VM_NAME" || warn "VM already running."

log "Enabling libvirtd service..."
systemctl enable libvirtd
systemctl start libvirtd

echo
log "🎉 Setup complete!"
echo -e "VM: ${YELLOW}$VM_NAME${RESET}"
echo -e "Bridge: ${YELLOW}$BRIDGE_NAME${RESET}"
echo -e "Disk: ${YELLOW}$DOWNLOAD_DIR/$QCOW_NAME${RESET}"
echo
echo -e "🧭 Manage VM with:"
echo "   virsh list --all"
echo "   virsh console $VM_NAME"
echo "   virsh shutdown $VM_NAME"
echo "   virsh autostart $VM_NAME"
