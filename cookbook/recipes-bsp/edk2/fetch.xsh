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
# if _CLEAN == "true":
#     if os.path.exists(_EDKREPO_DIR):
#         rm -rf @(_EDKREPO_DIR)
#     if os.path.exists(_WORKSPACE):
#         rm -rf @(_WORKSPACE)

if not os.path.exists(_EDKREPO_DIR):
    os.chdir(f"{_BUILD_ROOT}")
    mkdir -p @(_EDKREPO_DIR)
    os.chdir(_EDKREPO_DIR)
    wget -O- @(meta["customData"]["tianocore_repo"]["url"]) | tar zxvf -

# Fix for Python 3.11+ inspect.getargspec deprecation - must be before edkrepo install
# Python loads sitecustomize from the stdlib first, so write there
sitecustomize_path = "/usr/lib/python3.13/sitecustomize.py"

sitecustomize_content = (
    "import inspect\n"
    "if not hasattr(inspect, \"getargspec\"):\n"
    "    inspect.getargspec = inspect.getfullargspec\n"
)

try:
    tmp_path = "/tmp/sitecustomize_shim.py"
    with open(tmp_path, "w") as f:
        f.write(sitecustomize_content)
    sudo cp @(tmp_path) @(sitecustomize_path)
    sudo chmod 644 @(sitecustomize_path)
    os.remove(tmp_path)
    print(f"+ Wrote inspect.getargspec shim to {sitecustomize_path}")
except Exception as e:
    # Non-fatal: don't let this crash the whole fetch
    print(f"- Warning: failed to write sitecustomize.py shim: {e}")

# install edkrepo for the build user
os.chdir(_EDKREPO_DIR)
sudo -E ./install.py --no-prompt --user gaia -v
sudo chown -R gaia. @(f"{_HOME}/.edkrepo")

# configure edkrepo manifest repo for NVIDIA
_MANIFEST_URL = meta["customData"]["nvidia_manifest"]["url"]
_MANIFEST_REF = meta["customData"]["nvidia_manifest"]["ref"]

# when it is not already present so a second run does not break.
if "nvidia" in $(edkrepo manifest-repos list):
    print(f"+ manifest repo 'nvidia' already registered, skipping add")
else:
    edkrepo manifest-repos add nvidia @(_MANIFEST_URL) main nvidia
    print(f"+ added manifest repo 'nvidia' -> {_MANIFEST_URL}")

edkrepo manifest

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
