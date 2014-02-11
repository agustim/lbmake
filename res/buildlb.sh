#!/bin/sh
GP=$(pwd)/
IMAGE_PATH=images
WORKSPACE=lbmake
REPOSITORY=https://github.com/agustim/lbmake
IMAGE_NAME=gcodis
IMAGE_EXT=iso
LBIMAGE_NAME=binary.hybrid.iso
LBWORKSPACE=devel

make_dirs(){
	mkdir -p ${GP}${IMAGE_PATH}/unstable
	mkdir -p ${GP}${IMAGE_PATH}/unstable/old
}

gitpull(){
	# If not exist WORKSPACE/.git need clone
	if [ ! -d "${GP}${WORKSPACE}/.git" ];
	then
		git clone ${REPOSITORY} ${GP}${WORKSPACE}
	else
		git --git-dir=${GP}${WORKSPACE}/.git pull
	fi
}	

gitversion(){
	echo $(git --git-dir=${GP}${WORKSPACE}/.git rev-parse --short HEAD)
}

clean_workspace(){
	cd ${GP}${WORKSPACE} && sudo make clean
}

make_workspace(){
	cd ${GP}${WORKSPACE} && sudo make all	
}

make_readme(){
	echo "Automatic image generation"
	echo "--------------------------"
	echo "${IMAGE_NAME}.${IMAGE_EXT} (${MD5NF})\n"
	echo "Packages:"
	cd ${GP}${WORKSPACE} && make describe
	echo "\nBuilder: ${REPOSITORY} (hash:$(gitversion))"

}

md5_compare(){
	local file1
	
	file1=$(md5sum $1|cut -d " " -f 1)
	MD5NF=$(md5sum $2|cut -d " " -f 1)

	if [ "$file1" = "$MD5NF" ]
	then
		return 0
	else 
		return 1
	fi  
}

# Make image

make_dirs
[ -d "${GP}${WORKSPACE}" ] && clean_workspace
gitpull
make_workspace
if [ -f ${GP}${IMAGE_PATH}/unstable/${IMAGE_NAME}.${IMAGE_EXT} ]
then
	md5_compare ${GP}${IMAGE_PATH}/unstable/${IMAGE_NAME}.${IMAGE_EXT} ${GP}${WORKSPACE}/${LBWORKSPACE}/${LBIMAGE_NAME}
	if [ $? -eq 1 ]
	then
		TIMEFILE=$(stat -c %z ${GP}${IMAGE_PATH}/unstable/${IMAGE_NAME}.${IMAGE_EXT}|sed 's|[- :]||g'|cut -d "." -f 1)
		mv ${GP}${IMAGE_PATH}/unstable/${IMAGE_NAME}.${IMAGE_EXT} ${GP}${IMAGE_PATH}/unstable/old/${IMAGE_NAME}.${TIMEFILE}.${IMAGE_EXT}
		mv ${GP}${IMAGE_PATH}/unstable/${IMAGE_NAME}.README ${GP}${IMAGE_PATH}/unstable/old/${IMAGE_NAME}.${TIMEFILE}.README
	fi
fi
cp ${GP}${WORKSPACE}/${LBWORKSPACE}/${LBIMAGE_NAME} ${GP}${IMAGE_PATH}/unstable/${IMAGE_NAME}.${IMAGE_EXT}	
make_readme ${GP}${IMAGE_PATH}/unstable/${IMAGE_NAME}.${IMAGE_EXT} > ${GP}${IMAGE_PATH}/unstable/${IMAGE_NAME}.README
