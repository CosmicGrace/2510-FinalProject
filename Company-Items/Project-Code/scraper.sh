#!/user/bin/env bash
#
# scraper.sh - Part 1: download the faculty page and extract names.

readonly FACULTY_URL="https://www.tntech.edu/engineering/programs/csc/faculty-and-staff.php"

_fetch_page() {
    curl --silent --show-error --fail --location \
         --max-time 30 --proto '=https' \
         "$FACULTY_URL"
}

# Read HTML on stdin, print clean names on stdout.
_extract_names() {
    tr '\r\n' '  ' \
        | grep -ioP '<h4[^>]*>.*?</h4>' \
        | sed -e 's/<[^>]*>//g' \
              -e 's/&nbsp;/ /g' \
              -e 's/&amp;/\&/g' \
              -e 's/,.*//' \
        | tr -s ' ' \
        | sed -e 's/^ //' -e 's/ $//' \
        | grep -v '^$'
}

scrape_faculty_names() {
    local response_raw names

    echo "Downloading faculty page from $FACULTY_URL..." >&2

    response_raw=$(_fetch_page) || {
        echo "ERROR: could not download the faculty page." >&2
        return 1
    }

    names=$(printf '%s' "$response_raw" | _extract_names)

    if [[ -z $names ]]; then
        echo "ERROR: no names found - the website layout may have changed" >&2
        echo "       (expected names inside <h4> tags)." >&2
        return 1
    fi

    printf '%s\n' "$names"
}