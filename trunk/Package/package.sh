#!/bin/sh
set -u

#############################################
#############################################

# Define these to suit your nefarious purposes
project_name="WCSiOS"
CURR_DIR=$(PWD)
FRAMEWORK_NAME="${project_name}"
configuration="Release" 

project_path=$(PWD)/../
echo "Project name: ${project_name}, Project Path: ${project_path}"

# Where we'll put the build framework.
# The script presumes we're in the project root
# directory. Xcode builds in "build" by default
FRAMEWORK_BUILD_PATH="builtFramework"


# Clean any existing framework that might be there
# already
echo "Framework: Cleaning framework..."
if [ -d "$FRAMEWORK_BUILD_PATH" ]
then
	rm -rf "$FRAMEWORK_BUILD_PATH"
fi

if [[ $# -eq 0 ]] ; then
    configuration="Release"
else
    configuration="Debug"
fi

xcodebuild ARCHS="i386 x86_64" \
	ONLY_ACTIVE_ARCH=NO \
	-configuration "${configuration}" \
    -project "${project_path}/${project_name}.xcodeproj" \
    -target "${project_name}" \
    -sdk iphonesimulator \
    SYMROOT=$(PWD)/builtFramework \
    clean build

xcodebuild ARCHS="armv7 armv7s arm64" \
	ONLY_ACTIVE_ARCH=NO \
	-configuration "${configuration}" \
    -project "${project_path}/${project_name}.xcodeproj" \
    -target "${project_name}" \
    -sdk iphoneos \
    SYMROOT=$(PWD)/builtFramework \
    clean build

# The trick for creating a fully usable library is
# to use lipo to glue the different library
# versions together into one file. When an
# application is linked to this library, the
# linker will extract the appropriate platform
# version and use that.
# The library file is given the same name as the
# framework with no .a extension.
echo "Framework: Creating library..."
# if [ ${configuration} = "Debug" ] ; then
cp -r "builtFramework/${configuration}-iphoneos/${project_name}.framework" "${FRAMEWORK_BUILD_PATH}"
# else 
# cp -r "builtFramework/Release-iphoneos/${project_name}.framework" "${FRAMEWORK_BUILD_PATH}"
# fi
lipo -create \
    "builtFramework/${configuration}-iphoneos/${project_name}.framework/${project_name}" \
    "builtFramework/${configuration}-iphonesimulator/${project_name}.framework/${project_name}" \
    -o "builtFramework/${project_name}.framework/${project_name}"
echo "Build universal framework success."
