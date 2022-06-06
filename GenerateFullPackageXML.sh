#!/bin/bash
#
# Generate a full package xml using the Salesforce CLI

# Requirements :
#   * Salesforce CLI
#   * jq

#List all metadata that support * for speed increase
MetadataAll="AccountRelationshipShareRule,ActionLinkGroupTemplate,ApexClass,ApexComponent,
ApexPage,ApexTrigger,AppMenu,ApprovalProcess,ArticleType,AssignmentRules,Audience,AuthProvider,
AuraDefinitionBundle,AutoResponseRules,Bot,BrandingSet,CallCenter,Certificate,CleanDataService,
CMSConnectSource,Community,CommunityTemplateDefinition,CommunityThemeDefinition,CompactLayout,
ConnectedApp,ContentAsset,CorsWhitelistOrigin,CustomApplication,CustomApplicationComponent,
CustomFeedFilter,CustomHelpMenuSection,CustomMetadata,CustomLabels,CustomObjectTranslation,
CustomPageWebLink,CustomPermission,CustomSite,CustomTab,DataCategoryGroup,DelegateGroup,
DuplicateRule,EclairGeoData,EntitlementProcess,EntitlementTemplate,EventDelivery,EventSubscription,
ExternalServiceRegistration,ExternalDataSource,FeatureParameterBoolean,FeatureParameterDate,FeatureParameterInteger,
FieldSet,FlexiPage,Flow,FlowCategory,FlowDefinition,GlobalValueSet,GlobalValueSetTranslation,Group,HomePageComponent,
HomePageLayout,InstalledPackage,KeywordList,Layout,LightningBolt,LightningComponentBundle,LightningExperienceTheme,
LiveChatAgentConfig,LiveChatButton,LiveChatDeployment,LiveChatSensitiveDataRule,ManagedTopics,MatchingRules,MilestoneType,
MlDomain,ModerationRule,NamedCredential,Network,NetworkBranding,PathAssistant,PermissionSet,PlatformCachePartition,
Portal,PostTemplate,PresenceDeclineReason,PresenceUserConfig,Profile,ProfilePasswordPolicy,ProfileSessionSetting,
Queue,QueueRoutingConfig,QuickAction,RecommendationStrategy,RecordActionDeployment,ReportType,Role,SamlSsoConfig,
Scontrol,ServiceChannel,ServicePresenceStatus,SharingRules,SharingSet,SiteDotCom,Skill,StandardValueSetTranslation,
StaticResource,SynonymDictionary,Territory,Territory2,Territory2Model,Territory2Rule,Territory2Type,TopicsForObjects,
TransactionSecurityPolicy,Translations,WaveApplication,WaveDashboard,WaveDataflow,WaveDataset,WaveLens,WaveTemplateBundle,
WaveXmd,Workflow"

#######################################
# Generate timestamp for debug purpouses
# Returns:
#   string
#######################################
function timeStamp() {
    echo $(date "+%Y/%m/%d %T")
}

#######################################
# Generate XML for a metadata type name
# Arguments:
#   metadata type name
# Returns:
#   xml
#######################################
function generateNameXML() {
    local name=$1
    echo "<name>${name}</name>"
}

#######################################
# Generate XML for a metadata name
# Arguments:
#   metadata name
# Returns:
#   xml
#######################################
function generateMemberXML() {
    local member=$1
    if [ $member == "$$_" ]; then
        echo "<members>*</members>"
    else
        echo "<members>${member}</members>"
    fi

}

#######################################
# Convert JSON list metadata to a list
# Arguments:
#   list metadata names in JSON format
# Returns:
#   list of metadata names
#######################################
function convertListMetadata() {

    local listMetadataJSON=$1

    if [ "${listMetadataJSON}" != "null" ]; then

        isArray=$(echo ${listMetadataJSON} | jq 'if type=="array" then 1 else 0 end')

        if [ "$isArray" == "1" ]; then
            listMetadataNames="$(echo ${listMetadataJSON} | jq -r '.[] | .fullName' | tr '\n' ':')"
        else
            listMetadataNames="$(echo ${listMetadataJSON} | jq -r '.fullName' | tr '\n' ':')"
        fi
        echo ${listMetadataNames}
    fi

}

#######################################
# List metadata names for a metadata type
# Arguments:
#   api version
#   metadata type name
#   metadata type in folder flag
# Returns:
#   list of metadata names
#######################################
function listMetadataNames() {

    local apiVersion=$1
    local metadataTypeName=$2
    local metadataTypeInFolder=$3

    ## metadata type in folder
    if [ "${metadataTypeInFolder}" == "true" ]; then
        if [ "${metadataTypeName}" == "Report" ]; then
            local metadataTypeNameFolder="ReportFolder"
        fi
        if [ "${metadataTypeName}" == "Dashboard" ]; then
            local metadataTypeNameFolder="DashboardFolder"
        fi
        if [ "${metadataTypeName}" == "Document" ]; then
            local metadataTypeNameFolder="DocumentFolder"
        fi
        if [ "${metadataTypeName}" == "EmailTemplate" ]; then
            local metadataTypeNameFolder="EmailFolder"
        fi

        # list folders
        local listMetadataFolderResult=$(echo $(sfdx force:mdapi:listmetadata -u ${aliasOrg} -m ${metadataTypeNameFolder} --json) | jq '.result')
        local listMetadataFolders=$(convertListMetadata "${listMetadataFolderResult}")
        local listMetadataAllFolderItems=""
        # loop through folders
        IFS=":" read -ra listMetadataFoldersArray <<<"${listMetadataFolders}"
        for folder in ${listMetadataFoldersArray[@]}; do
            # list folder items
            local listMetadataFolderItemResult=$(echo $(sfdx force:mdapi:listmetadata -u ${aliasOrg} -m ${metadataTypeName} --folder ${folder} --json) | jq '.result')
            local listMetadataFolderItems="$(convertListMetadata "${listMetadataFolderItemResult}")"
            if [ "${listMetadataFolderItems}" != "" ]; then
                listMetadataAllFolderItems="${listMetadataAllFolderItems}${listMetadataFolderItems}"
                echo "${listMetadataFolderItems}"
            fi
        done
        local listMetadata="${listMetadataFolders}${listMetadataAllFolderItems}"
        echo "${listMetadata}"
    else
        isMetadataAll=$(echo $MetadataAll | grep -wc ${metadataTypeName})
        if [[ $isMetadataAll -eq 1 ]]; then
            echo "$$_"
        else
            local listMetadataResult=$(echo $(sfdx force:mdapi:listmetadata -u ${aliasOrg} -m ${metadataTypeName} --json) | jq '.result')
            echo "$(convertListMetadata "${listMetadataResult}")"
        fi
    fi
}

#######################################
# Generate XML for a metadata type
# Arguments:
#   api version
#   metadata type name
#   metadata type in folder flag
# Returns:
#   xml
#######################################
function generateTypeXML() {

    local apiVersion=$1
    local metadataTypeName=$2
    local metadataTypeInFolder=$3

    local listMetadataNames="$(listMetadataNames ${apiVersion} ${metadataTypeName} ${metadataTypeInFolder})"
    if [ "${listMetadataNames}" != "" ]; then
        echo "  <types>"
        IFS=":"
        for metadataName in ${listMetadataNames}; do
            echo "Metadata Name = ${metadataName}" >&2
            echo "      $(generateMemberXML ${metadataName})"
            if [[ $(generateMemberXML ${metadataName}) == "<members>*</members>" || ${metadataTypeName} == "CustomObject" ]]; then
                local retrieveWithoutComponent=$(sfdx force:source:retrieve -m "${metadataTypeName}")
            else
                local retrieveWithComponent=$(sfdx force:source:retrieve -m "${metadataTypeName}:${metadataName}")
            fi
        done
        echo "      $(generateNameXML ${metadataTypeName})"
        echo "  </types>"
    fi

}

#######################################
# Validate if metadata type exists in restricted metadata file
# Arguments:
#   metadatatype
# Returns:
#   integer
#######################################
function validarRestrictedMetadata() {

    local metadataType=$1

    if [ -f ${restrictfilename} ]; then
        echo $(grep -w ${metadataType} ${restrictfilename} | wc -l)
    else
        echo 0
    fi
}

#######################################
# Generate Package.xml
# Arguments:
#   api version
# Returns:
#   xml
#######################################
function generatePackageXML() {
    echo "$(timeStamp) Begin Generate Package XML " >&2

    local apiVersion=$1

    local describeMetadata=$(sfdx force:mdapi:describemetadata -u ${aliasOrg} | jq -r '.result.metadataObjects | .[] | "\(.xmlName) \(.inFolder)"' | tr '\r' ' ')

    echo describeMetadata >&2

    echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    echo '<Package xmlns="http://soap.sforce.com/2006/04/metadata">'
    IFS=' '
    while read -r metadataType inFolder; do
        if [ "$(validarRestrictedMetadata ${metadataType} ${restrictfilename})" = 0 ]; then
            echo "$(timeStamp) ${metadataType}" >&2

            local typeXML="$(generateTypeXML ${apiVersion} ${metadataType} ${inFolder})"

            if [ "${typeXML}" != "" ]; then
                echo "${typeXML} "
            fi
        fi
    done <<<"$describeMetadata"
    echo "  <version>${apiVersion}</version>"
    echo '</Package>'
    echo "$(timeStamp) End Generate Package XML " >&2
    # echo "$(timeStamp) Begin retrieve Metadata Process " >&2
    # echo "$(timeStamp) Processing........................ " >&2
    # local retrieveMetada=$(sfdx force:mdapi:retrieve -r ./ -k package.xml -u ${aliasOrg})
    # echo "$(timeStamp) End retrieve Metadata Process " >&2
    # echo "$(timeStamp) Begin unzip Metadata Process " >&2
    # echo "$(timeStamp) Processing........................ " >&2
    # local unzipretrieve=$(unzip unpackaged.zip -d src/)
    # echo "$(timeStamp) End unzip Metadata Process " >&2
    # echo "$(timeStamp) Begin convert Metadata Process " >&2
    # echo "$(timeStamp) Processing........................ " >&2
    # local converMetadata=$(sfdx force:mdapi:convert -r ./src/unpackaged/ --outputdir ./Salesforce/)
    # echo "$(timeStamp) End convert Metadata Process " >&2
    # echo "$(timeStamp) Cleanup Temporal Files and Folders " >&2
    # echo "$(timeStamp) Processing........................ " >&2
    # local deleteunzip=$(rm -r src/)
    # local deletepackage=$(rm package.xml)
    # local deletezip=$(rm unpackaged.zip)
    echo "$(timeStamp) End All Process " >&2
}

#######################################
# Main function
# Arguments:
#   api version
#   path to the package xml to output
# Returns:
#   package.xml file
#######################################
main() {
    local aliasOrg=$1
    local outputFile=${2:-'package.xml'}
    local apiVersion=${3:-'52.0'}
    local restrictfilename=${4:-'restrictfilename.txt'}

    echo ' _        _    ____ ______  ______' >&2
    echo '| |      / \  | __ ) ___\ \/ /  _ \' >&2
    echo '| |     / _ \ |  _ \___ \\  /| | | |' >&2
    echo '| |___ / ___ \| |_) |__) /  \| |_| |' >&2
    echo '|_____/_/   \_\____/____/_/\_\____/' >&2
    echo 'The use of this script is at your own risk and is not maintained.' >&2
    echo ' ____  _______     _____  ____  ____' >&2
    echo '|  _ \| ____\ \   / / _ \|  _ \/ ___|' >&2
    echo '| | | |  _|  \ \ / / | | | |_) \___ \' >&2
    echo '| |_| | |___  \ V /| |_| |  __/ ___) |' >&2
    echo '|____/|_____|  \_/  \___/|_|   |____/' >&2

    generatePackageXML ${apiVersion} >${outputFile}
}

main "$@"
