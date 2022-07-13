#!/bin/bash
set -e

echo "Checking status of collector at $collector_url..."
result=$(curl --silent "$collector_url/micro/all")

# Parse the results
total=$(jq -r '.total' <<< "$result")
good=$(jq -r '.good' <<< "$result")
bad=$(jq -r '.bad' <<< "$result")

# Export them to variables
echo "Parsed results (total: $total, good: $good, bad: $bad)"
envman add --key SNOWPLOW_MICRO_COLLECTOR_RESULTS_TOTAL --value "$total"
envman add --key SNOWPLOW_MICRO_COLLECTOR_RESULTS_GOOD --value "$good"
envman add --key SNOWPLOW_MICRO_COLLECTOR_RESULTS_BAD --value "$bad"

# TODO: In the future
# We need to do bad events parsing according to https://docs.snowplowanalytics.com/docs/managing-data-quality/testing-and-qa-workflows/set-up-automated-testing-with-snowplow-micro/#micro-bad
# Then create a junit report file that lists each issue as a failure, write it to $BITRISE_TEST_RESULT_DIRCreate a junit report file that lists each issue as a failure, write it to $BITRISE_TEST_RESULT_DIR
# It will be sharable script codes among other clients like `Android` and `Web`

if [[ $total -eq 0 ]]
then
  echo "There are no events posted to Snowplow Micro, text failed."
  exit 1
elif [[ $bad -eq 0 ]]
then
  echo "Snowplow test was successful 🎉"
else
  echo "Failing step because Snowplow reports more than zero bad events ($bad)"
  
  # Export the bad json into a file
  curl --silent "${CP_BITRISE_SNOWPLOW_MICRO_COLLECTOR_URL}/micro/bad" | json_pp >> $BITRISE_DEPLOY_DIR/snowplow_bad.json

  exit 1
fi
