#!/usr/bin/env bash

for envVar in ${!ACTION_*};
do
	unset $envVar;
done;

for envVar in ${!GITHUB_*};
do
	unset $envVar;
done;

for envVar in ${!INPUT_*};
do
	unset $envVar;
done;

"$@";
