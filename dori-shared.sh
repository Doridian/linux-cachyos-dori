#_build_zfs=yes
#_build_nvidia=yes
#_build_nvidia_open=yes
_processor_opt=zen4

_dori_add_source=(
    'git+https://github.com/amkillam/ryzen_smu.git#commit=21c1e2c51832dccfac64981b345745ce0cccf524'
)
_dori_add_b2sums=(
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
                     -e CONFIG_SECURITY_LOCKDOWN_LSM_EARLY
}

_dori_pkgbuild_end_hook() {
    source+=("${_dori_add_source[@]}")
    b2sums+=("${_dori_add_b2sums[@]}")
}
