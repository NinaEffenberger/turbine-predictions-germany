using AbstractGPs
using KernelFunctions
using NCDatasets
using CSV
using DataFrames
using LinearAlgebra
using Dates
using GeoMakie, CairoMakie
using ParameterHandling  # for nested and constrained parameters
using Optim  # optimization
using Zygote
using Random
using Printf

pathway = "ssp370"
path = "data/original/"
data_u = Dataset(
    path *
    pathway *
    "/u/outfile_46.66667175292969_55.833335876464844_5.0_15.416666984558105.nc",
    "r",
)

data_u["time"][:]

data = Dataset("data/original/ssp126/out.nc", "r")