#!/bin/bash

# Nanoscope Installer Script
# Options:
# 1. Install Nanoscope on a workstation
# 2. Update Nanoscope
# 3. Quit

# Color codes for highlighting
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================================"
echo -e "     Welcome to the Nanoscope Installation Script     "
echo -e "======================================================${NC}\n"

# Create and move into the ~/nanomatch-software directory
INSTALL_DIR="${HOME}/nanomatch-software"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Ask the user what they want to do
echo -e "${YELLOW}Please select an option:${NC}"
options=("Install Nanoscope on a workstation" "Update Nanoscope" "Quit")
select opt in "${options[@]}"; do
    case $REPLY in
        1 )
            INSTALL_NANOSCOPE=true
            UPDATE_NANOSCOPE=false
            break
            ;;
        2 )
            INSTALL_NANOSCOPE=false
            UPDATE_NANOSCOPE=true
            break
            ;;
        3 )
            echo -e "${RED}Exiting the installation script.${NC}"
            exit 0
            ;;
        * )
            echo -e "${RED}Please select a valid option (1-3).${NC}"
            ;;
    esac
done

install_nanoscope() {
    echo -e "\n${GREEN}Installing Nanoscope on your workstation...${NC}\n"

    # Check if micromamba is installed
    if ! command -v micromamba &> /dev/null; then
        echo -e "${RED}micromamba is not installed or not recognized.${NC}"
        echo -e "${CYAN}If you have just installed micromamba, please restart your shell and try again.${NC}"
        echo -e "${CYAN}Otherwise, please install micromamba by running the following commands:${NC}"
        echo -e "${YELLOW}\"${SHELL}\" <(curl -L micro.mamba.pm/install.sh)${NC}"
        echo -e "${YELLOW}micromamba self-update --version=1.5.6${NC}"
        echo -e "${RED}Installation cannot proceed without micromamba.${NC}"
        exit 1
    else
        echo -e "${GREEN}micromamba is correctly installed.${NC}"
    fi

    # Clone the nanomatch-release GitHub repository
    if [ -d "nanomatch-release" ]; then
        echo -e "${YELLOW}nanomatch-release directory already exists.${NC}"
        read -p "$(echo -e "${CYAN}Do you want to pull the latest updates? (Y/n): ${NC}")" update_repo
        update_repo=${update_repo:-Y}
        if [[ "$update_repo" =~ ^[Yy]$ ]]; then
            cd nanomatch-release
            git pull
            cd ..
        fi
    else
        echo -e "${CYAN}Cloning nanomatch-release repository...${NC}"
        git clone https://github.com/NanomatchGmbH/nanomatch-release.git
    fi

    cd nanomatch-release

    # List available releases
    echo -e "\n${GREEN}Listing available Nanoscope releases...${NC}\n"
    helper_output=$(./install_environment_helper.sh)

    # Parse the helper output to extract environments and commands
    nmsci_versions=()
    nmsci_commands=()
    simstackserver_versions=()
    simstackserver_commands=()
    current_env=""
    while IFS= read -r line; do
        if [[ $line =~ ^\ ---\ (.*)\ ---$ ]]; then
            current_env="${BASH_REMATCH[1]}"
        elif [[ $line =~ ^\ *micromamba\ create ]]; then
            if [[ "$current_env" == simstackserver* ]]; then
                simstackserver_versions+=("$current_env")
                simstackserver_commands+=("$line")
            else
                nmsci_versions+=("$current_env")
                nmsci_commands+=("$line")
            fi
        fi
    done <<< "$helper_output"

    # Function to compare version numbers
    version_compare() {
        # Return 0 if $1 == $2
        # Return 1 if $1 > $2
        # Return 2 if $1 < $2
        if [[ $1 == $2 ]]; then
            return 0
        fi

        IFS='.-' read -ra ver1 <<< "$1"
        IFS='.-' read -ra ver2 <<< "$2"

        for ((i=0; i<${#ver1[@]}; i++)); do
            if [[ -z ${ver2[i]} ]]; then
                # ver2 version component is missing, so ver1 is greater
                return 1
            fi
            if ((10#${ver1[i]} > 10#${ver2[i]})); then
                return 1
            elif ((10#${ver1[i]} < 10#${ver2[i]})); then
                return 2
            fi
        done
        # If ver1 has fewer components but all components are equal so far
        if (( ${#ver1[@]} < ${#ver2[@]} )); then
            return 2
        fi
        return 0
    }

    # Find the latest nmsci version
    latest_nmsci_version=""
    latest_nmsci_command=""
    for i in "${!nmsci_versions[@]}"; do
        version="${nmsci_versions[$i]}"
        command="${nmsci_commands[$i]}"
        if [[ -z "$latest_nmsci_version" ]]; then
            latest_nmsci_version="$version"
            latest_nmsci_command="$command"
        else
            version_compare "${version#nmsci-}" "${latest_nmsci_version#nmsci-}"
            result=$?
            if [[ $result -eq 1 ]]; then
                latest_nmsci_version="$version"
                latest_nmsci_command="$command"
            fi
        fi
    done

    # Find the latest simstackserver version
    latest_simstackserver_version=""
    latest_simstackserver_command=""
    for i in "${!simstackserver_versions[@]}"; do
        version="${simstackserver_versions[$i]}"
        command="${simstackserver_commands[$i]}"
        if [[ -z "$latest_simstackserver_version" ]]; then
            latest_simstackserver_version="$version"
            latest_simstackserver_command="$command"
        else
            version_compare "${version#simstackserver-}" "${latest_simstackserver_version#simstackserver-}"
            result=$?
            if [[ $result -eq 1 ]]; then
                latest_simstackserver_version="$version"
                latest_simstackserver_command="$command"
            fi
        fi
    done

    # Ask user if they want to install the latest nmsci version
    echo -e "${CYAN}The latest Nanoscope version is ${latest_nmsci_version}.${NC}"
    read -p "$(echo -e "${CYAN}Do you want to install this version? (Y/n): ${NC}")" install_latest_nmsci
    install_latest_nmsci=${install_latest_nmsci:-Y}
    if [[ "$install_latest_nmsci" =~ ^[Yy]$ ]]; then
        nmsci_version="$latest_nmsci_version"
        nmsci_command="$latest_nmsci_command"
    else
        echo -e "${YELLOW}Available Nanoscope versions:${NC}"
        for i in "${!nmsci_versions[@]}"; do
            echo -e "${CYAN}$((i+1)). ${nmsci_versions[$i]}${NC}"
        done
        read -p "$(echo -e "${CYAN}Please enter the number corresponding to your choice: ${NC}")" nmsci_choice
        nmsci_index=$((nmsci_choice - 1))
        if [[ $nmsci_index -ge 0 && $nmsci_index -lt ${#nmsci_versions[@]} ]]; then
            nmsci_version=${nmsci_versions[$nmsci_index]}
            nmsci_command=${nmsci_commands[$nmsci_index]}
        else
            echo -e "${RED}Invalid selection.${NC}"
            exit 1
        fi
    fi

    # Ask user if they want to install the latest simstackserver version
    echo -e "${CYAN}The latest SimStack Server version is ${latest_simstackserver_version}.${NC}"
    read -p "$(echo -e "${CYAN}Do you want to install this version? (Y/n): ${NC}")" install_latest_simstackserver
    install_latest_simstackserver=${install_latest_simstackserver:-Y}
    if [[ "$install_latest_simstackserver" =~ ^[Yy]$ ]]; then
        simstackserver_version="$latest_simstackserver_version"
        simstackserver_command="$latest_simstackserver_command"
    else
        echo -e "${YELLOW}Available SimStack Server versions:${NC}"
        for i in "${!simstackserver_versions[@]}"; do
            echo -e "${CYAN}$((i+1)). ${simstackserver_versions[$i]}${NC}"
        done
        read -p "$(echo -e "${CYAN}Please enter the number corresponding to your choice: ${NC}")" simstackserver_choice
        simstackserver_index=$((simstackserver_choice -1))
        if [[ $simstackserver_index -ge 0 && $simstackserver_index -lt ${#simstackserver_versions[@]} ]]; then
            simstackserver_version=${simstackserver_versions[$simstackserver_index]}
            simstackserver_command=${simstackserver_commands[$simstackserver_index]}
        else
            echo -e "${RED}Invalid selection.${NC}"
            exit 1
        fi
    fi

    # Install Nanoscope software
    echo -e "${CYAN}Installing Nanoscope software... This may take a few minutes.${NC}"
    echo -e "${CYAN}Executing: ${nmsci_command}${NC}"
    eval "${nmsci_command}"

    # Install SimStack Server
    echo -e "${CYAN}Installing SimStack Server... This may take a few minutes.${NC}"
    echo -e "${CYAN}Executing: ${simstackserver_command}${NC}"
    eval "${simstackserver_command}"

    cd ..

    # Set up the .nanomatch.config file
    echo -e "\n${GREEN}Setting up .nanomatch.config file...${NC}"
    config_file="${HOME}/.nanomatch.config"
    touch "$config_file"

    # Ask for the scratch directory
    read -p "$(echo -e "${CYAN}Scratch directory (default: /scratch/): ${NC}")" scratch_dir
    scratch_dir=${scratch_dir:-/scratch/}
    echo "export SCRATCH=$scratch_dir" >> "$config_file"

    # # Ask if using a commercial license (Default Yes)
    # read -p "$(echo -e "${CYAN}Are you using a commercial license? (Y/n): ${NC}")" use_license
    # use_license=${use_license:-Y}
    # if [[ "$use_license" =~ ^[Yy]$ ]]; then
    #     echo -e "${YELLOW}\nIn case the CodeMeter runtime is installed on a different computer in your network than the computational resource itself, provide the corresponding IP address.${NC}"
    #     echo -e "${YELLOW}See also Licensing documentation for details:${NC} ${BLUE}https://nanoscope.readthedocs.io/en/latest/docs/build/html/getting_started/licensing.html#getting-started-licensing.html${NC}\n"
    #     read -p "$(echo -e "${CYAN}NM_LICENSE_SERVER address (default: localhost): ${NC}")" license_server
    #     license_server=${license_server:-localhost}
    #     echo "export NM_LICENSE_SERVER=$license_server" >> "$config_file"
    # fi

    echo -e "${GREEN}.nanomatch.config file has been set up at $config_file.${NC}"

    # Create a new environment for the SimStack Client
    if micromamba env list | grep -q "simstack_client"; then
        echo -e "${YELLOW}SimStack Client environment 'simstack_client' already exists.${NC}"
        read -p "$(echo -e "${CYAN}Do you want to recreate it? (This will remove the existing environment) (y/N): ${NC}")" recreate_simstack_env
        recreate_simstack_env=${recreate_simstack_env:-N}
        if [[ "$recreate_simstack_env" =~ ^[Yy]$ ]]; then
            micromamba remove --name simstack_client --all -y
            micromamba create --name=simstack_client simstack -c https://mamba.nanomatch-distribution.de/mamba-repo -c conda-forge -y
        fi
    else
        echo -e "${CYAN}Creating a new environment for the SimStack Client...${NC}"
        micromamba create --name=simstack_client simstack -c https://mamba.nanomatch-distribution.de/mamba-repo -c conda-forge -y
    fi

    # Do not run SimStack Client
    # echo -e "${CYAN}Running SimStack Client...${NC}"
    # micromamba run -n simstack_client simstack &

    # Download the WaNos
    echo -e "\n${GREEN}Downloading WaNos...${NC}"
    if [ -d "wano" ]; then
        echo -e "${YELLOW}WaNos directory already exists.${NC}"
        read -p "$(echo -e "${CYAN}Do you want to pull the latest updates? (Y/n): ${NC}")" update_wanos
        update_wanos=${update_wanos:-Y}
        if [[ "$update_wanos" =~ ^[Yy]$ ]]; then
            cd wano
            git pull
            cd ..
        fi
    else
        echo -e "${CYAN}Cloning WaNos repository...${NC}"
        git clone https://github.com/NanomatchGmbH/wano.git
    fi

    # Skip SSH configurations

    # Create the Local.clustersettings file inside the ClusterSettings folder
    # Get the path to the simstack executable
    simstack_path=$(micromamba run -n simstack_client which simstack)
    simstack_dir=$(dirname "$simstack_path")

    # Set cluster_settings_dir to $HOME/.config/SimStack/ClusterSettings
    cluster_settings_dir="${HOME}/.config/SimStack/ClusterSettings"
    mkdir -p "$cluster_settings_dir"

    # Ask for CalculationBasepath
    default_calc_basepath="${HOME}/simstack_calculations"
    read -p "$(echo -e "${CYAN}Calculation Basepath [${default_calc_basepath}]: ${NC}")" calc_basepath
    calc_basepath=${calc_basepath:-${default_calc_basepath}}

    # Get SoftwareDirectoryOnResource
    echo -e "${CYAN}Determining Software Directory on Resource...${NC}"
    micromamba_info_output=$(micromamba info)
    software_dir=$(echo "$micromamba_info_output" | grep 'base environment' | awk -F ': ' '{print $2}')
    echo -e "${CYAN}Software Directory on Resource detected as ${software_dir}.${NC}"
    read -p "$(echo -e "${CYAN}Is this correct? (Y/n): ${NC}")" confirm_software_dir
    confirm_software_dir=${confirm_software_dir:-Y}
    if [[ ! "$confirm_software_dir" =~ ^[Yy]$ ]]; then
        read -p "$(echo -e "${CYAN}Please enter the Software Directory on Resource: ${NC}")" software_dir
    fi

    # Create the Local.clustersettings file
    local_clustersettings_file="${cluster_settings_dir}/Local.clustersettings"
    cat <<EOF > "$local_clustersettings_file"
{
    "resource_name": "localhost",
    "walltime": "86399",
    "cpus_per_node": "8",
    "nodes": "1",
    "queue": "default",
    "memory": "15354",
    "custom_requests": "",
    "base_URI": "localhost",
    "port": "22",
    "username": "$USER",
    "basepath": "$calc_basepath",
    "queueing_system": "Internal",
    "sw_dir_on_resource": "$software_dir",
    "extra_config": "None Required (default)",
    "ssh_private_key": "UseSystemDefault",
    "sge_pe": "",
    "reuse_results": "False"
}
EOF

    echo -e "\n${GREEN}Installation and configuration on the workstation are complete.${NC}"


    # Ask the user if they want to start SimStack now
    read -p "$(echo -e "${CYAN}Do you want to start SimStack now? (Y/n): ${NC}")" start_simstack
    start_simstack=${start_simstack:-Y}
    if [[ "$start_simstack" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}To launch SimStack in the future, run the following commands:${NC}"
        echo -e "${YELLOW}micromamba activate simstack_client${NC}"
        echo -e "${YELLOW}simstack${NC}"
        # echo -e "${CYAN}Now I am starting SimStack...${NC}"
        # micromamba activate simstack_client
        # simstack
        # echo -e "${GREEN}SimStack has been started.${NC}"
    fi
}

update_nanoscope() {
    echo -e "\n${GREEN}Updating Nanoscope...${NC}\n"

    # Update nanomatch-release
    if [ -d "nanomatch-release" ]; then
        cd nanomatch-release
        git pull
        cd ..
    else
        echo -e "${RED}nanomatch-release directory not found. Please install Nanoscope first.${NC}"
    fi

    # Update WaNos
    if [ -d "wano" ]; then
        cd wano
        git pull
        cd ..
    else
        echo -e "${RED}WaNos directory not found. Please install Nanoscope first.${NC}"
    fi

    echo -e "\n${GREEN}Update complete.${NC}"
}

# Main logic
if [ "$INSTALL_NANOSCOPE" = true ]; then
    install_nanoscope
elif [ "$UPDATE_NANOSCOPE" = true ]; then
    update_nanoscope
fi
