# Nanomatch Release Repository

This repository contains environment definitions to install our software and instructions to mirror our repository offline in case you are running our software in an air-gapped setup.
Start off by cloning the repository: `git clone https://github.com/NanomatchGmbH/nanomatch-release.git`. In case we release new versions you can always just `git pull`.

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
### Configuration file
During the installation you will be instructed to setup a configuration file `.nanomatch.config`. Afterwards, you can activate the environment with the following command: 
```
micromamba activate nmsci-2024.1 # This should produce an output on first activate.
```
**Check the output for details, when you activate your environment for the first time.** 

### License Server
Depending on your infrastructure and the setup of the license, you may need to adapt NM_LICENSE_SERVER in the .nanomatch.config file. 

If you are running CodeMeter runtime on your computational resource, set

```
export NM_LICENSE_SERVER=localhost
```
If you are running CodeMeter Runtime on a different machine in your network, set NM_LICENSE_SERVER to the IP address of the machine where CodeMeter Runtime is running.

Details on the license usage are available in our [documentation](http://docs.nanomatch.de/technical/licensing/licensing.html).


### Scratch 
Open the .nanomatch.config file (typically located in your home directory) and adapt the scratch directory, e. g. 
```
export SCRATCH=/scratch/
```
Note the comments in the template config file for chosing a reasonable scratch directory. Ask your system admin in case of doubts. 

### Turbomole
In case you are using Turbomole as DFT engine, you need to install Turbomole and include the directory in your config file, e.g.:
```
export TURBODIR=/shared/software/TURBOMOLE
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
For air-gapped installations, we start on a local machine with connection to the internet, download required files, copy them to the cluster and execute there. This needs to be done for both the installation of micromamba and the nanomatch software.
### Air-gapped micromamba installation
On your local machine in a directory of your choice, run one of the following commands:
```
# On your local machine
# Linux Intel (x86_64):
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
```
This will create a directory `bin`. Copy this directory to your server, login to your server and, in the respective directory, execute the following command:
```
./bin/micromamba shell init -s bash -p /path/of/your/choice
```
**Note**: Make sure to remember or save the `/path/of/your/choice`: This is the directory where the nanomatch software will later be accessible by the SimStack client.

**Note**: Source your `~/.bashrc` or log out and back onto your cluster in order to access micromamba.

Further information is available in the [Micromamba install docs](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html)

### Air-gapped installation of the nanomatch software
For air-gapped installations of the nanomatch software, we again start on a non air-gapped local machine and clone this repository.
Inside the directory on your local machine, execute `./tools/prepare_airgapped.py`:

```
# On your local machine
git clone git@github.com:NanomatchGmbH/nanomatch-release.git
cd nanomatch-release
./tools/prepare_airgapped.py
```
You can execute this script multiple times. It will not redownload already downloaded releases. If a new release was released and you updated the repository (via `git pull`), you can call the script again and it will only receive new files.
Afterwards transfer the files to your cluster, e.g. with rsync
```
# On your local machine
cd ..
rsync -av nanomatch-release yourcluster:/path/you/will/install/from
# /path/you/will/install/from is not the nanomatch install directory but rather a local copy of our install repository you will start the install from.
```
Log onto your cluster and cd to the directory where your files where copied, and into its subfolder "nanomatch-release". You can then invoke first `./tools/relocate_offline.py` followed by `./install_environment_helper.sh`, which in addition to the online releases should show the same amount of offline releases available for install:
```
# On your cluster
cd /path/you/will/install/from/nanomatch-release
./tools/relocate_offline.py
./install_environment_helper.sh
```
Install the offline nm-sci environment and the offline simstackserver environments using the commands provided by this script.
If required, subsequently install the rhel8 ssh workaround from the local repository contained in this repo using:
```
# On the cluster machine (inside the repository)
micromamba activate nmsci-2024.1 # Or the respective environment
micromamba install --override-channels rhel8_ssh_workaround -c `realpath rhel8_workaround_channel`
micromamba deactivate
```

## License server install

Keep in mind that you will need to install our CodeMeter license server component no matter if you have an online or offline install to use the packages. Instructions will shortly be available [here](http://docs.nanomatch.de/technical/technical.html).
