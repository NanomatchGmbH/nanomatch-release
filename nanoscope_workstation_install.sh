#!/bin/bash

# Nanoscope Installer Script
#
function nproc {
    grep ^cpu\\scores /proc/cpuinfo | uniq |  awk '{print $4}'
}

function memory_in_megs {
    grep MemTotal /proc/meminfo | awk '{print int($2/1024)}'
}

# Color codes for highlighting
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================================"
echo -e "     Welcome to the Nanoscope Installation Script     "
echo -e "======================================================${NC}\n"

# Create and move into the ~/nanoscope directory
INSTALL_DIR="${HOME}/nanoscope"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

install_nanoscope() {

    echo -e "\n${GREEN}Installing Nanoscope on your workstation...${NC}\n"

    # Check if micromamba is installed
    if ! command -v micromamba &> /dev/null; then
        echo -e "${RED}micromamba is not installed or not recognized.${NC}"
        echo -e "${YELLOW}If you have just installed micromamba, please restart your shell and try again.${NC}"
        echo -e "${YELLOW}Otherwise, please install micromamba by running the following commands:${NC}"
        echo -e "${CYAN}\"${SHELL}\" <(curl -L micro.mamba.pm/install.sh)${NC}"
        echo -e "${CYAN}micromamba self-update --version=1.5.6${NC}"
        echo -e "${RED}Installation cannot proceed without micromamba.${NC}"
        exit 1
    fi

    # Clone the nanomatch-release GitHub repository
    if [ -d "nanomatch-release" ]; then
        echo -e "${CYAN}Updating nanomatch-release repository...${NC}"
        cd nanomatch-release
        git pull
        cd ..
    else
        echo -e "${CYAN}Cloning nanomatch-release repository...${NC}"
        git clone https://github.com/NanomatchGmbH/nanomatch-release.git
    fi

    cd nanomatch-release

    # Fetching latest Nanoscope releases
    echo -e "${CYAN}Fetching latest Nanoscope releases...${NC}"
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

    # Install Nanoscope software (latest version)
    echo -e "${CYAN}Installing Nanoscope software version ${latest_nmsci_version}... Please wait...${NC}"
    eval "${latest_nmsci_command}"

    # Install SimStack Server (latest version)
    echo -e "${CYAN}Installing SimStack Server version ${latest_simstackserver_version}... Please wait...${NC}"
    eval "${latest_simstackserver_command}"

    cd ..

    # Set up the .nanomatch.config file from the template
    echo -e "${CYAN}Setting up .nanomatch.config file...${NC}"
    # Get micromamba environments directory
    micromamba_envs_dir=$(micromamba info | grep 'envs directories' | awk -F ':' '{print $2}' | xargs)
    # Extract the nmsci environment name from latest_nmsci_command
    nmsci_environment=$(echo "$latest_nmsci_command" | grep -oP '(?<=--name=)[^\s]+')

    # Construct the path to nanomatch.config.template
    nanomatch_config_template="${micromamba_envs_dir}/${nmsci_environment}/nanomatch.config.template"

    # Set the scratch directory to default ($HOME/scratch)
    scratch_dir="${HOME}/scratch"
    mkdir -p "$scratch_dir"

    if [ -f "$nanomatch_config_template" ]; then
        echo -e "${CYAN}Using template config file from ${nanomatch_config_template}${NC}"
        # Read the template, replace export SCRATCH line
        config_file="${HOME}/.nanomatch.config"
        sed "s|export SCRATCH=.*|export SCRATCH=${scratch_dir}|" "$nanomatch_config_template" > "$config_file"
    else
        echo -e "${RED}Template config file not found at ${nanomatch_config_template}.${NC}"
        # Handle error or create a basic config file
        echo -e "${CYAN}Creating basic .nanomatch.config file...${NC}"
        echo "#!/bin/bash" > "$config_file"
        echo "" >> "$config_file"
        echo "export SCRATCH=${scratch_dir}" >> "$config_file"
    fi

    # Create a new environment for the SimStack Client
    if micromamba env list | grep -w "simstack" &> /dev/null; then
        echo -e "${YELLOW}SimStack environment 'simstack' already exists.${NC}"
        recreate_simstack_env="N"
    else
        echo -e "${CYAN}Creating a new environment for the SimStack Client... Please wait...${NC}"
        micromamba create --name=simstack simstack -c https://mamba.nanomatch-distribution.de/mamba-repo -c conda-forge -y
    fi

    # Download the WaNos
    echo -e "${CYAN}Downloading WaNos...${NC}"
    path_to_wanos="${INSTALL_DIR}/wano"
    if [ -d "$path_to_wanos" ]; then
        echo -e "${CYAN}Updating WaNos repository...${NC}"
        cd "$path_to_wanos"
        git pull
        cd ..
    else
        echo -e "${CYAN}Cloning WaNos repository...${NC}"
        git clone https://github.com/NanomatchGmbH/wano.git "$path_to_wanos"
    fi

    # Create the workflows directory
    workflow_path="${INSTALL_DIR}/workflows"
    mkdir -p "$workflow_path"

    # Create the Local.clustersettings file inside the ClusterSettings folder
    # Get the path to the simstack executable
    simstack_path=$(micromamba run -n simstack which simstack)
    simstack_dir=$(dirname "$simstack_path")

    # Set ClusterSettings directory to $HOME/.config/SimStack/ClusterSettings
    cluster_settings_dir="${HOME}/.config/SimStack/ClusterSettings"
    mkdir -p "$cluster_settings_dir"

    # Set CalculationBasepath to INSTALL_DIR/calculations
    calc_basepath="${INSTALL_DIR}/calculations"
    mkdir -p "$calc_basepath"

    # Get SoftwareDirectoryOnResource from micromamba info
    base_env_path=$(micromamba info | grep 'base environment' | awk -F ':' '{print $2}' | xargs)

    # Create the Local.clustersettings file
    local_clustersettings_file="${cluster_settings_dir}/Local.clustersettings"
    cat <<EOF > "$local_clustersettings_file"
{
    "resource_name": "localhost",
    "walltime": "86399",
    "cpus_per_node": "$(nproc)",
    "nodes": "1",
    "queue": "default",
    "memory": "$(memory_in_megs)",
    "custom_requests": "",
    "base_URI": "localhost",
    "port": "22",
    "username": "$USER",
    "basepath": "$calc_basepath",
    "queueing_system": "Internal",
    "sw_dir_on_resource": "$base_env_path",
    "extra_config": "None Required (default)",
    "ssh_private_key": "UseSystemDefault",
    "sge_pe": "",
    "reuse_results": "False"
}
EOF

    # Create the ssh_clientsettings.yml file
    simstack_settings_dir="${HOME}/.local/share/simstack/NanoMatch"
    mkdir -p "$simstack_settings_dir"
    ssh_clientsettings_file="${simstack_settings_dir}/ssh_clientsettings.yml"
    cat <<EOF > "$ssh_clientsettings_file"
WaNo_Repository_Path: ${path_to_wanos}
workflow_path: ${workflow_path}
EOF

    echo -e "\n${GREEN}Installation and configuration on the workstation are complete.${NC}"

    # Collect paths for output
    nanomatch_release_dir="${INSTALL_DIR}/nanomatch-release"

    # Prepare the output
    echo -e "\n${CYAN}Main Folders and Paths:${NC}"
    echo -e "${YELLOW}Nanoscope version:${NC} ${latest_nmsci_version}"
    echo -e "${YELLOW}WaNo folder:${NC} ${path_to_wanos}"
    echo -e "${YELLOW}Workflows folder:${NC} ${workflow_path}"
    echo -e "${YELLOW}Calculations folder:${NC} ${calc_basepath}"
    echo -e "${YELLOW}Scratch folder:${NC} ${scratch_dir}"
    echo -e "${YELLOW}Nanomatch-release files folder:${NC} ${nanomatch_release_dir}"
    echo -e "${YELLOW}Micromamba environments folder:${NC} ${micromamba_envs_dir}"
    echo -e "${YELLOW}.nanomatch.config file:${NC} ${config_file}"

    # Save to Main_folders_paths.txt
    paths_file="${INSTALL_DIR}/Main_folders_paths.txt"
    cat <<EOF > "$paths_file"
Main Folders and Paths:

Nanoscope version: ${latest_nmsci_version}
WaNo folder: ${path_to_wanos}
Workflows folder: ${workflow_path}
Calculations folder: ${calc_basepath}
Scratch folder: ${scratch_dir}
Nanomatch-release files folder: ${nanomatch_release_dir}
Micromamba environments folder: ${micromamba_envs_dir}
.nanomatch.config file: ${config_file}
EOF

    echo -e "\n${CYAN}You can view this list again by running:${NC}"
    echo -e "${YELLOW}cat ${paths_file}${NC}"

    echo -e "\n${GREEN}To start SimStack, you need to enter the following commands:${NC}"
    echo -e "${YELLOW}micromamba activate simstack${NC}"
    echo -e "${YELLOW}simstack${NC}"

    echo -e "\n${GREEN}Installation completed successfully.${NC}"
}

# Run the installation
install_nanoscope

