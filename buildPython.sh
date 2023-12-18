#! /bin/sh

# jupyter-something adds pandas-1.5.3 and pyzmq-25.0b1, which breaks things down 
# So far, the "fix" is to manually remove them. 

export AR=/usr/bin/ar
export RANLIB=/usr/bin/ranlib

# Changed install prefix so multiple install coexist
export PREFIX=$PWD
export XCFRAMEWORKS_DIR=$PREFIX/Python-aux/
# $PREFIX/Library/bin so that the new python is in the path, 
# ~/.cargo/bin for rustc
export PATH=$PREFIX/Library/bin:~/.cargo/bin:$PATH
export PYTHONPYCACHEPREFIX=$PREFIX/__pycache__
export OSX_SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
export IOS_SDKROOT=$(xcrun --sdk iphoneos --show-sdk-path)
export SIM_SDKROOT=$(xcrun --sdk iphonesimulator --show-sdk-path)
export DEBUG="-O3 -Wall" #-DNDEBUG
# Comment this line to re-download all package source from PyPi
export USE_CACHED_PACKAGES=1
# DEBUG="-g"
export OSX_VERSION=11.5 # $(sw_vers -productVersion |awk -F. '{print $1"."$2}')
# Numpy sets it to 10.9 otherwise. gfortran needs it to 11.5 (for scipy at least)
export MACOSX_DEPLOYMENT_TARGET=$OSX_VERSION
# TODO: remove -3.11 from $PREFIX/build directories, use $ARCH in directory names.
# export ARCH=$(uname -m)
# Loading different set of frameworks based on the Application:
APP=$(basename `dirname $PWD`)


# Function to download source, using curl for speed, pip if jq is not available:
# For fast downloads, you need the jq command: https://stedolan.github.io/jq/
# Source: https://github.com/pypa/pip/issues/1884#issuecomment-800483766
# Can take version as an optional argument: downloadSource pyFFTW 0.12.0
# If the directory already exists, do not download it unless USE_CACHED_PACKAGES has been set to 0 above.
downloadSource() 
{
   package=$1
   if [ -d $package-* ] && [ $USE_CACHED_PACKAGES ];
   then 
   	   echo using cached version of $package
   	   return
   fi
   rm -rf $package-*
   if [ $# -eq 1 ]
   then
   	   command=.releases\[.info.version]\[\]\|select\(.packagetype==\"sdist\"\)\|.url
   else
   	   command=.releases\[\"$2\"\]\[\]\|select\(.packagetype==\"sdist\"\)\|.url
   fi
   echo "Downloading " $package
   if which jq;
   then
   	   # jq exists, let's use it:
   	   url=https://pypi.org/pypi/${package}/json
   	   address=`curl -L $url | jq -r $command`
   	   curl -OL $address
   else 
   	   # We do not have jq, let's use pip:
   	   env NPY_BLAS_ORDER="" NPY_LAPACK_ORDER="" MATHLIB="-lm" python3.11 -m pip download --no-deps --no-binary :all: --no-build-isolation $package $package
   fi
   if [ -f $package*.tar.gz ];
   then
	   tar xvzf $package*.tar.gz
	   rm $package*.tar.gz
   fi
   if [ -f $package*.zip ];
   then
	   unzip $package*.zip
	   rm $package*.zip
   fi
}

# # 1) compile for OSX (required)
# find . -name \*.o -delete
# rm -rf Library/lib/python3.11/site-packages/* 
# find Library -type f -name direct_url.jsonbak -delete
# env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT" CXXFLAGS="-isysroot $OSX_SDKROOT" LDFLAGS="-isysroot $OSX_SDKROOT -lz" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L. -lpython3.11" OPT="$DEBUG" ./configure --prefix=$PREFIX/Library --with-system-ffi --enable-shared \
#     $EXTRA_CONFIGURE_FLAGS_OSX \
# 	--without-computed-gotos \
# 	ac_cv_file__dev_ptmx=no \
# 	ac_cv_file__dev_ptc=no \
# 	ac_cv_func_getentropy=no \
# 	ac_cv_func_sendfile=no \
# 	ac_cv_func_setregid=no \
# 	ac_cv_func_setreuid=no \
# 	ac_cv_func_setsid=no \
# 	ac_cv_func_setpgid=no \
# 	ac_cv_func_setpgrp=no \
# 	ac_cv_func_setuid=no \
#     ac_cv_func_forkpty=no \
#     ac_cv_func_openpty=no \
# 	ac_cv_func_clock_settime=no >& configure_osx.log
# # enable-framework incompatible with local install
# # Other functions copied from iOS so packages are consistent
# mkdir -p $PREFIX/Frameworks_macosx
# mkdir -p $PREFIX/Frameworks_macosx/lib
# mkdir -p $PREFIX/Frameworks_macosx/include
# rm -rf Frameworks_macosx/openblas.framework
# # The build scripts from numpy need openblas to be in a dylib, not a framework (to detect lapack functions)
# # So we create the dylib from the framework:
# # TODO: add openssl and zmq headers and libraries here as well (requires changing Python-aux build scripts)
# cp -r $XCFRAMEWORKS_DIR/libfftw3.xcframework/macos-x86_64/Headers/* $PREFIX/Frameworks_macosx/include/
# cp $XCFRAMEWORKS_DIR/libfftw3.xcframework/macos-x86_64/libfftw3.a $PREFIX/Frameworks_macosx/lib/
# cp $XCFRAMEWORKS_DIR/libfftw3_threads.xcframework/macos-x86_64/libfftw3_threads.a $PREFIX/Frameworks_macosx/lib/

# cp $XCFRAMEWORKS_DIR/openblas.xcframework/macos-x86_64/openblas.framework/Headers/* $PREFIX/Frameworks_macosx/include/
# cp  $XCFRAMEWORKS_DIR/openblas.xcframework/macos-x86_64/openblas.framework/openblas $PREFIX/Frameworks_macosx/lib/libopenblas.dylib
# install_name_tool -id $PREFIX/Frameworks_macosx/lib/libopenblas.dylib   $PREFIX/Frameworks_macosx/lib/libopenblas.dylib

# cp -r $XCFRAMEWORKS_DIR/libgeos_c.xcframework/macos-x86_64/libgeos_c.framework/Headers/* $PREFIX/Frameworks_macosx/include/
# cp -r $XCFRAMEWORKS_DIR/libgeos_c.xcframework/macos-x86_64/libgeos_c.framework  $PREFIX/Frameworks_macosx/
# rm -rf $PREFIX/Frameworks_macosx/include/gdal
# cp -r $XCFRAMEWORKS_DIR/libgdal.xcframework/macos-x86_64/libgdal.framework/Headers $PREFIX/Frameworks_macosx/include/gdal
# cp -r $XCFRAMEWORKS_DIR/libgdal.xcframework/macos-x86_64/libgdal.framework  $PREFIX/Frameworks_macosx/
# cp -r $XCFRAMEWORKS_DIR/libproj.xcframework/macos-x86_64/libproj.framework/Headers/* $PREFIX/Frameworks_macosx/include
# cp -r $XCFRAMEWORKS_DIR/libproj.xcframework/macos-x86_64/libproj.framework  $PREFIX/Frameworks_macosx/
# cp  /usr/local/lib/libgfortran.dylib $PREFIX/Frameworks_macosx/lib/libgfortran.dylib 
# # TODO: add downloading of proj data set + install in Library/share/proj.
# #
# rm -rf build/lib.macosx-${OSX_VERSION}-x86_64-3.11
# make -j 4 >& make_osx.log
# # exit 0 # Debugging embedded packages in Modules/Setup
# mkdir -p build/lib.macosx-${OSX_VERSION}-x86_64-3.11  > $PREFIX/make_install_osx.log 2>&1
# cp libpython3.11.dylib build/lib.macosx-${OSX_VERSION}-x86_64-3.11  >> $PREFIX/make_install_osx.log 2>&1
# make  -j 4 install  >> $PREFIX/make_install_osx.log 2>&1
# export PYTHONHOME=$PREFIX/Library
# # When working on frozen importlib, we need to compile twice:
# # Otherwise, we can comment the next 7 lines
# # make regen-importlib >> $PREFIX/make_osx.log 2>&1
# # find . -name \*.o -delete  >> $PREFIX/make_osx.log 2>&1
# # make  -j 4 >> $PREFIX/make_osx.log 2>&1 
# # mkdir -p build/lib.macosx-${OSX_VERSION}-x86_64-3.11  >> $PREFIX/make_install_osx.log 2>&1
# # cp libpython3.11.dylib build/lib.macosx-${OSX_VERSION}-x86_64-3.11  >> $PREFIX/make_install_osx.log 2>&1
# # cp python.exe build/lib.macosx-${OSX_VERSION}-x86_64-3.11/python3.11  >> $PREFIX/make_install_osx.log 2>&1
# # make  -j 4 install >> $PREFIX/make_install_osx.log 2>&1
# # We should make this automatic, but it's not part of Python make install:
# cp -r Lib/venv/scripts/ios Library/lib/python3.11/venv/scripts/  >> $PREFIX/make_install_osx.log 2>&1
# cp $PREFIX/Library/bin/python3.11 $PREFIX >> make_osx.log 2>&1


# # Force reinstall and upgrade of pip, setuptools 
# echo Starting package installation  >> $PREFIX/make_install_osx.log 2>&1
# python3.11 -m pip install pip --upgrade >> $PREFIX/make_install_osx.log 2>&1
# python3.11 -m pip install setuptools --upgrade >> $PREFIX/make_install_osx.log 2>&1
# python3.11 -m pip install setuptools-rust --upgrade >> $PREFIX/make_install_osx.log 2>&1
# python3.11 -m pip install setuptools_scm --upgrade >> $PREFIX/make_install_osx.log 2>&1


# # OSX install of cffi: we need to recompile or Python crashes. 
# # TODO: edit cffi code if static variables inside function create problems.
# python3.11 -m pip uninstall cffi -y >> $PREFIX/make_install_osx.log 2>&1
# pushd packages >> $PREFIX/make_install_osx.log 2>&1
# downloadSource cffi >> $PREFIX/make_install_osx.log 2>&1
# pushd cffi-* >> $PREFIX/make_install_osx.log 2>&1
# rm -rf build/* >> $PREFIX/make_install_osx.log 2>&1
# cp ../setup_cffi.py ./setup.py  >> $PREFIX/make_install_osx.log 2>&1
# env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT" CXXFLAGS="-isysroot $OSX_SDKROOT" LDFLAGS="-isysroot $OSX_SDKROOT " LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.11 -lc++ " python3.11 setup.py build  >> $PREFIX/make_install_osx.log 2>&1
# # python3.11 -m pip install cffi --upgrade >> $PREFIX/make_install_osx.log 2>&1
# cp build/lib.macosx-${OSX_VERSION}-x86_64-*/_cffi_backend.cpython-311-darwin.so $PREFIX/build/lib.macosx-${OSX_VERSION}-x86_64-3.11/  >> $PREFIX/make_install_osx.log 2>&1
# env CC=clang CXX=clang++ CPPFLAGS="-isysroot $OSX_SDKROOT" CFLAGS="-isysroot $OSX_SDKROOT" CXXFLAGS="-isysroot $OSX_SDKROOT" LDFLAGS="-isysroot $OSX_SDKROOT " LDSHARED="clang -v -undefined error -dynamiclib -isysroot $OSX_SDKROOT -lz -L$PREFIX -lpython3.11 -lc++ " python3.11 -m pip install . >> $PREFIX/make_install_osx.log 2>&1
# popd  >> $PREFIX/make_install_osx.log 2>&1
# popd  >> $PREFIX/make_install_osx.log 2>&1


# compile for iOS:
unset MACOSX_DEPLOYMENT_TARGET
export OSX_VERSION=$(sw_vers -productVersion |awk -F. '{print $1"."$2}')

mkdir -p Frameworks_iphoneos
mkdir -p Frameworks_iphoneos/include
mkdir -p Frameworks_iphoneos/lib
rm -rf Frameworks_iphoneos/ios_system.framework
rm -rf Frameworks_iphoneos/freetype.framework
rm -rf Frameworks_iphoneos/openblas.framework
cp -r $XCFRAMEWORKS_DIR/ios_system.xcframework/ios-arm64/ios_system.framework $PREFIX/Frameworks_iphoneos
cp -r $XCFRAMEWORKS_DIR/freetype.xcframework/ios-arm64/freetype.framework $PREFIX/Frameworks_iphoneos
cp -r $XCFRAMEWORKS_DIR/libffi.xcframework/ios-arm64/Headers/ffi $PREFIX/Frameworks_iphoneos/include/ffi
cp -r $XCFRAMEWORKS_DIR/libffi.xcframework/ios-arm64/Headers/ffi/* $PREFIX/Frameworks_iphoneos/include/ffi/
cp -r $XCFRAMEWORKS_DIR/crypto.xcframework/ios-arm64/Headers $PREFIX/Frameworks_iphoneos/include/crypto/
cp -r $XCFRAMEWORKS_DIR/openssl.xcframework/ios-arm64/Headers $PREFIX/Frameworks_iphoneos/include/openssl/
cp -r $XCFRAMEWORKS_DIR/libzmq.xcframework/ios-arm64/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp -r $XCFRAMEWORKS_DIR/libjpeg.xcframework/ios-arm64/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp -r $XCFRAMEWORKS_DIR/libtiff.xcframework/ios-arm64/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp -r $XCFRAMEWORKS_DIR/libxslt.xcframework/ios-arm64/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp -r $XCFRAMEWORKS_DIR/libexslt.xcframework/ios-arm64/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp -r $XCFRAMEWORKS_DIR/libfftw3.xcframework/ios-arm64/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp -r $XCFRAMEWORKS_DIR/freetype.xcframework/ios-arm64/freetype.framework/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp -r $XCFRAMEWORKS_DIR/liblzma.xcframework/ios-arm64/Headers/lz* $PREFIX/Frameworks_iphoneos/include/
# Need to copy all libs after each make clean: 
cp $XCFRAMEWORKS_DIR/crypto.xcframework/ios-arm64/libcrypto.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/openssl.xcframework/ios-arm64/libssl.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libffi.xcframework/ios-arm64/libffi.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libzmq.xcframework/ios-arm64/libzmq.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libjpeg.xcframework/ios-arm64/libjpeg.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libtiff.xcframework/ios-arm64/libtiff.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libxslt.xcframework/ios-arm64/libxslt.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libexslt.xcframework/ios-arm64/libexslt.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libfftw3.xcframework/ios-arm64/libfftw3.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/libfftw3_threads.xcframework/ios-arm64/libfftw3_threads.a $PREFIX/Frameworks_iphoneos/lib/
cp $XCFRAMEWORKS_DIR/liblzma.xcframework/ios-arm64/liblzma.a $PREFIX/Frameworks_iphoneos/lib/
# The build scripts from numpy need openblas to be in a dylib, not a framework (to detect lapack functions)
# So we create the dylib from the framework:
cp $XCFRAMEWORKS_DIR/openblas.xcframework/ios-arm64/openblas.framework/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp  $XCFRAMEWORKS_DIR/openblas.xcframework/ios-arm64/openblas.framework/openblas $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib
install_name_tool -id $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib   $PREFIX/Frameworks_iphoneos/lib/libopenblas.dylib
#
cp -r $XCFRAMEWORKS_DIR/libgeos_c.xcframework/ios-arm64/libgeos_c.framework/Headers/* $PREFIX/Frameworks_iphoneos/include/
cp -r $XCFRAMEWORKS_DIR/libgeos_c.xcframework/ios-arm64/libgeos_c.framework  $PREFIX/Frameworks_iphoneos/
rm -rf $PREFIX/Frameworks_iphoneos/include/gdal
cp -r $XCFRAMEWORKS_DIR/libgdal.xcframework/ios-arm64/libgdal.framework/Headers $PREFIX/Frameworks_iphoneos/include/gdal
cp -r $XCFRAMEWORKS_DIR/libgdal.xcframework/ios-arm64/libgdal.framework  $PREFIX/Frameworks_iphoneos/
cp -r $XCFRAMEWORKS_DIR/libproj.xcframework/ios-arm64/libproj.framework/Headers/* $PREFIX/Frameworks_iphoneos/include
cp -r $XCFRAMEWORKS_DIR/libproj.xcframework/ios-arm64/libproj.framework  $PREFIX/Frameworks_iphoneos/

find . -name \*.o -delete
find Modules -name \*.a -delete
rm libpython3.11.dylib
rm libpython3.11.a
rm -f Programs/_testembed Programs/_freeze_importlib
# preadv / pwritev are iOS 14+ only

env CC=clang CXX=clang++ \
	CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX/Frameworks_iphoneos/include" \
	CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX/Frameworks_iphoneos/include" \
	CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX/Frameworks_iphoneos/include" \
	LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -lz -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib" \
	LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -L. -lpython3.11  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib" \
	PLATFORM=iphoneos \
	OPT="$DEBUG" \
	./configure --prefix=$PREFIX/Library --enable-shared \
	--host arm-apple-darwin --build x86_64-apple-darwin --enable-ipv6 \
	--with-openssl=$PREFIX/Frameworks_iphoneos \
	--with-build-python=python3 \
	--without-computed-gotos \
	with_system_ffi=yes \
	ac_cv_file__dev_ptmx=no \
	ac_cv_file__dev_ptc=no \
	ac_cv_func_getentropy=no \
	ac_cv_func_sendfile=no \
	ac_cv_func_setregid=no \
	ac_cv_func_setreuid=no \
	ac_cv_func_setsid=no \
	ac_cv_func_setpgid=no \
	ac_cv_func_setpgrp=no \
	ac_cv_func_setuid=no \
    ac_cv_func_forkpty=no \
    ac_cv_func_openpty=no \
	ac_cv_func_clock_settime=no >& configure_ios.log

# --without-pymalloc  when debugging memory
# --enable-framework fails with iOS compilers
rm -rf build/lib.darwin-arm64-3.11
make -j 8 >& make_ios.log
mkdir -p  build/lib.darwin-arm64-3.11
cp libpython3.11.dylib build/lib.darwin-arm64-3.11

#因为直接给链接器libmpdec报错，所以以下纯手工编译decimal扩展库
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ld -demangle -lto_library /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/libLTO.dylib -dynamic -dylib -arch arm64 -platform_version ios 14.0.0 16.1 -syslibroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS16.1.sdk -undefined error -undefined error -o build/lib.darwin-arm64-3.11/_decimal.cpython-311-darwin.so -L. -L/Users/huima/PythonSchool/modules/cpython/Frameworks_iphoneos/lib -L/Users/huima/PythonSchool/modules/cpython/Frameworks_iphoneos/lib -L. -L/Users/huima/PythonSchool/modules/cpython/Frameworks_iphoneos/lib -lz -lpython3.11 -framework ios_system -lz -framework ios_system build/temp.darwin-arm64-3.11/Users/huima/PythonSchool/modules/cpython/Modules/_decimal/_decimal.o  -lm -lSystem /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/14.0.0/lib/darwin/libclang_rt.ios.a -F/Users/huima/PythonSchool/modules/cpython/Frameworks_iphoneos -F/Users/huima/PythonSchool/modules/cpython/Frameworks_iphoneos Modules/_decimal/libmpdec/basearith.o Modules/_decimal/libmpdec/constants.o Modules/_decimal/libmpdec/context.o Modules/_decimal/libmpdec/convolute.o Modules/_decimal/libmpdec/crt.o Modules/_decimal/libmpdec/difradix2.o Modules/_decimal/libmpdec/fnt.o Modules/_decimal/libmpdec/fourstep.o Modules/_decimal/libmpdec/io.o Modules/_decimal/libmpdec/mpalloc.o Modules/_decimal/libmpdec/mpdecimal.o Modules/_decimal/libmpdec/numbertheory.o Modules/_decimal/libmpdec/sixstep.o Modules/_decimal/libmpdec/transpose.o


# Don't install for iOS
# Compilation of specific packages:
cp $PREFIX/build/lib.darwin-arm64-3.11/_sysconfigdata__darwin_darwin.py $PREFIX/Library/lib/python3.11/_sysconfigdata__darwin_darwin.py
if [ $APP == "Carnets" ]; 
then
cp $PREFIX/build/lib.darwin-arm64-3.11/_sysconfigdata__darwin_darwin.py $PREFIX/with_scipy/Library/lib/python3.11/_sysconfigdata__darwin_darwin.py
fi
# cffi: compile with iOS SDK
echo Installing cffi for iphoneos >> $PREFIX/make_ios.log 2>&1
pushd packages >> $PREFIX/make_ios.log 2>&1
pushd cffi* >> $PREFIX/make_ios.log 2>&1
# override setup.py for arm64 == iphoneos, not Apple Silicon
rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
env CC=clang CXX=clang++ CPPFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX" CFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -I$PREFIX" CXXFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT" LDFLAGS="-arch arm64 -miphoneos-version-min=14.0 -isysroot $IOS_SDKROOT -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib" LDSHARED="clang -v -undefined error -dynamiclib -isysroot $IOS_SDKROOT -lz -lpython3.11  -F$PREFIX/Frameworks_iphoneos -framework ios_system -L$PREFIX/Frameworks_iphoneos/lib -L$PREFIX/build/lib.darwin-arm64-3.11" PLATFORM=iphoneos python3.11 setup.py build  >> $PREFIX/make_ios.log 2>&1
cp build/lib.macosx-${OSX_VERSION}-arm64-cpython-311/_cffi_backend.cpython-311-darwin.so $PREFIX/build/lib.darwin-arm64-3.11/  >> $PREFIX/make_ios.log 2>&1
#rm -rf build/*  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
popd  >> $PREFIX/make_ios.log 2>&1
echo done compiling cffi >> $PREFIX/make_ios.log 2>&1
# end cffi

# Python build finished successfully!
# The necessary bits to build these optional modules were not found:
# _bz2                  _curses               _curses_panel      
# _gdbm                 _lzma                 _tkinter           
# _uuid                 nis                   ossaudiodev        
# readline              spwd                                     
# To find the necessary bits, look in setup.py in detect_modules() for the module's name.
# 
# 
# The following modules found by detect_modules() in setup.py, have been
# built by the Makefile instead, as configured by the Setup files:
# _abc                  atexit                pwd                
# time                                                           





# 禁掉 HAVE_GETC_UNLOCKED
# // #if defined(HAVE_GETC_UNLOCKED) && !defined(_Py_MEMORY_SANITIZER)
# // /* clang MemorySanitizer doesn't yet understand getc_unlocked. */
# // #define GETC(f) getc_unlocked(f)
# // #define FLOCKFILE(f) flockfile(f)
# // #define FUNLOCKFILE(f) funlockfile(f)
# // #else
# #define GETC(f) getc(f)
# #define FLOCKFILE(f)
# #define FUNLOCKFILE(f)
# // #endif
