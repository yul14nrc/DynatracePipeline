#Script that sends start evaluation to keptn and loops until evaluation it's done. Later sends custom info event to dynatrace service with the details of the quality gate result.

DYNATRACE_BASE_URL="$1"
DYNATRACE_API_TOKEN="$2"
DYNATRACE_API_URL="$1/api/v1/events"

keptnApiUrl=$3        # e.g. https://api.keptn.<YOUR VALUE>.xip.io
keptnApiToken=$4
TmpTagStructure=$5
start=$6              # e.g. 2019-11-21T11:00:00.000Z
end=$7                # e.g. 2019-11-21T11:00:10.000Z
project=$8            # e.g. keptnorders
service=$9            # e.g. frontend
stage=${10}           # e.g. staging

TAG_STRUCTURE=$(echo $TmpTagStructure|jq '.')

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

echo "Sending start Keptn Evaluation"
ctxid=$(curl -s -k -X POST --url "${keptnApiUrl}/v1/event" -H "Content-type: application/json" -H "x-token: ${keptnApiToken}" -d "$POST_DATA"|jq -r ".keptnContext")
echo "keptnContext ID = $ctxid"
echo ""

loops=20
i=0
while [ $i -lt $loops ]
do
    i=`expr $i + 1`
    result=$(curl -s -k -X GET "${keptnApiUrl}/v1/event?keptnContext=${ctxid}&type=sh.keptn.events.evaluation-done" -H "accept: application/json" -H "x-token: ${keptnApiToken}")
    status=$(echo $result|jq -r ".data.evaluationdetails.result")
    score=$(echo $result|jq -r ".data.evaluationdetails.score")
    if [ "$status" = "null" ]; then
      echo "Waiting for results (attempt $i of 20)..."
      sleep 15
    else
      break
    fi
done

echo "================================================================="
echo "Evaluation Status = ${status}"
echo "Evaluation Score = ${score}%"
echo "Evaluation Result = $(echo $result|jq -r ".data.evaluationdetails")"
echo "================================================================="
echo ""
if [ "$status" = "pass" ]; then
        echo "Keptn Quality Gate - Evaluation Succeeded"
else
        echo "Keptn Quality Gate - Evaluation failed!"
        echo "For details visit the Keptn Bridge!"
        echo ""
        exit 1
fi
echo ""

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
                        "tags" : $TAG_STRUCTURE
                   }
                   ]
        },"customProperties" :
                {        "Keptn Bridge" : "https://bridge.keptn.35.238.204.253.xip.io/project/$project",
                         "Keptn Context" : "${ctxid}",
                         "Status" : "${status^}",
                         "Score" : "$score%" }
    }
EOF
)
echo $POST_DATA
curl -s --url "$DYNATRACE_API_URL" -H "Content-type: application/json" -H "Authorization: Api-Token "$DYNATRACE_API_TOKEN -X POST -d "$POST_DATA"
