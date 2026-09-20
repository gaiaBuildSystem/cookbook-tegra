#!/usr/bin/env xonsh

# Copyright (c) 2025 MicroHobby
# SPDX-License-Identifier: MIT

# use the xonsh environment to update the OS environment
$UPDATE_OS_ENVIRON = True
# always return if a cmd fails
$XONSH_SUBPROC_CMD_RAISE_ERROR = True
$XONSH_SHOW_TRACEBACK = True


import os
import sys
import json
import os.path
import subprocess
from datetime import datetime
from torizon_templates_utils.colors import print,BgColor,Color
from torizon_templates_utils.errors import Error_Out,Error


print(
    "building edk2-nvidia ...",
    color=Color.WHITE,
    bg_color=BgColor.GREEN
)

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

# make sure to accept install pip packages system-wide
$PIP_BREAK_SYSTEM_PACKAGES="1"
os.environ['PIP_BREAK_SYSTEM_PACKAGES'] = "1"

# read the meta data
meta = json.loads(os.environ.get('META', '{}'))

# get the actual script path, not the process.cwd
_path = os.path.dirname(os.path.abspath(__file__))

_IMAGE_MNT_BOOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/boot"
_IMAGE_MNT_ROOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/root"
_BUILD_ROOT = f"{_BUILD_PATH}/tmp/{_MACHINE}"
os.environ['IMAGE_MNT_BOOT'] = _IMAGE_MNT_BOOT
os.environ['IMAGE_MNT_ROOT'] = _IMAGE_MNT_ROOT
os.environ['BUILD_ROOT'] = _BUILD_ROOT
$BUILD_ROOT = _BUILD_ROOT

_WORKSPACE = f"{_BUILD_ROOT}/edk2_workspace"
_DEPLOY_DIR = f"{_BUILD_ROOT}/deploy"
os.chdir(f"{_WORKSPACE}")

# make the build scripts executable
for _script in [
    "edk2-nvidia/Platform/NVIDIA/Tegra/build.sh",
    "edk2-nvidia/Platform/NVIDIA/StandaloneMmOptee/build.sh",
    "edk2-nvidia/Platform/NVIDIA/StandaloneMm/build.sh",
    "edk2-nvidia/Platform/NVIDIA/StandaloneMmJetson/build.sh",
    "edk2-nvidia/Platform/NVIDIA/DeviceTree/build.sh",
    "edk2-nvidia/Platform/NVIDIA/L4TLauncher/build.sh",
]:
    chmod +x @(_script)

mkdir -p @(_DEPLOY_DIR)

# ccache keeps compiled objects across builds even when the EDK2 Build
# directory itself is wiped for disk space, so unchanged sources still
# hit the cache instead of recompiling from scratch.
_CCACHE_DIR = f"{_BUILD_ROOT}/ccache"
_CCACHE_BIN = f"{_BUILD_ROOT}/ccache_bin"
os.environ['CCACHE_DIR'] = _CCACHE_DIR
$CCACHE_DIR = _CCACHE_DIR
os.makedirs(_CCACHE_BIN, exist_ok=True)

_CCACHE_PATH = $(which ccache).strip()
for _compiler in ["gcc-12", "g++-12", "gcc", "g++", "cc", "c++"]:
    _link = f"{_CCACHE_BIN}/{_compiler}"
    if not os.path.exists(_link):
        os.symlink(_CCACHE_PATH, _link)

os.environ['PATH'] = f"{_CCACHE_BIN}:{os.environ['PATH']}"
$PATH.insert(0, _CCACHE_BIN)

ccache -M 10G
ccache -z

# get the defconfig for the target machine
_DEFCONFIG = meta["customData"]["tegra_defconfigs"].get(_MACHINE)
if not _DEFCONFIG:
    Error_Out(
        f"no defconfig defined for machine [{_MACHINE}]",
        Error.EINVAL
    )

_defconfig_path = f"edk2-nvidia/Platform/NVIDIA/Tegra/DefConfigs/{_DEFCONFIG}.defconfig"
if not os.path.exists(_defconfig_path):
    Error_Out(
        f"defconfig [{_DEFCONFIG}] not found in the workspace",
        Error.EINVAL
    )

# only wipe the build output on an explicit clean request; otherwise keep
# it around so the EDK2 build system can do an incremental rebuild.
if _CLEAN == "true":
    print("Removing Build directory")
    rm -rf Build

print(f"Building defconfig: {_DEFCONFIG}")
edk2-nvidia/Platform/NVIDIA/Tegra/build.sh --init-defconfig @(_defconfig_path)

# keep the build logs
cp -v Build/*.txt @(_DEPLOY_DIR)

# build all non-Kconfig images
edk2-nvidia/Platform/NVIDIA/StandaloneMmOptee/build.sh
edk2-nvidia/Platform/NVIDIA/StandaloneMm/build.sh
edk2-nvidia/Platform/NVIDIA/StandaloneMmJetson/build.sh
edk2-nvidia/Platform/NVIDIA/DeviceTree/build.sh
edk2-nvidia/Platform/NVIDIA/L4TLauncher/build.sh

# copy the build logs from non-Kconfig images
cp -v Build/*.txt @(_DEPLOY_DIR)

ccache -s

print(
    "building edk2-nvidia, ok",
    color=Color.WHITE,
    bg_color=BgColor.GREEN
)
