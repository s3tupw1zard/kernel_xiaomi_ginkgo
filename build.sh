export PATH="$HOME/proton/bin:$PATH"
SECONDS=0
ZIPNAME="QuicksilveRV2-ginkgo-$(date '+%Y%m%d-%H%M').zip"

if ! [ -d "$HOME/proton" ]; then
echo "Proton clang not found! Cloning..."
if ! git clone -q --depth=1 --single-branch https://github.com/kdrag0n/proton-clang ~/proton; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

cat <<'EOF' >> arch/arm64/configs/vendor/ginkgo-perf_defconfig
CONFIG_LTO_CLANG=y
CONFIG_THINLTO=y
CONFIG_LD_DEAD_CODE_DATA_ELIMINATION=y
EOF

trap "git checkout arch/arm64/configs/vendor/ginkgo-perf_defconfig" INT

mkdir -p out
make O=out ARCH=arm64 vendor/ginkgo-perf_defconfig

if [[ $1 == "-r" || $1 == "--regen" ]]; then
cp out/.config arch/arm64/configs/vendor/ginkgo-perf_defconfig
echo -e "\nRegened defconfig succesfully!"
exit 0
else
echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- Image.gz-dtb dtbo.img
fi

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
git checkout arch/arm64/configs/vendor/ginkgo-perf_defconfig
git clone -q https://github.com/ghostrider-reborn/AnyKernel3
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
cp out/arch/arm64/boot/dtbo.img AnyKernel3
rm -f *zip
cd AnyKernel3
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
rm -rf AnyKernel3
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
if command -v gdrive &> /dev/null; then
gdrive upload --share $ZIPNAME
else
echo "Zip: $ZIPNAME"
fi
rm -rf out/arch/arm64/boot
else
echo -e "\nCompilation failed!"
git checkout arch/arm64/configs/vendor/ginkgo-perf_defconfig
fi
