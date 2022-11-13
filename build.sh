#!/bin/sh
#要build的target名
if [[ $2 ]]
then
  PROJECT_NAME=$1
  TARGET_NAME=$2
elif [[ $1 ]]
then
  TARGET_NAME=$1
else
  TARGET_NAME=${PROJECT_NAME}
fi

BUILD_DIR=build_tmp_path
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

UNIVERSAL_OUTPUT_FOLDER=bin
rm -rf $UNIVERSAL_OUTPUT_FOLDER
mkdir -p $UNIVERSAL_OUTPUT_FOLDER

#创建输出目录，并删除之前的framework文件
mkdir -p "${UNIVERSAL_OUTPUT_FOLDER}"
rm -rf "${UNIVERSAL_OUTPUT_FOLDER}/${TARGET_NAME}.framework"

#分别编译模拟器和真机的Framework
xcodebuild -target ${TARGET_NAME} ONLY_ACTIVE_ARCH=YES -arch arm64 -configuration Release -sdk iphoneos BUILD_DIR="${BUILD_DIR}" clean build

xcodebuild -target ${TARGET_NAME} ONLY_ACTIVE_ARCH=NO -configuration Release -sdk iphonesimulator BUILD_DIR="${BUILD_DIR}" clean build

xcodebuild -create-xcframework -framework "${BUILD_DIR}"/Release-iphoneos/"${TARGET_NAME}".framework  -framework "${BUILD_DIR}"/Release-iphonesimulator/"${TARGET_NAME}".framework  -output "${UNIVERSAL_OUTPUT_FOLDER}"/${TARGET_NAME}.xcframework

rm -rf $BUILD_DIR
