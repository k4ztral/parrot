#!/data/data/com.termux/files/usr/bin/bash

# Intro Banner
clear
cat << "EOF"
██████╗  █████╗ ██████╗ ██████╗  ██████╗ ████████╗
██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝
██████╔╝███████║██████╔╝██████╔╝██║   ██║   ██║   
██╔═══╝ ██╔══██║██╔═══╝ ██╔═══╝ ██║   ██║   ██║   
██║     ██║  ██║██║     ██║     ╚██████╔╝   ██║   
╚═╝     ╚═╝  ╚═╝╚═╝     ╚═╝      ╚═════╝    ╚═╝   

Parrot OS Installer for Termux
Author: k4tral
EOF

# Get current time
current_time="$(date +"%r")"

# Print banner
printf "\n\n"
echo "Parrot Installation Script"
echo "$(date)"
echo "--------------------------------------------------"

install_parrot() {
    directory="parrot-fs"
    tarball="parrot-rootfs.tar.xz"
    start_script="startparrot.sh"

    # Check existing installation
    if [ -d "$directory" ]; then
        echo -e "\033[38;5;214m[$current_time]\033[0m \033[38;5;227m[WARNING]:\033[0m \033[38;5;87m Parrot already installed, skipping download."
        return
    fi

    # Check required commands
    for cmd in proot wget; do
        if ! command -v $cmd >/dev/null 2>&1; then
            echo -e "\033[38;5;214m[$current_time]\033[0m \033[38;5;203m[ERROR]:\033[0m \033[38;5;87m '$cmd' is not installed."
            exit 1
        fi
    done

    # Download RootFS
    echo -e "\033[38;5;214m[$current_time]\033[0m \033[38;5;83m[INFO]:\033[0m \033[38;5;87m Downloading Parrot rootfs..."
    ARCH=$(dpkg --print-architecture)
    case "$ARCH" in
        aarch64) ARCH=arm64;;
        arm) ARCH=armhf;;
        amd64|x86_64) ARCH=amd64;;
        i*86|x86) ARCH=i386;;
        *)
            echo -e "\033[38;5;214m[$current_time]\033[0m \033[38;5;203m[ERROR]:\033[0m Unknown architecture: $ARCH"
            exit 1;;
    esac

    wget -q "https://github.com/AndronixApp/AndronixOrigin/blob/master/Rootfs/Parrot/${ARCH}/parrot-rootfs-${ARCH}.tar.xz?raw=true" -O "$tarball"
    echo -e "\033[38;5;214m[$current_time]\033[0m \033[38;5;83m[INFO]:\033[0m \033[38;5;87m Download complete."

    # Extract
    mkdir -p "$directory"
    echo -e "\033[38;5;214m[$current_time]\033[0m \033[38;5;83m[INFO]:\033[0m \033[38;5;87m Decompressing Rootfs..."
    proot --link2symlink tar -xJf "$tarball" -C "$directory"

    # Setup bind folder
    mkdir -p parrot-binds

    # Create launcher script
    echo -e "\033[38;5;214m[$current_time]\033[0m \033[38;5;83m[INFO]:\033[0m \033[38;5;87m Creating launcher script..."
    cat > "$start_script" <<-EOF_SCRIPT
#!/bin/bash
cd \$(dirname \$0)
unset LD_PRELOAD
CMD="proot --link2symlink -0 -r $directory"
[ -n "\$(ls -A parrot-binds 2>/dev/null)" ] && for f in parrot-binds/*; do . \$f; done
CMD+=" -b /dev -b /proc -b parrot-fs/root:/dev/shm"

# Uncomment below lines if needed
CMD+=" -b /data/data/com.termux/files/home:/root"
CMD+=" -b /sdcard"

CMD+=" -w /root /usr/bin/env -i HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin TERM=\$TERM LANG=C.UTF-8 /bin/bash --login"
[ -z "\$1" ] && exec \$CMD || \$CMD -c "\$@"
EOF_SCRIPT

    chmod +x "$start_script"
    termux-fix-shebang "$start_script"

    # Cleanup
    echo -e "\033[38;5;214m[$current_time]\033[0m \033[38;5;83m[INFO]:\033[0m \033[38;5;87m Cleaning up..."
    rm -f "$tarball"

    # Fix apt source
    sed -i 's/stable/lts/g' parrot-fs/etc/apt/sources.list

    echo -e "\033[38;5;214m[$current_time]\033[0m \033[38;5;83m[INFO]:\033[0m \033[38;5;87m Installation complete! Launch with ./startparrot.sh"
}

# Main execution
case "$1" in
    -y)
        install_parrot;;
    *)
        read -p "Do you want to install Parrot in Termux? [Y/n]: " response
        case "$response" in
            [Yy]*)
                install_parrot;;
            *)
                echo -e "\033[38;5;214m[$current_time]\033[0m \033[38;5;203m[INFO]:\033[0m \033[38;5;87m Installation aborted.";;
        esac
        ;;
esac
