#!/bin/bash
# shellcheck shell=bash disable=SC1094
# shellcheck shell=bash disable=SC1090

set -e
set -o pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ci.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"

"$@"
