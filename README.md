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
During the installation you will be instructed to setup a nanomatch.config file. Check the output of the installation in your terminal for details.

## Remark for RHEL8 installs

Due to an [unfortunate choice when packaging libcrypto in rhel8](https://github.com/conda/conda/issues/10241), rhel8 binaries are incompatible with libcrypto contained in our environment. After installing the respective environments please also install
rhel8-ssh-workaround via
```
    micromamba activate nmsci-2024.1 # Replace this with the target environment you just installed
    micromamba install rhel8_ssh_workaround -c https://mamba.nanomatch-distribution.de/mamba-repo
```
to workaround this behaviour.

## License server install

Keep in mind that you will need to install our CodeMeter license server component no matter if you have an online or offline install to use the packages. Instructions will shortly be available [here](http://docs.nanomatch.de/technical/technical.html).
