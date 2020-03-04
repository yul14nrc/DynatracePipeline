# Unix Shell script to send an create Dynatrace deployment API call 
# in AzureDev Ops pilelines can use built in environment variables
# "$(dynatrace-base-url)" "$(dynatrace-api-token)" $(Build.DefinitionName) $(app-problem-number) $(System.TeamProject) $(System.TeamFoundationCollectionUri)/$(System.TeamProject)/_build/results?buildId=$(Build.BuildId)' TagEnvironment TagService

DYNATRACE_BASE_URL="$1"
DYNATRACE_API_TOKEN="$2"
DYNATRACE_API_URL="$1/api/v1/events"

AZ_RELEASE_DEFINITION_NAME="$3"
AZ_RELEASE_NAME="$4"
AZ_RELEASE_TEAM_PROJECT="$5"
AZ_RELEASE_URL="$6"

TMP="$7"
TAG_STRUCTURE=$(echo $TMP|jq '.')

echo "================================================================="
echo "Dynatrace Deployment event:"
echo ""
echo "DYNATRACE_BASE_URL         = $DYNATRACE_BASE_URL"
echo "DYNATRACE_API_URL          = $DYNATRACE_API_URL"
echo "DYNATRACE_API_TOKEN        = $DYNATRACE_API_TOKEN"
echo "AZ_RELEASE_DEFINITION_NAME = $AZ_RELEASE_DEFINITION_NAME"
echo "AZ_RELEASE_NAME            = $AZ_RELEASE_NAME"
echo "AZ_RELEASE_TEAM_PROJECT    = $AZ_RELEASE_TEAM_PROJECT"
echo "AZ_RELEASE_URL             = $AZ_RELEASE_URL"
echo "TAG_STRUCTURE              = $TMP"
echo "================================================================="
POST_DATA=$(cat <<EOF
    {
        "eventType" : "CUSTOM_DEPLOYMENT",
        "source" : "AzureDevops" ,
        "deploymentName" : "$AZ_RELEASE_DEFINITION_NAME $AZ_RELEASE_NAME",
        "deploymentVersion" : "$AZ_RELEASE_NAME"  ,
        "deploymentProject" : "$AZ_RELEASE_TEAM_PROJECT" ,
        "ciBackLink" : "$AZ_RELEASE_URL",
        "attachRules" : {
               "tagRule" : [
                   {
                        "meTypes":"SERVICE" ,
                        "tags" : $TAG_STRUCTURE
                   }
                   ]
        }
    }
EOF
)
echo $POST_DATA
curl -s --url "$DYNATRACE_API_URL" -H "Content-type: application/json" -H "Authorization: Api-Token "$DYNATRACE_API_TOKEN -X POST -d "$POST_DATA"
