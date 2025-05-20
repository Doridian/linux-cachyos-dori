#_build_zfs=yes
#_build_nvidia=yes
#_build_nvidia_open=yes
_processor_opt=zen4

_dori_add_source=(
    'git+https://github.com/amkillam/ryzen_smu.git#commit=0bb95d961664c7a0ac180f849fa16fe7da71922d'
    'git+https://github.com/jetm/mediatek-mt7927-dkms.git#commit=48189cda3eea3de9fd95ecf7d6f4980397df66f0'
)
_dori_add_b2sums=(
    'SKIP'
    'SKIP'
)
for f in ../shared/*; do
    cp -fv "$f" ./
    _dori_add_source+=("$f")
    _dori_add_b2sums+=('SKIP')
done

_dori_pkgbuild_name_hook() {
    pkgbase="${pkgbase}-dori"
    pkgdesc="${pkgdesc} Dori"
}

_dori_build_hook() {
    msg2 "Setting Dori customizations..."

    local hash_algo="$(grep -Po 'CONFIG_MODULE_SIG_HASH="\K[^"]*' "${srcdir}/${_srcname}/.config")"
    local sign_key="${MAKEPKG_TEMPDIR}/signing_key.pem"

    openssl req -new -nodes -utf8 "-${hash_algo}" -days 36500 \
            -batch -x509 -config "${srcdir}/dori-x509.genkey" \
            -outform PEM -out "${sign_key}" -keyout "${sign_key}" -newkey ec -pkeyopt ec_paramgen_curve:secp384r1

    scripts/config --set-str CONFIG_MODULE_SIG_KEY "${sign_key}" -e CONFIG_MODULE_SIG_KEY_TYPE_ECDSA \
                     -e CONFIG_MODULE_SIG_FORCE \
                     -e CONFIG_FB_CON_DECOR \
                     -d DRM_EFIDRM -e DRM_SIMPLEDRM -d DRM_VESADRM \
                     -e CONFIG_SECURITY_LOCKDOWN_LSM_EARLY \
                     -e CONFIG_NVME_CORE -e CONFIG_BLK_DEV_NVME -e CONFIG_NVME_PCI -m CONFIG_ATA -m CONFIG_SATA_AHCI \
                     -e CONFIG_XFS_FS -m CONFIG_EXT4_FS -m CONFIG_BTRFS_FS -e CONFIG_DM_CRYPT -e CONFIG_BLK_DEV_DM -e CONFIG_DM_INIT
}

_dori_pkgbuild_end_hook() {
    source+=("${_dori_add_source[@]}")
    b2sums+=("${_dori_add_b2sums[@]}")
}
