declare -A directories=(
  ["kayobe"]="$HOME/kayobe-config"
)

function build_kayobe_image() {
  # Build a Kayobe container image.

  # Set base image for kayobe container. Use rocky 9 by default
  export BASE_IMAGE=rockylinux:9
  export USE_PYTHON_312=true

  if [[ "$(sudo docker image ls)" == *"kayobe"* ]]; then
    echo "Image already exists skipping docker build"
  else
    sudo DOCKER_BUILDKIT=1 docker build \
      --network host \
      --build-arg BASE_IMAGE=$BASE_IMAGE \
      --build-arg USE_PYTHON_312=$USE_PYTHON_312 \
      --file ${config_directories[kayobe]}/.automation/docker/kayobe/Dockerfile \
      --tag kayobe:latest \
      ${config_directories[kayobe]}
  fi
}

function activate_kayobe_env () {
  set +u
  source "${config_directories[kayobe]}/kayobe-env" --environment ci-multinode
  set -u
}

function run_sct() {

    activate_kayobe_env

    sct_dir="$HOME/sct-results"

    git -C ${config_directories[kayobe]} submodule init
    git -C ${config_directories[kayobe]} submodule update

    build_kayobe_image

    set +x
    export KAYOBE_AUTOMATION_SSH_PRIVATE_KEY=$(cat ~/.ssh/id_rsa)
    set -x

    export KAYOBE_AUTOMATION_SSH_PRIVATE_KEY_NAME="id_rsa"
    export KAYOBE_CONFIG_PATH=${config_directories[kayobe]}

    if [[ -d $sct_dir ]]; then
        sct_backup=${sct_dir}-$(date +%Y%m%dT%H%M%S)
        echo "Found previous SCT results"
        echo "Moving to $sct_backup"
        mv $sct_dir $sct_backup
    fi

    mkdir $sct_dir

    sudo chmod 0777 $sct_dir

    # Remove any previous sct container
    sudo docker rm sct || true

    sudo -E docker run -t \
        --name sct \
        --network host \
        -v ${config_directories[kayobe]}:/stack/kayobe-automation-env/src/kayobe-config \
        -v $sct_dir:/stack/sct-results \
        -v /home/stack/stackhpc-cloud-tests.sh:/stack/stackhpc-cloud-tests.sh \
        -v /home/stack/vault.password:/stack/vault.password \
        -e KAYOBE_ENVIRONMENT -e KAYOBE_CONFIG_PATH -e KAYOBE_VAULT_PASSWORD -e KAYOBE_AUTOMATION_SSH_PRIVATE_KEY_NAME -e KAYOBE_AUTOMATION_SSH_PRIVATE_KEY \
        kayobe:latest \
        /stack/stackhpc-cloud-tests.sh

    sudo docker logs --follow sct

    # Wait for Kayobe SCT pipeline to complete to ensure artifacts exist.
    sct_rc="$(sudo docker container wait sct)"
    if [[ $sct_rc != "0" ]]; then
        echo "Failed running sct container. Output:"
        sudo docker logs sct
    fi
    sudo docker rm sct

    if [[ ! -f $sct_dir/failed-tests ]]; then
        echo "Unable to find SCT results in $sct_dir/failed-tests"
        return 1
    fi

    if [[ $(wc -l < $sct_dir/failed-tests) -ne 0 ]]; then
        echo "Some SCT tests failed"
        return 1
    fi

    echo "SCT testing successful"

}

function main() {
    if ! run_sct; then
        echo "SCT testing failed."
    fi
}

main
