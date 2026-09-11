#!/usr/bin/env xonsh

# Copyright (c) 2025 MicroHobby
# SPDX-License-Identifier: MIT

# use the xonsh environment to update the OS environment
$UPDATE_OS_ENVIRON = True
# always return if a cmd fails
$XONSH_SUBPROC_CMD_RAISE_ERROR = True


import os
import json
import os.path
from torizon_templates_utils.colors import print,BgColor,Color
from torizon_templates_utils.errors import Error_Out,Error


print("Fetch edk2-nvidia ...", color=Color.WHITE, bg_color=BgColor.GREEN)

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

os.makedirs(_BUILD_ROOT, exist_ok=True)

# edk repo is a dependencie
if _CLEAN == "true":
    if os.path.exists(_EDKREPO_DIR):
        rm -rf @(_EDKREPO_DIR)
    if os.path.exists(_WORKSPACE):
        rm -rf @(_WORKSPACE)

if not os.path.exists(_EDKREPO_DIR):
    os.chdir(f"{_BUILD_ROOT}")
    mkdir -p @(_EDKREPO_DIR)
    os.chdir(_EDKREPO_DIR)
    wget -O- @(meta["customData"]["tianocore_repo"]["url"]) | tar zxvf -

# install edkrepo for the build user
os.chdir(_EDKREPO_DIR)
sudo -E ./install.py --no-prompt --user gaia -v
sudo chown -R gaia. @(f"{_HOME}/.edkrepo")

# start with the edkrepo combo that matches this ref
os.chdir(f"{_BUILD_ROOT}")
if not os.path.exists(_WORKSPACE):
    edkrepo clone -v edk2_workspace NVIDIA-Platforms @(_COMBO)

# checkout the ref pinned in the recipe
os.chdir(_WORKSPACE)
git -C edk2-nvidia fetch --verbose @(meta["source"]) @(_EDK2_NVIDIA_REF)
git -C edk2-nvidia checkout FETCH_HEAD

# summarize the workspace, for debug purposes.
git -C edk2 describe --always --dirty
git -C edk2-platforms describe --always --dirty
git -C edk2-nvidia describe --always --dirty


print("Fetch edk2-nvidia, OK", color=Color.WHITE, bg_color=BgColor.GREEN)
