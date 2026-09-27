#!/usr/bin/env xonsh

# Copyright (c) 2026 MicroHobby
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
    "building public nvidia drivers source ...",
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

# read the meta data
meta = json.loads(os.environ.get('META', '{}'))

# get the actual script path, not the process.cwd
_path = os.path.dirname(os.path.abspath(__file__))

_IMAGE_MNT_BOOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/boot"
_IMAGE_MNT_ROOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/root"
_BUILD_ROOT = f"{_BUILD_PATH}/tmp/{_MACHINE}"
_PUBLIC_SOURCE_DIR = f"{_BUILD_ROOT}/public_source"
_L4T_DIR = f"{_PUBLIC_SOURCE_DIR}/Linux_for_Tegra/source/src_out/kernel_src_build"
_GAIA_LINUX = f"{_BUILD_ROOT}/linux"

_nproc = os.cpu_count()

os.chdir(_L4T_DIR)

# now the jiripoca vai vua
# this will build the nvidia open source kernel drivers
# nvidia-drm
# nvidia-modeset
make modules \
    NV_OOT_TEGRA_HV_SKIP_BUILD=y \
    NV_OOT_IVC_EXT_SKIP_BUILD=y \
    NV_OOT_TEGRA_BPMP_SKIP_BUILD=y \
    KERNEL_HEADERS=@(_GAIA_LINUX) \
    KERNEL_OUTPUT=@(_GAIA_LINUX) \
    ARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    -j@(_nproc)


print(
    "building public nvidia drivers source, ok",
    color=Color.WHITE,
    bg_color=BgColor.GREEN
)
