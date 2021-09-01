#!/bin/bash
#
# Halium Project
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

df -h
free -h
nproc
cat /etc/os*
env

url=https://mirrors.kernelpanix.workers.dev/halium/GSI/halium-10.0-arm64/ccache.tar.gz

cd /tmp
time aria2c $url -x16 -s50
time tar xf ccache.tar.gz
rm -rf ccache.tar.gz

mkdir -p /tmp/rom
cd /tmp/rom
repo init -q --no-repo-verify --depth=1 -u https://github.com/Halium/android -b halium-10.0 -g default,-device,-mips,-darwin,-notdefault
repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j 30 || repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j$(nproc --all)
rm -rf device/halium/halium_arm64
git clone -b halium-10.0 https://github.com/UbPorts-On7xelte/GSI.git device/halium/halium_arm64

export CCACHE_DIR=/tmp/ccache
sleep 2m

while :
do
ccache -s
echo ''
top -b -i -n 1
sleep 1m
done

cd /tmp/rom

./halium/devices/setup halium_arm64
hybris-patches/apply-patches.sh --mb

. build/envsetup.sh
source build/envsetup.sh && breakfast halium_arm64
export CCACHE_DIR=/tmp/ccache
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
ccache -M 20G
ccache -o compression=true
ccache -z

make api-stubs-docs || echo no problem, we need ccache
make system-api-stubs-docs || echo no problem we need ccache
make test-api-stubs-docs || echo no problem, we need ccache
mka rawsystemimage -j$(nproc --all) &

sleep 85m
kill %1
ccache -s

cd /tmp

com ()
{
    tar --use-compress-program="pigz -k -$2 " -cf $1.tar.gz $1
}

time com ccache 1

time rclone copy ccache.tar.gz drive:Share/halium/GSI/halium-10.0-arm64/

cd /tmp/rom
time rclone copy -v out/target/product/halium_arm64/android-rootfs.img drive:Share/halium/GSI/halium-10.0-arm64/
