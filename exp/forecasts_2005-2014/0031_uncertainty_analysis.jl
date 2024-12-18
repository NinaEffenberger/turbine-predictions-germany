using DataFrames
using CSV
using Makie
using Statistics

# idea: take one run per climate scenario, compute variance over all scenarios and average over time
directory_path = "data/extracted_wind_speeds/MPI/ssp585/yearly"
files = readdir(directory_path, join = true)
data_frames = Dict{String,DataFrame}()
for file in files
    base_name = splitext(basename(file))[1]
    df = CSV.read(file, DataFrame)
    data_frames[base_name] = df
end

# Function to rename columns generically
function rename_columns(df::DataFrame, prefix::String)
    new_names = [Symbol(prefix * string(i)) for i = 1:ncol(df)]
    rename!(df, new_names)
end

directory_path = "data/extracted_wind_speeds/MPI/ssp126/yearly"
files = readdir(directory_path, join = true)
data_frames = Dict{String,DataFrame}()
for file in files
    base_name = splitext(basename(file))[1]
    df = CSV.read(file, DataFrame)
    data_frames[base_name] = df
end

r3_orig_wind_speeds_ssp126 = hcat(
    rename_columns(data_frames["r1_orig_wind_speeds_2015"], "1"),
    rename_columns(data_frames["r1_orig_wind_speeds_2016"], "2"),
    rename_columns(data_frames["r1_orig_wind_speeds_2017"], "3"),
    rename_columns(data_frames["r1_orig_wind_speeds_2018"], "4"),
    rename_columns(data_frames["r1_orig_wind_speeds_2019"], "5"),
    rename_columns(data_frames["r1_orig_wind_speeds_2020"], "6"),
    rename_columns(data_frames["r1_orig_wind_speeds_2021"], "7"),
    rename_columns(data_frames["r1_orig_wind_speeds_2022"], "8"),
    rename_columns(data_frames["r1_orig_wind_speeds_2023"], "9"),
)

directory_path = "data/extracted_wind_speeds/MPI/ssp245/yearly"
files = readdir(directory_path, join = true)
data_frames = Dict{String,DataFrame}()
for file in files
    base_name = splitext(basename(file))[1]
    df = CSV.read(file, DataFrame)
    data_frames[base_name] = df
end

r3_orig_wind_speeds_ssp245 = hcat(
    rename_columns(data_frames["r1_orig_wind_speeds_2015"], "1"),
    rename_columns(data_frames["r1_orig_wind_speeds_2016"], "2"),
    rename_columns(data_frames["r1_orig_wind_speeds_2017"], "3"),
    rename_columns(data_frames["r1_orig_wind_speeds_2018"], "4"),
    rename_columns(data_frames["r1_orig_wind_speeds_2019"], "5"),
    rename_columns(data_frames["r1_orig_wind_speeds_2020"], "6"),
    rename_columns(data_frames["r1_orig_wind_speeds_2021"], "7"),
    rename_columns(data_frames["r1_orig_wind_speeds_2022"], "8"),
    rename_columns(data_frames["r1_orig_wind_speeds_2023"], "9"),
)

directory_path = "data/extracted_wind_speeds/MPI/ssp370/yearly"
files = readdir(directory_path, join = true)
data_frames = Dict{String,DataFrame}()
for file in files
    base_name = splitext(basename(file))[1]
    df = CSV.read(file, DataFrame)
    data_frames[base_name] = df
end

r3_orig_wind_speeds_ssp370 = hcat(
    rename_columns(data_frames["r1_orig_wind_speeds_2015"], "1"),
    rename_columns(data_frames["r1_orig_wind_speeds_2016"], "2"),
    rename_columns(data_frames["r1_orig_wind_speeds_2017"], "3"),
    rename_columns(data_frames["r1_orig_wind_speeds_2018"], "4"),
    rename_columns(data_frames["r1_orig_wind_speeds_2019"], "5"),
    rename_columns(data_frames["r1_orig_wind_speeds_2020"], "6"),
    rename_columns(data_frames["r1_orig_wind_speeds_2021"], "7"),
    rename_columns(data_frames["r1_orig_wind_speeds_2022"], "8"),
    rename_columns(data_frames["r1_orig_wind_speeds_2023"], "9"),
)

directory_path = "data/extracted_wind_speeds/MPI/ssp585/yearly"
files = readdir(directory_path, join = true)
data_frames = Dict{String,DataFrame}()
for file in files
    base_name = splitext(basename(file))[1]
    df = CSV.read(file, DataFrame)
    data_frames[base_name] = df
end

r3_orig_wind_speeds_ssp585 = hcat(
    rename_columns(data_frames["r1_orig_wind_speeds_2015"], "1"),
    rename_columns(data_frames["r1_orig_wind_speeds_2016"], "2"),
    rename_columns(data_frames["r1_orig_wind_speeds_2017"], "3"),
    rename_columns(data_frames["r1_orig_wind_speeds_2018"], "4"),
    rename_columns(data_frames["r1_orig_wind_speeds_2019"], "5"),
    rename_columns(data_frames["r1_orig_wind_speeds_2020"], "6"),
    rename_columns(data_frames["r1_orig_wind_speeds_2021"], "7"),
    rename_columns(data_frames["r1_orig_wind_speeds_2022"], "8"),
    rename_columns(data_frames["r1_orig_wind_speeds_2023"], "9"),
)

variance_df = DataFrame(Matrix{Float64}(undef, 110, 13147), :auto)

# Calculate variance for each element
for row = 1:110
    for col = 1:13147
        # Extract the corresponding elements from each dataframe
        values = [
            r3_orig_wind_speeds_ssp126[row, col],
            r3_orig_wind_speeds_ssp245[row, col],
            r3_orig_wind_speeds_ssp370[row, col],
            r3_orig_wind_speeds_ssp585[row, col],
        ]
        # Calculate variance and assign to the new dataframe
        variance_df[row, col] = var(values)
    end
end

r3_orig_wind_speeds_ssp245[1, 1528]

row_means = Vector{Float64}(undef, 110)

var([
    r3_orig_wind_speeds_ssp126[1, 1528],
    r3_orig_wind_speeds_ssp245[1, 1528],
    r3_orig_wind_speeds_ssp585[1, 1528],
    r3_orig_wind_speeds_ssp370[1, 1528],
])
variance_df[1, 1528]

# Calculate the mean for each row
for row = 1:110
    row_means[row] = mean(variance_df[row, :])
end
row_means
variance_df

data_u = Dataset(
    "data/generated_data/MPI/uas_r3/outfile_46.66667175292969_55.833335876464844_5.0_15.416666984558105.nc",
    "r",
)
data_v = Dataset(
    "data/generated_data/MPI/vas_r3/outfile_46.66667175292969_55.833335876464844_5.0_15.416666984558105.nc",
    "r",
)

lon = data_u["lon"][:]
lat = data_u["lat"][:]


starting_point_cmip6 = 365 * 4 * 6 + 4
end_point_cmip6 = length(data_u["time"]) - 1
data_u["time"][starting_point_cmip6:end_point_cmip6]
lats = repeat(lat, size(lon)[1])
len_orig = length(lats)
lons = reshape(permutedims(repeat(lon, 1, size(lat)[1]), [2, 1]), size(lats))
log_data = log10.(row_means .+ 1)
f = Figure()
ax1 = Axis(
    f[1, 1],
    xlabel = L"\mathrm{Longitude}",
    #ylabel = L"Latitude",
    xticklabelsize = 20,
    yticklabelsize = 20,
    ylabelsize = 30,
    xlabelsize = 30,
)
arrows = Makie.heatmap!(ax1, lons, lats, log_data)
#Colorbar(f[1, 2], arrows, label = "Wind speed", width = 10, ticklabelsize = 8)
cbar = Colorbar(
    f[1, 2],
    arrows,
    label = "Log Scale",
    ticks = ([log10(4), log10(6), log10(8), log10(10)], ["4", "6", "8", "10"]),
)

f

log(10)