

scrape_faculty_names() {
    local url="https://www.tntech.edu/engineering/programs/csc/faculty-and-staff.php"
    echo "Downloading faculty page from $url..."
    
    html_data=$(curl -s "$url")

    echo "$html_data" | grep -oP '(?<=<h3>)[^<]+(?=</h3>)' | while read -r raw_name; do
        clean_name=$(echo "$raw_name" | sed -E 's/^(Dr\.|Prof\.|Mr\.|Ms\.|Mrs\.)\s*//I')
        
        if [ -n "$clean_name" ]; then
            create_user_account "$clean_name"
        fi
    done
}
