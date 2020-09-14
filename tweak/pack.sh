CodeSigning="Apple Development: xxxxx (xxxxx)"

# # 当前目录
WorkDir=$(pwd) 
# # build目录
BuildDir="${WorkDir}/build"

rm -rf $BuildDir

# 进入工程目录
cd ..

# 打包
xcodebuild -target 'FLEX' -project "FLEX.xcodeproj" -configuration 'Release' -sdk iphoneos BUILD_DIR="${BuildDir}" clean build;

# 删除无用文件
rm -rf "${BuildDir}/Release-iphoneos/FLEX.framework/Headers"
rm -rf "${BuildDir}/Release-iphoneos/FLEX.framework/Modules"
rm -rf "${BuildDir}/Release-iphoneos/FLEX.framework/PrivateHeaders"
rm "${BuildDir}/Release-iphoneos/FLEX.framework/LICENSE"

# 签名
codesign -fs "${CodeSigning}" "${BuildDir}/Release-iphoneos/FLEX.framework"

# 拷贝到对应路径
if [ -d "${WorkDir}/layout/usr/lib/FLEXLoader/FLEX.framework" ]; then
    rm -rf "${WorkDir}/layout/usr/lib/FLEXLoader/FLEX.framework"
fi
cp -rf "${BuildDir}/Release-iphoneos/FLEX.framework" "${WorkDir}/layout/usr/lib/FLEXLoader"


echo "完成"