using ReproData
using Test
using DataFrames
using CSV

@testset "ReproData.jl" begin
    n = 100
    d = ReproData.FEbenchmark(N = n, K = 10)
    @test size(d,1) == n 
    @test all(["y","id1","id2", ["x$i" for i in 1:7]...] .∈ Ref(names(d)))

    CSV.write(joinpath(@__DIR__,"..","testdata.csv"),d)
    
    d2 = CSV.read(joinpath(@__DIR__,"..","testdata.csv"), DataFrame)

    @test d == d2

    rm(joinpath(@__DIR__,"..","testdata.csv"), force = true)

end
