#!/bin/bash
##===----------------------------------------------------------------------===##
##
## This source file is part of the Swift Service Context
## open source project
##
## Copyright (c) 2020-2021 Apple Inc. and the Swift Service Context
## project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

set -eu
here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

bash $here/validate_license_headers.sh
bash $here/validate_language.sh
bash $here/validate_format.sh
