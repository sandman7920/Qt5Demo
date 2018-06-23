#!/bin/bash

. /opt/qt510/bin/qt510-env.sh

set -e

echo "Building GTK2 styles"

PLUGINS="`qmake -query QT_INSTALL_PLUGINS`"

if [ -f "${PLUGINS}/styles/libqgtk2style.so" ]; then
    echo "Already installed"
    exit 0
fi

if ! dpkg -l libgtk2.0-dev >/dev/null 2>&1; then
    echo "Please install libgtk2.0-dev"
    exit 1
fi

# see https://www.archlinux.org/packages/community/x86_64/qt5-styleplugins/
_commit=335dbece103e2cbf6c7cf819ab6672c2956b17b3

SRC="https://github.com/qt/qtstyleplugins/archive/${_commit}.tar.gz"

rm -rf /tmp/build_gtk2
mkdir /tmp/build_gtk2
cd /tmp/build_gtk2
curl -L "${SRC}" 2>/dev/null|tar zxv

qmake qtstyleplugins-335dbece103e2cbf6c7cf819ab6672c2956b17b3/qtstyleplugins.pro
make -j5
sudo make install

cd "${PLUGINS}"

sudo strip styles/* platformthemes/libqgtk2.so
sudo chmod 644 styles/* platformthemes/libqgtk2.so

rm -rf /tmp/build_gtk2
