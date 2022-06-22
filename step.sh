#!/bin/bash
set -e

echo "Checking status of collector at $collector_url..."
result=$(curl --silent "$collector_url/micro/all")

# Parse the results
total=$(jq '.total' <<< "$result")
good=$(jq '.good' <<< "$result")
bad=$(jq '.bad' <<< "$result")

# Export them to variables
echo "Parsed results (total: $total, good: $good, bad: $bad)"
envman add --key SNOWPLOW_MICRO_COLLECTOR_RESULTS_TOTAL --value "$total"
envman add --key SNOWPLOW_MICRO_COLLECTOR_RESULTS_GOOD --value "$good"
envman add --key SNOWPLOW_MICRO_COLLECTOR_RESULTS_BAD --value "$bad"

# TODO: Do a lot more.. Export the bad results (log files? test results?)
# TODO: Offer an option to reset?
# TODO: Maybe use a better language, Go? or Ruby?

# Fail if bad is != 0
if [ "$bad" != "0" ];
then
  echo "Failing step because Snowplow reports more than zero bad events ($bad)"
  exit 1
fi
