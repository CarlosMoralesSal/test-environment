#!/bin/bash

function checkgo {
  if ( ! type "go" > /dev/null 2>&1 )
  then
    installgo
  else
    GOREL="go1.9.5.linux-amd64.tar.gz"
    V1=$(go version | grep -oP '\d+(?:\.\d+)+')
    V2=$(echo $GOREL | grep -oP '\d+(?:\.\d+)+')
    nV1=$(echo $V1 | sed 's/\.//g')
    nV2=$(echo $V2 | sed 's/\.//g')
    if (( $nV1 >= $nV2 )); then
      echo "Your current version of golang ($V1) is higher than the required to run Alastria nodes ($V2), so we will use it"
    else
      installgo
    fi
  fi
}

function installgo {
  GOREL="go1.9.5.linux-amd64.tar.gz"
  echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/bash.bashrc
  echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc
  echo "Installing GO"
  wget "https://storage.googleapis.com/golang/$GOREL" -O /tmp/$GOREL
  pushd /tmp
  tar xvzf $GOREL
  sudo rm -rf /usr/local/go
  sudo mv /tmp/go /usr/local/go
  popd
  rm -rf /tmp/go
}

function installconstellation {
  constellationrel="constellation-0.3.2-ubuntu1604"
  if ( ! type "constellation-node" > /dev/null 2>&1 )
  then
    echo "Installing Constellation"
    wget https://github.com/ConsenSys/constellation/releases/download/v0.3.2/$constellationrel.tar.xz -O /tmp/$constellationrel.tar.xz
    pushd /tmp
    unxz $constellationrel.tar.xz
    tar -xf $constellationrel.tar
    sudo cp $constellationrel/constellation-node /usr/local/bin
    sudo chmod 0755 /usr/local/bin/constellation-node
    sudo rm -rf $constellationrel.tar.xz $constellationrel.tar $constellationrel
    popd
  fi
    fixconstellation
}

function fixconstellation {
  #Ubuntu 18 or 20 does not provide the libsodium18 package nor a link for it. So it is neccessary to mock the installation. Libsodium 18 was packed in Ubuntu 16, which is the version of Constellation.
  alreadyinstalled=$(ls /usr/lib/x86_64-linux-gnu/ | grep libsodium.so.18)
  OS=$(cat /etc/issue | grep -Po "(18|20)")
  if [ $OS = "20" ]
    sudo cp /usr/lib/x86_64-linux-gnu/libsodium.so.23.3.0 /usr/lib/x86_64-linux-gnu/libsodium.so.18
    sudo ln -s /usr/lib/x86_64-linux-gnu/libsodium.so.18 /lib64/libsodium.so.18
    sudo cp /usr/lib/x86_64-linux-gnu/libleveldb.so.1.22.0 /usr/lib/x86_64-linux-gnu/libleveldb.so.1
    sudo ldconfig
  else if [ $OS = "18" ]
    sudo cp /usr/lib/x86_64-linux-gnu/libsodium.so.23.1.0 /usr/lib/x86_64-linux-gnu/libsodium.so.18
    sudo ln -s /usr/lib/x86_64-linux-gnu/libsodium.so.18 /lib64/libsodium.so.18
    sudo ldconfig
  else if [ $alreadyinstalled = "libsodium.so.18" ]
    echo "libsodium.18 already fixed. Skipping"
  else
    echo "OS not supported. Please, perform this process manually and retry."
  fi
  #Checking if fix has worked:
  if [[ $alreadyinstalled != "libsodium.so.18" ]]
  then
    echo "WARNING: Not able to fix libsodium install. Please, perform this process manually and retry."
    exit
  fi
}

function installquorum {
  if ( ! type "geth" > /dev/null 2>&1 )
  then
    echo "Installing QUORUM"
    pushd /tmp
    git clone https://github.com/ConsenSys/quorum.git
    cd quorum
    git checkout 9339be03f9119ee488b05cf087d103da7e68f053 #2.6.0
    make all
    sudo cp build/bin/geth /usr/local/bin
    sudo cp build/bin/bootnode /usr/local/bin
    popd
    rm -rf /tmp/quorum
  fi
}

function gopath {
# Manage GOROOT variable
  if [[ -z "$GOROOT" ]]; then
    echo "[*] Trying default GOROOT. If the script fails please run $(pwd)/alastria-node/bootstrap.sh or configure GOROOT correctly"
    echo 'export GOROOT=/usr/local/go' >> /root/.bashrc
    echo 'export GOROOT=/usr/local/go' >> /etc/bash.bashrc
    echo 'export GOPATH=$(pwd)/alastria/workspace' >> /root/.bashrc
    echo 'export GOPATH=$(pwd)/alastria/workspace' >> /etc/bash.bashrc
    echo 'export PATH=$GOROOT/bin:$GOPATH/bin:$PATH' >> /root/.bashrc
    echo 'export PATH=$GOROOT/bin:$GOPATH/bin:$PATH' >> /etc/bash.bashrc
    export GOROOT=/usr/local/go
    export GOPATH=$(pwd)/alastria/workspace
    export PATH=$GOROOT/bin:$GOPATH/bin:$PATH
    echo "[*] GOROOT = $GOROOT, GOPATH = $GOPATH"
    mkdir -p "$GOPATH"/{bin,src}
  fi
}

function installalastria {
  set -e
  checkgo
  installconstellation
  installquorum
  gopath
  set +e
}

function uninstallalastria {
  sudo rm -rf /usr/local/go 2>/dev/null
  sudo rm /usr/local/bin/constellation-node 2>/dev/null
  sudo rm /usr/local/bin/geth 2>/dev/null
  rm -rf /tmp/* 2>/dev/null
}

if ( [ "uninstall" == "$1" ] )
then
  uninstallalastria
elif ( [ "reinstall" == "$1" ] )
then
   uninstallalastria
   installalastria
else
  installalastria
fi