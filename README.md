# Nanomatch Release Repository

This repository contains environment definitions to install our software and instructions to mirror our repository offline in case you are running our software in an air-gapped setup.
Start off by cloning the repository: `git clone git@github.com:NanomatchGmbH/nanomatch-release.git`. In case we release new versions you can always just `git pull`.

## Versioning

We version our software by year-major\_release\_version-patch\_version. Major releases are always expected to be installed the same environment, i.e. you cannot have 2024.1.1 and 2024.1.2 installed at the same time. Minor version upgrades are kept settings compatible. Unless you have a specific reason always install the newest respective minor version of a major version.
Different major versions can be installed alongside each other. Settings compatibility is not guaranteed between different major versions.

## Installing micromamba (prerequisite for our software).

Please install micromamba by following the automatic install documentation from here: [Micromamba install docs](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html)
Follow the manual installation and move over the file in case of an air-gapped install.

## Installing from online sources

You can list all available install sources by invoking

```
    ./install_environment_helper.sh
```
Copy and paste the resulting command into your shell to download and install the nanomatch environment.

## License server install

Keep in mind that you will need to install our CodeMeter license server component no matter if you have an online or offline install to use the packages.
