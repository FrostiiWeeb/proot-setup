#!/bin/bash
set -e

BOX86_DEB=https://github.com/xDoge26/Proot-Setup/raw/main/Packages/box86-android_0.3.0-1_armhf.deb
BOX64_DEB=https://github.com/xDoge26/Proot-Setup/raw/main/Packages/box64-android_0.2.2-1_arm64.deb
WINE_AMD64=https://github.com/Kron4ek/Wine-Builds/releases/download/8.0.2/wine-8.0.2-amd64.tar.xz
WINE_DIR=~/wine

# Install related kits
sudo dpkg --add-architecture armhf
sudo apt update
sudo apt upgrade -y
sudo apt install -y gpg xz-utils

# Install dependencies
sudo apt install -y \
    libgl1:armhf libc6:armhf \
    libgstreamer-plugins-base1.0-0:armhf libgstreamer1.0-0:armhf \
    libpulse0:armhf libsane1:armhf libudev1:armhf libunwind8:armhf \
    libusb-1.0-0:armhf libx11-6:armhf libxext6:armhf \
    ocl-icd-libopencl1:armhf libopencl1:armhf \
    libncurses6:armhf \
    libdbus-1-3:armhf libfontconfig1:armhf libfreetype6:armhf \
    libglu1-mesa:armhf libglu1:armhf libgsm1:armhf \
    libgssapi-krb5-2:armhf libjpeg8:armhf libkrb5-3:armhf \
    libosmesa6:armhf libsdl2-2.0-0:armhf libxcomposite1:armhf \
    libxcursor1:armhf libxfixes3:armhf libxi6:armhf \
    libxinerama1:armhf libxrandr2:armhf libxrender1:armhf \
    libxslt1.1:armhf libxxf86vm1:armhf \
    libgl1:arm64 libc6:arm64 \
    libglib2.0-0:arm64 \
    libgstreamer-plugins-base1.0-0:arm64 libgstreamer1.0-0:arm64 \
    libpulse0:arm64 libsane1:arm64 libudev1:arm64 libunwind8:arm64 \
    libusb-1.0-0:arm64 libx11-6:arm64 libxext6:arm64 \
    ocl-icd-libopencl1:arm64 libopencl1:arm64 \
    libncurses6:arm64 libcups2:arm64 \
    libdbus-1-3:arm64 libfontconfig1:arm64 libfreetype6:arm64 \
    libglu1-mesa:arm64 libglu1:arm64 libgsm1:arm64 \
    libgssapi-krb5-2:arm64 libjpeg8:arm64 libkrb5-3:arm64 \
    libosmesa6:arm64 libsdl2-2.0-0:arm64 libxcomposite1:arm64 \
    libxcursor1:arm64 libxfixes3:arm64 libxi6:arm64 \
    libxinerama1:arm64 libxrandr2:arm64 libxrender1:arm64 \
    libxslt1.1:arm64 libxxf86vm1:arm64

# Clean
sudo apt clean
sudo apt autoremove -y

# Install box86 and box64
wget https://ryanfortner.github.io/box86-debs/box86.list -O /etc/apt/sources.list.d/box86.list
wget -qO- https://ryanfortner.github.io/box86-debs/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg
wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list
wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg
sudo apt update
sudo apt install -y box86-android box64-android

# Download and Install Wine
rm -rf ${WINE_DIR}
mkdir -p ${WINE_DIR}
wget --quiet --show-progress --continue --directory-prefix ${WINE_DIR} ${WINE_AMD64}
tar -xf ${WINE_DIR}/wine-*.tar.xz --directory ${WINE_DIR}
mv ${WINE_DIR}/wine-*/* ${WINE_DIR}
rm -rf ${WINE_DIR}/wine-*

# Create Symlinks
sudo rm -f /usr/local/bin/wine /usr/local/bin/wine64
sudo ln -s ${WINE_DIR}/bin/wine /usr/local/bin/wine
sudo ln -s ${WINE_DIR}/bin/wine64 /usr/local/bin/wine64
sudo chmod +x /usr/local/bin/wine /usr/local/bin/wine64

# Setup scripts
echo '#!/bin/bash
DISPLAY=:1 WINE_DEBUG=-all MESA_NO_ERROR=1 GALLIUM_DRIVER=virpipe MESA_GL_VERSION_OVERRIDE=4.3COMPAT MESA_EXTENSION_OVERRIDE="GL_EXT_polygon_offset_clamp" \
exec taskset -c 4-7 box86 wine "$@"
' | sudo tee /usr/local/bin/virgl > /dev/null

echo '#!/bin/bash
DISPLAY=:1 WINE_DEBUG=-all MESA_NO_ERROR=1 TU_DEBUG=noconform MESA_VK_WSI_DEBUG=sw MESA_LOADER_DRIVER_OVERRIDE=zink \
exec taskset -c 4-7 box86 wine "$@"
' | sudo tee /usr/local/bin/zink > /dev/null

echo '#!/bin/bash
DISPLAY=:1 WINE_DEBUG=-all MESA_NO_ERROR=1 TU_DEBUG=noconform MESA_VK_WSI_DEBUG=sw \
exec taskset -c 4-7 box86 wine "$@"
' | sudo tee /usr/local/bin/vulkan > /dev/null

sudo chmod +x /usr/local/bin/vulkan /usr/local/bin/zink /usr/local/bin/virgl
