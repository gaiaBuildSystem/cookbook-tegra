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


print("Patch nvidia public drivers ...", color=Color.WHITE, bg_color=BgColor.GREEN)

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
_BUILD_ROOT = f"{_BUILD_PATH}/tmp/{_MACHINE}"
_PUBLIC_SOURCE_DIR = f"{_BUILD_ROOT}/public_source"
_L4T_DIR = f"{_PUBLIC_SOURCE_DIR}/Linux_for_Tegra/source/src_out/kernel_src_build"
_GAIA_LINUX = f"{_BUILD_ROOT}/linux"

_nproc = os.cpu_count()

def apply_patch(patch_file):
    name = os.path.basename(patch_file)
    result = subprocess.run(
        ["patch", "-p1", "--forward", "--no-backup-if-mismatch", "-i", patch_file],
        capture_output=True,
        text=True,
    )
    print(result.stdout, end="")
    print(result.stderr, end="", file=sys.stderr)

    if result.returncode == 0:
        return

    if "previously applied" in result.stdout or "Skipping patch" in result.stdout:
        print(f"Patch {name} already applied, skipping", color=Color.WHITE, bg_color=BgColor.YELLOW)
        return

    Error_Out(f"Failed to apply patch {name}", Error.EINVAL)


# apply the patches (not a git repo, use plain patch)
os.chdir(f"{_L4T_DIR}/nvidia-oot")
apply_patch(f"{_path}/assets/0001-conftest-work-around-stringify-issue-with-__assign_s.patch")
apply_patch(f"{_path}/assets/0002-bluetooth-fix-build-issues-with-Linux-v6.18.patch")

# kernel-open
os.chdir(f"{_L4T_DIR}/nvdisplay")
apply_patch(f"{_path}/assets/0003-Fix-unifiedgpudisp-modules-builds.patch")
apply_patch(f"{_path}/assets/0004-Fix-unifiedgpudisp-conftest-gcc-14-compatibility-iss.patch")
apply_patch(f"{_path}/assets/0005-nvdisplay-nvidia-drm-trigger-connector-detect-on-hot.patch")

# back to the nvidia-oot directory
os.chdir(f"{_L4T_DIR}/nvidia-oot")
apply_patch(f"{_path}/assets/0006-drm-tegra-Migrate-to-PMC-contextual-power-APIs.patch")


print("Patch nvidia public drivers, OK", color=Color.WHITE, bg_color=BgColor.GREEN)
