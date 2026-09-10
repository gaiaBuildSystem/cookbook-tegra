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

# read the meta data
meta = json.loads(os.environ.get('META', '{}'))

# get the actual script path, not the process.cwd
_path = os.path.dirname(os.path.abspath(__file__))

_IMAGE_MNT_BOOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/boot"
_IMAGE_MNT_ROOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/root"
os.environ['IMAGE_MNT_BOOT'] = _IMAGE_MNT_BOOT
os.environ['IMAGE_MNT_ROOT'] = _IMAGE_MNT_ROOT


# edk repo is a dependencie
if _CLEAN == "true":
    if os.path.exists(f"{_BUILD_PATH}/tmp/{_MACHINE}/edkrepo"):
        rm -rf @(f"{_BUILD_PATH}/tmp/{_MACHINE}/edkrepo")

if not os.path.exists(f"{_BUILD_PATH}/tmp/{_MACHINE}/edkrepo"):
    os.chdir(f"{_BUILD_PATH}/tmp/{_MACHINE}")
    mkdir -p @(f"{_BUILD_PATH}/tmp/{_MACHINE}/edkrepo")
    os.chdir(f"{_BUILD_PATH}/tmp/{_MACHINE}/edkrepo")
    wget -O- @(meta["customData"]["tianocore_repo"]["url"]) | tar zxvf -


# clone it to the _BUILD_PATH
if not os.path.exists(f"{_BUILD_PATH}/tmp/{_MACHINE}/edk2-nvidia"):
    os.chdir(f"{_BUILD_PATH}/tmp/{_MACHINE}")
    git clone @(meta["source"])

os.chdir(f"{_BUILD_PATH}/tmp/{_MACHINE}/edk2-nvidia")
git checkout @(meta["ref"]["linux/arm64"])


print("Fetch edk2-nvidia, OK", color=Color.WHITE, bg_color=BgColor.GREEN)
