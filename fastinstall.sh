# Go to home directory
pushd $HOME

# Check if already installed
if [ -d "zshrc" ]; then
  echo "Already installed."
  exit -1
fi

# Clone repo
git clone "https://github.com/hykilpikonna/zshrc"

# Addline function: add a line to a file if the line doesn't already exist
addline() {
  grep -qxF "$2" "$1" || echo "$2" >> $1
}

# Add lines
addline .zshrc 'SCR="$HOME/zshrc/scripts"'
addline .zshrc '. $SCR/zshrc.sh'

# Source file
. .zshrc

# Return to the previous directory
popd
