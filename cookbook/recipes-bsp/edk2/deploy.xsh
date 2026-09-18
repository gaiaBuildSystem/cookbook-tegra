#!/usr/bin/env xonsh

# Copyright (c) 2025 MicroHobby
# SPDX-License-Identifier: MIT

# use the xonsh environment to update the OS environment
$UPDATE_OS_ENVIRON = True
# always return if a cmd fails
$XONSH_SUBPROC_CMD_RAISE_ERROR = True


import os
import sys
import json
import subprocess
import os.path
from torizon_templates_utils.colors import print,BgColor,Color
from torizon_templates_utils.errors import Error_Out,Error


print("Deploy edk2-nvidia ...", color=Color.WHITE, bg_color=BgColor.GREEN)

# get the common variables
_ARCH = os.environ.get('ARCH')
_CLEAN = os.environ.get('CLEAN_IMAGE')
_MACHINE = os.environ.get('MACHINE')
_MAX_IMG_SIZE = os.environ.get('MAX_IMG_SIZE')
_BUILD_PATH = os.environ.get('BUILD_PATH')
_DISTRO_MAJOR = os.environ.get('DISTRO_MAJOR')
_DISTRO_MINOR = os.environ.get('DISTRO_MINOR')
_DISTRO_PATCH = os.environ.get('DISTRO_PATCH')
_USER_PASSWD = os.environ.get('USER_PASSWD')
_HOME = os.environ.get('HOME')

# make sure to accept install pip packages system-wide
$PIP_BREAK_SYSTEM_PACKAGES="1"
os.environ['PIP_BREAK_SYSTEM_PACKAGES'] = "1"

# read the meta data
meta = json.loads(os.environ.get('META', '{}'))

# get the actual script path, not the process.cwd
_path = os.path.dirname(os.path.abspath(__file__))

_IMAGE_MNT_BOOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/boot"
_IMAGE_MNT_ROOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/root"
os.environ['IMAGE_MNT_BOOT'] = _IMAGE_MNT_BOOT
os.environ['IMAGE_MNT_ROOT'] = _IMAGE_MNT_ROOT


_BUILD_ROOT = f"{_BUILD_PATH}/tmp/{_MACHINE}"
_EDKREPO_DIR = f"{_BUILD_ROOT}/edkrepo"
_WORKSPACE = f"{_BUILD_ROOT}/edk2_workspace"
_EDK2_NVIDIA_REF = meta["ref"]["linux/arm64"]
# the edkrepo combo (manifest branch) that matches the pinned edk2-nvidia ref
_COMBO = meta["customData"]["nvidia_manifest"]["ref"]

_EFI_IMAGE = f"{_WORKSPACE}/images/BOOTAA64_L4TLauncher_DEBUG.efi"


# we need it on the /EFI/
sudo mkdir -p @(f"{_IMAGE_MNT_BOOT}/EFI/BOOT/")
sudo cp @(_EFI_IMAGE) @(f"{_IMAGE_MNT_BOOT}/EFI/BOOT/BOOTAA64.efi")

# we need the extlinux also on the /boot partition for
sudo mkdir -p @(_IMAGE_MNT_BOOT)/boot
sudo -k cp -f @(_path)/@(_MACHINE)/extlinux.conf @(_IMAGE_MNT_BOOT)/boot/extlinux.conf


print("Deploy edk2-nvidia, OK", color=Color.WHITE, bg_color=BgColor.GREEN)
