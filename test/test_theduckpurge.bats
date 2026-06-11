#!/usr/bin/env bats

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    TEST_TMP="$(mktemp -d)"
    export TEST_TMP

    cp "$BATS_TEST_DIRNAME/../theduckpurge" "$TEST_TMP/theduckpurge"
    chmod +x "$TEST_TMP/theduckpurge"

    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/test.jpg"
    cp "$BATS_TEST_DIRNAME/fixtures/test.pdf" "$TEST_TMP/test.pdf"
    cp "$BATS_TEST_DIRNAME/fixtures/unsupported.txt" "$TEST_TMP/unsupported.txt"
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/clean_test.jpg"

    TEST_FILE="$TEST_TMP/test.jpg"
    TEST_PDF="$TEST_TMP/test.pdf"
    UNSUPPORTED_FILE="$TEST_TMP/unsupported.txt"
    CLEAN_TARGET="$TEST_TMP/clean_test.jpg"
    export TEST_FILE TEST_PDF UNSUPPORTED_FILE CLEAN_TARGET
}

teardown() {
    rm -rf "$TEST_TMP"
}

@test "shows version" {
    run "$TEST_TMP/theduckpurge" --version
    assert_success
    assert_output "theduckpurge v1.0.0"
}

@test "shows help" {
    run "$TEST_TMP/theduckpurge" --help
    assert_success
    assert_output --partial "USAGE:"
    assert_output --partial "--level"
}

@test "treats invalid option as file (warning)" {
    run "$TEST_TMP/theduckpurge" --invalid-option
    assert_output --partial "treating as file"
}

@test "invalid level produces error" {
    run "$TEST_TMP/theduckpurge" --level invalid "$TEST_FILE"
    assert_failure
    assert_output --partial "Invalid level"
}

@test "skips unsupported file" {
    run "$TEST_TMP/theduckpurge" --check-only "$UNSUPPORTED_FILE"
    assert_success
    assert_output --partial "Unsupported format"
}

@test "--check-only mode detects metadata" {
    run "$TEST_TMP/theduckpurge" --check-only "$TEST_FILE"
    assert_success
    assert_output --partial "Contains"
}

@test "dry-run mode prints message" {
    run "$TEST_TMP/theduckpurge" --dry-run "$TEST_FILE"
    assert_success
    assert_output --partial "[DRY RUN]"
}

@test "--zero-trace suppresses success messages" {
    run "$TEST_TMP/theduckpurge" --zero-trace --check-only "$TEST_FILE"
    assert_success
    refute_output --partial "Processing"
    refute_output --partial "completed"
}

@test "--zero-trace real cleaning with no output or backups" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/zt_clean.jpg"
    run "$TEST_TMP/theduckpurge" --zero-trace "$TEST_TMP/zt_clean.jpg"
    assert_success
    refute_output --partial "Processing:"
    [[ ! -d "$TEST_TMP/theduckpurge_backups" ]]
}

@test "cleans metadata from an image" {
    run "$TEST_TMP/theduckpurge" --level standard "$CLEAN_TARGET"
    assert_success
    assert_output --partial "Cleaned:"
}

@test "--backup creates a backup" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/backup_test.jpg"
    run "$TEST_TMP/theduckpurge" --backup "$TEST_TMP/backup_test.jpg"
    assert_success
    assert_output --partial "Backups: 1"
}

@test "--rename renames the file" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/rename_test.jpg"
    run "$TEST_TMP/theduckpurge" --rename "$TEST_TMP/rename_test.jpg"
    assert_success
    assert_output --partial "Cleaned and renamed"
    [[ ! -f "$TEST_TMP/rename_test.jpg" ]]
}

@test "rejects symlink" {
    ln -s "$TEST_FILE" "$TEST_TMP/link.jpg"
    run "$TEST_TMP/theduckpurge" "$TEST_TMP/link.jpg"
    assert_output --partial "Symlink"
    [[ -f "$TEST_FILE" ]]
}

@test "reports missing file" {
    run "$TEST_TMP/theduckpurge" "$TEST_TMP/does_not_exist.jpg"
    assert_output --partial "Does not exist"
}

@test "processes file with spaces in name" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/my file.jpg"
    run "$TEST_TMP/theduckpurge" --check-only "$TEST_TMP/my file.jpg"
    assert_success
    assert_output --partial "Contains"
}

@test "processes multiple files in one invocation" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/a.jpg"
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/b.jpg"
    run "$TEST_TMP/theduckpurge" --check-only "$TEST_TMP/a.jpg" "$TEST_TMP/b.jpg"
    assert_success
    assert_output --partial "Evaluated: 2"
}

@test "aggressive level works" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/agg_test.jpg"
    run "$TEST_TMP/theduckpurge" --level aggressive "$TEST_TMP/agg_test.jpg"
    assert_success
    assert_output --partial "Cleaned:"
}

@test "light level processes without errors" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/light_test.jpg"
    run "$TEST_TMP/theduckpurge" --level light "$TEST_TMP/light_test.jpg"
    assert_success
    assert_output --partial "Cleaned:"
}

@test "cleans metadata from a PDF" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.pdf" "$TEST_TMP/clean_test.pdf"
    run "$TEST_TMP/theduckpurge" --level standard "$TEST_TMP/clean_test.pdf"
    assert_success
    assert_output --partial "Cleaned:"
}

@test "--check-only detects metadata in PDF" {
    run "$TEST_TMP/theduckpurge" --check-only "$TEST_PDF"
    assert_success
    assert_output --partial "Contains"
}

@test "paranoid level processes with ffmpeg" {
    command -v ffmpeg &>/dev/null || skip "ffmpeg not available"
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/para_test.jpg"
    run "$TEST_TMP/theduckpurge" --level paranoid "$TEST_TMP/para_test.jpg"
    assert_success
    assert_output --partial "Re-encoded: 1"
}

@test "--force mode processes large files" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/large.jpg"
    run "$TEST_TMP/theduckpurge" --force "$TEST_TMP/large.jpg"
    assert_success
    refute_output --partial "File too large"
}

@test "processes non-recursive directory" {
    mkdir -p "$TEST_TMP/mydir"
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/mydir/img.jpg"
    cp "$BATS_TEST_DIRNAME/fixtures/unsupported.txt" "$TEST_TMP/mydir/doc.txt"
    run "$TEST_TMP/theduckpurge" --check-only "$TEST_TMP/mydir"
    assert_success
    assert_output --partial "Evaluated: 2"
    assert_output --partial "Dirty: 1"
    assert_output --partial "Skipped: 1"
}

@test "processes recursive directory" {
    mkdir -p "$TEST_TMP/mydir/sub"
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/mydir/img.jpg"
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/mydir/sub/deep.jpg"
    run "$TEST_TMP/theduckpurge" -R --check-only "$TEST_TMP/mydir"
    assert_success
    assert_output --partial "Evaluated: 2"
}

@test "library mode: sourcing exposes functions" {
    # shellcheck disable=SC1091
    source "$TEST_TMP/theduckpurge"
    command -v check_metadata
    command -v clean_file
    command -v is_supported_format
}

@test "exit code 1 on failures" {
    run "$TEST_TMP/theduckpurge" "$TEST_TMP/does_not_exist.jpg"
    assert_failure
}

@test "exit code 0 when all OK" {
    run "$TEST_TMP/theduckpurge" --check-only "$TEST_FILE"
    assert_success
}

# ---- New tests (v1.0) ----

@test "rejects symlink to directory" {
    mkdir -p "$TEST_TMP/realdir"
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/realdir/img.jpg"
    ln -s "$TEST_TMP/realdir" "$TEST_TMP/linkdir"
    run "$TEST_TMP/theduckpurge" "$TEST_TMP/linkdir"
    assert_output --partial "Symlink"
}

@test "aggressive level cleans PDF" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.pdf" "$TEST_TMP/agg_pdf.pdf"
    run "$TEST_TMP/theduckpurge" --level aggressive "$TEST_TMP/agg_pdf.pdf"
    assert_success
    assert_output --partial "Cleaned:"
}

@test "--backup --rename work together" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/br_test.jpg"
    run "$TEST_TMP/theduckpurge" --backup --rename "$TEST_TMP/br_test.jpg"
    assert_success
    assert_output --partial "Cleaned and renamed"
    assert_output --partial "Backups: 1"
}

@test "processes file with leading dash in name" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/-suspicious.jpg"
    run "$TEST_TMP/theduckpurge" --check-only "$TEST_TMP/-suspicious.jpg"
    assert_success
    assert_output --partial "Contains"
}

@test "progress indicator shown with multiple files" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/prog_a.jpg"
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/prog_b.jpg"
    run "$TEST_TMP/theduckpurge" --level standard "$TEST_TMP/prog_a.jpg" "$TEST_TMP/prog_b.jpg"
    assert_success
    assert_output --partial "[1/2]"
    assert_output --partial "[2/2]"
}
