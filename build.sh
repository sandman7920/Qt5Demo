#!/bin/bash

if ! patchelf --help >/dev/null 2>&1; then
    echo "please install patchelf"
    exit 1
fi

if ! curl --help >/dev/null 2>&1; then
    echo "please install curl"
    exit 1
fi

set -e

KDE_LIST="libQt5Concurrent.so.5 libQt5Core.so.5 libQt5DBus.so.5 libQt5Gui.so.5"
KDE_LIST="${KDE_LIST} libQt5Network.so.5 libQt5PrintSupport.so.5 libQt5Qml.so.5"
KDE_LIST="${KDE_LIST} libQt5QuickControls2.so.5 libQt5Quick.so.5 libQt5QuickTemplates2.so.5"
KDE_LIST="${KDE_LIST} libQt5Script.so.5 libQt5Svg.so.5 libQt5TextToSpeech.so.5 libQt5Widgets.so.5 libQt5X11Extras.so.5 libQt5Xml.so.5"

SELF="`readlink -f ${0}`"
HERE="${SELF%/*}"

cd "${HERE}"

QMAKE=/home/nik/Applications/Qt/5.11.0/gcc_64/bin/qmake
LIB_PATH=`$QMAKE -query QT_INSTALL_LIBS`

rm -rf build
mkdir -p build
cd build
$QMAKE ../src/mainwindows.pro
make -j5
cd "${HERE}"

if [ ! -x ./linuxdeployqt ]; then
    curl -L https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage >linuxdeployqt
    chmod 755 linuxdeployqt
fi

if [ ! -x ./appimagetool ]; then
    curl -L https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage >appimagetool
    chmod 755 appimagetool
fi

if [ ! -x ./appimage.qt5run ]; then
    curl -L https://github.com/sandman7920/AppImageQt5run/releases/download/v0.3/appimage-gcc4.8.4-GLIBC_2.2.5-GLIBCXX_3.4.9.qt5run >appimage.qt5run
    chmod 755 appimage.qt5run
fi

rm -rf appimages
. Qt.desktop.template
for EXE in `find build/ -type f -executable`; do
    FNAME="${EXE##*/}"
    OUTPUT="appimages/${FNAME}.AppDir/usr/bin"
    mkdir -p "${OUTPUT}"
    install -m755 -s "$EXE" "${OUTPUT}"
    ${HERE}/linuxdeployqt "${OUTPUT}/${FNAME}" \
        -qmake="${QMAKE}" \
        -no-translations \
        -extra-plugins=platformthemes/libqgtk3.so
    cp appimage.qt5run "${OUTPUT}/${FNAME}.qt5run"
    cp qt.png "appimages/${FNAME}.AppDir/"
    printf "${TEMPLATE}" "${FNAME}" "${FNAME}" > "appimages/${FNAME}.AppDir/Qt.desktop"
    cd "appimages/${FNAME}.AppDir/"
    rm AppRun
    ln -s "usr/bin/${FNAME}.qt5run" AppRun
    cd "${HERE}"
    
    cp /usr/lib/libpng*.so.0 "appimages/${FNAME}.AppDir/usr/lib" || true
    cp /usr/lib/x86_64-linux-gnu/libpng*.so.0 "appimages/${FNAME}.AppDir/usr/lib" || true
    
    for lib in ${KDE_LIST}; do
        cp "${LIB_PATH}/${lib}" "appimages/${FNAME}.AppDir/usr/lib"
        patchelf --set-rpath \$ORIGIN "appimages/${FNAME}.AppDir/usr/lib/${lib}"
    done
    
    mkdir -p output
    cd output
    "${HERE}/appimagetool" -n "${HERE}/appimages/${FNAME}.AppDir"
    cd "${HERE}"
done

rm -rf build
rm -rf appimages
