#!/bin/bash

# Fast fail the script on failures.
set -e

# Verify that the libraries are error free.
dartanalyzer --fatal-warnings \
  lib/logs.dart \
  test/all.dart

# Run the tests.
dart test/all.dart
