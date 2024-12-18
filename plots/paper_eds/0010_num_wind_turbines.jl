using CSV
using DataFrames
using Makie
using GeoMakie, CairoMakie
using OrderedCollections
T = Theme(fontsize = 17, size = (500, 400))

directory_path = "/Users/ninaeffenberger/phd/2023-09-gp-julia/power-forecasts-gp/data/turbine_locations"
files = readdir(directory_path, join = true)
data_frames = Dict{String,DataFrame}()
for file in files
    base_name = splitext(basename(file))[1]
    df = CSV.read(file, DataFrame)
    data_frames[base_name] = df
end
data_frames
num_rows_vector = [nrow(data_frames[key]) for key in keys(data_frames)]
turbines = collect(
    values(sort(Dict(key => nrow(value) for (key, value) in data_frames))),
)
with_theme(T) do

    f = Figure()
    ax = Axis(
        f[1, 1],
        #xlabel = L"\mathrm{years}",
        ylabel = L"\mathrm{Power in MW}",
        xticklabelrotation = pi / 4,
        xticks = (1:3:14, [
            "2010",
            #"2011",
            #"2012",
            "2013",
            #"2014",
            #"2015",
            "2016",
            #"2017",
            #"2018",
            "2019",
            #"2020",
            #"2021",
            "2022",
            #"2023",
        ]),
        #xlabelsize = 15,
        #ylabelsize = 15,
        #xticklabelsize = 12,
        #yticklabelsize = 12,
    )

    lines!(ax, 1:length(turbines), turbines)
    save("plots/paper/pdfs/num_wind_turbines.pdf", f)
    f
end