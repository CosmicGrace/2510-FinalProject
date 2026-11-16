# Since prompted by the assingment to use AI
# Claude (Sonnet 5) was used in order to generate this


# lib/license.sh - Part 4: license enforcement.
#
# CONTRACT (the only thing main.sh relies on):
#   license_enforce
#       return 0       -> a valid license exists (prompting first, if needed)
#       return non-0   -> no valid license; main.sh exits
#
# REQUIREMENTs met?:
#   - "license file placed somewhere, random name"   -> FILE below
#   - "prompt for key if file does not exist"        -> license_enforce()
#   - "always check for a valid license before running" -> main.sh calls
#     license_enforce() before showing the menu, every run
#   - "key obfuscated so it cannot be seen in clear text, using AI" ->
#     see the OBFUSCATED KEY block below
#
#

readonly _LICENSE_DIR="/etc/halberd-onboard"
readonly FILE=".q7m2_runtime.dat"  
readonly _LICENSE_FILE="${_LICENSE_DIR}/${FILE}"

# ---------------------------------------------------------------------------
# OBFUSCATED KEY
# ---------------------------------------------------------------------------
# The real key is never written here as 16 plain digits. It goes through
# three reversible steps, built with AI assistance (document this for the
# Part-4 "must use AI" requirement and for your usage manual):
#
#   real key  --[digit-shift cipher using _KEY_PAD, mod 10]-->  shifted digits
#             --[base64 encode]-->                              blob
#             --[reverse the text]-->                           reversed blob
#             --[cut in half]-->          _KEY_PART_A + _KEY_PART_B  (below)
#
# _deobfuscate_key() undoes all three steps at runtime to rebuild the key
# in memory, in a local variable, only for as long as it takes to hash it.
#
# Run tools/make_license_key.sh to turn your real key into the two lines
# below. _KEY_PAD must be IDENTICAL in both files, or the key won't rebuild.
readonly _KEY_PAD="4815162342908223"
readonly _KEY_PART_A="==AM4EDMzkzM"
readonly _KEY_PART_B="4MTNzkTO0UDO"

# Reverse a string using only Bash (no external tool has to exist for this).
_reverse_str() {
    local s="$1" out="" i
    for (( i=${#s}-1; i>=0; i-- )); do out+="${s:i:1}"; done
    printf '%s' "$out"
}

# Undo the digit-shift cipher: subtract the pad's digit (mod 10, wrapping
# negative results back into 0-9) from each digit of $1.
_unshift_digits() {
    local shifted="$1" pad="$_KEY_PAD" plain="" i d p
    for (( i=0; i<${#shifted}; i++ )); do
        d=${shifted:i:1}
        p=${pad:$(( i % ${#pad} )):1}
        plain+=$(( (d - p + 10) % 10 ))
    done
    printf '%s' "$plain"
}

# Rebuild the real 16-digit key from the two obfuscated pieces above.
# Returns 1 if the pieces are still the placeholders, or aren't valid
# base64, so a half-set-up license.sh fails loudly instead of quietly.
_deobfuscate_key() {
    local blob="${_KEY_PART_A}${_KEY_PART_B}"
    local reversed shifted key

    reversed=$(_reverse_str "$blob")
    shifted=$(printf '%s' "$reversed" | base64 -d 2>/dev/null) || return 1
    [[ $shifted =~ ^[0-9]{16}$ ]] || return 1

    key=$(_unshift_digits "$shifted")
    [[ $key =~ ^[0-9]{16}$ ]] || return 1

    printf '%s' "$key"
}

_sha256_of() {
    printf '%s' "$1" | sha256sum | cut -d' ' -f1
}

# ---------------------------------------------------------------------------
# Public function
# ---------------------------------------------------------------------------

license_enforce() {
    local real_key expected_hash stored_hash entered attempt

    real_key=$(_deobfuscate_key) || {
        echo "ERROR: the license key could not be rebuilt - has" >&2
        echo "       tools/make_license_key.sh been run yet? See lib/license.sh." >&2
        return 1
    }
    expected_hash=$(_sha256_of "$real_key")
    unset real_key   # it has done its one job (making the hash); drop it now

    if [[ -f $_LICENSE_FILE ]]; then
        stored_hash=$(< "$_LICENSE_FILE")
        if [[ $stored_hash == "$expected_hash" ]]; then
            return 0     # license file present and valid - run with no prompt
        fi
        echo "A license file exists but does not match this copy of the program." >&2
    fi

    # First run, or the file above didn't check out: ask for the key.
    for attempt in 1 2 3; do
        read -r -p "Enter your 16-digit license key: " entered

        if [[ ! $entered =~ ^[0-9]{16}$ ]]; then
            echo "  That is not 16 digits. Try again." >&2
            continue
        fi

        if [[ $(_sha256_of "$entered") == "$expected_hash" ]]; then
            mkdir -p "$_LICENSE_DIR"
            printf '%s\n' "$expected_hash" > "$_LICENSE_FILE"
            chmod 600 "$_LICENSE_FILE"
            echo "License accepted."
            return 0
        fi

        echo "  Incorrect key ($((3 - attempt)) attempt(s) left)." >&2
    done

    echo "ERROR: no valid license. The program will not run." >&2
    return 1
}
