#!/usr/bin/env bash

scriptPath="$( cd "$(dirname "$0")" ; pwd -P )"
_CMakeBuildType=Debug
_CMakeBuildTarget=veldrid-spirv
_CMakeOsxArchitectures=
_OSDir=

while :; do
    if [ $# -le 0 ]; then
        break
    fi

    lowerI="$(echo $1 | awk '{print tolower($0)}')"
    case $lowerI in
        debug|-debug)
            _CMakeBuildType=Debug
            ;;
        release|-release)
            _CMakeBuildType=Release
            ;;
        osx)
            _CMakeOsxArchitectures=$2
            _OSDir=osx
            shift
            ;;
        linux-x64)
            _OSDir=linux-x64
            ;;
		linux-arm64)
            _OSDir=linux-arm64
            ;;
        ios)
            _OSDir=ios
            ;;
        *)
            __UnprocessedBuildArgs="$__UnprocessedBuildArgs $1"
    esac

    shift
done

_OutputPath=$scriptPath/build/$_CMakeBuildType/$_OSDir
_PythonExePath=$(which python3)
if [[ $_PythonExePath == "" ]]; then
    echo Build failed: could not locate python executable.
    exit 1
fi

mkdir -p $_OutputPath
pushd $_OutputPath

if [[ $_OSDir == "ios" ]]; then
	_CMakeEnableBitcode=-DENABLE_BITCODE=0
	_CMakeGenerator="-G Xcode"
	_CMakeExtraBuildArgs="--config Release"
	_CMakeToolchain=../../ios/ios.toolchain.cmake

	# Build for iOS device (arm64)
    mkdir -p device-build
    pushd device-build

    cmake ../../../.. $_CMakeGenerator -DCMAKE_BUILD_TYPE=$_CMakeBuildType -DCMAKE_TOOLCHAIN_FILE=$_CMakeToolchain -DPLATFORM=OS64 -DDEPLOYMENT_TARGET=13.4 $_CMakeEnableBitcode -DPYTHON_EXECUTABLE=$_PythonExePath
    cmake --build . --target $_CMakeBuildTarget $_CMakeExtraBuildArgs

    popd

	# Build for iOS simulator (combined arm64 + x86_64)
    mkdir -p simulator-build
    pushd simulator-build

    cmake ../../../.. $_CMakeGenerator -DCMAKE_BUILD_TYPE=$_CMakeBuildType -DCMAKE_TOOLCHAIN_FILE=$_CMakeToolchain -DPLATFORM=SIMULATOR64COMBINED -DDEPLOYMENT_TARGET=13.4 $_CMakeEnableBitcode -DPYTHON_EXECUTABLE=$_PythonExePath
    cmake --build . --target $_CMakeBuildTarget $_CMakeExtraBuildArgs

    popd

	# Build for Mac Catalyst (universal arm64 + x86_64)
    mkdir -p maccatalyst-build
    pushd maccatalyst-build

	cmake ../../../.. $_CMakeGenerator -DCMAKE_BUILD_TYPE=$_CMakeBuildType -DCMAKE_TOOLCHAIN_FILE=$_CMakeToolchain -DPLATFORM=MAC_CATALYST_UNIVERSAL -DDEPLOYMENT_TARGET=13.4 $_CMakeEnableBitcode -DPYTHON_EXECUTABLE=$_PythonExePath
    #cmake --build . --target $_CMakeBuildTarget $_CMakeExtraBuildArgs	
	xcodebuild -project $_CMakeBuildTarget.xcodeproj -scheme $_CMakeBuildTarget -configuration Release -destination 'generic/platform=iOS,variant=Mac Catalyst' SUPPORTS_MACCATALYST=YES

    popd

	# Final combine all builds to framework
    xcodebuild -create-xcframework \
	    -framework ./device-build/Release-iphoneos/veldrid-spirv.framework \
	    -framework ./simulator-build/Release-iphonesimulator/veldrid-spirv.framework \
        -framework ./maccatalyst-build/Release/veldrid-spirv.framework \
	    -output ./veldrid-spirv.xcframework
else
    cmake ../../.. -DCMAKE_BUILD_TYPE=$_CMakeBuildType $_CMakeGenerator $_CMakeEnableBitcode -DPYTHON_EXECUTABLE=$_PythonExePath -DCMAKE_OSX_ARCHITECTURES="$_CMakeOsxArchitectures"
    cmake --build . --target $_CMakeBuildTarget $_CMakeExtraBuildArgs
fi

popd
