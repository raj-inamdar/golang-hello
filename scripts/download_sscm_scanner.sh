#!/bin/sh

SSCM_SCANNER_JAR=$1

download_sscm_scanner_jar() {
  echo "Downloading latest sscm-scanner ..."
  ARTIFACTORY_BASE_URL=http://artifactory-slc.oraclecorp.com/artifactory/wls-sandbox-local

  echo "curl $ARTIFACTORY_BASE_URL/com/oracle/sscm/sscm-scanner/0.1.0-SNAPSHOT/maven-metadata.xml -o /tmp/maven-metadata.xml"
  curl $ARTIFACTORY_BASE_URL/com/oracle/sscm/sscm-scanner/0.1.0-SNAPSHOT/maven-metadata.xml -o /tmp/maven-metadata.xml
  version=$(cat /tmp/maven-metadata.xml | grep value | head -1 | sed 's?[>|<]? ?g' | awk '{print $2}')

  JAR=sscm-scanner-$version.jar

  echo "curl $ARTIFACTORY_BASE_URL/com/oracle/sscm/sscm-scanner/0.1.0-SNAPSHOT/$JAR -o $SSCM_SCANNER_JAR"
  curl $ARTIFACTORY_BASE_URL/com/oracle/sscm/sscm-scanner/0.1.0-SNAPSHOT/$JAR -o $SSCM_SCANNER_JAR
}

download_sscm_scanner_jar

