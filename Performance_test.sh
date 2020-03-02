DYNATRACE_BASE_URL="$1"
DYNATRACE_API_TOKEN="$2"
DYNATRACE_API_URL="$1/api/v1/events"

ENVIONMENT_TAG="$3"
APP_TAG="$4"

echo "================================================================="
echo "Dynatrace Deployment event:"
echo ""
echo "DYNATRACE_BASE_URL         = $DYNATRACE_BASE_URL"
echo "DYNATRACE_API_URL          = $DYNATRACE_API_URL"
echo "DYNATRACE_API_TOKEN        = $DYNATRACE_API_TOKEN"
echo "ENVIONMENT_TAG             = $ENVIONMENT_TAG"
echo "APP_TAG                    = $APP_TAG"
echo "================================================================="
POST_DATA=$(cat <<EOF
    {
        "eventType" : "PERFORMANCE_EVENT",
        "description" : "Load performance to service",
        "title" : "Load performance test",
        "source" : "Cloudtest",
        "attachRules" : {
               "tagRule" : [
                   {
                        "meTypes":"SERVICE" ,
                        "tags" : [
                            {
                                "context" : "CONTEXTLESS",
                                "key": "$ENVIONMENT_TAG"    
                            },
                            {
                                "context" : "CONTEXTLESS",
                                "key": "$APP_TAG"    
                            }
                            ]
                   }
                   ]
        }
    }
EOF
)
echo $POST_DATA
curl --url "$DYNATRACE_API_URL" -H "Content-type: application/json" -H "Authorization: Api-Token "$DYNATRACE_API_TOKEN -X POST -d "$POST_DATA"
