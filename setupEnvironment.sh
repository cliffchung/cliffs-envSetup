#!/bin/bash
# copies all config files to the home directory

# find the files but exclude hidden ones
FILES_TO_COPY=`find . -maxdepth 1 -type f \( ! -name "\.*" \)`
DIRECTORIES_TO_COPY=`find . -maxdepth 1 -type d \( ! -name "\.*" ! -name "ssh" \)` # exclude the ssh directory

echo "Setting up environment"
echo "======================"

echo -e "Copying files\n"
for file in $FILES_TO_COPY;
do
    fileToCopy=$(basename $file)
    newFileName=`echo $fileToCopy | sed "s/dot_/./"`
    echo "copying $fileToCopy to $newFileName"
    cp $fileToCopy ~/$newFileName
done

echo -e "\n\n"
echo "Copying directories"

for dir in $DIRECTORIES_TO_COPY;
do
    dirToCopy=$(basename $dir)
    newDirName=`echo $dirToCopy | sed "s/dot_/./"`
    echo "copying $dirToCopy to ~/$newDirName"
    cp -r $dirToCopy ~/$newDirName
done

echo -e "\n\n"
echo "Finished!"
