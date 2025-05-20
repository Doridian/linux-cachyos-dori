#_build_zfs=yes
#_build_nvidia=yes
#_build_nvidia_open=yes
_processor_opt=zen4

_dori_add_source=(
    'vmware-host-modules::git+https://github.com/philipl/vmware-host-modules.git#commit=5c80f597017882f76e9c7ffd48a292a4b7c860fe'
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

_package-vmware-host-modules() {
    pkgdesc="vmware modules for the ${pkgbase} kernel"
    depends=("$pkgbase=$_kernver")
    provides=(vmware-host-modules-dkms vmware-host-modules)
    conflicts=(vmware-host-modules-dkms vmware-host-modules)
    license=('GPL2')

    cd "${_srcname}"
    local modulesdir="$pkgdir/usr/lib/modules/$(<version)/misc"

    cd "${srcdir}/vmware-host-modules"
    install -dm755 "${modulesdir}"
    install -m644 */*.ko "${modulesdir}"

    _sign_modules "${modulesdir}"
    find "$pkgdir" -name '*.ko' -exec zstd --rm -19 -T0 {} +
}
