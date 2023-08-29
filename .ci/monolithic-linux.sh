#!/usr/bin/env bash
#===----------------------------------------------------------------------===##
#
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
#
#===----------------------------------------------------------------------===##

#
# This script performs a monolithic build of the monorepo and runs the tests of
# most projects on Linux. This should be replaced by per-project scripts that
# run only the relevant tests.
#

set -ex
set -o pipefail

MONOREPO_ROOT="${MONOREPO_ROOT:="$(git rev-parse --show-toplevel)"}"
BUILD_DIR="${BUILD_DIR:=${MONOREPO_ROOT}/build}"

rm -rf ${BUILD_DIR}

sccache --zero-stats
function show-stats {
  sccache --show-stats >> artifacts/sccache_stats.txt
}
trap show-stats EXIT

projects="${1}"
targets="${2}"

echo "--- cmake"
pip install -q -r ${MONOREPO_ROOT}/mlir/python/requirements.txt
cmake -S ${MONOREPO_ROOT}/llvm \
      -B ${BUILD_DIR} \
      -G Ninja \
      -D BOLT_CLANG_EXE=/usr/bin/clang \
      -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_C_COMPILER_LAUNCHER=sccache \
      -D CMAKE_C_COMPILER=clang \
      -D CMAKE_CXX_COMPILER_LAUNCHER=sccache \
      -D CMAKE_CXX_COMPILER=clang++ \
      -D CMAKE_CXX_FLAGS=-gmlt \
      -D COMPILER_RT_BUILD_LIBFUZZER=OFF \
      -D LLVM_BUILD_EXAMPLES=ON \
      -D LLVM_ENABLE_ASSERTIONS=ON \
      -D LLVM_ENABLE_LLD=ON \
      -D LLVM_ENABLE_PROJECTS="${projects}" \
      -D LLVM_LIT_ARGS="-v --xunit-xml-output ${BUILD_DIR}/test-results.xml"

echo "--- ninja"
ninja -C ${BUILD_DIR} ${targets}