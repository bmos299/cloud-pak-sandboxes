#!/bin/bash

#These values are used by the update_cursor()
cursor[0]='|'
cursor[1]='/'
cursor[2]='-'
cursor[3]='\'
cursor[4]='|'
cursor[5]='/'
cursor[6]='-'
pos=0
x=0

# These values are used for the echo colors
bold=$(tput setaf 4; tput bold)
normal=$(tput sgr0)
green=$(tput setaf 2; tput bold)

# These values are used through out the progam
CP4MCM="false"
CP4APP="false"
CP4I="false"
CP4D35="false"
CP4D30="false"
CP4AUTO="false"
EXISTING_CLUSTER="false"

# Creats a spinning cursor for user to know program is running
update_cursor() {
    printf "\b"${cursor[pos]}
    pos=$(( ( pos + 1 )  % 7 ))
}

# Ask user to select cloud pak installation and updates workspace-configuration with choice
get_cloud_pak_install() {

    
    
    # check existing workspace list
    # updates .template_repo.url and .template_repo.branch based off of the choice made. Defaults to master branch
    echo "${bold}This script will generate a ROKS cluster and install a specified cloud pak${normal}"
    echo ""
    echo "${bold}Select the cloud pack option to install${green}"
    cloudPaks=("Cloud Pak for Multicloud Management 2.2" "Cloud Pak for Applications 4.2" "Cloud Pak for Data 3.5" "Cloud Pak for Data 3.0" "Cloud Pak for Integration 2021.1" "Cloud Pak for Automation 20.0")
    select cloudpak in "${cloudPaks[@]}"; do
        case $cloudpak in
            "Cloud Pak for Multicloud Management 2.2")
                echo "${bold}Selected: Cloud Pak for Multicloud Management"
                CP4MCM="true"
                cp ./cpmcm-workspace-configuration.json workspace-configuration.json
                cp workspace-configuration.json temp.json
                jq -r ".template_repo.url |= \"https://github.com/ibm-hcbt/cloud-pak-sandboxes/tree/master/terraform/cp4mcm\"" temp.json  > workspace-configuration.json
                cp workspace-configuration.json temp.json
                jq -r ".template_repo.branch |= \"master\"" temp.json > workspace-configuration.json
                break
                ;;
            "Cloud Pak for Applications 4.2")
                echo "${bold}Selected: Cloud Pak for Applications"
                CP4APP="true"
                cp ./cp4a-workspace-configuration.json workspace-configuration.json
                cp workspace-configuration.json temp.json
                jq -r ".template_repo.url |= \"https://github.com/ibm-hcbt/cloud-pak-sandboxes/tree/master/terraform/cp4app\"" temp.json  > workspace-configuration.json
                cp workspace-configuration.json temp.json
                jq -r ".template_repo.branch |= \"master\"" temp.json > workspace-configuration.json
                break
                ;;
            "Cloud Pak for Data 3.5")
                echo "${bold}Selected: Cloud Pak for Data 3.5"
                CP4D35="true"
                cp ./cp4d-workspace-configuration.json workspace-configuration.json
                cp workspace-configuration.json temp.json
                jq -r ".template_repo.url |= \"https://github.com/ibm-hcbt/cloud-pak-sandboxes/tree/master/terraform/cp4data\"" temp.json  > workspace-configuration.json
                cp workspace-configuration.json temp.json
                jq -r ".template_repo.branch |= \"master\"" temp.json > workspace-configuration.json
                break
                ;;
            "Cloud Pak for Data 3.0")
                echo "${bold}Selected: Cloud Pak for Data 3.0"
                CP4D30="true"
                cp ./cp4d_3.0-workspace-configuration.json workspace-configuration.json
                cp workspace-configuration.json temp.json
                jq -r ".template_repo.url |= \"https://github.com/ibm-hcbt/cloud-pak-sandboxes/tree/master/terraform/cp4data_3.0\"" temp.json  > workspace-configuration.json
                cp workspace-configuration.json temp.json
                jq -r ".template_repo.branch |= \"master\"" temp.json > workspace-configuration.json
                break
                ;;    
            "Cloud Pak for Integration 2021.1")
                echo "${bold}Selected: Cloud Pak for Integration 2021.1"
                CP4I="true"
                cp ./cp4i-workspace-configuration.json workspace-configuration.json
                cp workspace-configuration.json temp.json
                jq -r ".template_repo.url |= \"https://github.com/ibm-hcbt/cloud-pak-sandboxes/tree/master/terraform/cp4i\"" temp.json  > workspace-configuration.json
                cp workspace-configuration.json temp.json
                jq -r ".template_repo.branch |= \"master\"" temp.json > workspace-configuration.json
                break
                ;;
            "Cloud Pak for Automation 20.0")
                echo "${bold}Selected: Cloud Pak for Automation 20.0"
                CP4AUTO="true"
                cp ./cp4auto-workspace-configuration.json workspace-configuration.json
                cp workspace-configuration.json temp.json
                jq -r ".template_repo.url |= \"https://github.com/ibm-hcbt/cloud-pak-sandboxes/tree/master/terraform/cp4auto\"" temp.json  > workspace-configuration.json
                cp workspace-configuration.json temp.json
                jq -r ".template_repo.branch |= \"master\"" temp.json > workspace-configuration.json
                break
                ;; 
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

}

# get workspace name from user, appends with appropriant cloud pak name
# defines the workspace name for future use
get_workspace_name() {

    if $CP4MCM
    then
        read -p "${bold}Enter sandbox name (sandbox name will be appended with ${green}-mcm-sandbox${bold}):${normal} " -e WORKSPACE_NAME
        WORKSPACE_NAME=$WORKSPACE_NAME"-mcm-sandbox"
    fi

    if $CP4APP
    then
        read -p "${bold}Enter sandbox name (sandbox name will be appended with ${green}-cp4a-sandbox${bold}):${normal} " -e WORKSPACE_NAME
        WORKSPACE_NAME=$WORKSPACE_NAME"-cp4a-sandbox"
    fi

    if $CP4I
    then
        read -p "${bold}Enter sandbox name (sandbox name will be appended with ${green}-cp4i-sandbox${bold}):${normal} " -e WORKSPACE_NAME
        WORKSPACE_NAME=$WORKSPACE_NAME"-cp4i-sandbox"
    fi

    if $CP4D35
    then
        read -p "${bold}Enter Sandbox Name (sandbox name will be appended with ${green}-cp4data35-sandbox${bold}):${normal} " -e WORKSPACE_NAME
        WORKSPACE_NAME=$WORKSPACE_NAME"-cp4data35-sandbox"
    fi

    if $CP4D30
    then
        read -p "${bold}Enter Sandbox Name (sandbox name will be appended with ${green}-cp4data30-sandbox${bold}):${normal} " -e WORKSPACE_NAME
        WORKSPACE_NAME=$WORKSPACE_NAME"-cp4data30-sandbox"
    fi

    if $CP4AUTO
    then
        read -p "${bold}Enter Sandbox Name (sandbox name will be appended with ${green}-cp4auto-sandbox${bold}):${normal} " -e WORKSPACE_NAME
        WORKSPACE_NAME=$WORKSPACE_NAME"-cp4auto-sandbox"
    fi    
}

# get project metadata (name, owner, env, etc...)
get_meta_data() {
    # tags for workspace, used by workspace-configuration.json
    read -p "${bold}Enter Project Owner Name:${normal} " -e PROJECT_OWNER_NAME
    PROJECT_OWNER_NAME_TAG="owner:$PROJECT_OWNER_NAME"
    read -p "${bold}Enter Environment Name:${normal} " -e ENV_NAME
    ENV_NAME_TAG="env:$ENV_NAME"
    read -p "${bold}Enter Project Name (new clusters will be named starting with ${green}Project Name):${normal} " -e PROJECT_NAME
    PROJECT_NAME_TAG="project:$PROJECT_NAME"
    read -s -p "${bold}Enter Entitled Registry key (retrieve from ${green}https://myibm.ibm.com/products-services/containerlibrary):${normal} " -e ENTITLED_KEY
    echo " "
    read -p "${bold}Enter Entitled Registry Email:${normal} " -e ENTITLED_EMAIL
}

# writes metadata to workspace-configuration.json and temp.json these need to be cleaned up later
# also writes the cluster_id value which decides on new clusters or existing ones
write_meta_data() {
    # updates workspace-configuration.json  .name
    cp workspace-configuration.json temp.json
    jq -r ".name |= \"$WORKSPACE_NAME\"" temp.json > workspace-configuration.json
    # updates workspace-configuration.json  .tags[owner]
    cp workspace-configuration.json temp.json
    jq -r ".tags[0] |= \"$PROJECT_OWNER_NAME_TAG\"" temp.json > workspace-configuration.json
    # updates workspace-configuration.json .template_data[.varialbestore.owner]
    cp workspace-configuration.json temp.json
    jq -r --arg v "$PROJECT_OWNER_NAME" '(.template_data[] | .variablestore[] | select(.name == "owner") | .value) |= $v' temp.json > workspace-configuration.json
    # updates workspace-configuration.json .tags[env]
    cp workspace-configuration.json temp.json
    jq -r ".tags[1] |= \"$ENV_NAME_TAG\"" temp.json > workspace-configuration.json
    # updates workspace-configuration.json .template_data[.varialbestore.enviorment]
    cp workspace-configuration.json temp.json
    jq -r --arg v "$ENV_NAME" '(.template_data[] | .variablestore[] | select(.name == "environment") | .value) |= $v' temp.json > workspace-configuration.json
    # updates workspace-configuration.json .tags[project]
    cp workspace-configuration.json temp.json
    jq -r ".tags[2] |= \"$PROJECT_NAME_TAG\"" temp.json > workspace-configuration.json
    # updates workspace-configuration.json .template_data[.varialbestore.project_name]
    cp workspace-configuration.json temp.json
    jq -r --arg v "$PROJECT_NAME" '(.template_data[] | .variablestore[] | select(.name == "project_name") | .value) |= $v' temp.json > workspace-configuration.json
    # updates workspace-configuration.json .template_data[.varialbestore.entitled_registry_user_email]
    cp workspace-configuration.json temp.json
    jq -r --arg v "$ENTITLED_EMAIL" '(.template_data[] | .variablestore[] | select(.name == "entitled_registry_user_email") | .value) |= $v' temp.json > workspace-configuration.json
    # updates workspace-configuration.json .template_data[.varialbestore.entitled_registry_key]
    cp workspace-configuration.json temp.json
    jq -r --arg v "$ENTITLED_KEY" '(.template_data[] | .variablestore[] | select(.name == "entitled_registry_key") | .value) |= $v' temp.json > workspace-configuration.json
    # updates workspace-configuration.json .template_data[.varialbestore.cluster_id]
    cp workspace-configuration.json temp.json
    jq -r --arg v "$CLUSTER_ID" '(.template_data[] | .variablestore[] | select(.name == "cluster_id") | .value) |= $v' temp.json > workspace-configuration.json
}

# writes cp4mcm module values if needed
# updates the values across the respective workspace-configuration values.
cp4mcm_modules() {
    
    # updates workspace-configuration.json .template_data[.varialbestore.install_infr_mgt_module]
    echo "${bold}Install Infrastructure Management Module? ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_infr_mgt_module") | .value) |= "true"' temp.json > workspace-configuration.json
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_infr_mgt_module") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.installing_monitoring_module]
    echo "${bold}Install Monitoring Module? ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_monitoring_module") | .value) |= "true"' temp.json > workspace-configuration.json
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_monitoring_module") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_security_svcs_module]
    echo "${bold}Install Security Services Module? ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_security_svcs_module") | .value) |= "true"' temp.json > workspace-configuration.json
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_security_svcs_module") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_operations_module]
    echo "${bold}Install Operations Module?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_operations_module") | .value) |= "true"' temp.json > workspace-configuration.json
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_operations_module") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_tech_prev_module]
    echo "${bold}Install Tech Preview Module?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_tech_prev_module") | .value) |= "true"' temp.json > workspace-configuration.json
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_tech_prev_module") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done
}

# writes cp4d 3.5 module data
# updates the values across the respective workspace_configuration values
cp4d35_modules() {
    isEmptyList=true
    # updates workspace-configuration.json .template_data[.varialbestore.install_watson_knowledge_catalog]
    echo "${bold}Install Watson knowledge catalog?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_knowledge_catalog") | .value) |= "true"' temp.json > workspace-configuration.json
               isEmptyList=false
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_knowledge_catalog") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_watson_studio]
    echo "${bold}Install Watson studio?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_studio") | .value) |= "true"' temp.json > workspace-configuration.json
               isEmptyList=false
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_studio") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_watson_machine_learning]
    echo "${bold}Install Watson machine learning?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_machine_learning") | .value) |= "true"' temp.json > workspace-configuration.json
               isEmptyList=false
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_machine_learning") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_watson_open_scale]
    echo "${bold}Install Watson open scale?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_open_scale") | .value) |= "true"' temp.json > workspace-configuration.json
               isEmptyList=false             
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_open_scale") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_data_virtualization]
    echo "${bold}Install data virtualization?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_data_virtualization") | .value) |= "true"' temp.json > workspace-configuration.json
               isEmptyList=false
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_data_virtualization") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_streams]
    echo "${bold}Install streams?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_streams") | .value) |= "true"' temp.json > workspace-configuration.json
               isEmptyList=false
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_streams") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_analytics_dashboard]
    echo "${bold}Install analytics dashboard?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_analytics_dashboard") | .value) |= "true"' temp.json > workspace-configuration.json
               isEmptyList=false
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_analytics_dashboard") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_spark]
    echo "${bold}Install Spark?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_spark") | .value) |= "true"' temp.json > workspace-configuration.json
               isEmptyList=false
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_spark") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_db2_warehouse]
    echo "${bold}Install DB2 warehouse?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_db2_warehouse") | .value) |= "true"' temp.json > workspace-configuration.json
               isEmptyList=false
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_db2_warehouse") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_db2_data_gate]
    echo "${bold}Install DB2 data gate?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_db2_data_gate") | .value) |= "true"' temp.json > workspace-configuration.json
               isEmptyList=false
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_db2_data_gate") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_rstudio]
    echo "${bold}Install rstudio?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_rstudio") | .value) |= "true"' temp.json > workspace-configuration.json
               isEmptyList=false
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_rstudio") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_db2_data_management]
    echo "${bold}Install DB2 data management?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_db2_data_management") | .value) |= "true"' temp.json > workspace-configuration.json
               isEmptyList=false
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_db2_data_management") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    if [ $isEmptyList == false ]; then
        cp ./workspace-configuration.json temp.json
        jq -r '(.template_data[] | .variablestore[] | select(.name == "empty_module_list") | .value) |= "false"' temp.json > workspace-configuration.json
    fi
}

# wites cp4d_3.0 module data
# updates the value across the respective workspace_configuration values
cp4d30_modules() {

    # updates workspace-configuration.json .template_data[.varialbestore.install_guardium_external_stap]
    # updates workspace-configuration.json .template_data[.varialbestore.docker_id]
    # updates workspace-configuration.json .template_data[.varialbestore.docker_access_token]
    echo "${bold}Install guardium external? ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_guardium_external_stap") | .value) |= "true"' temp.json > workspace-configuration.json
               read -p "${bold}Enter Docker ID:${normal} " -e DOCKER_ID
               read -p "${bold}Enter Docker Access Token:${normal} " -e DOCKER_ACCESS
               cp workspace-configuration.json temp.json
               jq -r --arg v "$DOCKER_ID" '(.template_data[] | .variablestore[] | select(.name == "docker_id") | .value) |= $v' temp.json > workspace-configuration.json
               cp workspace-configuration.json temp.json
               jq -r --arg v "$DOCKER_ACCESS" '(.template_data[] | .variablestore[] | select(.name == "docker_access_token") | .value) |= $v' temp.json > workspace-configuration.json
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_guardium_external_stap") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_watson_assistant]
    echo "${bold}Install watson assistant? ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_assistant") | .value) |= "true"' temp.json > workspace-configuration.json
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_assistant") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_watson_assistant_for_voice_interaction]
    echo "${bold}Install watson assistant for voice interaction? ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_assistant_for_voice_interaction") | .value) |= "true"' temp.json > workspace-configuration.json
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_assistant_for_voice_interaction") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_watson_discovery]
    echo "${bold}Install watson discovery?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_discovery") | .value) |= "true"' temp.json > workspace-configuration.json
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_discovery") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_watson_knowledge_studio]
    echo "${bold}Install watson knowledge studio?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_knowledge_studio") | .value) |= "true"' temp.json > workspace-configuration.json
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_knowledge_studio") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_watson_language_translator]
    echo "${bold}Install watson language translator?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_language_translator") | .value) |= "true"' temp.json > workspace-configuration.json
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_language_translator") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_watson_speech_text]
    echo "${bold}Install Watson speech text?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_speech_text") | .value) |= "true"' temp.json > workspace-configuration.json
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_watson_speech_text") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    # updates workspace-configuration.json .template_data[.varialbestore.install_edge_analytics]
    echo "${bold}Install edge analytics?  ${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_edge_analytics") | .value) |= "true"' temp.json > workspace-configuration.json
               break
               ;;
            "No")
               cp ./workspace-configuration.json temp.json
               jq -r '(.template_data[] | .variablestore[] | select(.name == "install_edge_analytics") | .value) |= "false"' temp.json > workspace-configuration.json
               break
               ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

}

# Sets cluster id to user input or null
# user input will use existing cluster for cloud pak install, null will create new cluster.
get_cluster_info() {
    echo "${bold}Do you have a Pre-existing cluster to install cloud paks to?${green}"
    yesno=("Yes" "No")
    select response in "${yesno[@]}"; do
        case $response in
            "Yes")
                echo "${bold}Please give cluster ID of existing cluster"
                EXISTING_CLUSTER="true"
                read -p "${bold}Enter Cluster ID ${green}(Leave blank for new clusters)${bold}: ${normal}" -e CLUSTER_ID
                break
                ;;
            "No")
                echo "${bold}Creating new cluster"
                EXISTING_CLUSTER="false"
                CLUSTER_ID=""
                break
                ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done
}

# select two vlans (private, public) based off of region selected
# if no vlans are found new ones will be created
create_private_vlan() {
    echo "${bold}Creating private VLAN${normal}"
    ibmcloud sl vlan create -t private -d $DATACENTER -n sandbox-private -f --output json > logs/vlan-private-$WORKSPACE_NAME.json
    echo "${bold}Private VLAN creation started, this process may take some time.${normal}"
    echo "${bold}You may continue to refresh the VLAN list until it appears, cancel this current sandbox creation, or choose another vlan${normal}"
    echo "${bold}The VLAN confirmation can be found in ${green}logs/vlan-private-$WORKSPACE_NAME${normal}"
    ibmcloud sl vlan list --output json > vlan.json
    jq --arg v "$DATACENTER" '[.[] | select(.primaryRouter.datacenter.name | contains($v)) | select(.networkSpace | contains("PRIVATE"))]' vlan.json > vlan-private.json
}

get_private_vlan() {
    VLAN_PRIVATE_OPTION="0"
    #echo "$VLAN_PRIVATE_OPTION"
    
    while true;
    do
        echo "${green}"
        for (( c=1; c<=$LENGTH; c++))
        do 
            TEMP=$(jq -c ".[$c-1] | {id: .id, name: .name, vlanNumber: .vlanNumber, datacenter: .primaryRouter.datacenter.name}" vlan-private.json )
            echo $c". "$TEMP
        done
        echo $c".  Create your new private VLAN${normal}"
        echo "${bold}Type 0 to refresh available VLANs${normal}"
        read -p "${bold}Choose a private VLAN option:${normal} " -e VLAN_PRIVATE_OPTION

        if (($VLAN_PRIVATE_OPTION == $c))
        then create_private_vlan
        elif (($VLAN_PRIVATE_OPTION>0)) && (($VLAN_PRIVATE_OPTION<=$LENGTH))
        then echo "${bold}Writing Private VLAN...${normal}"
             VLAN_PRIVATE_OPTION=$VLAN_PRIVATE_OPTION-1
             PRIVATE=$(jq .[$VLAN_PRIVATE_OPTION].id vlan-private.json)
             cp ./workspace-configuration.json temp.json
             jq -r --arg v "$PRIVATE" '(.template_data[] | .variablestore[] | select(.name == "private_vlan_number") | .value) |= $v' temp.json > workspace-configuration.json
             echo "${bold}Wrote Private VLAN ${green}$PRIVATE ${normal}"
             break
        elif (($VLAN_PRIVATE_OPTION == 0))
        then echo "${bold}Refrehing Private Vlans...${normal}"
                ibmcloud sl vlan list --output json > vlan.json
                jq --arg v "$DATACENTER" '[.[] | select(.primaryRouter.datacenter.name | contains($v)) | select(.networkSpace | contains("PRIVATE"))]' vlan.json > vlan-private.json
        else echo "${bold}PLEASE TRY AGAIN${normal}"
                ibmcloud sl vlan list --output json > vlan.json
                jq --arg v "$DATACENTER" '[.[] | select(.primaryRouter.datacenter.name | contains($v)) | select(.networkSpace | contains("PRIVATE"))]' vlan.json > vlan-private.json
        fi
    done    
}

create_public_vlan() {
    echo "${bold}creating public vlan${normal}"
    ibmcloud sl vlan create -t public -d $DATACENTER -n sandbox-public -f --output json > logs/vlan-public-$WORKSPACE_NAME.json
    echo "${bold}Public Vlan creation started, this process may take some time.${normal}"
    echo "${bold}You may continue to refresh the vlan list until it appears, cancel this current sandbox creation, or choose another vlan${normal}"
    echo "${bold}The VLAN confirmation can be foudn in ${green}logs/vlan-public-$WORKSPACE_NAME${normal}"
    ibmcloud sl vlan list --output json > vlan.json
    jq --arg v "$DATACENTER" '[.[] | select(.primaryRouter.datacenter.name | contains($v)) | select(.networkSpace | contains("PUBLIC"))]' vlan.json > vlan-public.json
}

get_public_vlan() {
    VLAN_PUBLIC_OPTION="0"
    
    while true;
    do
        echo "${green}"
        for (( c=1; c<=$LENGTH; c++))
        do 
            TEMP=$(jq -c ".[$c-1] | {id: .id, name: .name, vlanNumber: .vlanNumber, datacenter: .primaryRouter.datacenter.name}" vlan-public.json )
            echo $c". "$TEMP
        done
        echo $c".  Create your new public VLAN${normal}"
        echo "${bold}Type 0 to refresh available VLANs${normal}"
        read -p "${bold}Choose a public VLAN option:${normal} " -e VLAN_PUBLIC_OPTION

        if (($VLAN_PUBLIC_OPTION == $c))
        then create_public_vlan
        elif (($VLAN_PUBLIC_OPTION>0)) && (($VLAN_PUBLIC_OPTION<=$LENGTH))
        then echo "${bold}writing Public VLAN${normal}"
             VLAN_PUBLIC_OPTION=$VLAN_PUBLIC_OPTION-1
             PUBLIC=$(jq .[$VLAN_PUBLIC_OPTION].id vlan-public.json)
             cp ./workspace-configuration.json temp.json
             jq -r --arg v "$PUBLIC" '(.template_data[] | .variablestore[] | select(.name == "public_vlan_number") | .value) |= $v' temp.json > workspace-configuration.json
             echo "${bold}Wrote Public VLAN ${green}$PUBLIC ${normal}"
             break
        elif (($VLAN_PUBLIC_OPTION == 0))
        then echo "${bold}Refrehing Public VLANs...${normal}"
                ibmcloud sl vlan list --output json > vlan.json
                jq --arg v "$DATACENTER" '[.[] | select(.primaryRouter.datacenter.name | contains($v)) | select(.networkSpace | contains("PUBLIC"))]' vlan.json > vlan-public.json
        else echo "${bold}PLEASE TRY AGAIN${normal}"
                ibmcloud sl vlan list --output json > vlan.json
                jq --arg v "$DATACENTER" '[.[] | select(.primaryRouter.datacenter.name | contains($v)) | select(.networkSpace | contains("PUBLIC"))]' vlan.json > vlan-public.json
        fi
    done    
}

manage_vlan() {
    VLAN_PRIVATE_OPTION="0"
    VLAN_OPTION="0"
    LENGTH="0"
    DATACENTER=$(jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) ' workspace-configuration.json)
    
    echo "${bold}VLAN datacenter set to: ${green}$DATACENTER${normal}"
    
    ibmcloud sl vlan list --output json > vlan.json
       
    echo "${bold}Searching for VLAN's for ${green}$DATACENTER${bold}. This may take a moment${normal}"
    jq --arg v "$DATACENTER" '[.[] | select(.primaryRouter.datacenter.name | contains($v)) | select(.networkSpace | contains("PUBLIC"))]' vlan.json > vlan-public.json
    jq --arg v "$DATACENTER" '[.[] | select(.primaryRouter.datacenter.name | contains($v)) | select(.networkSpace | contains("PRIVATE"))]' vlan.json > vlan-private.json

    LENGTH=$(jq length vlan-private.json)
    if (($LENGTH))
    then
        echo "${bold}Private VLANs found${normal}"
        
        get_private_vlan
    else
        echo "${bold}Private VLANs not found, creating new vlan:${normal}"
        
        create_private_vlan
    fi

    LENGTH=$(jq length vlan-public.json)
    if (($LENGTH))
    then
        echo "${bold}Public VLANs found${normal}"
        #echo "length is not empty"
        get_public_vlan
    else
        echo "${bold}Public VLANs not found, creating new vlan:${normal}"
        #echo "length is  empty"
        create_public_vlan
    fi

    rm vlan.json
    rm vlan-public.json
    rm vlan-private.json
}

#displays all the possible regions to be selected
#information given will be used for creating new clusters
select_region() {
    # pick region and datacenter
    echo "${bold}Choose your cluster region: ${green}"
    regions=("us-east" "us-south" "eu-central" "uk-south" "ap-north" "ap-south")
    select region in "${regions[@]}"; do
        case $region in
            "us-east")
                echo "${bold}Chosen region: us-east, pease pick a data center:${green}"
                cp ./workspace-configuration.json temp.json
                jq -r '(.template_data[] | .variablestore[] | select(.name == "region") | .value) |= "us-east"' temp.json > workspace-configuration.json
                eastData=("wdc04" "wdc06" "wdc07")
                select datacenter in "${eastData[@]}"; do
                    case $datacenter in
                        "wdc04")
                            echo "${bold}Chosen data center: wdc04"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "wdc04"' temp.json > workspace-configuration.json
                            break
                            ;;
                        "wdc06")
                            echo "${bold}Chosen data center: wdc06"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "wdc06"' temp.json > workspace-configuration.json
                            break
                            ;;
                        "wdc07")
                            echo "${bold}Chosen data center: wdc07"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "wdc07"' temp.json > workspace-configuration.json
                            break
                            ;;
                        *) echo "${bold}invalid option $REPLY ${green}";;
                    esac
                done
                break
                ;;
            "us-south")
                echo "${bold}Chosen region: us-south, pease pick a data center:${green}"
                cp ./workspace-configuration.json temp.json
                jq -r '(.template_data[] | .variablestore[] | select(.name == "region") | .value) |= "us-south"' temp.json > workspace-configuration.json
                southData=("dal10" "dal12" "dal13")
                select datacenter in "${southData[@]}"; do
                    case $datacenter in
                        "dal10")
                            echo "${bold}Chosen data center: dal10"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "dal10"' temp.json > workspace-configuration.json
                            break
                            ;;
                        "dal12")
                            echo "${bold}Chosen data center: dal12"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "dal12"' temp.json > workspace-configuration.json
                            break
                            ;;
                        "dal13")
                            echo "${bold}Chosen data center: dal13"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "dal13"' temp.json > workspace-configuration.json
                            break
                            ;;
                        *) echo "${bold}invalid option $REPLY ${green}";;
                    esac
                done
                break
                ;;
            "eu-central")
                echo "${bold}Chosen region: us-central, pease pick a data center${green}"
                cp ./workspace-configuration.json temp.json
                jq -r '(.template_data[] | .variablestore[] | select(.name == "region") | .value) |= "ue-de"' temp.json > workspace-configuration.json
                euData=("fra02" "fra04" "fra05")
                select datacenter in "${euData[@]}"; do
                    case $datacenter in
                        "fra02")
                            echo "${bold}Chosen data center: fra02"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "fra02"' temp.json > workspace-configuration.json
                            break
                            ;;
                        "fra04")
                            echo "${bold}Chosen data center: fra04"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "fra04"' temp.json > workspace-configuration.json
                            break
                            ;;
                        "fra05")
                            echo "${bold}Chosen data center: fra05"
                            cp workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "fra05"' temp.json > workspace-configuration.json
                            break
                            ;;
                        *) echo "${bold}invalid option $REPLY ${green}";;
                    esac
                done
                break
                ;;
            "uk-south")
                echo "${bold}Chosen region: uk south, pease pick a data center${green}"
                cp ./workspace-configuration.json temp.json
                jq -r '(.template_data[] | .variablestore[] | select(.name == "region") | .value) |= "uk-south"' temp.json > workspace-configuration.json
                ukData=("lon04" "lon05" "lon06")
                select datacenter in "${ukData[@]}"; do
                    case $datacenter in
                        "lon04")
                            echo "${bold}Chosen data center: lon04"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "lon04"' temp.json > workspace-configuration.json
                            break
                            ;;
                        "lon05")
                            echo "${bold}Chosen data center: lon05"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "lon05"' temp.json > workspace-configuration.json
                            break
                            ;;
                        "lon06")
                            echo "${bold}Chosen data center: lon06"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "lon06"' temp.json > workspace-configuration.json
                            break
                            ;;
                        *) echo "${bold}invalid option $REPLY ${green}";;
                    esac
                done
                break
                ;;
                "ap-north")
                echo "${bold}Chosen region: ap north, pease pick a data center${green}"
                cp ./workspace-configuration.json temp.json
                jq -r '(.template_data[] | .variablestore[] | select(.name == "region") | .value) |= "ap-north"' temp.json > workspace-configuration.json
                apNorthData=("hkg02" "che01" "tok02" "tok04" "tok05" "seo01" "sng01")
                select datacenter in "${apNorthData[@]}"; do
                    case $datacenter in
                        "hkg02")
                            echo "${bold}Chosen data center: hkg02"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "hkg02"' temp.json > workspace-configuration.json
                            break
                            ;;
                        "che01")
                            echo "${bold}Chosen data center: che01"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "che01"' temp.json > workspace-configuration.json
                            break
                            ;;
                        "tok02")
                            echo "${bold}Chosen data center: tok02"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "tok02"' temp.json > workspace-configuration.json
                            break
                            ;;
                        "tok04")
                            echo "${bold}Chosen data center: tok04"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "tok04"' temp.json > workspace-configuration.json
                            break
                            ;;
                        "tok05")
                            echo "${bold}Chosen data center: tok05"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "tok05"' temp.json > workspace-configuration.json
                            break
                            ;;
                        "seo01")
                            echo "${bold}Chosen data center: seo01"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "seo01"' temp.json > workspace-configuration.json
                            break
                            ;;
                        "sng01")
                            echo "${bold}Chosen data center: sng01"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "sng01"' temp.json > workspace-configuration.json
                            break
                            ;;
                        *) echo "${bold}invalid option $REPLY ${green}";;
                    esac
                done
                break
                ;;
                "ap-south")
                echo "${bold}Chosen region: ap-south, pease pick a data center${green}"
                cp ./workspace-configuration.json temp.json
                jq -r '(.template_data[] | .variablestore[] | select(.name == "region") | .value) |= "ap-south"' temp.json > workspace-configuration.json
                apSouthData=("mel01" "syd01" "syd04" "syd05")
                select datacenter in "${apSouthData[@]}"; do
                    case $datacenter in
                        "mel01")
                            echo "${bold}Chosen data center: mel01"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "mel01"' temp.json > workspace-configuration.json
                            break
                            ;;
                        "syd01")
                            echo "${bold}Chosen data center: syd01"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "syd01"' temp.json > workspace-configuration.json
                            break
                            ;;
                        "syd04")
                            echo "${bold}Chosen data center: syd04"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "syd04"' temp.json > workspace-configuration.json
                            break
                            ;;
                        "syd05")
                            echo "${bold}Chosen data center: syd05"
                            cp ./workspace-configuration.json temp.json
                            jq -r '(.template_data[] | .variablestore[] | select(.name == "datacenter") | .value) |= "syd05"' temp.json > workspace-configuration.json
                            break
                            ;;    
                        *) echo "${bold}invalid option $REPLY ${green}";;
                    esac
                done
                break
                ;;
            *) echo "${bold}invalid option $REPLY ${green}";;
        esac
    done

    manage_vlan

}

# create workspace, keeps a copy of the input and stores in $WORKSPACE_NAME-input.json and a copy of the ouptput in $WORKSPACE_NAME-config.json
create_workspace() {
    echo
    echo "${bold}Creating workspace: ${green}$WORKSPACE_NAME${bold}...${normal}"
    #ibmcloud target -g schematics
    ibmcloud schematics workspace new --file ./logs/$WORKSPACE_NAME-input.json --json > ./logs/$WORKSPACE_NAME-config.json
    if [ $? -ne 0 ]; then
    exit 1
    fi

    echo
    WORKSPACE_ID=$(jq -r '.id' ./logs/$WORKSPACE_NAME-config.json)
    clean_entitled_key
    echo
    echo "${bold}Created workspace: ${green}$WORKSPACE_ID${bold}${normal}" 
    echo "${bold}To view workspace, login to cloud.ibm.com and go to: ${green}https://cloud.ibm.com/schematics/workspaces/$WORKSPACE_ID${normal}"
    echo "${bold}Working on setting up workspace....${green}"
    while (( x < 60 ))
    do
        update_cursor
        sleep 1
        x=$(( x+1 ))
    done
    echo
    echo "Workspace ready"
}

# Generates a workspace plan, this sets up the terraform to run in the script 
generate_workspace_plan() {
    echo "${bold}Generating workspace plan:${normal}"
    ibmcloud schematics plan --id $WORKSPACE_ID 

    echo "${bold}Schematics plan in progress...${green}"
    # creates a graphic on commond line for users to follow script is still running
    while (( x < 150 ))
    do
        update_cursor
        sleep 1
        x=$(( x+1 ))
    done

    echo "ready"
}

# Apply the workspace plan after it has been generated.
# This only starts the apply process, the process itself takes
apply_workspace_plan() {
    echo "${bold}Preparing to apply ${green}$WORKSPACE_NAME${normal}"
    ibmcloud schematics apply --id $WORKSPACE_ID --force 
    echo "${bold}Applied ${green}$WORKSPACE_NAME${normal}"
    echo "${bold}To see progress, login to cloud.ibm.com and go to: ${green}https://cloud.ibm.com/schematics/workspaces/$WORKSPACE_ID${normal}"
    echo "${bold}Once there click '${green}Activity${bold}' on the left, then select ${green}View Log${bold} from the '${green}Applying Plan${bold}' activity${normal}"
}

# clean the entitled registry key values and replace with SENSITIVE_DATA
clean_entitled_key() {
    #sanatize .json's
    cp ./logs/$WORKSPACE_NAME-input.json temp.json
    jq -r ".template_data[0].variablestore[9].value |= \"SENSITIVE_DATA\"" temp.json > ./logs/$WORKSPACE_NAME-input.json

    cp ./logs/$WORKSPACE_NAME-config.json temp.json
    jq -r ".template_data[0].variablestore[9].value |= \"SENSITIVE_DATA\"" temp.json > ./logs/$WORKSPACE_NAME-config.json
    rm temp.json    
}

if [ ! -d "./logs" ] 
then mkdir logs
fi
# sets up the workspace-config.json
get_cloud_pak_install
get_workspace_name
get_meta_data
write_meta_data
get_cluster_info
write_meta_data
if ! $EXISTING_CLUSTER
    then select_region
fi


if $CP4MCM
    then cp4mcm_modules
fi
if $CP4D35
    then cp4d35_modules
fi
if $CP4D30
    then cp4d30_modules
fi


# clean up temp
cp ./workspace-configuration.json ./logs/$WORKSPACE_NAME-input.json
rm temp.json
rm workspace-configuration.json

# pushes .json using the ibmcloud schmatics plugin
create_workspace
generate_workspace_plan
apply_workspace_plan

# A post install set of messages for users to complete any remaining steps.
if $CP4MCM
then
    echo "${bold} For MCM installs the credentials can be retrieved from the 'Plan applied' log${normal}"

    echo "${bold}MCM will take approximately 40 minutes for software to install. The time is currently${green}"
    date
    echo
    echo "${bold}To monitor progress: ${green}'kubectl get pods -A | grep -Ev \"Completed|1/1|2/2|3/3|4/4|5/5|6/6|7/7\"'${bold}"
    echo "Should not return anything when MCM is up and running"
    echo
    echo "To get the URL to get to the Multicloud Management Console:"
    echo "${green}ibmcloud oc cluster config -c $CLUSTER_NAME --admin"
    echo "kubectl get route -n ibm-common-services cp-console -o jsonpath=‘{.spec.host}’ && echo"
    echo
    echo "${bold}To get default login id:${green}"
    echo "kubectl -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_username}\' | base64 -d && echo"
    echo
    echo "${bold}To get default Password:${green}"
    echo "kubectl -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d && echo${normal}"
fi

if $CP4I
then
    echo "${bold}Cloud Pak for Integrations will be available in about 30 minutes.${green}"
    date
    echo
    echo "${bold}When the installation is finished Platform Navigator run the below command in OpenShift Cli to get the dashboard ${green}"
    echo " oc describe PlatformNavigator cp4i-navigator --namespace=cp4i | grep https://cp4i-navigator ${normal}"
    echo "${bold}or run this and look for endpoint.uri ${green}"
    echo " oc describe PlatformNavigator cp4i-navigator --namespace=cp4i${normal}"
    echo
    echo "${bold}To get the default login credentials go to: ${green} https://www.ibm.com/support/knowledgecenter/SSGT7J_20.3/install/initial_admin_password.html"
    echo "${bold}or run: ${green} oc get secrets -n ibm-common-services platform-auth-idp-credentials -ojsonpath='{.data.admin_password}' | base64 --decode && echo ""  ${normal}"
fi


if $CP4AUTO
then
    echo "${bold}Cloud Pak for Integrations will be available in about 30 minutes.${green}"
fi