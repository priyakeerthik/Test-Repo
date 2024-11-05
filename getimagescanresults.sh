#!/bin/bash

ECR_REPO=$1
IMAGE_TAG=$2
REGION=$3
SCAN_STATUS=1

# Check if scan is complete
until [ "$SCAN_STATUS" -eq "0" ];
do  
  echo "aws ecr wait image-scan-complete --region $REGION --repository-name $ECR_REPO --image-id imageTag=$IMAGE_TAG"
  SCAN_STATUS=$(aws ecr wait image-scan-complete --region $REGION --repository-name $ECR_REPO --image-id imageTag=$IMAGE_TAG; echo $?)
  echo "Waiting for scan to complete"
  sleep 5
done

# Get the Scan results
echo "aws ecr describe-image-scan-findings --region $REGION --repository-name $ECR_REPO --image-id imageTag=$IMAGE_TAG | jq '.imageScanFindings.findingSeverityCounts'"
SCAN_FINDINGS=$(aws ecr describe-image-scan-findings --region $REGION --repository-name $ECR_REPO --image-id imageTag=$IMAGE_TAG | jq '.imageScanFindings.findingSeverityCounts')

CRITICAL=$(echo $SCAN_FINDINGS | jq '.CRITICAL')
HIGH=$(echo $SCAN_FINDINGS | jq '.HIGH')
MEDIUM=$(echo $SCAN_FINDINGS | jq '.MEDIUM')
LOW=$(echo $SCAN_FINDINGS | jq '.LOW')
INFORMATIONAL=$(echo $SCAN_FINDINGS | jq '.INFORMATIONAL')
UNDEFINED=$(echo $SCAN_FINDINGS | jq '.UNDEFINED')

echo "CHECK IF DOCKERFILE HAS LINT ERROR:"
LINTERR=$(grep error dockerlinter.log|wc -l)
if [ "$LINTERR" -gt "0" ]; then
   echo "======================================"
   echo "** Dockerfile contains lint errors ***"
   echo "======================================"
   exit 1 
fi

echo "CHECK IF DOCKER_IMAGE HAS VULNERABILITIES:"
if [ $CRITICAL != null ] || [ $HIGH != null ]; then
 if [ "$HIGH" -gt "50" ]; then
   echo "============================================"
   echo "** Docker image contains vulnerabilities ***"
   echo "============================================"
   exit 1  
 fi
fi

echo "INFO: No Vulnerabilities found"
