#!/bin/bash -e

# It is assumed that current directory is directory where with script is
# located. It is also assumed that all prerequisites are downloaded to the
# "tars" directory. Eclipse in the "tars" should be already unpacked and has
# all plug-ins installed. This is a "quick and dirty" script, thus it have
# such strict requirements.

mkdir in
cd in

# Copy MinGW and MSYS runtime files
echo "Copying MSYS and MinGW runtime files..."
tar xaf ../tars/coreutils-*-msys-*-bin.tar.lzma
tar xaf ../tars/gcc-core-*-mingw32-dll.tar.lzma
tar xaf ../tars/gettext-*-mingw32-dll.tar.lzma
tar xaf ../tars/libiconv-*-msys-*-dll*.tar.lzma
tar xaf ../tars/libiconv-*-mingw32-dll.tar.lzma
tar xaf ../tars/libintl-*-msys-*-dll*.tar.lzma
tar xaf ../tars/msysCORE-*-msys-*-bin.tar.lzma
tar xaf ../tars/make-*-mingw32-cvs-*-bin.tar.lzma
mv bin/{mingw32-,}make.exe

# Copy arcshell.bat
echo "Copying arcshell.bat..."
cp ../tars/arcshell.bat .

# Copy OpenOCD
echo "Copying OpenOCD..."
tar xaf ../tars/openocd-ide-*.tgz --strip-components=1

# Copy tool chain
echo "Copything toolchain..."
tar xaf ../tars/arc_gnu_*_prebuilt_elf32_windows_install.tgz --strip-components=1

# Copy Eclipse
echo "Copying Eclipse..."
rsync -a ../tars/eclipse .

# Copy Java runtime environment:
echo "Copying JRE..."
mkdir eclipse/jre
cd eclipse/jre
tar xaf ../../../tars/jre-*-windows-i586.tar.gz --strip-components=1
cd ../../..

# Generate installer an uninstaller sections
echo "Generating nsis files..."
./gen-nsis-sections.sh

# Generate installer
echo "Creating installer..."
/cygdrive/c/Program\ Files\ \(x86\)/NSIS/makensis.exe installer-standard.nsi

echo "Done"

