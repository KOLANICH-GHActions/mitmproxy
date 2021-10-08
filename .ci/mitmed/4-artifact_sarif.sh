#!/usr/bin/env bash

set -e;

HTTPS_PROXY=$MITMPROXY_ADDR HTTP_PROXY=$MITMPROXY_ADDR INPUT_SARIF_FILE=out.sarif $sarifUploadCmd;
