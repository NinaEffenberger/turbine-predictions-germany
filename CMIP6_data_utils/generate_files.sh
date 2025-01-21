#!/bin/bash

# Define the base directory where subfolders are located
base_dir="/Users/ninaeffenberger/phd/2023-09-gp-julia/cmip6forecasts/data/original/ssp245/r1"

# Use find to locate all subfolders within the base directory
subfolders=$(find "$base_dir" -mindepth 0 -maxdepth 1 -type d)

# Iterate through each subfolder and execute the command
for folder in $subfolders; do
    echo "Entering directory: $folder"
    # Change into the subfolder
    cd "$folder" || continue  # Continue to next iteration if cd fails
    
    # Perform your command (e.g., listing files in the directory)
    ncrcat *.nc out.nc
    
    # Change back to the base directory
    cd "$base_dir"
done
