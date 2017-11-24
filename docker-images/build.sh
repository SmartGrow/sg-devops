#!/usr/bin/env bash

ROOT_DIR=$(pwd)

# Iterate over directories trying to find Dockerfile files
DIRECTORIES=()
SUCCESSFUL_ITERATIONS=0
for file in $(pwd)/*; do

	# Check if is a directory
	if [ -d $file ]; then
		DIR=$(basename "$file")

		# Check if directory have a Dockerfile file inside
		for filename in ./$DIR/*; do

			# Check if is a file
			[ ! -f "$filename" ] && continue 
			dir_file=${filename##*/}
			case $dir_file in
				# If directory contains a Dockerfile file add to directories array and increment count
				Dockerfile) DIRECTORIES[$SUCCESSFUL_ITERATIONS]=$DIR; SUCCESSFUL_ITERATIONS=$((SUCCESSFUL_ITERATIONS + 1));;
			esac
		done
	fi
done


# Print directories with Dockerfile for user selection
echo " "
echo "Select one of the following available Images to build"
echo " "

IMAGE_IDX=0
for DIR in ${DIRECTORIES[@]}; do
	echo "  $IMAGE_IDX) $DIR"
	IMAGE_IDX=$((IMAGE_IDX + 1))
done


# Read Image index from user and validate if exists, loop until is valid
echo " "
IMAGE_IDX=
IMAGE_IDX_REGEX='^[0-9]+$'
while true; do
	read -p "Build Image: " IMAGE_IDX
	# If user input is not empty and is a number (regex) and the directory index exists
	if [ -n "${IMAGE_IDX}" ] && [[ $IMAGE_IDX =~ $IMAGE_IDX_REGEX ]] && [ -n "${DIRECTORIES[$IMAGE_IDX]}" ]; then
		break
	else
		echo "Please inform a valid Image index"
	fi
done


# Read Image name from user, if input is empty assume directory name as Image name
read -p "Image name (${DIRECTORIES[$IMAGE_IDX]}): " IMAGE_NAME
if [ -z "${IMAGE_NAME}" ]; then
	IMAGE_NAME=${DIRECTORIES[$IMAGE_IDX]}
fi


# Read Image version from user and validate if it's not empty, loop until is valid
read -p "Image version: " IMAGE_VERSION
if [ -z "${IMAGE_VERSION}" ]; then
	while true; do
		echo "Please inform a valid Image version"
		read -p "Image version: " IMAGE_VERSION
		if [ -n "${IMAGE_VERSION}" ]; then
			break
		fi
	done
fi


# Read from user a flag to tag Image as latest too, assume yes as default (N* or n* for no)
read -p "Tag latest (yes): " TAG_LATEST
if [ -z "${TAG_LATEST}" ]; then
	TAG_LATEST=1
else
	case ${TAG_LATEST^^} in
		N*) TAG_LATEST=0;;
		*) TAG_LATEST=1;;
	esac
fi

# Print images to de build and wait for user confirmation
echo " "
echo "The following Image will be build and tagged"
echo " "
echo "  ${IMAGE_NAME}:${IMAGE_VERSION}"
if [ $TAG_LATEST = 1 ]; then
	echo "  ${IMAGE_NAME}:latest"
fi
echo " "
while true; do
	read -p "Confirm? [yes/no]: " CONFIRM_BUILD
	case ${CONFIRM_BUILD^^} in
		YES) break;;
		NO) exit 0;;
	esac
done

echo " "

cd ${DIRECTORIES[$IMAGE_IDX]}

# Concat images to de built on docker build command format
DOCKER_BUILD_IMAGES_PARAM="-t ${IMAGE_NAME}:${IMAGE_VERSION}"
if [ $TAG_LATEST = 1 ]; then
	DOCKER_BUILD_IMAGES_PARAM="${DOCKER_BUILD_IMAGES_PARAM} -t ${IMAGE_NAME}:latest"
fi


# Build Image
docker build ${DOCKER_BUILD_IMAGES_PARAM} . -f Dockerfile

echo " "

# Print images
docker images -f "reference=${IMAGE_NAME}"

cd $ROOT_DIR