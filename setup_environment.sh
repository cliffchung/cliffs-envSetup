#!/bin/bash
# copies all config files to the home directory

##################
# Setup variables
##################
ROOT_DIR=~
BACKUP_DIR=~/dot_backup.`date +"%Y-%h-%d_%H.%M.%S"`
BIN_DIR=${ROOT_DIR}/bin

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

copy_dot_files() {
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

copy_dot_directories() {
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

setup_vim_plugins() {
    echo "Setting up vim plugins"
    local VIM_PLUG="${ROOT_DIR}/.vim/autoload/plug.vim"

    if [ -f "${VIM_PLUG}" ]; then
        echo "Vim plugins already setup, skipping installation"
        return 0
    fi

    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    vim +PlugInstall +qall
}

install_brew() {
    echo "Setting up homebrew"

    if hash brew 2>/dev/null; then
        echo "Brew already setup, skipping installation"
        return 0
    fi

    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

install_vim() {
    echo "Setting up vim"

    if brew ls --versions vim > /dev/null; then
        echo "vim already setup, skipping installation"
        return 0
    fi

    brew install vim
}

install_oh_my_zsh() {
    echo "Setting up oh-my-zsh"
    local OH_MY_ZSH_DIR="${ROOT_DIR}/.oh-my-zsh"

    if [ -d "${OH_MY_ZSH_DIR}" ]; then
        echo "oh-my-zsh already setup, skipping installation"
        return 0
    fi

    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

    echo "Installing zsh-syntax-highlighting"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
}

install_tmux() {
    echo "Setting up tmux"

    if hash tmux 2>/dev/null; then
        echo "tmux already installed, skipping installation"
        return 0
    fi

    brew install tmux

    local TPM_DIR="~/.tmux/plugins/tpm"
    if [ ! -d ${TPM_DIR} ]; then
        echo "Setting up TPM"
        git clone https://github.com/tmux-plugins/tpm ${TPM_DIR}
    fi
}

install_powerline_fonts() {
    echo "Setting up powerline fonts"
    local FONTS_DIR="${BIN_DIR}/powerline_fonts"

    if [ -d "${FONTS_DIR}" ]; then
        echo "Powerline fonts already setup, skipping installation"
        return 0
    fi

    git clone https://github.com/powerline/fonts.git ${FONTS_DIR}
    ${FONTS_DIR}/install.sh
}

install_rip_grep() {
    echo "Setting up ripgrep"

    if brew ls --versions ripgrep > /dev/null; then
        echo "ripgrep already setup, skipping installation"
        return 0
    fi

    brew install ripgrep
}

install_z() {
    echo "Setting up z"
    local Z_DIR="${BIN_DIR}/z"

    if [ -d "${Z_DIR}" ]; then
        echo "z already setup, skipping installation"
        return 0
    fi

    git clone https://github.com/rupa/z.git ${Z_DIR}
}

install_fzf() {
    echo "Setting up fzf"

    if brew ls --versions fzf > /dev/null; then
        echo "fzf already setup, skipping installation"
        return 0
    fi

    brew install fzf
    $(brew --prefix)/opt/fzf/install
}

################
# Actual script
################

echo "Setting up environment"
echo "======================"

# Setup directories
if [ ! -d "${BIN_DIR}" ]; then
    mkdir ${BIN_DIR}
fi

# Install useful tools first
install_brew
install_vim
install_oh_my_zsh
install_tmux
install_powerline_fonts
install_rip_grep
install_z
install_fzf

setup_vim_plugins

# Do these after installation steps so we have our own configurations
copy_dot_files
copy_dot_directories

echo -e "\n\n"
echo "Finished!"
