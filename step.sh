#!/bin/bash

# Helper for finishing and exiting.
#   $0 - A summary message to be printed and exported
#   $1 - The script exit code. Defaults to 0, will be overwritten if $fail_for_bad_events is set to 'no'
finish () {
  summary="$1"
  exit_code="$2"

  # Downgrade any errors if fail_for_bad_events is turned off
  if [ "$fail_for_bad_events" = "no" ]
  then
    unset exit_code
  fi

  # Finish and exit with the appropriate code
  echo "$summary"
  exit "${exit_code:-0}"
}

echo "Checking status of collector at $collector_url..."
result=$(curl "$collector_url/micro/all")
echo "Response from the server: '$result'"

# Parse the results
total=$(jq -r '.total' <<< "$result")
good=$(jq -r '.good' <<< "$result")
bad=$(jq -r '.bad' <<< "$result")

# Check that the results were parsed properly
if [[ -z "$total" ]] || [[ -z "$good" ]] || [[ -z "$bad" ]]
then
  finish "Unable to retrieve status from the collector" 1
fi

# Export them to variables
envman add --key SNOWPLOW_MICRO_COLLECTOR_RESULTS_TOTAL --value "$total"
envman add --key SNOWPLOW_MICRO_COLLECTOR_RESULTS_GOOD --value "$good"
envman add --key SNOWPLOW_MICRO_COLLECTOR_RESULTS_BAD --value "$bad"

# TODO: In the future
# We need to do bad events parsing according to https://docs.snowplowanalytics.com/docs/managing-data-quality/testing-and-qa-workflows/set-up-automated-testing-with-snowplow-micro/#micro-bad
# Then create a junit report file that lists each issue as a failure, write it to $BITRISE_TEST_RESULT_DIR
# It will be sharable script codes among other clients like `Android` and `Web`

# After parsing, use the counts as the output summary
summary="$bad bad, $good good ($total total)"

# Check the result and finish appropriately
if [[ $total -eq 0 ]]
then
  echo "No events were received by the collector"
  finish "$summary" 1
elif [[ $bad -eq 0 ]]
then
  echo "No bad events were reported by the collector 🎉"
  finish "$summary" 0
else
  echo "The collector reported $bad bad events, exporting details to snowplow_bad.json."
  curl --silent "$collector_url/micro/bad" | jq '.' >> $BITRISE_DEPLOY_DIR/snowplow_bad.json
  finish "$summary" 1
fi
