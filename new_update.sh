#!/bin/bash
set -e

if [ "$1" = "" ]; then
	echo "Provide a folder name (to be used or created in the current directory) as an argument."
	exit 1
fi

# setup working dir
mkdir -pv "$1" && cd "$1" 

# setup depot_tools
if [ ! -d depot_tools ]; then
	git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
else
	pushd depot_tools
		git fetch origin
		git reset --hard origin/main
	popd
fi
export PATH=`pwd`/depot_tools:"$PATH"

# setup project dir
mkdir -pv chromium-legacy && cd chromium-legacy

# place this repo as src
curl -OJL https://gist.githubusercontent.com/blueboxd/c1f355fb6fe829e98ff5453880683993/raw/9d97a2c622c206fd7bc03ec891ad89dd58be4004/.gclient

# checkout sources & dependencies if necessary
if [ ! -d src ]; then
	gclient sync -v
fi

# switch to stable.lion
pushd src
	git checkout stable.lion
	git reset --hard stable.lion
popd

printf "src/third_party/skia\nsrc/third_party/angle/\nsrc/third_party/dawn/\nsrc/third_party/swiftshader/\nsrc/third_party/vulkan_memory_allocator/\nsrc/third_party/webrtc/\nsrc/third_party/libc++/src\nsrc/third_party/boringssl/src" | while read $d; do 
	echo "calculating DEPS retrieval for $d"
	pattern="$(printf $d | sed 's/^.*[/]//' | sed 's/c[+][+]/cxx/')"

	# use one dot prefix for most dependencies, two dots for those with a nested src for git repo
	deps="$(printf $d | sed 's/libcxx/../' | sed 's/boringssl/../' | sed 's/^[^.].*$/./')"
	deps="$deps/../../DEPS"

	if [ "$pattern" = "vulkan_memory_allocator" ]; then
		REV=`grep "VulkanMemory" ../../DEPS |awk -F "\'" '{print $8}'`
	elif [ "$pattern" = "webrtc" ]; then
		REV=`grep "Var.*webrtc_git" ../../DEPS |awk -F "\'" '{print $8}'`
	else
		REV=`grep "\'"$pattern"_revision\':" ../../DEPS |awk -F "\'" '{print $4}'`
	fi

	pushd $d
		git fetch --all
		git checkout $REV
	popd
done

# checkout sources & dependencies based on stable.lion's DEPS
gclient sync -v

# setup patched skia
pushd src/third_party/skia
	if ! git remote | grep ^github$ >/dev/null; then
		git remote add github https://github.com/blueboxd/skia.git
	fi

	git fetch github
	git reset --hard HEAD
	git checkout stable.lion # for-lion
	git reset --hard stable.lion # for-lion
popd

# setup patched angle
pushd src/third_party/angle/
	if ! git remote | grep ^github$ >/dev/null; then
		git remote add github https://github.com/blueboxd/angle.git
	fi

	git fetch github
	git reset --hard HEAD
	git checkout stable.lion
	git reset --hard stable.lion
popd

# setup patched dawn
pushd src/third_party/dawn/
	if ! git remote | grep ^github$ >/dev/null; then
		git remote add github https://github.com/blueboxd/dawn.git
	fi

	git fetch github
	git reset --hard HEAD
	git checkout stable.lion
	git reset --hard stable.lion
popd

# setup patched swiftshader
pushd src/third_party/swiftshader/
	if ! git remote | grep ^github$ >/dev/null; then
		git remote add github https://github.com/blueboxd/swiftshader.git
	fi

	git fetch github
	git reset --hard HEAD
	git checkout stable.lion
	git reset --hard stable.lion
popd

# setup patched vulkan_memory_allocator
pushd src/third_party/vulkan_memory_allocator/
	if ! git remote | grep ^github$ >/dev/null; then
		git remote add github https://github.com/blueboxd/vulkan_memory_allocator.git
	fi

	# vulkan_memory_allocator has no `stable.lion` branch
	git fetch github
	git reset --hard HEAD
	git checkout master.lion
	git reset --hard master.lion
popd

# setup patched webrtc
pushd src/third_party/webrtc/
	if ! git remote | grep ^github$ >/dev/null; then
		git remote add github https://github.com/blueboxd/webrtc.git
	fi

	git fetch github
	git reset --hard HEAD
	git checkout stable.lion
	git reset --hard stable.lion
popd

# setup patched libc++
pushd src/third_party/libc++/src
	if ! git remote | grep ^github$ >/dev/null; then
		git remote add github https://github.com/blueboxd/libcxx.git
	fi

	git fetch github
	git reset --hard HEAD
	git checkout stable.lion
	git reset --hard stable.lion
popd

# setup patched boringssl
pushd src/third_party/boringssl/src
	if ! git remote | grep ^github$ >/dev/null; then
		git remote add github https://github.com/blueboxd/boringssl.git
	fi

	git fetch github
	git reset --hard HEAD
	git checkout stable.lion
	git reset --hard stable.lion
popd

echo ""
echo "Ready to build.sh."
