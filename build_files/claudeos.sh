#!/bin/bash
# Claude OS image build step. Runs inside the container build, on top of Bazzite.
set -ouex pipefail

BRAND_NAME="Claude OS"
LOGO_SRC="/ctx/branding/logo.png"
LOGO_ICON="claudeos-logo"
KICKOFF_JS="/usr/share/plasma/shells/org.kde.plasma.desktop/contents/updates/claudeos-branding.js"

### 1. Files from system_files/ (cos command, app list, Plasma branding script)
cp -avf /ctx/system_files/. /
chmod 0755 /usr/bin/cos

### 1b. Remote desktop: make sure KDE's RDP server is in the image (used by "cos remote")
if ! rpm -q krdp >/dev/null 2>&1; then
    dnf5 install -y krdp || echo "WARNING: krdp not installed; cos remote will only offer SSH"
fi

### 2. OS name. ID stays "bazzite" so Bazzite's own tooling keeps working.
OS_RELEASE="/usr/lib/os-release"
set_osr() {
    local key="$1" val="$2"
    if grep -q "^${key}=" "$OS_RELEASE"; then
        sed -i "s|^${key}=.*|${key}=${val}|" "$OS_RELEASE"
    else
        echo "${key}=${val}" >>"$OS_RELEASE"
    fi
}
BUILD_ID_VALUE="$(sed -n 's/^BUILD_ID=//p' "$OS_RELEASE" | tr -d '"' | head -1)"
set_osr NAME "\"${BRAND_NAME}\""
set_osr PRETTY_NAME "\"${BRAND_NAME}\""
set_osr DEFAULT_HOSTNAME "\"claudeos\""
set_osr BOOTLOADER_NAME "\"${BRAND_NAME} ${BUILD_ID_VALUE}\""

### 3. Logo: launcher icon, About page, boot splash. Skipped when no logo.png was supplied.
if [[ -f "$LOGO_SRC" ]]; then
    LOGO_OUT="/tmp/${LOGO_ICON}.png"
    if command -v magick >/dev/null 2>&1; then
        magick "$LOGO_SRC" -resize 256x256 "$LOGO_OUT"
    else
        cp "$LOGO_SRC" "$LOGO_OUT"
    fi

    install -Dm0644 "$LOGO_OUT" "/usr/share/icons/hicolor/256x256/apps/${LOGO_ICON}.png"
    install -Dm0644 "$LOGO_OUT" "/usr/share/pixmaps/${LOGO_ICON}.png"
    gtk-update-icon-cache -f /usr/share/icons/hicolor || true
    set_osr LOGO "${LOGO_ICON}"

    # Boot splash: the spinner theme's watermark is what Bazzite brands too
    install -Dm0644 "$LOGO_OUT" /usr/share/plymouth/themes/spinner/watermark.png

    # The splash lives in the initramfs, so rebuild it the way Bazzite's own build does.
    # Built to a temp file first: if dracut fails, the build fails and nothing is published.
    KVER=""
    for dir in /usr/lib/modules/*/; do
        [[ -f "${dir}vmlinuz" ]] && KVER="$(basename "$dir")"
    done
    [[ -n "$KVER" ]] || { echo "No kernel found in /usr/lib/modules"; exit 1; }
    DRACUT_NO_XATTR=1 /usr/bin/dracut \
        --no-hostonly \
        --kver "$KVER" \
        --reproducible \
        --add fido2 \
        -f /tmp/initramfs.new
    install -m0600 /tmp/initramfs.new "/usr/lib/modules/${KVER}/initramfs.img"
else
    echo "No build_files/branding/logo.png: keeping Bazzite's logo and boot splash"
    rm -f "$KICKOFF_JS"
fi
