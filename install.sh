#!/bin/sh

# Install script for the Gera programming language.
# Requirements:
# - Curl installed
# - JVM 17+ installed
# - C compiler installed
# - Git installed
# - latest release of 'geralang/gerac' has a file 'gerac.jar' compiled with Java 17

c_red=$(echo -e "\033[31m")
c_green=$(echo -e "\033[32m")
c_blue=$(echo -e "\033[34m")
c_reset=$(echo -e "\033[0m")
c_bold=$(echo -e "\033[1m")

# Check that curl is present
if ! command -v "curl" >/dev/null 2>&1; then
    echo "${c_red}Curl could not be found!$c_reset"
    exit 1
fi 

# Find Java at '$GERA_JAVA' or 'java'
java_path=""
if command -v "java" >/dev/null 2>&1; then
    java_path="java"
fi
if command -v "$GERA_JAVA" >/dev/null 2>&1; then
    java_path="$GERA_JAVA"
fi
if [ -z "$java_path" ]; then
    echo "${c_red}Java could not be found!"
    echo "If it is installed, try specifying its path under the 'GERA_JAVA' variable.$c_reset"
    exit 1
fi

# Ensure that Java returns a version 17 or above
java_version=$("$java_path" --version | awk 'match($0, /build.*?\)/) { print substr($0, RSTART+6, RLENGTH-7); exit }')
java_major_version=$(echo "$java_version" | cut -d '.' -f 1)
if [ "$java_major_version" -lt 17 ]; then
    echo "$c_red'$java_path' has version '$java_version', but needs to be Java 16 or later!"
    echo "If it is installed, try specifying its path under the 'GERA_JAVA' variable.$c_reset"
    exit 1
fi

# Find a C compiler at '$GERA_CC', 'cc', 'gcc' or 'clang'
cc_path=""
if command -v "clang" >/dev/null 2>&1; then
    cc_path="clang"
fi
if command -v "gcc" >/dev/null 2>&1; then
    cc_path="gcc"
fi
if command -v "cc" >/dev/null 2>&1; then
    cc_path="cc"
fi
if command -v "$GERA_CC" >/dev/null 2>&1; then
    cc_path="$GERA_CC"
fi
if [ -z "$cc_path" ]; then
    echo "${c_red}No C compiler could be found!"
    echo "If one is installed, try specifying its path under the 'GERA_CC' variable.$c_reset"
    exit 1
fi

# Find a Git implementation at '$GERA_GIT' or 'git'
git_path=""
if command -v "git" >/dev/null 2>&1; then
    git_path="git"
fi
if command -v "$GERA_GIT" >/dev/null 2>&1; then
    git_path="$GERA_GIT"
fi
if [ -z "$git_path" ]; then
    echo "{$c_red}Git could not be found!"
    echo "If it is installed, try specifying its path under the 'GERA_GIT' variable.$c_reset"
    exit 1
fi

# If '~/.gerap' already exists fail
if [ -d "$HOME/.gera" ]; then
    echo "${c_red}A previous partial or full installation of Gera has been detected!"
    echo "'$HOME/.gera' must not exist for the installation to proceed.$c_reset"
    exit 1
fi

# Create '~/.gerap'
echo "${c_green}Creating directory '$HOME/.gera'...$c_reset"
mkdir "$HOME/.gera"
cd "$HOME/.gera"
if [ $? -ne 0 ]; then
    echo "${c_red}Unable to create directory!"
    echo "Stopping installation...$c_reset"
    exit 1
fi

# From now on used when a command fails
abort() {
    echo "${c_red}Stopping installation...$c_reset"
    rm -rf "$HOME/.gera"
    exit 1
}

# Download latest release of 'https://github.com/geralang/gerac'
echo "${c_green}Getting latest release of 'https://github.com/geralang/gerac'...$c_reset"
gerac_url=$(curl -s "https://api.github.com/repos/geralang/gerac/releases/latest" \
    | grep "gerac.jar" \
    | grep "browser_download_url" \
    | cut -d : -f 2,3 \
    | tr -d \" \
    | tr -d " " \
)
curl --progress-bar -L "$gerac_url" -o "./gerac.jar"
if [ $? -ne 0 ]; then
    echo "${c_red}Unable to get the latest release!"
    abort
fi

# Clone 'https://github.com/geralang/gerap' and its dependencies
echo "${c_green}Getting 'https://github.com/geralang/gerap' and its dependencies$c_reset"
do_clone() {
    "$git_path" clone "$1" "$2"
    if [ $? -ne 0 ]; then
        echo "${c_red}Unable to clone '$1'!"
        abort
    fi
}
do_clone "https://github.com/geralang/gerap" "gerap-gh"
do_clone "https://github.com/geralang/std" "std-gh"
do_clone "https://github.com/geralang/ccoredeps" "ccoredeps-gh"
do_clone "https://github.com/typesafeschwalbe/gera-cjson" "gera-cjson-gh"

# Build 'gerap' from source
echo "${c_green}Compiling 'gerap' from source...$c_reset"
"$java_path" -jar "gerac.jar" \
    -m "gerap::cli::main" -t "c" -o "./gerap-gh/gerap.c" \
    $(find "./gerap-gh/src" -type f \( -iname \*.gera -o -iname \*.gem \)) \
    $(find "./std-gh/src" -type f \( -iname \*.gera -o -iname \*.gem \)) \
    $(find "./gera-cjson-gh/src" -type f \( -iname \*.gera -o -iname \*.gem \))
if [ $? -ne 0 ]; then
    echo "${c_red}Unable to compile 'gerap'!"
    abort
fi
"$cc_path" \
    $(find "./std-gh/src-c" -name "*.c") \
    $(find "./gera-cjson-gh/src-c" -name "*.c") \
    "./gerap-gh/gerap.c" \
    "./ccoredeps-gh/coredeps.c" \
    -I "./ccoredeps-gh/" \
    -lm -O3 -o "gerap"
if [ $? -ne 0 ]; then
    echo "${c_red}Unable to compile 'gerap'!"
    abort
fi
echo "${c_green}Successfully compiled 'gerap'!$c_reset"

# Clean up cloned repositories
rm -rf "./gerap-gh"
rm -rf "./std-gh"
rm -rf "./ccoredeps-gh"
rm -rf "./gera-cjson-gh"

# Determine file used for shell configuration
cfg_any="false"
configure_shell() {
    cfg_any="true"
    echo "${c_green}Adding configurations for environment variables to '$1'...$c_reset"
    echo "export PATH=\"\$PATH:$HOME/.gera\"" >> "$1"
    echo "export GERAP_JAVA_PATH=\"$java_path\"" >> "$1"
    echo "export GERAP_GERAC_PATH=\"$HOME/.gera/gerac.jar\"" >> "$1"
    echo "export GERAP_GIT_PATH=\"$git_path\"" >> "$1"
    echo "export GERAP_CC_PATH=\"$cc_path\"" >> "$1"
    source "$1"
}
# configure fish
if [ -e "$HOME/.config/fish/config.fish" ]; then
    configure_shell "$HOME/.config/fish/config.fish"
fi
# configure zsh
if [ -e "$HOME/.zshrc" ]; then
    configure_shell "$HOME/.zshrc"
fi
# configure bash
bash_cfg=""
if [ -e "$HOME/.bash_login" ]; then
    bash_cfg="$HOME/.bash_login"
fi
if [ -e "$HOME/.bash_profile" ]; then
    bash_cfg="$HOME/.bash_profile"
fi
if [ -n "$bash_cfg" ]; then
    configure_shell "$bash_cfg"
fi
# warn if no shell has been configured
if [ "$cfg_any" == "false" ]; then
    echo "${c_red}Warning: no shell was configured!"
    echo "The installation will be completed without anything being configured."
    echo "If this is unintentional, do the following to configure your shell:"
    echo "- Add '$HOME/.gerap/' to the 'PATH' environment variable"
    echo "- Set the 'GERAP_GERAC_PATH' environment variable to '$HOME/.gerap/gerac.jar'$c_reset"
fi

# Done!
echo "${c_green}Done!$c_reset"
echo "${c_bold}Gera has successfully been installed!"
echo "To start using Gera, simply run 'gerap'.$c_reset"
