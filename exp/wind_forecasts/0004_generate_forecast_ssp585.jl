using AbstractGPs
using KernelFunctions
using NCDatasets
using CSV
using DataFrames
using Dates

pathway = "ssp585"
path = "data/original/"
data_u = Dataset(
    path *
    pathway *
    "/u/outfile_46.66667175292969_55.833335876464844_5.0_15.416666984558105.nc",
    "r",
)

data_v = Dataset(
    path *
    pathway *
    "/v/outfile_46.66667175292969_55.833335876464844_5.0_15.416666984558105.nc",
    "r",
)

lon = data_u["lon"][:]
lat = data_u["lat"][:]

lats = repeat(lat, size(lon)[1])
lons = reshape(permutedims(repeat(lon, 1, size(lat)[1]), [2, 1]), size(lats))
lons = (lons .- minimum(lons)) ./ (maximum(lons) - minimum(lons))
lats = (lats .- minimum(lats)) ./ (maximum(lats) - minimum(lats))

yearly_turbines = CSV.read("data/turbines_in_2023.csv", DataFrame)
latitudes_turbines = yearly_turbines.y_coordinates
longitudes_turbines = yearly_turbines.x_coordinates
lons_turbines =
    (longitudes_turbines .- minimum(longitudes_turbines)) ./
    (maximum(longitudes_turbines) - minimum(longitudes_turbines))
lats_turbines =
    (latitudes_turbines .- minimum(latitudes_turbines)) ./
    (maximum(latitudes_turbines) - minimum(latitudes_turbines))

years = collect(2024:2030)
for i in years
    indices_per_year = findall(x -> x == i, year.(data_u["time"][:]))
    loc_mean_speeds = Vector{Vector{Float64}}()
    print(i)
    for j in collect(1:length(indices_per_year))
        u = data_u["uas"][:, :, indices_per_year[1]-1+j]
        v = data_v["vas"][:, :, indices_per_year[1]-1+j]
        u = collect(Iterators.flatten(transpose(u)))
        v = collect(Iterators.flatten(transpose(v)))
        old_X = Vector{Vector{Float64}}(undef, size(lats))
        for i in eachindex(lats)
            old_X[i] = [lats[i], lons[i]]
        end
        k1 = k2 = k3 = Matern32Kernel()
        kron_kernel = IndependentMOKernel(k1)
        Y = Vector{Vector{Float64}}(undef, size(u))
        for i in eachindex(u)
            Y[i] = [u[i], v[i]]
        end
        Y = ColVecs(reduce(hcat, Y))
        X, Y = prepare_isotopic_multi_output_data(old_X, Y)
        gp = GP(kron_kernel)
        fx = gp(X, 0.0001)
        p_fx = posterior(fx, Y)
        new_X = Vector{Vector{Float64}}(undef, size(lons_turbines))
        for i in eachindex(lons_turbines)
            new_X[i] = [lats_turbines[i], lons_turbines[i]]
        end
        speeds = mean(p_fx, MOInput(new_X, 2))
        speeds = reshape(speeds, Int(length(speeds) / 2), 2)
        u = speeds[:, 1]
        v = speeds[:, 2]
        speeds_timepoint = vec(sqrt.(u .^ 2 .+ v .^ 2))
        push!(loc_mean_speeds, speeds_timepoint)
    end
    df = DataFrame(loc_mean_speeds, :auto)
    CSV.write(
        "data/wind_speeds_turbines/" *
        pathway *
        "/r1_wind_speeds_turbines" *
        string(i) *
        ".csv",
        df,
    )
end