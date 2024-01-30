#!/usr/bin/env python3
import os
import yaml
from pathlib import Path
from typing import Dict, Tuple, List, Any
import hashlib
import requests


_CONDA_FORGE_URL= "https://conda.anaconda.org/"
_NM_REPO_URL = "https://mamba.nanomatch-distribution.de/"

class RedownloadException(Exception):
    pass

def url_to_target_dir(url: str) -> Tuple[Path, str]:
    target_split = url.split("/")
    target_path = Path(target_split[-3])/target_split[-2]
    target_split[-1]
    return target_path, target_split[-1]

def offline_channel_dir() -> Path:
    return Path(__file__).resolve().parent.parent / "offline_channels"

def repo_dir() -> Path:
    return Path(__file__).resolve().parent.parent

def releases_dir() -> Path:
    return Path(__file__).resolve().parent.parent / "releases"

def offline_releases_dir() -> Path:
    return Path(__file__).resolve().parent.parent / "offline_releases"
    
def patch_yml(yml_to_patch: Dict[str, Any], target_path: Path) -> None:
    previous_folder = None
    for entry in yml_to_patch["metadata"]["channels"]:
        if previous_folder is None:
            previous_folder = entry["url"]
            assert previous_folder.startswith("file://"), "Can only patch local offline channels"
            last_slash = previous_folder.rfind("/")
            previous_folder = previous_folder[0:last_slash+1]
            entry["url"] = entry["url"].replace(previous_folder, f"file://{target_path}/")
    assert previous_folder is not None, "Did not find previous_folder"
    for entry in yml_to_patch["package"]:
        entry["url"] = entry["url"].replace(previous_folder, f"file://{target_path}/")


def main():
    for releasefile in offline_releases_dir().glob("*.conda-lock.yml"):
        with releasefile.open('r') as infile:
            release = yaml.safe_load(infile)
            patch_yml(release, offline_channel_dir())
        with releasefile.open("w") as outfile:
            yaml.safe_dump(release, outfile)

if __name__ == '__main__':
    main()
