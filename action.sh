#!/usr/bin/env bash

set -e;

if [[ -z "${ACTIONS_RUNTIME_URL}" ]]; then
	echo "::error::ACTIONS_RUNTIME_URL is missing. Uploading artifacts won't work without it. See https://github.com/KOLANICH-GHActions/passthrough-restricted-actions-vars and https://github.com/KOLANICH-GHActions/node_based_cmd_action_template";
	exit 1;
fi;

if [[ -z "${ACTIONS_RUNTIME_TOKEN}" ]]; then
	echo "::error::ACTIONS_RUNTIME_TOKEN is missing. Uploading artifacts won't work without it. See https://github.com/KOLANICH-GHActions/passthrough-restricted-actions-vars and https://github.com/KOLANICH-GHActions/node_based_cmd_action_template";
	exit 1;
fi;

ACTION_MAIN_SCRIPT_DIR=`dirname "${BASH_SOURCE[0]}"`; # /home/runner/work/_actions/KOLANICH-GHActions/typical-python-workflow/master
echo "This script is $ACTION_MAIN_SCRIPT_DIR";
export ACTION_MAIN_SCRIPT_DIR=`realpath "${ACTION_MAIN_SCRIPT_DIR}"`;
echo "This script is $ACTION_MAIN_SCRIPT_DIR";
export ACTIONS_DIR=`realpath "$ACTION_MAIN_SCRIPT_DIR/../../.."`;

export ISOLATE="${ACTION_MAIN_SCRIPT_DIR}/isolate.sh";

AUTHOR_NAMESPACE=KOLANICH-GHActions;

export SETUP_ACTION_REPO=$AUTHOR_NAMESPACE/setup-python;
export GIT_PIP_ACTION_REPO=$AUTHOR_NAMESPACE/git-pip;
export APT_ACTION_REPO=$AUTHOR_NAMESPACE/apt;
export CHECKOUT_ACTION_REPO=$AUTHOR_NAMESPACE/checkout;
export ARTIFACT_ACTION_REPO=actions/upload-artifact;
export CACHE_ACTION_REPO=actions/cache;

export SETUP_ACTION_DIR=$ACTIONS_DIR/$SETUP_ACTION_REPO/master;
export GIT_PIP_ACTION_DIR=$ACTIONS_DIR/$GIT_PIP_ACTION_REPO/master;
export APT_ACTION_DIR=$ACTIONS_DIR/$APT_ACTION_REPO/master;
export ARTIFACT_ACTION_DIR=$ACTIONS_DIR/$ARTIFACT_ACTION_REPO/master;
export CACHE_ACTION_DIR=$ACTIONS_DIR/$CACHE_ACTION_REPO/master;
export CHECKOUT_ACTION_DIR=$ACTIONS_DIR/$CHECKOUT_ACTION_REPO/master;

export artifactUploadCmd="env INPUT_IF-NO-FILES-FOUND=warn INPUT_RETENTION-DAYS=0 node $ARTIFACT_ACTION_DIR/dist/index.js";

if [ -d "$CHECKOUT_ACTION_DIR" ]; then
	:
else
	$ISOLATE git clone --depth=1 https://github.com/$CHECKOUT_ACTION_REPO $CHECKOUT_ACTION_DIR;
fi;

if [ -d "$SETUP_ACTION_DIR" ]; then
	:
else
	$ISOLATE bash "$CHECKOUT_ACTION_DIR/action.sh" "$SETUP_ACTION_REPO" "" "$SETUP_ACTION_DIR" 1 0;
fi;

if [ -d "$GIT_PIP_ACTION_DIR" ]; then
	:
else
	$ISOLATE bash "$CHECKOUT_ACTION_DIR/action.sh" "$GIT_PIP_ACTION_REPO" "" "$GIT_PIP_ACTION_DIR" 1 0;
fi;

if [ -d "$APT_ACTION_DIR" ]; then
	:
else
	$ISOLATE bash "$CHECKOUT_ACTION_DIR/action.sh" "$APT_ACTION_REPO" "" "$APT_ACTION_DIR" 1 0;
fi;

if [ -d "$ARTIFACT_ACTION_DIR" ]; then
	:
else
	$ISOLATE bash "$CHECKOUT_ACTION_DIR/action.sh" "$ARTIFACT_ACTION_REPO" "" "$ARTIFACT_ACTION_DIR" 1 0;
fi;

#bash $SETUP_ACTION_DIR/action.sh 0;


$ISOLATE bash "$CHECKOUT_ACTION_DIR/action.sh" "$GITHUB_REPOSITORY" "$GITHUB_SHA" "$GITHUB_WORKSPACE" 1 1;

echo "##[group] Installing dependencies";
bash $APT_ACTION_DIR/action.sh $GITHUB_WORKSPACE/aptPackagesToInstall.txt;
#bash $GIT_PIP_ACTION_DIR/action.sh $GITHUB_WORKSPACE/pythonPackagesToInstallFromGit.txt;
echo "##[endgroup]";


cd "$GITHUB_WORKSPACE";

#socks, transparent
MODE=regular;

echo "##[group] Running mitmdump to generate a cert file";
mitmdump --listen-host 127.0.0.1 --mode $MODE & MITMDUMP=$!;
sleep 2;
kill -s TERM $MITMDUMP;
echo "##[endgroup]";

echo "##[group] Installing certs files";
sudo mkdir /usr/local/share/ca-certificates/extra;
sudo cp $(realpath ~/.mitmproxy/mitmproxy-ca-cert.cer) /usr/local/share/ca-certificates/extra/mitmproxy-ca-cert.crt;
sudo update-ca-certificates;
export NODE_EXTRA_CA_CERTS=$(realpath ~/.mitmproxy/mitmproxy-ca-cert.cer);
echo "##[endgroup]";

echo "##[group] Importing GPG key";
gpg --import --batch --no-tty $GITHUB_WORKSPACE/key.gpg;
echo "##[endgroup]";

echo "##[group] Getting its fingerprint";
for fp in $(gpg --show-keys --with-colons --import-options show-only --fingerprint key.gpg | awk -F: '$1 == "fpr" {print $10;}'); do
	GPG_KEY_FINGERPRINT=$fp;
	break;
done
echo "##[endgroup]";

BEFORE_MiTM_COMMANDS_FILE="$GITHUB_WORKSPACE/.ci/beforeMiTM.sh";
if [ -f "$BEFORE_MiTM_COMMANDS_FILE" ]; then
	echo "##[group] Running before MiTM commands";
	. $BEFORE_MiTM_COMMANDS_FILE;
	echo "##[endgroup]";
fi;

set -x;
for el in $(find $GITHUB_WORKSPACE/.ci/mitmed/ -name "*.sh" | sort -n); do
	bn=$(basename $el);
	res_name=$(echo $bn | sed s/\\.sh$//);
	echo "##[group] Running mitmed commands for $res_name";

	# https://raw.githubusercontent.com/mitmproxy/mitmproxy/main/examples/contrib/har_dump.py
	# -s ./har_dump.py --set hardump=./dump.har

	mitmdump --listen-host 127.0.0.1 --mode $MODE -w $res_name & MITMDUMP=$!;
	export MITMPROXY_ADDR=http://127.0.0.1:8080;
	. $el;
	kill -s TERM $MITMDUMP;

	if [ -f "$res_name" ]; then
		gpg --batch --no-tty --trust-model always -r $GPG_KEY_FINGERPRINT --encrypt-files $res_name;
		INPUT_NAME=mitmproxy_results INPUT_PATH=$res_name.gpg $artifactUploadCmd;
	fi

	echo "##[endgroup]";
done;
