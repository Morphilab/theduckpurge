#!/usr/bin/env bash
# =============================================================================
# theduckpurge — Installer with SHA256 verification
# =============================================================================
# Downloads the latest version from GitHub, verifies integrity, and installs.
# Usage: curl -fsSL https://raw.githubusercontent.com/morphilab/theduckpurge/main/install.sh | bash

set -euo pipefail

URL="https://raw.githubusercontent.com/morphilab/theduckpurge/main/theduckpurge"
CHECKSUM_URL="https://raw.githubusercontent.com/morphilab/theduckpurge/main/theduckpurge.sha256"
TARGET="/usr/local/bin/theduckpurge"
TMPFILE=""
CHECKSUM_FILE=""
SKIP_VERIFY=false
ASSUME_YES=false

# NOTE: the checksum is served from the same origin as the binary, so it
# protects against download corruption, not against a compromised repository.
for arg in "$@"; do
    case "$arg" in
        --skip-verify) SKIP_VERIFY=true ;;
        --yes|-y) ASSUME_YES=true ;;
        --help|-h)
            echo "Usage: install.sh [--skip-verify] [--yes]"
            echo "  --skip-verify  Skip SHA256 checksum verification"
            echo "  --yes, -y      Overwrite existing installation without prompt"
            exit 0 ;;
    esac
done

cleanup() {
    # if-form (not "[[ ]] && rm"): under set -e a failing guard inside the
    # EXIT trap aborts the trap and overrides the script's real exit code
    # (e.g. --skip-verify installs fine but exited 1).
    if [[ -n "$TMPFILE" && -f "$TMPFILE" ]]; then
        rm -f "$TMPFILE"
    fi
    if [[ -n "$CHECKSUM_FILE" && -f "$CHECKSUM_FILE" ]]; then
        rm -f "$CHECKSUM_FILE"
    fi
}
trap cleanup EXIT INT TERM

# --- Pre-flight checks ---
if ! command -v curl &>/dev/null; then
    echo "✗ curl is not installed. Please install it and try again." >&2
    exit 1
fi

confirm_overwrite() {
    [[ "$ASSUME_YES" == true ]] && return 0
    local reply=""
    if [[ -t 0 ]]; then
        read -r -p "⚠ $TARGET already exists. Overwrite? [y/N] " reply
    elif [[ -e /dev/tty ]]; then
        read -r -p "⚠ $TARGET already exists. Overwrite? [y/N] " reply </dev/tty 2>/dev/null || {
            echo "✗ Non-interactive shell: pass --yes to overwrite." >&2
            exit 1
        }
    else
        echo "✗ Non-interactive shell: pass --yes to overwrite." >&2
        exit 1
    fi
    [[ "$reply" == "y" || "$reply" == "Y" ]]
}

if [[ -f "$TARGET" ]]; then
    if confirm_overwrite; then
        :
    else
        echo "Installation cancelled."
        exit 0
    fi
fi

# --- Download script ---
echo "• Downloading theduckpurge from GitHub..."
TMPFILE="$(mktemp /tmp/theduckpurge.XXXXXX)"
HTTP_CODE="$(curl -fsSL -w '%{http_code}' -o "$TMPFILE" "$URL" 2>/dev/null || true)"

if [[ "$HTTP_CODE" != "200" ]]; then
    echo "✗ Download error (HTTP $HTTP_CODE). Check your connection." >&2
    exit 1
fi

# Quick sanity check: the downloaded file should be a shell script
if ! head -1 "$TMPFILE" | grep -q '^#!/'; then
    echo "✗ Downloaded file does not look like a valid script." >&2
    exit 1
fi

# --- Download checksum ---
if [[ "$SKIP_VERIFY" != true ]]; then
    echo "• Downloading checksum..."
    CHECKSUM_FILE="$(mktemp /tmp/theduckpurge_checksum.XXXXXX)"
    HTTP_CODE="$(curl -fsSL -w '%{http_code}' -o "$CHECKSUM_FILE" "$CHECKSUM_URL" 2>/dev/null || true)"

    if [[ "$HTTP_CODE" == "200" ]] && [[ -s "$CHECKSUM_FILE" ]]; then
        EXPECTED="$(awk '{print $1}' "$CHECKSUM_FILE")"
        ACTUAL="$(sha256sum "$TMPFILE" | awk '{print $1}')"

        if [[ "$EXPECTED" != "$ACTUAL" ]]; then
            echo "✗ SHA256 checksum mismatch!" >&2
            echo "  Expected: $EXPECTED" >&2
            echo "  Got:      $ACTUAL" >&2
            echo "  The downloaded file may be corrupted or tampered with." >&2
            exit 1
        fi
        echo "✓ Checksum verified."
    else
        # Fail closed: an unverifiable download must not be installed silently.
        echo "✗ Could not download checksum (HTTP $HTTP_CODE)." >&2
        echo "  Refusing to install an unverified binary." >&2
        echo "  Re-run with --skip-verify to override." >&2
        exit 1
    fi
else
    echo "• Skipping checksum verification (--skip-verify)"
fi

chmod +x "$TMPFILE"

# --- Install ---
if [[ -w "$(dirname "$TARGET")" ]]; then
    mv "$TMPFILE" "$TARGET"
    TMPFILE=""
else
    echo "• Installing to $TARGET (requires sudo)..."
    if sudo mv "$TMPFILE" "$TARGET"; then
        TMPFILE=""
    else
        echo "✗ Could not install. File left at $TMPFILE" >&2
        exit 1
    fi
fi

# --- Verify installation ---
INSTALLED_VERSION=""
if command -v theduckpurge &>/dev/null; then
    INSTALLED_VERSION="$(theduckpurge --version 2>/dev/null || true)"
fi

echo "✅ theduckpurge successfully installed at $TARGET"
[[ -n "$INSTALLED_VERSION" ]] && echo "   $INSTALLED_VERSION"
echo ""
echo "Usage:"
echo "  theduckpurge              # Show help"
echo "  theduckpurge --check-only document.pdf"
echo "  theduckpurge --level paranoid -R ./my_files/"
echo ""
echo "Thank you for using theduckpurge!"
