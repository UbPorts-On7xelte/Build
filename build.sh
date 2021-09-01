#!/bin/bash
#
# Doraemon Kernel Script 2021
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software

# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

mkdir /tmp/ci/halium
cd /tmp/ci/halium
# Get all the needed repositories for a Halium-based build
repo init -u https://github.com/Halium/android -b halium-10.0 --depth=1
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
rm -rf device/halium/halium_arm64
git clone -b halium-10.0 https://github.com/UbPorts-On7xelte/GSI.git device/halium/halium_arm64

# Get the required repositories for this specific build
./halium/devices/setup halium_arm64

# Apply Halium patches to the Android source tree
hybris-patches/apply-patches.sh --mb

# Setup the build environment
source build/envsetup.sh && breakfast halium_arm64

# Build the raw system image
mka rawsystemimage -j$(nproc --all)

rclone copy -v out/target/product/halium_arm64/android-rootfs.img drive:halium/GSI/halium-10.0-arm64/
