#!/bin/sh

WORKSPACE=$1
JOB_URL=$2
BUILD_NUMBER=$3
build_type=$4

if [ -z $WORKSPACE ]; then
	exit -1;
fi

if [ -z $JOB_URL ]; then
	exit -1;
fi

if [ -z $BUILD_NUMBER ]; then
	exit -1;
fi

if [ -z $build_type ]; then
	exit -1;
fi

check_result_path="${WORKSPACE}/check_result.plist"

security unlock-keychain -p h /Users/Shared/Jenkins/Library/Keychains/login.keychain || exit -1

if [[ -e "$check_result_path" ]]; then
	rm -f ${check_result_path}
fi

#${WORKSPACE}/../../SourceChecker ${build_type} ${WORKSPACE} iOS ${check_result_path} || exit -1

sh ${WORKSPACE}/build_script/jenkins_build.sh ${build_type} ${BUILD_NUMBER} || exit -1

#${WORKSPACE}/../../EmailWriter ${WORKSPACE}/output/Build_${BUILD_NUMBER} ${JOB_URL}ws/output/Build_${BUILD_NUMBER} iOS ${check_result_path}
