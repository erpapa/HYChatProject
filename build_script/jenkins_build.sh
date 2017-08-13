#!/bin/sh

RestorePlistFile()
{
	if [[ ! -z "$origin_bundle_version" ]] && [[ ! -z "$info_plist_path" ]]; then
		/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${origin_bundle_version}" "${info_plist_path}"
	fi

	if [[ ! -z "$info_string_path" ]] && [[  -e "$info_string_path".bak ]]; then
		mv "$info_string_path".bak $info_string_path
	fi
}

#统一fail处理函数
Failed()
{
    echo "Failed: $*"
    RestorePlistFile
    exit -1
}

Build()
{
	mkdir -p ${output_dir}
	
	version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${info_plist_path}")
	origin_bundle_version=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${info_plist_path}")
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${version}.${build_number}" "${info_plist_path}"

	app_name="HYChatProject-${server_env}-${build_type}-${version}.${build_number}"
	app_file_path="${output_dir}/${app_name}.app"
	ipa_file_path="${output_dir}/${app_name}.ipa"
	sym_file_path="${output_dir}/${app_name}.app.dSYM"
    app_archive_path="${output_dir}/${app_name}.archive"

	final_output_dir="${build_root_path}/${app_name}"

	#进入工程目录
	cd "${src_path}"

	#开始编译操作

	echo "Build and Archive Run Target..."


	#"${xcodePath}/xcodebuild" -target "${target}" -configuration "${configuration}" -sdk "${sdk}" clean || Failed "Clean Run Target"
	#"${xcodePath}/xcodebuild" -target "${target}" -configuration "${configuration}" -sdk "${sdk}" CONFIGURATION_BUILD_DIR="${build_output_dir}" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" PROVISIONING_PROFILE_SPECIFIER="${PROVISIONING_PROFILE}" || Failed "Build Run Target"
	"${xcodePath}/xcodebuild" clean -scheme "${scheme}" -target "${target}" -configuration "${configuration}" -sdk "${sdk}" || Failed "Clean Run Target"
	"${xcodePath}/xcodebuild" archive -scheme "${scheme}" -target "${target}" -archivePath "${app_archive_path}" -configuration "${configuration}" -sdk "${sdk}" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" PROVISIONING_PROFILE="${PROVISIONING_PROFILE}" || Failed "Build Run Target"

	#mv "${build_app_file_path}" "${app_file_path}"
	#mv "${build_sym_file_path}" "${sym_file_path}"
	echo "Build and Archive Run Target end"

	if [ ! -d "${output_dir}" ];then
	    Failed "No build directory"
	fi

	#开始打包操作

	#"${xcodePath}/xcrun" -sdk "$sdk" PackageApplication "${app_file_path}" -o "${ipa_file_path}" || Failed "Package ipa"
	"${xcodePath}/xcodebuild" -exportArchive -archivePath "${app_archive_path}" -exportPath "${ipa_file_path}" -exportOptionsPlist "${export_plist_path}"

	if [[ ! -z "$final_output_dir" ]]  && [[ ! -z "$root_path" ]]; then
		rm -rf ${final_output_dir}
	fi

	if [[ ! -z "$build_output_dir" ]]  && [[ ! -z "$root_path" ]]; then
		rm -rf ${build_output_dir}
	fi

	mv "${output_dir}" "${final_output_dir}" || Failed "Rename"

	RestorePlistFile
}

jenkins_build_type=$1 # Test Online Release

if [ -z $jenkins_build_type ]; then
	jenkins_build_type="Release"
fi

build_number=$2

if [ -z $build_number ]; then
	build_number=0
fi

root_path="`dirname $0`/.."
root_path_prefix=${root_path:0:1}
if [[ "$root_path_prefix" != "/" ]]; then
	root_path="`pwd`/${root_path}"
fi
# root_path="`pwd`/.."
xcodePath=/usr/bin

src_path="${root_path}"
cert_path="${root_path}/cert"
comment_file_path="${root_path}/comment.txt"
export_plist_path="${root_path}/build_script/exportPlist.plist"
info_plist_path="${src_path}/HYChatProject/Info.plist"
info_string_path="${src_path}/HYChatProject/zh-Hans.lproj/InfoPlist.strings"

build_root_path="${root_path}/output/Build_${build_number}"
build_output_dir="${build_root_path}/build"
output_dir="${build_root_path}/tmp"
build_app_file_path="${build_output_dir}/HYChatProject.app"
build_sym_file_path="${build_output_dir}/HYChatProject.app.dSYM"

sdk="iphoneos"
scheme="HYChatProject"
target="HYChatProject"

adhoc_pp_uuid=`/usr/libexec/PlistBuddy -c "Print UUID" /dev/stdin <<< $(/usr/bin/security cms -D -i ${cert_path}/adhoc.mobileprovision)`
dis_pp_uuid=`/usr/libexec/PlistBuddy -c "Print UUID" /dev/stdin <<< $(/usr/bin/security cms -D -i ${cert_path}/dis.mobileprovision)`
dev_pp_uuid=`/usr/libexec/PlistBuddy -c "Print UUID" /dev/stdin <<< $(/usr/bin/security cms -D -i ${cert_path}/dev.mobileprovision)`

#删除之前的产出

if [[ ! -z "$build_root_path" ]]  && [[ ! -z "$root_path" ]]; then
	rm -rf ${build_root_path}
fi

mkdir -p ${build_root_path}
cp "${comment_file_path}" "${build_root_path}/comment.txt"

if [[ "$jenkins_build_type" = "Test" ]]; then
	if [[ ! -z "$info_string_path" ]]; then
		sed -i '.bak' "s/洽聊/洽聊测试/g" ${info_string_path}
	fi
	server_env="Test"
	build_type="qa"
	configuration="TestRelease"
	CODE_SIGN_IDENTITY="iPhone Developer: hyplcf@163.com (6QBWM96MK3)"
	PROVISIONING_PROFILE="${dev_pp_uuid}"

	Build || Failed "Test"
fi 

if [[ "$jenkins_build_type" = "Online" ]]; then

	server_env="Online"
	build_type="qa"
	configuration="OnlineRelease"
	CODE_SIGN_IDENTITY="iPhone Developer: hyplcf@163.com (6QBWM96MK3)"
	PROVISIONING_PROFILE="${adhoc_pp_uuid}"

	Build || Failed "Online"
fi

if [[ "$jenkins_build_type" = "Release" ]]; then

	server_env="Online"
	build_type="release"
	configuration="OnlineRelease"
	CODE_SIGN_IDENTITY="iPhone Developer: hyplcf@163.com (6QBWM96MK3)"
	PROVISIONING_PROFILE="${dis_pp_uuid}"

	Build || Failed "Release"
fi

exit 0
