#!/usr/bin/env bash

git tag --list --contains "$(git log -n1 --pretty='%h')" --sort -refname | head -n 1