#!/bin/bash

# run generate_files.sh first
base_dir="/Users/ninaeffenberger/phd/2023-09-gp-julia/cmip6forecasts/data/original/ssp245"

# 46.66667175292969 55.833335876464844 5.0 15.416666984558105
# Use find to locate all subfolders within the base directory
subfolders=$(find "$base_dir" -mindepth 1 -maxdepth 2 -type d)

# Iterate through each subfolder and execute the command
for folder in $subfolders; do
    echo "Entering directory: $folder"
    # Change into the subfolder
    cd "$folder" || continue  # Continue to next iteration if cd fails
    
    # Perform your command (e.g., listing files in the directory)
    ncks -d lat,$1,$2 -d lon,$3,$4 out.nc outfile_$1_$2_$3_$4.nc
    
    # Change back to the base directory
    cd "$base_dir"
done
