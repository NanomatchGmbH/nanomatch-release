# Nanomatch Release Repository

This repository contains environment definitions to install our software and instructions to mirror our repository offline in case you are running our software in an air-gapped setup.
Start off by cloning the repository: `git clone git@github.com:NanomatchGmbH/nanomatch-release.git`. In case we release new versions you can always just `git pull`.

## Versioning

We version our software by year-major\_release\_version-patch\_version. Major releases are always expected to be installed the same environment, i.e. you cannot have 2024.1.1 and 2024.1.2 installed at the same time. Minor version upgrades are kept settings compatible. Unless you have a specific reason always install the newest respective minor version of a major version.
Different major versions can be installed alongside each other. Settings compatibility is not guaranteed between different major versions.

## Installing micromamba (prerequisite for our software).

Please install micromamba by following the automatic install documentation from here: [Micromamba install docs](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html)
In case of an air-gapped install (i.e. when you cannot access our repository from your computational resource), please follow the manual installation instead and move over the file respectively.
During the installation process you will be prompted whether you wish to initialize your shell and conda-forge as a default repo. Choose "yes" in both cases unless you are familiar with this process and prefer a different setup.

## Installing from online sources

You can list all available install sources by invoking

```
./install_environment_helper.sh
```
Copy and paste the resulting command into your shell to download and install the nanomatch environment.

## Adaptations of your environment
During the installation you will be instructed to setup a nanomatch.config file. Check the output, when you activate your environment for the first time in your terminal for details, when you activate your environment for the first time.
```
micromamba activate nmsci-2024.1 # This should produce an output on first activate.
```

## Remark for RHEL8 installs

Due to an [unfortunate choice when packaging libcrypto in rhel8](https://github.com/conda/conda/issues/10241), rhel8 binaries are incompatible with libcrypto contained in our environment. After installing the respective environments please also install
rhel8-ssh-workaround via
```
micromamba activate nmsci-2024.1 # Replace this with the target environment you just installed
micromamba install rhel8_ssh_workaround -c https://mamba.nanomatch-distribution.de/mamba-repo
```
to workaround this behaviour.

## Air-gapped installations

For air-gapped installations, we start on a local machine with connection to the internet. Start by creating a new directory in the *same directory* where you will also host the new environment on your server. This is not the installation directory, but rather the directory you will install from. It can be shared between multiple users. Inside the directory on your local machine, execute `./tools/prepare_airgapped.py`:
```
# On your local machine
mkdir /same/path/as/on/cluster
cd /same/path/as/on/cluster
git clone git@github.com:NanomatchGmbH/nanomatch-release.git
./tools/prepare_airgapped.py
```
You can execute this script multiple times. It will not redownload already downloaded releases. If a new release was released and you updated the repository, you can call the script again and it will only receive new files.
Afterwards transfer the files to your cluster, e.g. with rsync
```
# On your local machine
rsync -av . yourcluster:/same/path/as/on/cluster/
```
On your cluster you can then invoke `./install_environment_helper.sh`, which in addition to the online releases should show the same amount of offline releases available for install:
```
# On your cluster
cd /same/path/as/on/cluster
./install_environment_helper.sh
```

You also need to install the rhel8 ssh workaround (if required) from the local repository contained in this repo:
```
# On the cluster machine (inside the repository)
micromamba activate nmsci-2024.1 # Or the respective environment
micromamba install --override-channels rhel8_ssh_workaround -c `realpath rhel8_workaround_channel`
micromamba deactivate
```

## License server install

Keep in mind that you will need to install our CodeMeter license server component no matter if you have an online or offline install to use the packages. Instructions will shortly be available [here](http://docs.nanomatch.de/technical/technical.html).
