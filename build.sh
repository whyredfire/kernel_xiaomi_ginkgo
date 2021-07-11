#!/bin/bash
#
# Compile script for QuicksilveR kernel
# Copyright (C) 2020-2021 Adithya R.

SECONDS=0 # builtin bash timer
ZIPNAME="StormBreaker-ginkgo-beta-$(date '+%Y%m%d-%H%M').zip"
SB_DIR="$PWD"
TC_DIR="$SB_DIR/tc"

export KBUILD_BUILD_HOST=whyredfire
export KBUILD_BUILD_USER=karan

if ! [ -d "${TC_DIR}/clang11" ]; then
echo "Clang not found! Cloning to ${TC_DIR}/clang11..."
if ! git clone --depth=1 --single-branch -b aosp-11.0.5 https://github.com/sohamxda7/llvm-stable ${TC_DIR}/clang11; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if ! [ -d "${TC_DIR}/gcc" ]; then
echo "gcc not found! Cloning to ${TC_DIR}/gcc..."
if ! git clone --depth=1 --single-branch -b master https://github.com/stormbreaker-project/aarch64-linux-android-4.9 ${TC_DIR}/gcc; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

if ! [ -d "${TC_DIR}/gcc_32" ]; then
echo "gcc_32 not found! Cloning to ${TC_DIR}/gcc_32..."
if ! git clone --depth=1 --single-branch -b master https://github.com/stormbreaker-project/arm-linux-androideabi-4.9 ${TC_DIR}/gcc_32; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi


export KBUILD_COMPILER_STRING="$(${TC_DIR}/clang11/bin/clang --version | head -n 1 | sed -e 's/  */ /g' -e 's/[[:space:]]*$//'))"


make O=out ARCH=arm64 vendor/ginkgo-perf_defconfig

PATH="${TC_DIR}/clang11/bin:${TC_DIR}/gcc/bin:${TC_DIR}/gcc_32/bin:${PATH}"

echo -e "\nStarting compilation...\n"

make -j8 O=out ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-android- CROSS_COMPILE_ARM32=arm-linux-androideabi-

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
if ! git clone -q https://github.com/stormbreaker-project/AnyKernel3 -b ginkgo; then
echo -e "\nCloning AnyKernel3 repo failed! Aborting..."
exit 1
fi
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
else
echo -e "\nCompilation failed!"
fi
