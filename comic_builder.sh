#!/bin/bash

# Set the path to your parent Comic folder
parent_folder="/Users/kushalshah/main/Comics/Incomplete"

# Create a master folder for the renamed images
master_folder="/Users/kushalshah/main/Comics/Comics"
mkdir -p "$master_folder"

# Function to print a progress bar
print_progress() {
    local progress=$1
    local bar_length=50
    local filled_length=$((progress * bar_length / 100))
    local empty_length=$((bar_length - filled_length))

    printf "\r[%-${bar_length}s] %d%%" $(printf "%-${filled_length}s" "#" | tr ' ' '#') "$progress"
}

# Function to calculate the percentage
calculate_percentage() {
    local total_files=$1
    local processed_files=$2
    echo $((processed_files * 100 / total_files))
}

# Function to rename issue folders
rename_issue_folders() {
    local comic_folder="$1"
    local comic_name="$2"
    local issue_count=1
    for issue_folder in "$comic_folder"/*; do
        # Check if it's a directory
        if [ -d "$issue_folder" ]; then
            # Rename the issue folder
            new_issue_folder="$comic_folder/$comic_name-Issue-$issue_count"
            mv "$issue_folder" "$new_issue_folder"
            ((issue_count++))
        fi
    done
}

# Count the total number of files to process
total_files=$(find "$parent_folder" -type f -name "*.jpg" | wc -l)
processed_files=0

# Iterate through each comic book folder
for comic_folder in "$parent_folder"/*; do
    # Check if it's a directory
    if [ -d "$comic_folder" ]; then
        # Get the comic book name from the folder
        comic_name=$(basename "$comic_folder")
        echo "Renaming issue folders in comic '$comic_name'..."

        # Rename issue folders
        rename_issue_folders "$comic_folder" "$comic_name"

        # Create a subfolder under the master folder for the current comic book
        comic_master_folder="$master_folder/$comic_name"
        mkdir -p "$comic_master_folder"

        # Iterate through each issue folder
        for issue_folder in "$comic_folder"/*; do
            # Check if it's a directory
            if [ -d "$issue_folder" ]; then
                # Get the issue number from the folder
                issue_number=$(basename "$issue_folder")

                # Iterate through each image in the issue folder
                page_number=1
                for image_path in "$issue_folder"/*.jpg; do
                    # Check if there are images in the issue folder
                    if [ -e "$image_path" ]; then
                        # Get the image extension
                        image_extension="${image_path##*.}"

                        # Create the new filename
                        new_filename="$comic_name-$issue_number-Page$page_number.$image_extension"

                        # Rename the image
                        mv "$image_path" "$comic_master_folder/$new_filename"

                        ((page_number++))
                        ((processed_files++))
                        progress=$(calculate_percentage "$total_files" "$processed_files")
                        print_progress "$progress"
                    fi
                done
            fi
        done

        echo "Making a PDF of comic '$comic_name'..."
        # Convert images to PDF
        cd "$comic_master_folder"

        # Count the total number of images for PDF conversion
        total_images=$(find . -type f -name "*.jpg" | wc -l)
        converted_images=0

        for image_path in *.jpg; do
            # Check if there are images in the folder
            if [ -e "$image_path" ]; then
                # Convert the image to PDF
                convert "$image_path" "${image_path%.jpg}.pdf"
                ((converted_images++))
                pdf_progress=$(calculate_percentage "$total_images" "$converted_images")
                print_progress "$pdf_progress"
            fi
        done

        # Combine PDFs into one
        pdf_location="$master_folder/$comic_name.pdf"
        gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile="$pdf_location" *.pdf

        # Clean up individual PDFs
        rm *.pdf

        echo -e "\nPDF location for comic '$comic_name': $pdf_location"
        echo "Comic '$comic_name' complete."
        echo "Starting on the next comic..."
    fi
done

# Cleanup: Delete everything in the original folder
echo "Cleaning the main folder..."
rm -rf "$parent_folder"/*

echo -e "\nTask complete."
