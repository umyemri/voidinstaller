#!/bin/sh
#
# encrypt.sh
#
# installer for void linux for a partial disk encryption (luks)
#

read -p 'host: ' hname
read -p 'swap size (number of gigs): ' swaps

# partition
sgdisk -og /dev/sda # gpt partition erase
sgdisk -z /dev/sda # zap all gpt records
sgdisk -n 1:2048:+512MiB -t 1:ef00 /dev/sda
start_of=$(sgdisk -f /dev/sda)
end_of=$(sgdisk -E /dev/sda)
sgdisk -n 2:$start_of:$end_of -t 2:8e00 /dev/sda
sgdisk -p /dev/sda

# luks lvm
cryptsetup -v -c serpent-xts-plain64 -s 512 --hash whirlpool --iter-time 5000 --use-random luksFormat /dev/sda2
cryptsetup luksOpen /dev/sda2 crypt
pvcreate --dataalignment 1m /dev/mapper/crypt
vgcreate volume /dev/mapper/crypt
lvcreate -L 2G volume -n boot
lvcreate -L $(swaps)12GB volume -n swap 
lvcreate -l 100%FREE volume -n root
modprobe dm_mod
modprobe dm_crypt
vgscan
vgchange -ay

# vg file system
mkfs.vfat -F32 /dev/sda1 # grub boot only
mkfs.ext4 /dev/volume/root
mkfs.ext4 /dev/volume/boot
mkswap /dev/volume/swap && swapon /dev/volume/swap
mount -t ext4 /dev/volume/root /mnt
mkdir /mnt/boot
# grub commands
#mount -t ext4 /dev/volume/boot /mnt/boot
#mkdir /mnt/boot/efi
#mount -t vfat /dev/sda1 /mnt/boot/efi
mount -t ext4 /dev/sda1 /mnt/boot # syslinux boot only
