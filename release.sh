#!/bin/bash

ARCHITECTURES="\
386
amd64
arm
arm64
"
VERSION=$1
if [ -z "$VERSION" ];then
	echo version not provided
	exit 1
fi

mkdir -p Release
for arch in $ARCHITECTURES;do
	rm -rf ./Binary_Modules/bin
	(
	cd Binary_Modules
	GOARCH="$arch" bash build.sh
 	)
	files_to_zip=$(find . -maxdepth 1 ! -name Release ! -name '.')
	zip -r "Release/awesome-bash-scripts-${VERSION}-$arch.zip" $files_to_zip
done
