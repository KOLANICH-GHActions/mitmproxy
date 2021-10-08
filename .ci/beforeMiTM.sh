#!/usr/bin/env bash

set -e;

export cacheUploadCmd="env node $CACHE_ACTION_DIR/dist/save/index.js";

if [ -d "$CACHE_ACTION_DIR" ]; then
	:
else
	$ISOLATE bash "$CHECKOUT_ACTION_DIR/action.sh" "$CACHE_ACTION_REPO" "" "$CACHE_ACTION_DIR" 1 0;
fi;


export CODEQL_ACTION_REPO=github/codeql-action;
export CODEQL_ACTION_DIR=$ACTIONS_DIR/$CHECKOUT_ACTION_REPO/master;

if [ -d "$CODEQL_ACTION_DIR" ]; then
	:
else
	$ISOLATE bash "$CHECKOUT_ACTION_DIR/action.sh" "$CODEQL_ACTION_REPO" "" "$CODEQL_ACTION_DIR" 1 0;
fi;

export sarifUploadCmd="env node $CODEQL_ACTION_DIR/lib/upload-sarif-action.js";
