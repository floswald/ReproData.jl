module ReproData

using Random
using DataFrames
using CSV
using CategoricalArrays: categorical

    """
        FEbenchmark(;N=10_000_000,K= 100)

    A function to create a 2-way fixed effect dataset. `N` observations, `K` 
    and `N/K` categories for Fixed effects respectively. We generate 7 regressors as well as a weight vector.
    """
    function FEbenchmark(;N=10_000_000,K= 100)
        @info "creating $(fld(N,K)) groups for id1"
        @info "creating $K groups for id2"
        id1_int = Int.(rand(1:fld(N,K), N))
        id2_int = Int.(rand(1:K, N))
        w = rand(id1_int)
        
        x1 = 5 * cos.(id1_int) + 5 * sin.(id2_int) + randn(N)
        x2 =  randn(N)
        x3 =  randn(N)
        x4 =  randn(N)
        x5 =  randn(N)
        x6 =  randn(N)
        x7 =  randn(N)
        y = 3 .* x1 .+ 5 .* x2 .+ 2 .* x3 .+ x4 .+ x5 .+ x6 .+ x7 .+ sin.(id1_int) .+ cos.(id2_int).^2 .+ randn(N)
        df = DataFrame(id1 = categorical(id1_int),id1_int = id1_int, 
                    id2 = categorical(id2_int), id2_int = id2_int,
                    x1 = x1, 
                    x2 = x2,
                    x3 = x3,
                    x4 = x4,
                    x5 = x5,
                    x6 = x6,
                    x7 = x7,        
                    w = w, y = y)
        df
    end

    function run(;N=10_000_000,K= 100)
        Random.seed!(29032025)
        d = FEbenchmark(N = N, K = K) 
        CSV.write(joinpath(@__DIR__,"..","data.csv"),d)
    end

end  # module