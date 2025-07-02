# Install Dart SDK (using apt, official Google repo)
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'curl -fsSL https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt-get update
sudo apt-get install -y dart
# Add Dart to PATH
export PATH="$PATH:/usr/lib/dart/bin"
dart pub global activate fvm
# Add FVM to PATH
export PATH="$PATH:$HOME/.pub-cache/bin"
# Install Flutter version from .fvmrc
fvm install
# Get Flutter dependencies
fvm flutter pub get