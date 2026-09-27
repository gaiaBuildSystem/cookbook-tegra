#!/usr/bin/env xonsh

# Copyright (c) 2026 MicroHobby
# SPDX-License-Identifier: MIT

# use the xonsh environment to update the OS environment
$UPDATE_OS_ENVIRON = True
# always return if a cmd fails
$XONSH_SUBPROC_CMD_RAISE_ERROR = True


import os
import sys
import json
import glob
import subprocess
import os.path
from torizon_templates_utils.colors import print,BgColor,Color
from torizon_templates_utils.errors import Error_Out,Error


print("Fetch public nvidia drivers source ...", color=Color.WHITE, bg_color=BgColor.GREEN)

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


# prepare the public source directory
_BUILD_ROOT = f"{_BUILD_PATH}/tmp/{_MACHINE}"
_PUBLIC_SOURCE_DIR = f"{_BUILD_ROOT}/public_source"
_L4T_DIR = f"{_PUBLIC_SOURCE_DIR}/Linux_for_Tegra/source"
mkdir -p @(_PUBLIC_SOURCE_DIR)

# fetch the public_sources.tbz2
os.chdir(_PUBLIC_SOURCE_DIR)

if not os.path.exists("Linux_for_Tegra"):
    wget -O- @(meta["source"]) | tar jxvf -

    # unpack the nvidia source packages, mirroring source/source.sh: only
    # .tbz2 files that ship a nvbuild.sh are relevant, each one is extracted
    # into its own src_out/<pkg>_build directory (kernel needs extra OOT tarballs)
    os.chdir(_L4T_DIR)
    _SRC_BUILD_DIR = f"{_L4T_DIR}/src_out"
    for tbz2_file in sorted(glob.glob("**/*.tbz2", recursive=True)):
        _pkg_name = tbz2_file[:-len(".tbz2")]
        _pkg_build_dir = f"{_SRC_BUILD_DIR}/{_pkg_name}_build"

        _tar_list = subprocess.run(
            ["tar", "-tf", tbz2_file], capture_output=True, text=True, check=True
        ).stdout
        if "nvbuild.sh" not in _tar_list:
            print(
                f"nvbuild.sh not found for package {tbz2_file}, skipping."
            )
            print("please wait ...")
            continue

        mkdir -p @(_pkg_build_dir)
        if not os.path.exists(f"{_pkg_build_dir}/nvbuild.sh"):
            tar jxf @(tbz2_file) -C @(_pkg_build_dir)

            if os.path.basename(tbz2_file) == "kernel_src.tbz2":
                for _extra_tbz2 in (
                    "kernel_oot_modules_src.tbz2",
                    "nvidia_kernel_display_driver_source.tbz2",
                    "nvidia_unified_gpu_display_driver_source.tbz2"
                ):
                    if os.path.exists(_extra_tbz2):
                        tar jxf @(_extra_tbz2) -C @(_pkg_build_dir)
else:
    print(
        "Linux_for_Tegra directory already exists, skipping fetch.",
        color=Color.WHITE,
        bg_color=BgColor.YELLOW
    )


print("Fetch public nvidia drivers source, OK", color=Color.WHITE, bg_color=BgColor.GREEN)
