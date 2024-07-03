#!/bin/bash

usage() {
    echo "Please set up the required secrets in your forked GitHub repository."
    echo "REFERENCE: Your application reference number in the format RNVE-1234567-24(3)."
    echo "BIRTHDAY: Your date of birth in the format DD-MM-YYYY."
}

if [ "$#" -ne 2 ] || [ -z "$1" ] || [ -z "$2" ]; then
    usage
    exit 0
fi

# Application reference number, date of birth (dd-mm-yyyy)
applicationRefNumFull="$1" # e.g., RNVE-1234567-24(3)
dob="$2" # e.g., 23-01-1990

# Extract the application reference number without the checksum
applicationRefNum=$(echo "$applicationRefNumFull" | sed -E 's/(.*)\([0-9A-Z]\)$/\1/')

# Extract the checksum which is inside the brackets
# arn2=$(echo "$applicationRefNumFull" | grep -oP '\(\K[^)]*')
arn2=$(echo "$applicationRefNumFull" | sed -n 's/.*(\([0-9]*\)).*/\1/p')

# Break down the date of birth
enq_DOB_Date=$(echo "$dob" | cut -d'-' -f1)
enq_DOB_Month=$(echo "$dob" | cut -d'-' -f2)
enq_DOB_Year=$(echo "$dob" | cut -d'-' -f3)

# Extract parts of the application reference number
enq_arn_1=$(echo "$applicationRefNum" | cut -c3-4)
enq_arn_2=$(echo "$applicationRefNum" | cut -d'-' -f2)
enq_arn_3=$(echo "$applicationRefNum" | cut -d'-' -f3)
enq_arn_4="$arn2"

# Construct JSON data for the curl command
data_raw=$(cat <<EOF
{
  "applicationRefNum": "$applicationRefNum",
  "appDob": "",
  "appId": "591",
  "arn": "",
  "arn2": "$arn2",
  "enq_DOB_Date": "$enq_DOB_Date",
  "enq_DOB_Month": "$enq_DOB_Month",
  "enq_DOB_Year": "$enq_DOB_Year",
  "transDateTime": "",
  "reminderType": "",
  "trn": "",
  "transDateTimeEN": "",
  "transDateTimeCN": "",
  "transDateTimeHK": "",
  "ern": "",
  "officeCode": "",
  "officeName": "",
  "reminderValue": "",
  "reminderDate": "",
  "reminderMaker": "",
  "apmDetailId": "",
  "aptDateTimeEN": "",
  "aptDateTimeCN": "",
  "aptDateTimeHK": "",
  "enq_arn_1": "$enq_arn_1",
  "enq_arn_2": "$enq_arn_2",
  "enq_arn_3": "$enq_arn_3",
  "enq_arn_4": "$enq_arn_4",
  "email": "",
  "reEmail": "",
  "reminderRadio": "",
  "cancelRadio": "",
  "email1": "",
  "email2": "",
  "cancelReminder": "",
  "arnFull": "",
  "dayOfBirth": "",
  "monOfBirth": "",
  "yearOfBirth": "",
  "appointmentDateTimeMilli": ""
}
EOF
)

echo $data_raw
response=$(curl -s 'https://webapp.es2.immd.gov.hk/applies2-services/eservice2/appointment/identity/verification/enquireAppointment' -H 'Content-Type: application/json' --data-raw "$data_raw")

result=$(echo $response | jq -r 'to_entries|map("\(.key): \(.value|tostring)")|.[]')
echo $result

# Check if the code is not E-2106: NOT EXIST ARN
code=$(echo $response | jq -r '.code')
if [ "$code" != "E-2106" ]; then
    # Exit with status 1 to trigger a failure email notification
    exit 1
fi
