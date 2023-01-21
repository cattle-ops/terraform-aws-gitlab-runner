#!/usr/bin/env bash

dd if=/dev/zero of=/swapfile bs=1M count=${ coalesce(swap_size, "512") }
chmod 0600 /swapfile
mkswap /swapfile
swapon /swapfile

echo '/swapfile swap swap defaults 0 0' >>/etc/fstab
