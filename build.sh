#!/bin/bash
#
# Compile script for QuicksilveR kernel
# Copyright (C) 2020-2021 Adithya R.

SECONDS=0 # builtin bash timer
ZIPNAME="Stormbreaker-ginkgo-beta-0.4-$(date '+%Y%m%d-%H%M').zip"

SB_DIR="$HOME/weeb"
TC_DIR="$SB_DIR/tc"

export KBUILD_BUILD_HOST="saalim"
export KBUILD_BUILD_USER="StormCI"

export KBUILD_COMPILER_STRING="$(${TC_DIR}/clang11/bin/clang --version | head -n 1 | sed -e 's/  */ /g' -e 's/[[:space:]]*$//'))"
make O=out ARCH=arm64 vendor/ginkgo-perf_defconfig

PATH="${TC_DIR}/clang11/bin:${TC_DIR}/gcc/bin:${TC_DIR}/gcc_32/bin:${PATH}"

make -j8 O=out ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_ARM32=arm-linux-androideabi-

git clone https://github.com/stormbreaker-project/AnyKernel3.git -b ginkgo

cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
cp out/arch/arm64/boot/dtbo.img AnyKernel3

rm -f *zip
cd AnyKernel3
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder

cd ..
rm -rf AnyKernel3
rm -rf out/arch/arm64/boot
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"
curl --upload-file $ZIPNAME http://transfer.sh/$ZIPNAME; echo
