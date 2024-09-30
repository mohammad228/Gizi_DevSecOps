#!/bin/sh
echo ${CI_PROJECT_NAME}
echo ${CI_COMMIT_BRANCH}
echo $CI_PROJECT_DIR
echo ${FULL_IMAGE_NAME}
echo ${CI_COMMIT_SHORT_SHA}
echo ${ENG_ID}
echo ${GOLANG}
echo ${SERVICE}

trivy_failed=0
. /venv/bin/activate
echo "------------------------------Code Scan with GOSEC----------------------------------------------"
echo "------------------------------Current directory ----------------------------------------------"
echo $PATH
time pwd
if [ -n "$GOLANG" ] && [ "$GOLANG" = "true" ]; then
  echo "GOLANG variable exists and is true, running gosec scan..."
  time gosec -fmt=json -out=results.json "$CI_PROJECT_DIR"
else
  echo "GOLANG variable either does not exist or is not set to true, skipping gosec scan..."
  
  semgrep --version
  semgrep scan  --config auto --json -o semgrep.json

fi
Scan_Path = "$CI_PROJECT_DIR"
if [ -n "$SERVICE" ]; then
  if [ "$SERVICE" = "deposit" ]; then
    $Scan_Path="$CI_PROJECT_DIR"
  elif [ "$SERVICE" = "withdrawals" ]; then
    $Scan_Path="$CI_PROJECT_DIR/src/services/withdrawals"
  elif [ "$SERVICE" = "rebalancer" ]; then
    $Scan_Path="$CI_PROJECT_DIR/src/services/rebalancer"
  elif [ "$SERVICE" = "address-management" ]; then
    $Scan_Path="$CI_PROJECT_DIR"
  else
    $Scan_Path = $CI_PROJECT_DIR
  fi
fi


echo "------------------------------Code Scan with Trivy----------------------------------------------"
TRIMMED_REPORT_FILE_NAME=$(echo "$REPORT_FILE_NAME" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
echo trivy fs --exit-code 1 --severity HIGH,CRITICAL --format json -o FS_report.json "$Scan_Path"
time trivy fs --exit-code 1 --severity HIGH,CRITICAL --format json -o FS_report.json "$Scan_Path"
if [ $? -ne 0 ]; then
  echo "Trivy FS scan failed with exit code 1."
  trivy_failed=1
fi

echo "------------------------------IAC Scan ----------------------------------------------"
echo trivy config --exit-code 1 --severity HIGH,CRITICAL --format json -o IAC_report.json "$Scan_Path" 
time trivy config --exit-code 1 --severity HIGH,CRITICAL --format json -o IAC_report.json "$Scan_Path" 
if [ $? -ne 0 ]; then
  echo "Trivy IAC scan failed with exit code 1."
  trivy_failed=1
fi



echo trivy image --exit-code 1 --severity HIGH,CRITICAL --cache-dir .trivycache/ --format json  -o CON_report.json $FULL_IMAGE_NAME
time trivy image --timeout 15m --exit-code 1 --severity HIGH,CRITICAL --cache-dir .trivycache/ --format json  -o CON_report.json $FULL_IMAGE_NAME
if [ $? -ne 0 ]; then
  echo "Trivy Container scan failed with exit code 1."
  trivy_failed=1
fi

DEFECTDOJO_API_KEY="Your API KEY for DOJO"
DEFECTDOJO_URL="Your Dojo URL"
DEFECTDOJO_PRODUCT_ID=$ENG_ID

echo "------------------------------Upload Scan Reports to DefectDojo----------------------------------------------"

upload_to_defectdojo() {
  report_name="$1"
  report_file="$2"
  scantype="$3"
  echo "Uploading $report_name report to DefectDojo..."

  time curl -X POST "$DEFECTDOJO_URL/import-scan/" \
    -H "Authorization: Token $DEFECTDOJO_API_KEY" \
    -F "scan_type=$scantype" \
    -F "file=@$report_file" \
    -F "engagement=$DEFECTDOJO_PRODUCT_ID" \
    -F "test_title"=${report_name}_${CI_COMMIT_SHORT_SHA} \
    -F "deduplication_on_engagement"=false
}

# Upload each report to DefectDojo
upload_to_defectdojo "Filesystem" "FS_report.json" "Trivy Scan"
upload_to_defectdojo "Container" "CON_report.json" "Trivy Scan"
upload_to_defectdojo "IAC" "IAC_report.json" "Trivy Scan"
if [ -n "$GOLANG" ] && [ "$GOLANG" = "true" ]; then

  upload_to_defectdojo "GOSEC" "results.json" "Gosec Scanner"
 else
  upload_to_defectdojo "SEMGREP" "semgrep.json" "Semgrep JSON Report"
fi

if [ $trivy_failed -eq 1 ]; then
  echo "At least one trivy scan failed. Exiting the script..."
  exit 1
fi