load '../helpers/load'

@test 'factory reset' {
    RD_RAMDISK_SIZE=$((12 * 1024)) # We need more disk to run the Rancher image.
    factory_reset
}

@test 'start container engine' {
    start_container_engine
    wait_for_container_engine
}

@test 'run rancher' {
    local rancher_image="rancher/rancher:$RD_RANCHER_IMAGE_TAG"

    ctrctl pull "$rancher_image"
    ctrctl run --privileged -d --restart=no -p 8080:80 -p 8443:443 --name rancher "$rancher_image"
}

@test 'verify rancher' {
    local max_tries=9
    if [[ -n ${CI:-} ]]; then
        max_tries=30
    fi
    run try --max $max_tries --delay 10 curl --insecure --silent --show-error "https://localhost:8443/dashboard/auth/login"
    assert_success
    assert_output --partial "Rancher Dashboard"
    run ctrctl logs rancher
    assert_success
    assert_output --partial "Bootstrap Password:"
}
