mitmproxy [![Unlicensed work](https://raw.githubusercontent.com/unlicense/unlicense.org/master/static/favicon.png)](https://unlicense.org/)
=========

A GitHub Action to run mitmproxy on GitHub Actions infrastructure.

Useful for understanding poorly documented API used by Actions runtime which source code is so badly written that is hard to understand.

`key.gpg` is needed because the repo uses secrets to upload the artifacts, and these secrets surely go to the dumps.
