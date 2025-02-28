#Download scommand to run the loadtest from cloudtest
cloudtest_url=https://ec2-18-235-65-145.compute-1.amazonaws.com/concerto
sc_zip_url=$cloudtest_url/downloads/scommand/scommand.zip
wget --no-check-certificate --no-verbose -O scommand.zip $sc_zip_url
unzip ./scommand.zip

#Send the custom annotation event to dynatrace for L&P Test Start
DYNATRACE_BASE_URL="$1"
DYNATRACE_API_TOKEN="$2"
DYNATRACE_API_URL="$1/api/v1/events"
TMP_TAG_STRUCTURE=$3
SCRIPT=$4
CLOUDTEST_USERNAME=$5
CLOUDTEST_PASSWORD=$6
AZ_RELEASE_DEFINITION_NAME=$7
AZ_RELEASE_NAME=$8

TAG_STRUCTURE=$(echo $TMP_TAG_STRUCTURE|jq '.')

#Obtain the current time and converts to UTC to set the start load test variable
start_test=$(TZ="EST5EDT" date "+%Y-%m-%d %H:%M:%S")
start_test_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
startux="$(date -d "${start_test_utc}" +%s)000"
echo "##vso[task.setvariable variable=STARTLPTEST]$start_test_utc"

#start load test
echo ""
echo "================================================================="
echo "Load and Performance Test Information:"
echo ""
echo "SCRIPT                     = $SCRIPT"
echo "CLOUDTEST_URL              = $cloudtest_url"
echo "CLOUDTEST_USERNAME         = $CLOUDTEST_USERNAME"
echo "CLOUDTEST_PASSWORD         = $CLOUDTEST_PASSWORD"
echo "================================================================="

echo ""
echo "Executing L&P Test..."
loadtest=$(./\scommand/\bin/\scommand cmd=play name="$SCRIPT" username="$CLOUDTEST_USERNAME" password="$CLOUDTEST_PASSWORD" url="$cloudtest_url" wait)
echo ""
if [[ $loadtest = *"status Completed"* ]]; then
        echo "L&P Test finished"
        echo ""
        if [[ $loadtest = *"errors: 0"* ]]; then
                echo "The L&P Test finished without errors:"
                loadtest_result=$(echo $loadtest | sed -n 's/.*\.\.\. \(.*\)/\1/p')
                echo $loadtest_result
        else
                echo "The L&P Test finished with errors:"
                echo $loadtest
                exit 1
        fi
else
        echo "Error executing L&P Test"
        echo ""
        echo $loadtest
        exit 1
fi

#Obtain the current time and converts to UTC to set the end load test variable
end_test=$(TZ="EST5EDT" date "+%Y-%m-%d %H:%M:%S")
end_test_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
endux="$(date -d "${end_test_utc}" +%s)000"
echo "##vso[task.setvariable variable=ENDLPTEST]$end_test_utc"

#Send the custom annotation event to dynatrace for L&P Test End
echo "================================================================="
echo "Dynatrace Custom Annotation Event:"
echo ""
echo "DYNATRACE_BASE_URL         = $DYNATRACE_BASE_URL"
echo "DYNATRACE_API_URL          = $DYNATRACE_API_URL"
echo "DYNATRACE_API_TOKEN        = $DYNATRACE_API_TOKEN"
echo "TAG_STRUCTURE              = $TMP_TAG_STRUCTURE"
echo "SCRIPT                     = $SCRIPT"
echo "START LOAD TEST            = $start_test"
echo "END LOAD TEST              = $end_test"
echo "================================================================="
echo ""
POST_DATA=$(cat <<EOF
    {
        "eventType" : "CUSTOM_ANNOTATION",
        "annotationType" : "L&P Test for $AZ_RELEASE_DEFINITION_NAME $AZ_RELEASE_NAME",
        "annotationDescription": "L&P Test for $AZ_RELEASE_DEFINITION_NAME $AZ_RELEASE_NAME",
        "source" : "$cloudtest_url",
        "start" : "$startux",
        "end" : "$endux",
        "attachRules" : {
            "tagRule" : [
                {
                    "meTypes":"SERVICE" ,
                    "tags" :  $TAG_STRUCTURE
                }
                ]
                },"customProperties" :
                {        "Script Path" : "$SCRIPT"
                    }
    }
EOF
)
echo $POST_DATA
curl -s --url "$DYNATRACE_API_URL" -H "Content-type: application/json" -H "Authorization: Api-Token "$DYNATRACE_API_TOKEN -X POST -d "$POST_DATA"
