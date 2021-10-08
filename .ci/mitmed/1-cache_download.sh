#!/usr/bin/env bash

set -e;

HTTPS_PROXY=$MITMPROXY_ADDR HTTP_PROXY=$MITMPROXY_ADDR INPUT_PATH=test.txt INPUT_KEY=test_key $cacheDownloadCmd;
