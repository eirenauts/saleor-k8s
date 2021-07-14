#!/bin/bash
# shellcheck shell=bash disable=SC1090,SC1091,SC1094

set -e
set -o pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ci.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/charts_ci.sh"

"$@"
