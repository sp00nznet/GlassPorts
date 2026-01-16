#!/bin/bash
#
# GlassPorts Dependency Auto-Installer
# Automatically installs all required build dependencies
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLASSPORTS_ROOT="$(dirname "$SCRIPT_DIR")"

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        OS_VERSION=$DISTRIB_RELEASE
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        OS_VERSION=$(sw_vers -productVersion)
    else
        OS="unknown"
    fi
    echo "$OS"
}

# Install dependencies for Debian/Ubuntu
install_debian() {
    log_info "Installing dependencies for Debian/Ubuntu..."

    sudo apt-get update

    # Core build tools (ncurses handled separately due to version differences)
    sudo apt-get install -y \
        git-core \
        gnupg \
        flex \
        bison \
        build-essential \
        zip \
        unzip \
        curl \
        wget \
        file \
        zlib1g-dev \
        gcc-multilib \
        g++-multilib \
        libc6-dev-i386 \
        x11proto-core-dev \
        libx11-dev \
        lib32z1-dev \
        libgl1-mesa-dev \
        libxml2-utils \
        xsltproc \
        fontconfig \
        imagemagick

    # ncurses - try ncurses6 first (newer distros), fall back to ncurses5
    sudo apt-get install -y libncurses6 libncurses-dev 2>/dev/null || \
        sudo apt-get install -y libncurses5 libncurses5-dev 2>/dev/null || true

    # 32-bit ncurses - try newer package names first
    sudo apt-get install -y lib32ncurses-dev 2>/dev/null || \
        sudo apt-get install -y lib32ncurses5-dev 2>/dev/null || true

    # Python
    sudo apt-get install -y python3 python3-pip python-is-python3 || \
        sudo apt-get install -y python3 python3-pip

    # Java - try multiple versions
    if ! command -v java &> /dev/null; then
        sudo apt-get install -y openjdk-11-jdk || \
        sudo apt-get install -y openjdk-8-jdk || \
        sudo apt-get install -y default-jdk
    fi

    # Additional tools
    sudo apt-get install -y \
        bc \
        bsdmainutils \
        cgpt \
        lzop \
        lunzip \
        lz4 \
        pngcrush \
        schedtool \
        squashfs-tools \
        android-sdk-libsparse-utils \
        2>/dev/null || true

    # For older Ubuntu that doesn't have android-sdk-libsparse-utils
    sudo apt-get install -y android-tools-fsutils 2>/dev/null || true

    log_success "Debian/Ubuntu dependencies installed"
}

# Install dependencies for Fedora/RHEL
install_fedora() {
    log_info "Installing dependencies for Fedora/RHEL..."

    sudo dnf groupinstall -y "Development Tools" "C Development Tools and Libraries"

    sudo dnf install -y \
        git \
        curl \
        wget \
        gnupg \
        flex \
        bison \
        gcc \
        gcc-c++ \
        glibc-devel \
        glibc-devel.i686 \
        zlib-devel \
        ncurses-devel \
        libX11-devel \
        mesa-libGL-devel \
        libxml2 \
        python3 \
        java-11-openjdk-devel \
        zip \
        unzip \
        ImageMagick \
        lz4 \
        bc \
        perl-Digest-SHA

    log_success "Fedora/RHEL dependencies installed"
}

# Install dependencies for Arch Linux
install_arch() {
    log_info "Installing dependencies for Arch Linux..."

    sudo pacman -Syu --noconfirm

    sudo pacman -S --noconfirm --needed \
        git \
        gnupg \
        flex \
        bison \
        base-devel \
        zip \
        unzip \
        curl \
        wget \
        zlib \
        gcc \
        lib32-gcc-libs \
        lib32-zlib \
        ncurses \
        lib32-ncurses \
        libxcrypt-compat \
        libx11 \
        mesa \
        libxml2 \
        python \
        python-pip \
        jdk11-openjdk \
        imagemagick \
        lz4 \
        bc

    log_success "Arch Linux dependencies installed"
}

# Install repo tool
install_repo() {
    log_info "Installing Google repo tool..."

    REPO_PATH="$HOME/bin/repo"
    mkdir -p "$HOME/bin"

    if [ ! -f "$REPO_PATH" ] || [ ! -x "$REPO_PATH" ]; then
        curl -s https://storage.googleapis.com/git-repo-downloads/repo > "$REPO_PATH"
        chmod a+x "$REPO_PATH"
    fi

    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$HOME/bin:$PATH"
    fi

    log_success "Repo tool installed at $REPO_PATH"
}

# Configure git
configure_git() {
    log_info "Configuring git..."

    # Check if git user is configured
    if [ -z "$(git config --global user.email)" ]; then
        log_warning "Git user.email not configured"
        read -p "Enter your email for git: " git_email
        git config --global user.email "$git_email"
    fi

    if [ -z "$(git config --global user.name)" ]; then
        log_warning "Git user.name not configured"
        read -p "Enter your name for git: " git_name
        git config --global user.name "$git_name"
    fi

    # Increase git buffer size for large repos
    git config --global http.postBuffer 1048576000
    git config --global core.compression 9

    log_success "Git configured"
}

# Setup ccache for faster rebuilds
setup_ccache() {
    log_info "Setting up ccache..."

    OS=$(detect_os)
    case $OS in
        ubuntu|debian|linuxmint)
            sudo apt-get install -y ccache
            ;;
        fedora|centos|rhel)
            sudo dnf install -y ccache
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm ccache
            ;;
    esac

    # Configure ccache
    mkdir -p "$HOME/.ccache"
    echo "max_size = 50G" > "$HOME/.ccache/ccache.conf"
    echo "compression = true" >> "$HOME/.ccache/ccache.conf"

    # Add ccache to PATH
    if [[ ":$PATH:" != *":/usr/lib/ccache:"* ]]; then
        echo 'export PATH="/usr/lib/ccache:$PATH"' >> "$HOME/.bashrc"
        echo 'export USE_CCACHE=1' >> "$HOME/.bashrc"
        echo 'export CCACHE_EXEC=/usr/bin/ccache' >> "$HOME/.bashrc"
    fi

    log_success "ccache configured (50GB max)"
}

# Increase system limits for building
increase_limits() {
    log_info "Configuring system limits for building..."

    # Check if we can modify limits
    if [ -w /etc/security/limits.conf ]; then
        # Increase file descriptor limits
        if ! grep -q "# GlassPorts" /etc/security/limits.conf; then
            echo "" | sudo tee -a /etc/security/limits.conf
            echo "# GlassPorts build limits" | sudo tee -a /etc/security/limits.conf
            echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
            echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf
        fi
    fi

    # Increase inotify watches
    if [ -w /etc/sysctl.conf ]; then
        if ! grep -q "fs.inotify.max_user_watches" /etc/sysctl.conf; then
            echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
            sudo sysctl -p 2>/dev/null || true
        fi
    fi

    log_success "System limits configured"
}

# Create swap if needed
setup_swap() {
    log_info "Checking swap space..."

    TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
    SWAP_SIZE=$(free -g | awk '/^Swap:/{print $2}')

    if [ "$TOTAL_MEM" -lt 16 ] && [ "$SWAP_SIZE" -lt 8 ]; then
        log_warning "Low memory detected (${TOTAL_MEM}GB RAM, ${SWAP_SIZE}GB swap)"
        read -p "Create 8GB swap file? (y/n): " create_swap

        if [ "$create_swap" = "y" ]; then
            if [ ! -f /swapfile ]; then
                sudo fallocate -l 8G /swapfile
                sudo chmod 600 /swapfile
                sudo mkswap /swapfile
                sudo swapon /swapfile
                echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
                log_success "8GB swap file created"
            fi
        fi
    else
        log_success "Sufficient memory available (${TOTAL_MEM}GB RAM, ${SWAP_SIZE}GB swap)"
    fi
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."

    local missing=()

    command -v git &>/dev/null || missing+=("git")
    command -v python3 &>/dev/null || missing+=("python3")
    command -v java &>/dev/null || missing+=("java")
    command -v make &>/dev/null || missing+=("make")
    command -v gcc &>/dev/null || missing+=("gcc")
    command -v curl &>/dev/null || missing+=("curl")
    command -v repo &>/dev/null || [ -x "$HOME/bin/repo" ] || missing+=("repo")

    if [ ${#missing[@]} -eq 0 ]; then
        log_success "All dependencies verified!"
        return 0
    else
        log_error "Missing dependencies: ${missing[*]}"
        return 1
    fi
}

# Main installation
main() {
    echo ""
    echo "========================================"
    echo "  GlassPorts Dependency Auto-Installer"
    echo "========================================"
    echo ""

    OS=$(detect_os)
    log_info "Detected OS: $OS"

    case $OS in
        ubuntu|debian|linuxmint|pop)
            install_debian
            ;;
        fedora|centos|rhel)
            install_fedora
            ;;
        arch|manjaro)
            install_arch
            ;;
        *)
            log_error "Unsupported OS: $OS"
            log_info "Please install dependencies manually"
            exit 1
            ;;
    esac

    install_repo
    configure_git
    setup_ccache
    increase_limits
    setup_swap

    echo ""
    verify_installation

    echo ""
    log_success "Dependency installation complete!"
    log_info "Please restart your terminal or run: source ~/.bashrc"
    echo ""
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
