# Claude OS (Linux) - custom bootc image on top of Bazzite KDE
# Same as the ublue-os/image-template Containerfile, except the build step runs claudeos.sh.

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# Base image: Bazzite desktop (KDE Plasma, AMD/Intel graphics)
FROM ghcr.io/ublue-os/bazzite:stable

# Called through bash so the script works even if its executable bit is lost on upload
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    bash /ctx/claudeos.sh

# Verify final image and contents are correct
RUN bootc container lint
