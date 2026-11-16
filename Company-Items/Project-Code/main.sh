#!/usr/bin/env bash
#
#   main.sh - This holds the menu for the code
#
#   What it does:
#       1. Enforces the license check
#       2. Shows a text menu
#           [1] Import faculty from website
#           [2] Add a single user manually
#           [3] Remove a user
#           [4] Quit
#
#   Must be run as root (creating users requires it):
#       sudo ./main.sh
#
#
#   The other code files are what helps this run properly
#       scrape.sh - downlads + parse names
#       users.sh - username/password rules, create and remove accounts
#       


set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/license.sh"
source "${SCRIPT_DIR}/scraper.sh"
source "${SCRIPT_DIR}/user.sh"


# ---------------------------------------------------------------------------
#       Helpers
# ---------------------------------------------------------------------------

require_root() {
    if (( EUID != 0 )); then
        echo "ERROR: this tool creates users, so it must be run as root." >&2
        echo "      Try: sudo $0" >&2
        exit 1
    fi
}

show_menu() {
    echo
    echo "=============================================="
    echo "    hAlberd Technologies - Facaulty Account   "
    echo "                  Onboarding                  "
    echo "=============================================="

    echo "  1) Import faculty from website (default option)"
    echo "  2) Add a single user manually"
    echo "  3) Remove a user"
    echo "  4) Quit"
}

# Ask a yes/no question. Returns 0 only for "y" or "yes".
# Anything else (including pressing enter) will decline
confirm() {
    local answer
    read -r -p "$1 [y/N]: " answer
    case "${answer,,}" in
        y|yes) return 0 ;;
        *)    return 1 ;;
    esac  
}


# ---------------------------------------------------------------------------
#       Menu Actions
# ---------------------------------------------------------------------------

# Menu option 1: scrape names and then create a account for each facaulty member
action_import_faculty() { 
    local names name
    local created=0 existed=0 failed=0

    echo "Downloading faculty page..."
    names=$(scrape_faculty_names) || return 1 

    echo "Found $(wc -l <<< "$names") people. Creating accounts..."
    while IFS= read -r name; do
        create_user_account "$name" 
        case $? in 
            0) (( created++ )) ;; 
            2) (( existed++ )) ;; 
            *) (( failed++ )) ;; 
        esac  
    done <<< "$names"

    echo
    echo "Done. Created: $created | Already existed: $existed | Failed: $failed"

}

# Menu option 2: add one user by typing their name
action_add_user() {
    local first last
    read -r -p "First name: " first
    read -r -p "Last name: " last
    create_user "$first" "$last"
}

# Menu option 3: Remove a user. Asks for first and last name
action_remove_user() {
    local first last username delete_home="no"

    read -r -p "First name of user to remove: " first
    read -r -p "Last name: " last

    username=$(make_username "$first" "$last") || {
        echo " [failed] need both a valid first and last name" >&2
        return 1
    }

    confirm "Remove the account '$username'?" || { echo "Cancelled."; return 0; }

    confirm "Also DELETE their home directory and files? (cannot be undone)" && delete_home="yes"

    remove_user "$username" "$delete_home"
}


# ---------------------------------------------------------------------------
#       Main loopty loop
# ---------------------------------------------------------------------------

main() {
    require_root
    license_enforce || exit 1       # no valid license -> get blicked no runnign code for you

    local choice
    while true; do
        show_menu # showing the menu to the user
        read -r -p "Choose an option [1]: " choice  # User enters menu choice here :P

        choice="${choice:-1}"   # pressing Enter = default action of option 1

        case "$choice" in
            1) action_import_faculty ;;
            2) action_add_user ;;
            3) action_remove_user ;;
            4) echo "Goodbye!"; exit 0 ;;
            *) echo "Invalid choice of '$choice', try again!"
        esac

    done
}

main "$@"