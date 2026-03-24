#!/usr/bin/env bash
# Portable dotfiles installer — works on macOS and Linux
set -euo pipefail

##################
# Setup variables
##################
ROOT_DIR="${HOME}"
BACKUP_DIR="${ROOT_DIR}/dot_backup.$(date +"%Y-%h-%d_%H.%M.%S")"
BIN_DIR="${ROOT_DIR}/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Darwin) IS_MAC=true;  IS_LINUX=false ;;
    Linux)  IS_MAC=false; IS_LINUX=true  ;;
    *)      echo "Unsupported OS: ${OS}"; exit 1 ;;
esac

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

############
# Helpers
############

info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }

command_exists() { command -v "$1" &> /dev/null; }

# Install a package via the system package manager
pkg_install() {
    local pkg="$1"
    if ${IS_MAC}; then
        if ! brew list "$pkg" &> /dev/null; then
            info "Installing ${pkg} via brew..."
            brew install "$pkg"
        else
            info "${pkg} already installed, skipping"
        fi
    elif ${IS_LINUX}; then
        if ! dpkg -s "$pkg" &> /dev/null 2>&1; then
            info "Installing ${pkg} via apt..."
            sudo apt-get install -y "$pkg"
        else
            info "${pkg} already installed, skipping"
        fi
    fi
}

############
# Functions
############

make_backup_directory() {
    if [[ ! -d "${BACKUP_DIR}" ]]; then
        info "Creating backup directory ${BACKUP_DIR}"
        mkdir -p "${BACKUP_DIR}"
    fi
}

copy_dot_files() {
    echo ""
    info "Copying dotfiles"
    echo "-------------------"

    # Files to skip (not installed as dotfiles)
    local skip_files=("dot_zshrc_custom")

    while IFS= read -r -d '' file; do
        local filename
        filename="$(basename "$file")"
        local new_filename="${filename/dot_/.}"

        # Check skip list
        local skip=false
        for s in "${skip_files[@]}"; do
            if [[ "${filename}" == "${s}" ]]; then
                skip=true
                break
            fi
        done
        ${skip} && continue

        # Backup existing file
        if [[ -e "${ROOT_DIR}/${new_filename}" ]]; then
            make_backup_directory
            local backup_name="${new_filename/#./dot_}"
            info "Backing up ${ROOT_DIR}/${new_filename} -> ${BACKUP_DIR}/${backup_name}"
            cp "${ROOT_DIR}/${new_filename}" "${BACKUP_DIR}/${backup_name}"
        fi

        info "Installing ${filename} -> ${ROOT_DIR}/${new_filename}"
        cp "${file}" "${ROOT_DIR}/${new_filename}"
    done < <(find "${SCRIPT_DIR}" -maxdepth 1 -type f -name "dot_*" -print0)
}

install_homebrew() {
    if ! ${IS_MAC}; then return 0; fi

    if command_exists brew; then
        info "Homebrew already installed, skipping"
        return 0
    fi

    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Ensure brew is on PATH for the rest of this script
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

install_apt_essentials() {
    if ! ${IS_LINUX}; then return 0; fi

    info "Updating apt package list..."
    sudo apt-get update -qq

    local packages=(git curl zsh vim tmux ripgrep fzf xclip)
    for pkg in "${packages[@]}"; do
        pkg_install "$pkg"
    done
}

install_vim() {
    if command_exists vim; then
        info "vim already installed, skipping"
        return 0
    fi
    pkg_install vim
}

install_vim_plug() {
    info "Setting up vim-plug"
    local vim_plug="${ROOT_DIR}/.vim/autoload/plug.vim"

    if [[ -f "${vim_plug}" ]]; then
        info "vim-plug already installed, skipping"
        return 0
    fi

    curl -fLo "${vim_plug}" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    info "Running :PlugInstall..."
    vim +PlugInstall +qall
}

install_oh_my_zsh() {
    info "Setting up oh-my-zsh"
    local omz_dir="${ROOT_DIR}/.oh-my-zsh"

    if [[ -d "${omz_dir}" ]]; then
        info "oh-my-zsh already installed, skipping"
        return 0
    fi

    # RUNZSH=no prevents oh-my-zsh from launching zsh after install
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_zsh_syntax_highlighting() {
    info "Setting up zsh-syntax-highlighting"

    if ${IS_MAC}; then
        if brew list zsh-syntax-highlighting &> /dev/null; then
            info "zsh-syntax-highlighting already installed, skipping"
            return 0
        fi
        brew install zsh-syntax-highlighting
    elif ${IS_LINUX}; then
        local zsh_hl_dir="${ROOT_DIR}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
        if [[ -d "${zsh_hl_dir}" ]]; then
            info "zsh-syntax-highlighting already installed, skipping"
            return 0
        fi
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${zsh_hl_dir}"
    fi
}

install_tmux() {
    if command_exists tmux; then
        info "tmux already installed, skipping"
    else
        pkg_install tmux
    fi

    # Install TPM
    local tpm_dir="${ROOT_DIR}/.tmux/plugins/tpm"
    if [[ -d "${tpm_dir}" ]]; then
        info "TPM already installed, skipping"
        return 0
    fi

    info "Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm "${tpm_dir}"
    info "Run 'prefix + I' inside tmux to install plugins"
}

install_powerline_fonts() {
    info "Setting up powerline fonts"
    local fonts_dir="${BIN_DIR}/powerline_fonts"

    if [[ -d "${fonts_dir}" ]]; then
        info "Powerline fonts already installed, skipping"
        return 0
    fi

    git clone https://github.com/powerline/fonts.git "${fonts_dir}"
    "${fonts_dir}/install.sh"
}

install_ripgrep() {
    if command_exists rg; then
        info "ripgrep already installed, skipping"
        return 0
    fi
    pkg_install ripgrep
}

install_fzf() {
    if command_exists fzf; then
        info "fzf already installed, skipping"
        return 0
    fi

    if ${IS_MAC}; then
        brew install fzf
        "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc
    elif ${IS_LINUX}; then
        pkg_install fzf
    fi
}

set_default_shell() {
    if [[ "${SHELL}" == */zsh ]]; then
        info "Default shell is already zsh, skipping"
        return 0
    fi

    local zsh_path
    zsh_path="$(which zsh)"

    if [[ -z "${zsh_path}" ]]; then
        warn "zsh not found, skipping default shell change"
        return 0
    fi

    # Ensure zsh is in /etc/shells
    if ! grep -q "${zsh_path}" /etc/shells 2>/dev/null; then
        info "Adding ${zsh_path} to /etc/shells"
        echo "${zsh_path}" | sudo tee -a /etc/shells > /dev/null
    fi

    info "Changing default shell to zsh..."
    chsh -s "${zsh_path}"
}

################
# Main
################

echo "=============================="
echo "  Environment Setup"
echo "  OS: ${OS}"
echo "=============================="
echo ""

# Create bin directory
mkdir -p "${BIN_DIR}"

# Install package manager (brew on macOS, update apt on Linux)
install_homebrew
install_apt_essentials

# Install tools
install_vim
install_oh_my_zsh
install_tmux
install_powerline_fonts
install_ripgrep
install_fzf
install_zsh_syntax_highlighting

# Copy dotfiles (do this AFTER tools are installed so our configs take effect)
copy_dot_files

# Install vim plugins (do this AFTER dotfiles are copied so vimrc is in place)
install_vim_plug

# Set zsh as default shell
set_default_shell

echo ""
info "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Edit ~/.gitconfig and set your [user] name and email"
echo "  2. Open a new terminal (or run: source ~/.zshrc)"
echo "  3. Inside tmux, press 'C-a I' to install tmux plugins"
echo "  4. In vim, run :CocInstall coc-clangd (and any other CoC extensions you need)"
