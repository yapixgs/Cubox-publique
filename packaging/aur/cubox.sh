#!/bin/sh
# Cubox launcher wrapper.
#
# Cubox (like HMCL) stores its data (accounts, mods, Minecraft versions, config)
# in a ".hmcl"/".minecraft" folder inside the *current working directory*. The
# packaged jar lives in a read-only system path, so without a fixed working
# directory the data would land wherever the user happens to run "cubox" from
# (e.g. the build folder) and get fragmented or lost.
#
# Pin a stable per-user data directory so the data is always in the same place.
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/cubox"
mkdir -p "$DATA_DIR"
cd "$DATA_DIR" || exit 1
exec java -jar /usr/share/java/cubox/Cubox.jar "$@"
