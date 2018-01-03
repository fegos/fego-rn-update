#!/bin/bash
#脚本说明：把工程里的文件生成文档
#参数说明：

#-n:companyName
#-p:projectPath
#-d:companyID
#-u:companyURL
#-t:target
#-o:outputPath

#if [ $# -lt 1 ];then
#    echo "Error! There's no param!"
#    exit 1
#fi

companyName="fego";
companyID="fego";
companyURL="http://fe.hhtcex.com";
os="iphoneos";
projectPath="./ios";
outputPath="./help/ios";
target="fego-rn-update";
#os="macosx";

while getopts "n:p:d:u:t:o:" arg 
do
	case $arg in
		n)
			companyName=$OPTARG #公司名称
			;;
		p)
	 		projectPath=$OPTARG #项目路径
			;;
		d)
	 		companyID=$OPTARG #项目id
			;;
		u)
	 		companyURL=$OPTARG #公司URL地址
			;;
		t)
			target=$OPTARG #项目target name	
			;;
		o)
	 		outputPath=$OPTARG #文档的输出路径
			;;
		"?")
			echo "Error! Unknown option $OPTARG"
			exit 2
			;;
		":")
			echo "Error! No argument value for option $OPTARG"
			exit 2
			;;
		*)
			# Should not occur
			echo "Error! Unknown error while processing options"
			exit 2
			;;
	esac
done

# 判断工程路径是否传入
if [ "$projectPath" == "" ];then
	echo '(-p):project path must not null!'
	exit 1
fi

# 判断工程路径是否是正确
if [ ! -d $projectPath ];then
	echo "-p param must be a directory."
	exit 2
fi

# 判断target是否传入
if [ "$target" == "" ];then
	echo '(-t):target name must not null!'
	exit 1
fi

# 判断输出路径是否传入
if [ "$outputPath" == "" ];then
	outputPath=$projectPath/help
fi

# 判断URL是否传入
docset_feed_url=$companyName
if [ "$companyURL" != "" ];then
	docset_feed_url=$companyURL/$companyName
fi

# End constants
/usr/local/bin/appledoc \
--project-name "${target}" \
--project-company "${companyName}" \
--company-id "${companyID}" \
--docset-atom-filename "${companyName}.atom" \
--docset-feed-url "${docset_feed_url}/%DOCSETATOMFILENAME" \
--docset-package-url "${docset_feed_url}/%DOCSETPACKAGEFILENAME" \
--docset-fallback-url "${docset_feed_url}" \
--output "${outputPath}" \
--publish-docset \
--docset-platform-family "${os}" \
--logformat xcode \
--keep-intermediate-files \
--no-repeat-first-par \
--no-warn-invalid-crossref \
--exit-threshold 2 \
"${projectPath}"

echo 'doc output path:'$outputPath
