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
    return Path(__file__).parent.parent / "offline_channels"

def repo_dir() -> Path:
    return Path(__file__).parent.parent

def releases_dir() -> Path:
    return Path(__file__).parent.parent / "releases"

def offline_releases_dir() -> Path:
    return Path(__file__).parent.parent / "offline_releases"
    
def get_url_and_hash_list(yml: Dict[str, Any]) -> List[Tuple[str, str]]:
    returnlist = []
    for entry in yml["package"]:
        url = entry["url"]
        sha256 = entry["hash"]["sha256"]
        returnlist.append((url, sha256))
    return returnlist
        
def hash_compare(filepath, sha256):
    with filepath.open("rb") as f:
        digest = hashlib.file_digest(f, "sha256")
        if digest.hexdigest() != sha256:
            print("Downloaded file does not match referenced file. Will remove and redownload.")
            filepath.unlink()
        else:
            print(f"{filepath} exists already and has correct hash. Will not redownload.")

def download_url_to_target(url: str, target_path = Path) -> None:
    response = requests.get(url, stream=True)
    with target_path.open('wb') as output:
        output.write(response.content)

def download_list_to_offline_repos(file_and_hash_list: List[Tuple[str,str]]) -> None:
    for url, filehash in file_and_hash_list:
        target_path, filename = url_to_target_dir(url)
        abs_dir = offline_channel_dir()/ target_path 
        abs_target = abs_dir / filename
        print(f"Downloading {url} to {abs_target}")
        os.makedirs(abs_dir, exist_ok = True)
        if abs_target.exists():
            hash_compare(abs_target, filehash)
        if not abs_target.exists():
            download_url_to_target(url, abs_target)

def patch_yml(url_replacement_dict: Dict[str,Path], yml_to_patch: Dict[str, Any]) -> None:
    for entry in yml_to_patch["metadata"]["channels"]:
        for from_url, to_url in url_replacement_dict.items():
            if entry["url"] == "conda-forge":
                target = url_replacement_dict[_CONDA_FORGE_URL]
                entry["url"] = f"file://{target}/conda-forge"
            else:
                entry["url"] = entry["url"].replace(from_url, f"file://{to_url}/")
    for entry in yml_to_patch["package"]:
        for from_url, to_url in url_replacement_dict.items():
            entry["url"] = entry["url"].replace(from_url, f"file://{to_url}/")


def main():
    url_hash_list = []
    replace_url_dict = {
        _CONDA_FORGE_URL: offline_channel_dir(),
        _NM_REPO_URL: offline_channel_dir(),
    }
    os.makedirs(offline_releases_dir(), exist_ok = True)
    for releasefile in releases_dir().glob("*.conda-lock.yml"):
        with releasefile.open('r') as infile:
            release = yaml.safe_load(infile)
            url_hash_list = [*url_hash_list, *get_url_and_hash_list(release)]
            patch_yml(replace_url_dict, release)
        with (offline_releases_dir() / releasefile.name).open("w") as outfile:
            yaml.safe_dump(release, outfile)

    url_hash_list = list(sorted(set(url_hash_list)))
    download_list_to_offline_repos(url_hash_list)

if __name__ == '__main__':
    main()
