locals {
  password = vault("/vmware/data/password", "ssh_password")
}

source "proxmox-iso" "rocky9" {
  proxmox_url              = "https://proxmox.lan:8006/api2/json"
  node                     = "proxmox"
  username                 = "root@pam"
  password                 = local.password
  insecure_skip_tls_verify = true

  sockets = "1"
  cores   = "2"
  memory  = "2048"

  vm_name              = "Template-ROCKY9-${formatdate("MM-DD-YYYY", timestamp())}"
  template_description = "Build via Packer on ${formatdate("MM-DD-YYYY", timestamp())}"
  os                   = "l26"
  cpu_type = "host"

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }
  scsi_controller = "virtio-scsi-single"
  disks {
    cache_mode        = "writeback"
    disk_size         = "30G"
    format            = "raw"
    storage_pool      = "local-lvm"
    storage_pool_type = "lvm-thin"
    type              = "scsi"
  }

  unmount_iso    = true
  iso_file       = "local:iso/Rocky-9.0-x86_64-minimal.iso"

  ssh_password = "P@ssw0rd"
  ssh_username = "camfu"
  qemu_agent   = true

  boot_command = ["<tab> inst.ks=nfs:truenas.lan:/mnt/Pool1/NFS/Packer/rocky9/ks.cfg<enter><wait><enter>"]
  boot_wait    = "5s"
}

build {
  sources = ["source.proxmox-iso.rocky9"]
  provisioner "ansible" {
    playbook_file = "./playbook.yml"
    ansible_env_vars = [
      "ANSIBLE_SSH_ARGS='-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=ssh-rsa'",
      "ANSIBLE_HOST_KEY_CHECKING=False"
    ]
    user            = "camfu"
    extra_arguments = ["-vv"]

  }

}