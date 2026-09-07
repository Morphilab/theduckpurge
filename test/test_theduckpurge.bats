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
    [[ -n "${INST_SANDBOX:-}" ]] && rm -rf "$INST_SANDBOX"
    rm -rf "$TEST_TMP"
}

@test "shows version" {
    run "$TEST_TMP/theduckpurge" --version
    assert_success
    assert_output "theduckpurge v1.2.0"
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

@test "invalid level in config aborts without destroying file" {
    printf 'level=inexistente\n' > "$TEST_TMP/cfg"
    local size_before size_after
    size_before="$(stat -c%s "$TEST_FILE")"
    run "$TEST_TMP/theduckpurge" --config "$TEST_TMP/cfg" "$TEST_FILE"
    assert_failure
    assert_output --partial "Invalid level"
    size_after="$(stat -c%s "$TEST_FILE")"
    assert_equal "$size_before" "$size_after"
}

@test "empty level value in config aborts without destroying file" {
    printf 'level=\n' > "$TEST_TMP/cfg"
    local size_before size_after
    size_before="$(stat -c%s "$TEST_FILE")"
    run "$TEST_TMP/theduckpurge" --config "$TEST_TMP/cfg" "$TEST_FILE"
    assert_failure
    size_after="$(stat -c%s "$TEST_FILE")"
    assert_equal "$size_before" "$size_after"
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

# ---- File handling and cleaning modes ----

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

# ---- CLI behavior ----

@test "exit code 2 when no files processed" {
    run "$TEST_TMP/theduckpurge" --check-only "$TEST_TMP/nonexistent_dir"
    assert_failure
}

@test "--no-color disables color codes" {
    run "$TEST_TMP/theduckpurge" --no-color --version
    assert_success
    refute_output --partial '\033'
}

@test "--verbose shows detailed info" {
    run "$TEST_TMP/theduckpurge" --verbose --check-only "$TEST_FILE"
    assert_success
}

@test "--json produces JSON output" {
    run "$TEST_TMP/theduckpurge" --json --check-only "$TEST_FILE"
    assert_success
    assert_output --partial '"version"'
    assert_output --partial '"summary"'
}

@test "--json with cleaning produces JSON report" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/json_test.jpg"
    run "$TEST_TMP/theduckpurge" --json "$TEST_TMP/json_test.jpg"
    assert_success
    assert_output --partial '"status":"cleaned"'
}

@test "--exclude skips matching files" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/keep_this.jpg"
    run "$TEST_TMP/theduckpurge" --check-only --exclude "keep_this" "$TEST_TMP/keep_this.jpg"
    assert_output --partial "Excluded"
}

@test "--init creates .theduckpurge.exclude" {
    cd "$TEST_TMP"
    run "$TEST_TMP/theduckpurge" --init
    assert_success
    [[ -f "$TEST_TMP/.theduckpurge.exclude" ]]
}

@test "--init does not overwrite existing .theduckpurge.exclude" {
    cd "$TEST_TMP"
    echo "custom" > "$TEST_TMP/.theduckpurge.exclude"
    run "$TEST_TMP/theduckpurge" --init
    assert_output --partial "already exists"
    grep -q "custom" "$TEST_TMP/.theduckpurge.exclude"
}

@test "--config loads settings from file" {
    cat > "$TEST_TMP/test_config.cfg" << 'CFG'
level=light
verbose=true
CFG
    run "$TEST_TMP/theduckpurge" --config "$TEST_TMP/test_config.cfg" --check-only "$TEST_FILE"
    assert_success
}

@test "rejects empty file" {
    touch "$TEST_TMP/empty.jpg"
    run "$TEST_TMP/theduckpurge" --check-only "$TEST_TMP/empty.jpg"
    assert_success
}

@test "rejects read-only file for cleaning" {
    touch "$TEST_TMP/readonly.jpg"
    chmod 444 "$TEST_TMP/readonly.jpg"
    run "$TEST_TMP/theduckpurge" "$TEST_TMP/readonly.jpg"
    assert_failure
    chmod 644 "$TEST_TMP/readonly.jpg" 2>/dev/null || true
}

@test "processes empty directory" {
    mkdir -p "$TEST_TMP/emptydir"
    run "$TEST_TMP/theduckpurge" --check-only "$TEST_TMP/emptydir"
    assert_failure
    assert_output --partial "No files were processed"
}

@test "handles Unicode filename" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/foto_caf\u00e9.jpg"
    run "$TEST_TMP/theduckpurge" --check-only "$TEST_TMP/foto_caf\u00e9.jpg"
    assert_success
    assert_output --partial "Contains"
}

@test "multiple --exclude flags work" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/skip_a.jpg"
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/skip_b.jpg"
    run "$TEST_TMP/theduckpurge" --check-only --exclude "skip_a" --exclude "skip_b" "$TEST_TMP/skip_a.jpg" "$TEST_TMP/skip_b.jpg"
    assert_output --partial "Excluded"
}

@test "exit code 3 for missing dependency" {
    # A mat2 stub that fails its own smoke test makes check_dependencies
    # treat mat2 as unresponsive and abort with exit 3.
    mkdir -p "$TEST_TMP/fakebin"
    printf '#!/usr/bin/env bash\nexit 1\n' > "$TEST_TMP/fakebin/mat2"
    chmod +x "$TEST_TMP/fakebin/mat2"
    # shellcheck disable=SC2030  # each @test runs in its own subshell; PATH export is test-scoped by design
    export PATH="$TEST_TMP/fakebin:$PATH"
    run "$TEST_TMP/theduckpurge" --check-only "$TEST_FILE"
    assert_failure
    assert_equal "$status" "3"
    assert_output --partial "Dependency issues"
}

# ---- Report mode and format support ----

@test "--report shows detailed metadata info" {
    run "$TEST_TMP/theduckpurge" --report "$TEST_FILE"
    assert_success
    assert_output --partial "File:"
    assert_output --partial "Extension:"
    assert_output --partial "Size:"
    assert_output --partial "Status:"
}

@test "--report shows metadata fields" {
    run "$TEST_TMP/theduckpurge" --report "$TEST_PDF"
    assert_success
    assert_output --partial "Metadata details:"
}

@test "new formats are supported" {
    touch "$TEST_TMP/test.heic"
    run "$TEST_TMP/theduckpurge" --check-only "$TEST_TMP/test.heic"
    assert_output --partial "Contains" || assert_output --partial "Already clean"

    touch "$TEST_TMP/test.webp"
    run "$TEST_TMP/theduckpurge" --check-only "$TEST_TMP/test.webp"
    assert_output --partial "Contains" || assert_output --partial "Already clean"

    touch "$TEST_TMP/test.svg"
    run "$TEST_TMP/theduckpurge" --check-only "$TEST_TMP/test.svg"
    assert_output --partial "Contains" || assert_output --partial "Already clean"
}

@test "--report with JSON produces JSON output" {
    run "$TEST_TMP/theduckpurge" --report --json "$TEST_FILE"
    assert_success
    assert_output --partial '"version"'
}

# ---- Metadata counting, JSON safety, and robustness ----

@test "--config accepts max-file-size without crashing" {
    cat > "$TEST_TMP/size_config.cfg" << 'CFG'
level=light
max-file-size=200000000
CFG
    run "$TEST_TMP/theduckpurge" --config "$TEST_TMP/size_config.cfg" --check-only "$TEST_FILE"
    assert_success
}

@test "--config rejects invalid max-file-size gracefully" {
    cat > "$TEST_TMP/bad_size.cfg" << 'CFG'
max-file-size=notanumber
CFG
    run "$TEST_TMP/theduckpurge" --config "$TEST_TMP/bad_size.cfg" --check-only "$TEST_FILE"
    assert_success
    assert_output --partial "Invalid max-file-size"
}

@test "check_metadata counts multi-word fields (Create Date)" {
    # shellcheck disable=SC1091
    source "$TEST_TMP/theduckpurge"
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/cd_test.jpg"
    exiftool -overwrite_original -all= "$TEST_TMP/cd_test.jpg" >/dev/null 2>&1
    exiftool -overwrite_original -CreateDate="2020:01:01 10:00:00" "$TEST_TMP/cd_test.jpg" >/dev/null 2>&1
    count="$(check_metadata "$TEST_TMP/cd_test.jpg")"
    [[ "$count" -eq 1 ]]
}

@test "--check-only detects GPS coordinates as privacy metadata" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/gps_test.jpg"
    exiftool -overwrite_original -GPSLatitude=40.4462 -GPSLongitude=-79.9821 "$TEST_TMP/gps_test.jpg" >/dev/null 2>&1
    run "$TEST_TMP/theduckpurge" --check-only "$TEST_TMP/gps_test.jpg"
    assert_success
    assert_output --partial "Contains"
}

@test "aggressive cleaning removes GPS coordinates" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/gps_clean.jpg"
    exiftool -overwrite_original -GPSLatitude=40.4462 -GPSLongitude=-79.9821 "$TEST_TMP/gps_clean.jpg" >/dev/null 2>&1
    run "$TEST_TMP/theduckpurge" --level aggressive "$TEST_TMP/gps_clean.jpg"
    assert_success
    remaining="$(exiftool -b -GPSLatitude "$TEST_TMP/gps_clean.jpg" | tr -d '[:space:]')"
    [[ -z "$remaining" ]]
}

@test "--json emits valid JSON with hostile filename" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/bad\"name.jpg"
    run "$TEST_TMP/theduckpurge" --json --check-only "$TEST_TMP/bad\"name.jpg"
    assert_success
    # bats merges stderr into $output; extract the pure stdout JSON document
    json_line="$(printf '%s\n' "$output" | grep '^{' | tail -n1)"
    printf '%s' "$json_line" | python3 -m json.tool >/dev/null
}

@test "--json stdout contains no plain-text summary" {
    run "$TEST_TMP/theduckpurge" --json --check-only "$TEST_FILE"
    refute_output --partial "Evaluated:"
}

@test "paranoid level requires ffmpeg when cleaning (exit 3)" {
    mkdir -p "$TEST_TMP/fakebin"
    for d in /usr/bin /bin /usr/local/bin; do
        [[ -d "$d" ]] || continue
        for f in "$d"/*; do
            b="$(basename "$f")"
            [[ "$b" == "ffmpeg" || -e "$TEST_TMP/fakebin/$b" ]] && continue
            ln -sf "$f" "$TEST_TMP/fakebin/$b" 2>/dev/null || true
        done
    done
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/pf_test.jpg"
    run env PATH="$TEST_TMP/fakebin" "$TEST_TMP/theduckpurge" --level paranoid "$TEST_TMP/pf_test.jpg"
    assert_failure
    assert_output --partial "ffmpeg"
}

@test "library mode: reencode_file truly re-encodes jpeg (no stream copy)" {
    command -v ffmpeg &>/dev/null || skip "ffmpeg not available"
    # shellcheck disable=SC1091
    source "$TEST_TMP/theduckpurge"
    TEMP_DIR="$(mktemp -d)"
    out="$TEMP_DIR/re_out.jpg"
    reencode_file "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$out"
    [[ -s "$out" ]]
    [[ "$REENCODE_MODE" == "re-encoded" ]]
    rm -rf "$TEMP_DIR"
}

@test "--report evaluates each file exactly once" {
    run "$TEST_TMP/theduckpurge" --report "$TEST_FILE" "$TEST_PDF"
    assert_output --partial "Evaluated: 2"
}

@test "paranoid preserves regular file mode (644)" {
    chmod 644 "$TEST_FILE"
    run "$TEST_TMP/theduckpurge" --level paranoid "$TEST_FILE"
    assert_success
    assert_equal "644" "$(stat -c%a "$TEST_FILE")"
}

@test "paranoid preserves restrictive file mode (600)" {
    chmod 600 "$TEST_FILE"
    run "$TEST_TMP/theduckpurge" --level paranoid "$TEST_FILE"
    assert_success
    assert_equal "600" "$(stat -c%a "$TEST_FILE")"
}

@test "--backup preserves same-named files from different directories" {
    mkdir -p "$TEST_TMP/src/d1" "$TEST_TMP/src/d2"
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/src/d1/img.jpg"
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/src/d2/img.jpg"
    cd "$TEST_TMP"
    run "$TEST_TMP/theduckpurge" --backup -R ./src
    assert_success
    assert_output --partial "Backups: 2"
    n="$(find "$TEST_TMP/theduckpurge_backups" -type f 2>/dev/null | wc -l)"
    [[ "$n" -eq 2 ]]
}

@test "invalid exclusion regex aborts instead of being ignored" {
    run "$TEST_TMP/theduckpurge" --check-only --exclude '[unclosed' "$TEST_FILE"
    assert_failure
    assert_output --partial "Invalid exclude pattern"
}

@test "--exclude patterns may contain spaces" {
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/my file.jpg"
    run "$TEST_TMP/theduckpurge" --check-only --exclude "my file" "$TEST_TMP/my file.jpg"
    assert_output --partial "Excluded"
}

@test "--jobs accepted with warning; runs sequentially" {
    run "$TEST_TMP/theduckpurge" --jobs 4 --check-only "$TEST_FILE"
    assert_success
    assert_output --partial "not implemented"
}

# ============================ install.sh ============================

setup_installer_sandbox() {
    INST_SANDBOX="$(mktemp -d)"
    mkdir -p "$INST_SANDBOX/bin" "$INST_SANDBOX/target"
    local script_src="$BATS_TEST_DIRNAME/../theduckpurge"

    cat > "$INST_SANDBOX/bin/curl" <<STUB
#!/usr/bin/env bash
out=""; url=""
while [[ \$# -gt 0 ]]; do
    case "\$1" in
        -o) out="\$2"; shift 2 ;;
        *) url="\$1"; shift ;;
    esac
done
if [[ "\$url" == *sha256* ]]; then
    if [[ "\$INSTALL_STUB_NO_CHECKSUM" == 1 ]]; then
        echo 404
        exit 0
    fi
    if [[ "\$INSTALL_STUB_BAD_CHECKSUM" == 1 ]]; then
        printf 'deadbeef  theduckpurge\n' > "\$out"
    else
        printf '%s  theduckpurge\n' "\$(sha256sum "$script_src" | cut -d' ' -f1)" > "\$out"
    fi
else
    cp "$script_src" "\$out"
fi
echo 200
STUB

    cat > "$INST_SANDBOX/bin/sudo" <<'STUB'
#!/usr/bin/env bash
if [[ "${1:-}" == "mv" ]]; then
    exec mv "${2:?}" "${INSTALL_STUB_TARGET:?}/installed_theduckpurge"
fi
exec "$@"
STUB

    chmod +x "$INST_SANDBOX/bin/curl" "$INST_SANDBOX/bin/sudo"
    export INSTALL_STUB_TARGET="$INST_SANDBOX/target"
}

run_installer() {
    # shellcheck disable=SC2031  # PATH prefix is intentional per-invocation
    run env PATH="$INST_SANDBOX/bin:$PATH" INSTALL_STUB_TARGET="$INSTALL_STUB_TARGET" \
        bash "$BATS_TEST_DIRNAME/../install.sh" "$@"
}

@test "installer: --skip-verify installs and exits 0" {
    setup_installer_sandbox
    run_installer --skip-verify --yes
    assert_success
    [[ -x "$INSTALL_STUB_TARGET/installed_theduckpurge" ]]
}

@test "installer: valid checksum installs and exits 0" {
    setup_installer_sandbox
    run_installer --yes
    assert_success
    [[ -x "$INSTALL_STUB_TARGET/installed_theduckpurge" ]]
}

@test "installer: tampered checksum refuses to install" {
    setup_installer_sandbox
    INSTALL_STUB_BAD_CHECKSUM=1 run_installer --yes
    assert_failure
    assert_output --partial "checksum mismatch"
    [[ ! -e "$INSTALL_STUB_TARGET/installed_theduckpurge" ]]
}

@test "installer: missing checksum fails closed" {
    setup_installer_sandbox
    INSTALL_STUB_NO_CHECKSUM=1 run_installer --yes
    assert_failure
    assert_output --partial "Could not download checksum"
    [[ ! -e "$INSTALL_STUB_TARGET/installed_theduckpurge" ]]
}

# ---- Permission errors, exit codes, and reporting ----

@test "unreadable file yields permission exit code 4" {
    [[ "$(id -u)" == "0" ]] && skip "running as root: chmod 000 is not effective"
    chmod 000 "$TEST_FILE"
    run "$TEST_TMP/theduckpurge" --no-color "$TEST_FILE"
    assert_failure
    assert_output --partial "No read permission"
    assert_equal "$status" "4"
}

@test "unreadable file inside directory does not abort batch (exit 4)" {
    [[ "$(id -u)" == "0" ]] && skip "running as root: chmod 000 is not effective"
    mkdir -p "$TEST_TMP/dirx"
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/dirx/good.jpg"
    cp "$BATS_TEST_DIRNAME/fixtures/test.jpg" "$TEST_TMP/dirx/bad.jpg"
    chmod 000 "$TEST_TMP/dirx/bad.jpg"
    run "$TEST_TMP/theduckpurge" --check-only --no-color "$TEST_TMP/dirx"
    assert_failure
    assert_equal "$status" "4"
    assert_output --partial "good.jpg"
}

@test "--check-only --json summary includes verified counts" {
    run "$TEST_TMP/theduckpurge" --check-only --json "$TEST_PDF"
    assert_success
    local counts
    counts="$(printf '%s\n' "$output" | grep '^{' | python3 -c \
        'import json,sys; s=json.load(sys.stdin)["summary"]; print(s.get("verified_dirty", -1), s.get("verified_clean", -1))')"
    assert_equal "$counts" "1 0"
}

@test "--dry-run --json summary includes simulated count" {
    run "$TEST_TMP/theduckpurge" --dry-run --json "$TEST_FILE"
    assert_success
    local simulated
    simulated="$(printf '%s\n' "$output" | grep '^{' | python3 -c \
        'import json,sys; print(json.load(sys.stdin)["summary"].get("simulated", -1))')"
    assert_equal "$simulated" "1"
}

@test "--report classifies technical fields as technical" {
    run "$TEST_TMP/theduckpurge" --report "$TEST_PDF"
    assert_success
    assert_output --partial "[technical]: PDF"
    refute_output --partial "[privacy]: PDF"
    refute_output --partial "[privacy]: application/pdf"
}

@test "exclusion matches dash-flag-like basename" {
    : > "$TEST_TMP/-n"
    run "$TEST_TMP/theduckpurge" --check-only --exclude '^-n$' "$TEST_TMP/-n"
    assert_output --partial "Excluded:"
    refute_output --partial "Unsupported format"
}
