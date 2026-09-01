#!/usr/bin/env bash
# mayhem/build.sh — libretro-common: cdfs file-input harness + subset of the libcheck test suite.
set -euo pipefail

[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

: "${SANITIZER_FLAGS=-fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer}"
: "${DEBUG_FLAGS:=-g -gdwarf-3}"
: "${CC:=clang}"
: "${MAYHEM_JOBS:=$(nproc)}"
: "${COVERAGE_FLAGS=}"
export SANITIZER_FLAGS DEBUG_FLAGS CC MAYHEM_JOBS COVERAGE_FLAGS

cd "$SRC"

INC="-I$SRC/include -D_GNU_SOURCE"

# --- 1) cdfs harness (file-input reproducer, sanitized) --------------------
CDFS_SRCS=(
  formats/cdfs/cdfs.c
  streams/file_stream.c
  streams/file_stream_transforms.c
  streams/interface_stream.c
  streams/memory_stream.c
  vfs/vfs_implementation.c
  compat/compat_strl.c
  file/file_path.c
  file/file_path_io.c
  string/stdstring.c
  string/rstrtod.c
  time/rtime.c
  encodings/encoding_utf.c
  encodings/encoding_crc32.c
  features/features_cpu.c
)

# shellcheck disable=SC2086
$CC $SANITIZER_FLAGS $DEBUG_FLAGS $INC \
  mayhem/cdfs/test_cdfs.c "${CDFS_SRCS[@]}" \
  -lm -o /mayhem/test_cdfs

# --- 2) test suite (unsanitized, oracle) -----------------------------------
# A subset of Makefile.test — libcheck-based unit tests with minimal deps.
# Built with the project's normal flags plus $COVERAGE_FLAGS (empty by default).
mkdir -p /mayhem/tests

LIBCHECK_CFLAGS="$(pkg-config --cflags check 2>/dev/null || true)"
LIBCHECK_LIBS="$(pkg-config --libs check 2>/dev/null || echo -lcheck)"

TEST_CFLAGS="-O2 -Iinclude -D_GNU_SOURCE $LIBCHECK_CFLAGS $COVERAGE_FLAGS"

# shellcheck disable=SC2086
$CC $TEST_CFLAGS \
  test/compat/test_strl.c compat/compat_strl.c \
  $LIBCHECK_LIBS -lm -o /mayhem/tests/test_strl

# shellcheck disable=SC2086
$CC $TEST_CFLAGS \
  test/lists/test_linked_list.c lists/linked_list.c \
  $LIBCHECK_LIBS -lm -o /mayhem/tests/test_linked_list

# shellcheck disable=SC2086
$CC $TEST_CFLAGS \
  test/queues/test_generic_queue.c queues/generic_queue.c \
  $LIBCHECK_LIBS -lm -o /mayhem/tests/test_generic_queue

# shellcheck disable=SC2086
$CC $TEST_CFLAGS \
  test/memory/test_mempool.c memory/mempool.c \
  $LIBCHECK_LIBS -lm -o /mayhem/tests/test_mempool

echo "build.sh: OK — /mayhem/test_cdfs + /mayhem/tests/{test_strl,test_linked_list,test_generic_queue,test_mempool}"
