default:
    @just --list

# Collaborative AI helper for QML and C++ tasks
ai:
    gemini --include-directories ./src,./scripts,./tools

# Robust configuration that skips ccache if not found on the system
configure:
    cmake --preset dev -DCMAKE_CXX_COMPILER_LAUNCHER=$(which ccache 2>/dev/null || echo "")

build: configure
    cmake --build --preset dev

release:
    cmake --preset release
    cmake --build --preset release

test:
    ctest --preset dev

# Run with optional flags: e.g., just run "--debug-geom"
run *args: build
    XDG_DATA_DIRS="$HOME/.local/share:/usr/local/share:/usr/share${XDG_DATA_DIRS:+:${XDG_DATA_DIRS}}" QT_PLUGIN_PATH="/usr/lib/qt6/plugins${QT_PLUGIN_PATH:+:${QT_PLUGIN_PATH}}" ./build/dev/bin/krema {{args}}

format:
    ninja -C build/dev clang-format

clean:
    rm -rf build/

package:
    cd packaging/arch && makepkg -si

# OBS 로컬 빌드 테스트
obs-build-rpm distro="openSUSE_Tumbleweed" arch="x86_64":
    osc build {{distro}} {{arch}} packaging/obs/krema.spec

obs-build-deb distro="Debian_13" arch="x86_64":
    osc build {{distro}} {{arch}} packaging/obs/debian.control

# Install .desktop file for development (KWin Wayland protocol access)
dev-desktop:
    @mkdir -p ~/.local/share/applications
    @sed -e 's|@KDE_INSTALL_FULL_BINDIR@/krema|'$PWD'/build/dev/bin/krema|' \
         -e '/^NoDisplay=/d' \
         src/com.bhyoo.krema.desktop.in > ~/.local/share/applications/com.bhyoo.krema.desktop
    @echo "Installed dev launcher to ~/.local/share/applications/com.bhyoo.krema.desktop"
    @echo "Run: kbuildsycoca6 --noincremental"
    @# Clean up legacy dev desktop files if they exist
    @rm -f ~/.local/share/applications/org.krema.dev.desktop
    @rm -f ~/.local/share/applications/org.krema.desktop

# Remove dev .desktop file
dev-desktop-clean:
    @rm -f ~/.local/share/applications/org.krema.dev.desktop
    @rm -f ~/.local/share/applications/org.krema.desktop
    @rm -f ~/.local/share/applications/com.bhyoo.krema.desktop
    @echo "Removed dev .desktop file"
