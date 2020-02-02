#!/bin/bash
# Author: Franklin E.
# Description: This bash script uploads a file to AWS S3 using curl & openssl. It uses a AWSV4 signature, this is required for most regions that were launched during/after 2014.

# AWS S3 Auth
S3ACCESSKEY='<AWS Access Key>';
S3SECRETKEY='<AWS Secret Key>';

# Getopts parameters
BUCKET="";
LOCATION="";
FILE="";
REGION="";

# Function to check our vars.
function checkVars()
{
    if [ ! -z "$1" ];
    then
        echo "A parameter that is required was not specified! Please see usage example below.";
	help
        exit 1;
    fi
}

# Help function
function help()
{
    echo "Example usage:";
    echo "./s3Upload.sh -b <bucket name> -l <file path without '/' at end> -f <file name> -r <region>";
    echo "./s3Upload.sh -b bucketofchickenwings -l /home/user -f dummyfile.txt -r us-east-1";
}

# Getopts for our switches/flags. :)
while getopts ":b::l:f::r:" opt; do
  case $opt in
    b)
      BUCKET=$OPTARG >&2
      ;;
    l)
      LOCATION=$OPTARG >&2
      ;;
    f)
      FILE=$OPTARG >&2
      ;;
    r)
      REGION=$OPTARG >&2
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Verify getopts parameters.
for var in "$BUCKET" "$LOCATION" "$FILE" "$REGION";
do
    checkVars "$var";
done

PAYLOAD=$(openssl dgst -sha256 $LOCATION/$FILE | sed 's/^.* //');
AMZDATE=$(date +'%Y%m%dT%H%M%SZ');
FETCHA=$(echo $AMZDATE | cut -dT -f1)

# Canonical Request
read -r -d '' CANREQ << EOF
PUT
/$FILE

host:$BUCKET.s3.amazonaws.com
x-amz-content-sha256:$PAYLOAD
x-amz-date:$AMZDATE

host;x-amz-content-sha256;x-amz-date
$PAYLOAD
EOF

CANREQHASH=$(echo -n "$CANREQ" | openssl dgst -sha256 | sed 's/^.* //');

# String to Sign
read -r -d '' STRSIGN << EOF
AWS4-HMAC-SHA256
$AMZDATE
$FETCHA/$REGION/s3/aws4_request
$CANREQHASH
EOF

# Generate user's signing key.
# Credit: Łukasz Adamczak (https://czak.pl/2015/09/15/s3-rest-api-with-curl.html)
function hmac_sha256() 
{
  key="$1"
  data="$2"
  echo -n "$data" | openssl dgst -sha256 -mac HMAC -macopt "$key" | sed 's/^.* //';
}

# Four-step signing key calculation
dateKey=$(hmac_sha256 key:"AWS4$S3SECRETKEY" $FETCHA)
dateRegionKey=$(hmac_sha256 hexkey:$dateKey $REGION)
dateRegionServiceKey=$(hmac_sha256 hexkey:$dateRegionKey s3)
signingKey=$(hmac_sha256 hexkey:$dateRegionServiceKey "aws4_request")


# Calculate Signature
SIGNATURE=$(echo -n "$STRSIGN" | openssl dgst -sha256 -mac HMAC -macopt hexkey:$signingKey | sed 's/^.* //');

# Upload
curl -sk -X PUT -T "$LOCATION/$FILE" \
    -H "Authorization: AWS4-HMAC-SHA256 \
    Credential=$S3ACCESSKEY/$FETCHA/$REGION/s3/aws4_request, \
    SignedHeaders=host;x-amz-content-sha256;x-amz-date, \
    Signature=$SIGNATURE" \
    -H "x-amz-content-sha256: $PAYLOAD" \
    -H "x-amz-date: $AMZDATE" \
    "https://$BUCKET.s3.amazonaws.com/"
