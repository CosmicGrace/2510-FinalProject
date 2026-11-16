#!/usr/bin/env bash
#
# lib/users.sh - Parts 2 & 3:
#   username/password rules + acc creation.
#
# Target environment: Ubuntu 26.04, Bash 5.3.
# 
#
# Public Functions:
#
#   create_user_acc "Full Name"
#       Accepts a full name and uses the first
#       word as first name and last word, before any
#       comma, as the last name.
#
#   Return Codes: 
#       0 = created
#       1 = failed
#       2 = already existed

readonly PASSWORD_PHRASE="HALBERD"
readonly MAX_USERNAME_BYTES=32 # Linux limit (bytes, not characters)
readonly MIN_NORMAL_UID=1000
readonly MAX_NORMAL_UID=59999

# Lowercase a name and strip it down to letters, hyphens and apostrophes
# C.UTF-8 will make bash understand accented letters because it won't otherwise ;P

normalize_part() {
    local LC_ALL=C.UTF-8
    local curly=$'\xe2\x80\x99'
    local part="${1,,}"                 # lowercase (works on accents too)
    part="${part//$curly/"'"}"              # curly apostrope -> straight one
    local unwanted="[^[:alpha:]'-]"     # anything that is not a lette, ' or -
    printf '%s' "${part//$unwanted/}"
}


# Length in BYTES (an accented e is 2 bytes). Linus usernames max out at 32 bytes.
byte_length() {
    local LC_ALL=C
    printf '%d' "${#1}"
}

create_user_account() {
    local full_name="${1%%,*}"
    local -a words

    read -ra words <<< "$full_name"

    if (( ${#words[@]} < 2)); then
        echo " [failed] '$1' needs both a first and last name" >&2
        return 1
    fi

    # ${words[*]} re-joins the words with single spaces
    create_user "${words[0]}" "${words[-1]}" "${words[*]}"
}


create_user() {
    local first last username password real_name

    first=$(normalize_part "$1")
    last=$(normalize_part "$2")
    real_name="${3:-$1 $2}"
    real_name="${real_name//[:,]/}"     # ":" and "," would corrupt /etc/passwd

    if [[ -z $first || -z $last ]]; then
        echo "  [failed]  need both a first and last name (got '$1' '$2')" >&2
        return 1
    fi

    username="${first}.${last}"
    password="${first}${last}${PASSWORD_PHRASE}"

    # We do our own checks, because we ask useradd to skip its strict ones.
    if [[ $username == -* ]]; then
        echo "  [failed]  username '$username' may not start with '-'" >&2
        return 1
    fi
    if (( $(byte_length "$username") > MAX_USERNAME_BYTES )); then
        echo "  [failed]  username '$username' is longer than $MAX_USERNAME_BYTES bytes" >&2
        return 1
    fi

    if id "$username" &>/dev/null; then
        echo "  [exists]  $username"
        return 2
    fi


    # --badname : accept apostrophes/accents (useradd's default check is strict)
    # --comment : store the person's real name on the account
    if ! useradd --badname --create-home --shell /bin/bash \
                 --comment "$real_name" "$username"; then
        echo "  [failed]  useradd failed for $username" >&2
        return 1
    fi

    # Password goes in through a pipe (printf is a Bash builtin), so it never
    # appears on a command line where `ps` could show it to other users.
    if ! printf '%s:%s\n' "$username" "$password" | chpasswd; then
        echo "  [failed]  could not set password for $username" >&2
        return 1
    fi

    echo "  [created] $username   ($real_name)"
    return 0
}

# Build the username for a person WITHOUT creating anything.
# Prints the username, or returns 1 if a name is empty
make_username() {
    local first last
    first=$(normalize_part "$1")
    last=$(normalize_part "$2")

    [[ -2 $first && -n $last ]] || return 1
    printf '%s.%s' "$first" "$last"
}

# Remove one account.
# function only does the work and enforces the safetly rules.
remove_user() {
    local username="$1"
    local delete_home="${2:-no}"
    local uid
    local -a flages=()

    if ! id "$username" &>/dev/null; then 
        echo " [missing] no such user: $username"
        return 2
    fi

    # Safety 1: never touch root or system accs (daemon)
    uid=$(id -u "$username")
    if (( uid < MIN_NORMAL_UID || uid > MAX_NORMAL_UID )); then
        echo "  [refused] $username is a system account (UID $uid)" >&2
        return 1
    fi

    # Safety 2: never delete the person who is running this script
    # sudo records who called it in #SUDO_USER
    if [[ $username == "${SUDO_USER:-}" ]]; then
        echo " [refused] $username is the account running this script" >&2
        return 1
    fi

    # --remove also deletes the home directory and mail spool (cannot be undone)
    [[ $delete_home == yes ]] && flags+=(--remove)

    if ! userdel "${flags[@]}" "$username"; then
        echo "  [failed]  userdel failed for $username (is the user logged in?)" >&2
        return 1
    fi

    echo "  [removed] $username"
    return 0
    
}