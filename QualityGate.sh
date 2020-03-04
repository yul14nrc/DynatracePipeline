#Script that sends start evaluation to keptn and loops until evaluation it's done. Later sends custom info event to dynatrace service with the details of the quality gate result.

keptnApiUrl=$1        # e.g. https://api.keptn.<YOUR VALUE>.xip.io
keptnApiToken=$2
DYNATRACE_BASE_URL="$3"
DYNATRACE_API_TOKEN="$4"
DYNATRACE_API_URL="$3/api/v1/events"
start=$5              # e.g. 2019-11-21T11:00:00.000Z
end=$6                # e.g. 2019-11-21T11:00:10.000Z
project=$7            # e.g. keptnorders
service=$8            # e.g. frontend
stage=$9              # e.g. staging

echo ""
echo "================================================================="
echo "Keptn Quality Gate:"
echo ""
echo "keptnApiUrl = $keptnApiUrl"
echo "start       = $start"
echo "end         = $end"
echo "project     = $project"
echo "service     = $service"
echo "stage       = $stage"
echo "================================================================="
echo ""

POST_DATA=$(cat <<EOF
{
  "data": {
    "start": "$start",
    "end": "$end",
    "project": "$project",
    "service": "$service",
    "stage": "$stage",
    "teststrategy": "manual"
  },
  "type": "sh.keptn.event.start-evaluation"
}
EOF
)
echo "================================================================="
echo "Dynatrace Custom Info Event:"
echo ""
echo "DYNATRACE_BASE_URL         = $DYNATRACE_BASE_URL"
echo "DYNATRACE_API_URL          = $DYNATRACE_API_URL"
echo "DYNATRACE_API_TOKEN        = $DYNATRACE_API_TOKEN"
echo "ENVIRONMENT_TAG            = $stage"
echo "SERVICE_TAG                = $service"
echo "================================================================="
echo ""
POST_DATA=$(cat <<EOF
    {
        "eventType" : "CUSTOM_INFO",
        "description" : "Quality gate result for release ...",
        "title" : "Quality Gate Result",
        "source" : "Keptn" ,
        "attachRules" : {
               "tagRule" : [
                   {
                        "meTypes":"SERVICE",
                        "tags" : [
                            {
                                "context" : "CONTEXTLESS",
                                "key": "$stage"
                            },
                            {
                                    "context" : "CONTEXTLESS",
                                    "key": "$service"
                            }
                                                                  ]
                   }
                   ]
        },"customProperties" :
                {        "Keptn Bridge" : "https://bridge.keptn.35.238.204.253.xip.io/project/carnival",
                         "Keptn Context" : "${ctxid}",
                         "Status" : "${status^}",
                         "Score" : "$score%" }
    }
EOF
)
echo $POST_DATA
curl -s --url "$DYNATRACE_API_URL" -H "Content-type: application/json" -H "Authorization: Api-Token "$DYNATRACE_API_TOKEN -X POST -d "$POST_DATA"
