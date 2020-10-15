# Alastria (Quorum) Test Environments Tidy Up Feature Branch; Testnet implementation

This is the branch where the testnet implementation will be upgraded, tested and documented. The resulting work will be merged to the "TidyUp" branch.

# Test Environment Installation:

- **VAGRANT (preferred)**

  - Clone the project
  - Execute `vagrant up`
  - Once it finishes building, you have to perform a `vagrant reload`
  - Then, you can communicate with the Virtual Machine through `vagrant ssh` command
  - Notes:

    You can change the parameters of the virtual machine in `vagrant/config/vconfig/vagrant-local-example.yml` BEFORE the first execution. The parameters are self-explanatory. The recommended parameters are the ones already in place.

    You require to have installed Virtualbox and Vagrant into your machine.

    If the `vagrant up` command stops shortly after first execution and there is not any error message, just keep executing it. Vagrant is installing its required plugins.

- **Ubuntu 20**

  - Install necessary packages: `$apt-get install -y npm software-properties-common unzip wget git make gcc libsodium-dev build-essential libdb-dev zlib1g-dev libtinfo-dev libtinfo5 sysvbanner psmisc libleveldb-dev libdb5.3-dev dnsutils sudo netcat nodejs docker docker-compose npm install -g truffle@5.1.48`

  - Clone this project

  - Navigate to the testnet folder: `cd test-environment/infrastructure/testnet`

  - Execute the bootstrap script: `sudo bash bin/bootstrap.sh`

  - Now you can open up a parallel terminal and clone the cbx-quorum-explorer project: `git clone https://github.com/Councilbox/cbx-quorum-explorer.git`

  - Navigate to the newly cloned directory: `cd cbx-quorum-explorer`

  - Create a new folder, that the explorer will use to store its database. It can be wherever you want; we will assume it is the following: `mkdir mongo_data_dir`

  - Modify the docker-compose.yaml.template, that does not work, with the command: `curl https://gist.githubusercontent.com/brunneis/f6ffc3898635f2ab5718f8ab0f5f6905/raw/83a39419fea1ac6acc53230d83320f337d9df3ad/docker-compose.yaml.template > docker-compose.yaml.template`

  - Change the env.sh file with these parameters (see explanation below, in the "notes" section):

  ```
  QUORUM_ENDPOINTS=localhost:22000,localhost:22001,localhost:22002,localhost:22003,localhost:22005
  ENABLE_SSL=false
  EXPLORER_PORT=8888
  API_DOMAIN=localhost
  MONGO_DATA_DIR=/path/to/mongo_data_dir
  API_PORT=
  EXTERNAL_API_PORT=
  WEBAPP_VERSION=cbx-alastria-telsius
  ```

  - Build the docker scripts: `bash build.sh`

  - In the terminal where the bootstrap script was running, once it finishes, bring the node up: `sudo bash bin/start_network.sh`

  - Execute the docker container construction processes in the other terminal: `bash launch.sh`

  - Check localhost:22000 to see the block explorer running.

  - You can execute `sudo bash bin/start_ethstats.sh` to see ethstats. Open localhost:3000 in a browser.

  <!-- - Geth 1.9.5. Recommended procedure: -- IS INSTALLED ALONG QUORUM
    ```
    cd /usr/local
    git clone https://github.com/ethereum/go-ethereum.git
    PATH="$PATH:/usr/local/go-ethereum"
    cd go-ethereum
    git checkout v1.9.5
    make geth
    ``` -->

# CHANGELOG

Note that this has been developed in Ubuntu 20.04 LTS. If neccessary it will be ported to Ubuntu 18.04 LTS.

- **infrastructure/testnet/bin/bootstrap.sh**

  - Added call to the bootstrap.sh of the repository of alastria-node, copied into `infrastructure/testnet/bin`
  - Changed variable definition: `"${pwd}"` => `"$(pwd)"`
  - Commented out the package installation for the time being, while development takes place. Possibly it will be removed or at least outsourced.
  - The script SHOULD be run using `sudo bash bin/bootstrap.sh` so it executes all the functions as it should.

- **infrastructure/testnet/bin/bootstrap-alastria-node.sh**

  - This is the alastria-node repository bootstrap script. Copied into this one for two reasons: the first is to reduce the time of execution at least while developing. The main reason, however, is to fix some issues with that script: this is a test environment and is meant for testing but also for enhancing the current working environment and more importantly, to have it working properly without strange workarounds. That said, it will remain as close as possible to the real environment (paths, software versions when possible, etc).
  - Changed all occurrences of `$HOME` beacuse it defaults to `/root` as soon as the first "superuser" function gets executed: `$HOME` => `$(pwd)`
  - Commented out last command of GOPATH function because it stopped script execution: `exec "$BASH"`
  - Commented out the package installation for the time being, while development takes place. Possibly it will be removed or at least outsourced.
  - Changed the `fixconstellation` function so it works standalone:

    ```
    if [ $sodiumrel = "notfound" ]
      then
        installedpath=$(whereis libsodium 2>/dev/null | grep libsodium.so |  cut -d ' ' -f2 | sed 's/libsodium.so//' | tr -d '[:space:]')
        if [[ -d $installedpath ]]
        then
          echo "The libsodium package version in the distribution mismatches the one linked in constellation. Symlinking"
          superuser ln -s $installedpath/libsodium.so /lib64/libsodium.so.18
          superuser cp $installedpath/libsodium.so $installedpath/libsodium.so.18
          superuser cp $installedpath/libleveldb.so $installedpath/libleveldb.so.1
          superuser ldconfig
        else
    ```

  - Changed Quorum version to Consensys 2.6 instead of Alastria 2.2 (this is an upcoming change to Alastria-node environment.

- **infrastructure/testnet/bin/start-node.sh**

  - Added the `env PRIVATE_CONFIG=ignore` modifier in the node initialization. This is due to the Quorum update and a temporary change just to have the script working properly.

- **TBD**:

  - Have a look at some potential problems of `set -e` command and maybe change all its occurrences:
    https://stackoverflow.com/questions/19622198/what-does-set-e-mean-in-a-bash-script
    https://stackoverflow.com/questions/3474526/stop-on-first-error
    http://mywiki.wooledge.org/BashFAQ/105
  - Consider to avoid the installation of packages or at least the apt-get-upgrade command.
  - **IMPORTANT**: Consider to lock package versions so there are no issues with that in the future. In the case of a container like docker or a Vagrant installation, the packages should already be installed. This can potentially break the scripts and lead to security and/or performance issues.

- **Other changes and notes**:

  - In Ubuntu 20 it has been mandatory to install libtinfo5 because it's the version used by Constellation