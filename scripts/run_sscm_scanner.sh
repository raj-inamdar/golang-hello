#!/bin/sh

printenv

if [ "$ENABLE_SSCM_SCANNER" != "true" ];then
  echo "Skipping scan step since it is not enabled."
  exit 0
fi

SCRIPT_DIR=$(dirname $0)

PREFIX="$(date '+%Y.%m.%d.%H.%M.%S')"
JAVA_OPTS=
CONFIG_FILE=$SCRIPT_DIR/gitlab-sscm-scanner-config.properties
SERVER_BASE_URL=$(grep '^[ \t]*grafeas.url[ \t]*=' $CONFIG_FILE | sed 's/^.*=[ \t]*//;s/[ \t]*$//')

JAR_FILE_NAME=sscm-scanner-0.1.0-SNAPSHOT.jar
SSCM_SCANNER_JAR=/tmp/$JAR_FILE_NAME
APPLICATION_NAME=
PROJECT_DIR=

if [ "$WERCKER_APPLICATION_NAME" != "" ];then
  # Wercker environment
  APPLICATION_NAME=$WERCKER_APPLICATION_NAME
  PROJECT_DIR=$PWD
else
  # Gitlab
  APPLICATION_NAME=$CI_PROJECT_NAME
  PROJECT_DIR=$CI_PROJECT_DIR
fi

GRAFEAS_PROJECT_NAME="metalinter-scanned-$APPLICATION_NAME"

findProxies() {
  analyzeProxy "http" $http_proxy
  analyzeProxy "https" $https_proxy
}

analyzeProxy() {
  type=$1
  proxy=$2

  echo "Analyzing proxy $proxy of type $type"

  if [ "$proxy" != "" ];then
    host=$(echo $proxy | sed 's?.*//\(.*\):.*?\1?')
    port=$(echo $proxy | sed 's/.*://')
    # Check if proxy is reachable. If not, we are probably in an env with no proxy
    nslookup $host 2>&1 | grep "can't" 
    if [ $? == 0 ];then
      echo "Failed to lookup proxy host: $host. Resetting $type proxy"
      if [ "$type" == "http" ];then
        export http_proxy=
        export HTTP_PROXY=
      else
        export https_proxy=
        export HTTPS_PROXY=
      fi
    else
      JAVA_OPTS="$JAVA_OPTS -D$type.proxyHost=$host -D$type.proxyPort=$port"
    fi
  fi
}

get_sscm_scanner_jar() {

  # Cannot download copy from Artifactory, so use a built-in copy in the image.
  # This implies that we may run with a stale copy. We will need to occassionally 
  # update the image with the latest sscm-scanner-0.1.0-SNAPSHOT.jar. 
  # Note that, eventually when sscm-scanner stabilizes we may run with a "released"
  # copy which will be baked in the image and download it every time during a run
  # anyway. So eventually this will not be an issue.
  if [ "$WERCKER_APPLICATION_NAME" != "" ];then
    SSCM_SCANNER_JAR=$SCRIPT_DIR/$JAR_FILE_NAME
    return
  fi

  # While running within a runner, fetch the latest copy.
  # Note that, as mentioned above, we may not need to do this eventually.
  $SCRIPT_DIR/download_sscm_scanner.sh $SSCM_SCANNER_JAR
}

prepare() {
  echo "Preparing ..."
  echo "curl -v $SERVER_BASE_URL/v1alpha1/projects/$GRAFEAS_PROJECT_NAME | grep projects/$GRAFEAS_PROJECT_NAME "
  curl -v $SERVER_BASE_URL/v1alpha1/projects/$GRAFEAS_PROJECT_NAME | grep projects/$GRAFEAS_PROJECT_NAME 
  if [ $? != 0 ];then
    echo "Creating project projects/$GRAFEAS_PROJECT_NAME"
    echo "curl -v -X POST $SERVER_BASE_URL/v1alpha1/projects -d '{\"name\": \"projects/$GRAFEAS_PROJECT_NAME\" }'"
    curl -v -X POST $SERVER_BASE_URL/v1alpha1/projects -d "{\"name\": \"projects/$GRAFEAS_PROJECT_NAME\" }"
  fi
  echo "curl -v $SERVER_BASE_URL/v1alpha1/projects "
  curl -v $SERVER_BASE_URL/v1alpha1/projects 
}

performScan() {
  echo "Running scan ..."

  echo "java $JAVA_OPTS -jar $SSCM_SCANNER_JAR $SSCM_SCANNER_EXTRA_ARGS -config=$CONFIG_FILE -occurrencePrefix=$PREFIX -projectName=$APPLICATION_NAME -projectDir=$PROJECT_DIR"
  # java $JAVA_OPTS -jar $SSCM_SCANNER_JAR $SSCM_SCANNER_EXTRA_ARGS -config=$CONFIG_FILE -occurrencePrefix=$PREFIX -projectName="$APPLICATION_NAME" -projectDir="$PROJECT_DIR"
}
  

findProxies
get_sscm_scanner_jar
prepare
performScan

