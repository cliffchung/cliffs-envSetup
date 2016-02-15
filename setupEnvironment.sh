#!/bin/bash
# copies all config files to the home directory

##################
# Setup variables
##################
ROOT_DIR=~
BACKUP_DIR=~/dot_backup.`date +"%Y-%h-%d_%H.%M.%S"`

DOT_FILES_TO_COPY=`find . -maxdepth 1 -type f -name "dot_*"`
DOT_DIRECTORIES_TO_COPY=`find . -maxdepth 1 -type d \( ! -name "\.*" ! -name "ssh" \)` # exclude the ssh directory

############
# Functions
############

makeBackupDirectory()
{
    # make the backup directory only if it doesn't exist
    if [ ! -d $BACKUP_DIR ]
    then
        echo "Creating directory $BACKUP_DIR"
        mkdir $BACKUP_DIR
    fi
}

copyDotFiles() {
    echo -e "\n"
    echo -e "Copying files"
    echo -e "-------------"

    for file in $DOT_FILES_TO_COPY;
    do
        fileToCopy=$(basename $file)
        newFileName=`echo $fileToCopy | sed "s/dot_/./"`

        if [ -a $ROOT_DIR/$newFileName ]
        then
            makeBackupDirectory
            backupFileName=`echo $newFileName | sed "s/^\./dot_/"`
            echo "backing up $ROOT_DIR/$newFileName to $BACKUP_DIR/$backupFileName"
            cp $ROOT_DIR/$newFileName $BACKUP_DIR/$backupFileName
        fi
        echo "copying $fileToCopy to $ROOT_DIR/$newFileName"
        cp $fileToCopy $ROOT_DIR/$newFileName
    done
}

copyDotDirectories() {
    echo -e "\n"
    echo -e "Copying directories"
    echo -e "-------------------"

    for dir in $DOT_DIRECTORIES_TO_COPY;
    do
        dirToCopy=$(basename $dir)
        newDirName=`echo $dirToCopy | sed "s/dot_/./"`

        if [ -d $ROOT_DIR/$newDirName ]
        then
            makeBackupDirectory
            backupDirName=`echo $newDirName | sed "s/^\./dot_/"`
            echo "backing up $ROOT_DIR/$newDirName to $BACKUP_DIR/$backupDirName"
            cp -r $ROOT_DIR/$newDirName $BACKUP_DIR/$backupDirName
        fi
        echo "copying $dirToCopy to $ROOT_DIR/$newDirName"
        cp -r $dirToCopy $ROOT_DIR/$newDirName
    done
}

setupVundle() {
    mkdir -p ~/.vim/bundle
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    vim +PluginInstall +qall

    # setup YouCompleteMe
    cd ~/.vim/bundle/YouCompleteMe
    ./install.py --clang-completer --omnisharp-completer --gocode-completer \
            --tern-completer --racer-completer
}

################
# Actual script
################

echo "Setting up environment"
echo "======================"

copyDotFiles
copyDotDirectories
setupVundle

echo -e "\n\n"
echo "Finished!"
