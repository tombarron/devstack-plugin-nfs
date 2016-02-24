#

XTRACE=$(set +o | grep xtrace)
#set +o xtrace

NFS_EXPORT_DIR=${NFS_EXPORT_DIR:-/srv/nfs1}
STACK_NFS_CONF=${STACK_NFS_CONF:-/etc/exports.d/stack_nfs}

if is_ubuntu; then
    NFS_SERVICE=nfs-kernel-server
else
    NFS_SERVICE=nfs-server
fi

function install_nfs {
    if is_ubuntu; then
        install_package nfs-common
        install_package nfs-kernel-server
    elif is_fedora; then
        install_package nfs_utils
    fi
}

function configure_nfs {
    sudo mkdir -p $NFS_EXPORT_DIR
    sudo mkdir -p /etc/exports.d

    cat <<EOF | sudo tee ${STACK_NFS_CONF}>/dev/null
$NFS_EXPORT_DIR	localhost(rw)
EOF
}

function start_nfs {
    sudo service $NFS_SERVICE start
}

function stop_nfs {
    sudo service $NFS_SERVICE stop
}

# is_nfs_enabled_for_service() - checks whether the OpenStack service
# specified as an argument is enabled with NFS as its storage backend.
function is_nfs_enabled_for_service {
    local config config_name enabled service
    enabled=1
    service=$1
    # Construct the global variable ENABLE_NFS_.* corresponding to a
    # $service.
    config_name=ENABLE_NFS_$(echo $service | \
                                    tr '[:lower:]' '[:upper:]' | tr '-' '_')
    config=$(eval echo "\$$config_name")

    if (is_service_enabled $service) && [[ $config == 'True' ]]; then
        enabled=0
    fi
    return $enabled
}


if [[ "$1" == "stack" && "$2" == "pre-install" ]]; then
    echo_summary "Installing NFS"
    install_nfs
    echo_summary "Configuring NFS"
    configure_nfs
    echo_summary "Initializing NFS"
    start_nfs
elif [[ "$1" == "stack" && "$2" == "post-config" ]]; then
    if is_nfs_enabled_for_service cinder; then
        true
    fi
fi

if [[ "$1" == "unstack" ]]; then
    stop_nfs
fi

if [[ "$1" == "clean" ]]; then
    #cleanup_nfs
    true
fi


$XTRACE
