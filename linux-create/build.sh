#!/usr/bin/env bash
# Build vphone-cli's firmware tooling for Linux in one step: fetch the pinned
# vphone-cli tag, sync its sources, install Swift if needed, and build.
#
#   linux-create/build.sh            # -> linux-create/vphone-cli (wrapper) works
#
# Needs no swiftly env/PATH setup: the pinned toolchain (.swift-version) is
# installed with swiftly if missing and called by its full path.
# VPHONE_CLI=DIR uses an existing vphone-cli checkout instead.
set -Eeuo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "$here/../setup/lib/common.sh"
# shellcheck disable=SC1091
source "$here/../setup/lib/swift.sh"

[ "$(id -u)" != 0 ] || die "run this as your user, not root (the build tree would become root-owned)"

src=${VPHONE_CLI:-$here/../cpu-tree/vphone-cli-$VPHONE_CLI_PUBLIC}
if [ ! -d "$src/.git" ] && [ -z "${VPHONE_CLI:-}" ]; then
  log "Cloning vphone-cli $VPHONE_CLI_PUBLIC into $src"
  mkdir -p "$(dirname "$src")"
  git clone --depth 1 --branch "$VPHONE_CLI_PUBLIC" "$VPHONE_CLI_REPO" "$src"
fi
[ -d "$src" ] || die "no vphone-cli checkout at $src"

ensure_swift
swift_check_libs

cd "$here"
VPHONE_CLI=$src ./sync-sources.sh
log "Building with Swift $VPHONE_SWIFT_VERSION ($(swift_bin))"
swift build --build-system swiftbuild --scratch-path .build/out "$@"
log "Built: $here/.build/out/out/Products/Debug-linux-x86_64/vphone-cli  (or run linux-create/vphone-cli)"
