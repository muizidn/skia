#!/bin/sh
# Copyright 2018 Google LLC.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Notes:
#
#    You may need to run as root for docker permissions.
#
#    You *must* run `tools/git-sync-deps` first.

OUT="$(mktemp -d "${TMPDIR:-/tmp}/skqp_apk.XXXXXXXXXX")"
BUILD="$(mktemp -d "${TMPDIR:-/tmp}/skqp_apk_build.XXXXXXXXXX")"
SKIA_ROOT="$(cd "$(dirname "$0")/../.."; pwd)"

cd "${SKIA_ROOT}/infra/skqp/docker"

docker build -t android-skqp ./android-skqp/

docker run --rm -d --name android_em \
        --env=DEVICE="Samsung Galaxy S6" \
        --volume="$SKIA_ROOT":/SRC \
        --volume="$OUT":/OUT \
        --volume="$BUILD":/BUILD \
        android-skqp

docker exec \
    --env=SKQP_OUTPUT_DIR=/OUT \
    --env=SKQP_BUILD_DIR=/BUILD \
    android_em /SRC/tools/skqp/make_universal_apk.py

docker exec android_em find '/BUILD/.' '!' -name '.' -prune -exec rm -rf '{}' '+'

if [ -f "$OUT"/skqp-universal-debug.apk ]; then
    docker exec android_em find /OUT -type f -exec chmod 0666 '{}' '+'
fi

docker kill android_em

rmdir "$BUILD"

ls -l "$OUT"/*.apk 2> /dev/null
