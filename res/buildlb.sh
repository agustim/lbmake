#!/bin/bash -ex

# Being used as a cron job as follows:
# 0 3 * * * root. /etc/profile; /home/repo/buildlb.sh > /var/www/images/logs/buildlb.log 2>&1

GP=/var/www/
IMAGE_PATH=images
WORKSPACE=lbmake
REPOSITORY=https://github.com/agustim/lbmake
IMAGE_NAME=gcodis
IMAGE_EXT=iso
LBIMAGE_NAME=binary.hybrid.iso
LBWORKSPACE=devel
USER=repo
GROUP=repo

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
	cd ${GP}${WORKSPACE} && make clean
}

make_workspace(){
	cd ${GP}${WORKSPACE} && make all	
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
ACTIMG=${GP}${IMAGE_PATH}/unstable/${IMAGE_NAME}.${IMAGE_EXT}
ACTREADME=${GP}${IMAGE_PATH}/unstable/${IMAGE_NAME}.README
BUILDIMG=${GP}${WORKSPACE}/${LBWORKSPACE}/${LBIMAGE_NAME}
OLDIMG=${GP}${IMAGE_PATH}/unstable/old/${IMAGE_NAME}.${TIMEFILE}.${IMAGE_EXT}
OLDREADME=${GP}${IMAGE_PATH}/unstable/old/${IMAGE_NAME}.${TIMEFILE}.README

make_dirs
[ -d "${GP}${WORKSPACE}" ] && clean_workspace
gitpull
make_workspace

if [ -f ${ACTIMG} ]
then
	md5_compare ${ACTIMG} ${BUILDIMG}
	if [ $? -eq 1 ]
	then
		TIMEFILE=$(stat -c %z ${ACTIMG}|sed 's|[- :]||g'|cut -d "." -f 1)
		mv ${ACTIMG} ${OLDIMG}
		mv ${ACTREADME} ${OLDREADME}
	fi
fi
cp ${BUILDIMG} ${ACTIMG}	
make_readme ${ACTIMG} > ${ACTREADME}

chown -R ${USER}:${GROUP} ${GP}${IMAGE_PATH}
