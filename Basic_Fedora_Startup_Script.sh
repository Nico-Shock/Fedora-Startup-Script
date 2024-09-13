#!/bin/bash

set -e

DNF_CONFIG_FILE="/etc/dnf/dnf.conf"
MAX_PARALLEL="max_parallel_downloads=20"
FASTEST_MIRROR="fastestmirror=True"
DNF_PACKAGES="kernel-devel vlc git git-core p7zip fastfetch gnome-tweaks"
REMOVE_PACKAGES="gnome-contacts gnome-maps mediawriter totem simple-scan gnome-boxes gnome-user-docs rhythmbox evince eog gnome-photos gnome-documents gnome-initial-setup yelp winhelp32 dosbox winehelp fedora-release-notes firefox gnome-characters gnome-logs fonts-tweak-tool timeshift epiphany gnome-weather cheese pavucontrol qt5-settings"

log() {
    echo "[INFO] $1"
}

configure_dnf() {
    log "Konfiguriere DNF"
    grep -q "^$MAX_PARALLEL" $DNF_CONFIG_FILE || echo "$MAX_PARALLEL" | sudo tee -a $DNF_CONFIG_FILE > /dev/null
    grep -q "^$FASTEST_MIRROR" $DNF_CONFIG_FILE || echo "$FASTEST_MIRROR" | sudo tee -a $DNF_CONFIG_FILE > /dev/null
}

upgrade_system_version() {
    local releasever=$1
    local upgrade_flag_file="$HOME/.system_upgrade_done"

    if [ -f "$upgrade_flag_file" ]; then
        log "System wurde bereits auf Version $releasever aktualisiert. Überspringe diesen Schritt."
    else
        if sudo dnf system-upgrade download --releasever=$releasever -y; then
            touch "$upgrade_flag_file"
            log "System-Upgrade auf Version $releasever geplant. Ein Neustart wird durchgeführt, um das Upgrade abzuschließen."
            return 0
        else
            log "System-Upgrade auf Version $releasever fehlgeschlagen."
            return 1
        fi
    fi
}

add_repositories() {
    log "Füge Repositories hinzu"
    sudo dnf install -y \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
}

install_flatpak() {
    log "Installiere Flatpak und füge Flathub hinzu"
    sudo dnf install -y flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

install_dnf_packages() {
    log "Installiere DNF-Pakete"
    sudo dnf install -y $DNF_PACKAGES
}

remove_unnecessary_packages() {
    log "Entferne unerwünschte Pakete"
    sudo dnf remove -y $REMOVE_PACKAGES
    sudo dnf clean all
    sudo dnf clean packages
}

main() {
    configure_dnf
    add_repositories
    install_flatpak
    install_dnf_packages
    remove_unnecessary_packages
    upgrade_system_version 40
}

main
