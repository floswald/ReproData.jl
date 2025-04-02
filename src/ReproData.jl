module ReproData

    using Random
    using DataFrames
    using CSV
    using CategoricalArrays: categorical
    using Downloads
    

    include("statawriters.jl")
    include("latex_writers.jl")
    include("r-writers.jl")

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
        
        x1 = cos.(id1_int) + sin.(id2_int) + 0.1 .* randn(N)
        x2 = sin.(id2_int) + 0.1 .* randn(N)
        x3 =  randn(N)
        x4 =  randn(N)
        x5 =  randn(N)
        x6 =  randn(N)
        x7 =  randn(N)
        y = 3 .* x1 .+ 3 .* x2 .+ x3 .+ x4 .+ x5 .+ x6 .+ x7 .+ cos.(id1_int) .+ sin.(id2_int) .+ randn(N)
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

    # building project functions
    root() = "/Users/floswald/git/ReproWorkshop"

    subdirs() = ["output","paper","code","data"]
    wipe() = map(x -> rm(joinpath(root(),x), recursive = true, force = true), subdirs() )
    function createtree()
        map(x -> mkpath(joinpath(root(),x)), subdirs())
    end
    
    
    records() = Dict("Oswald" => "15124721")
    
    function get_packages(root)
        for (kr,vr) in records()
            @info "downloading record $kr"
            dest = mkpath(joinpath(root,"data","raw"))
            Downloads.download("https://zenodo.org/api/records/$vr/files-archive", joinpath(dest,"archive.zip"))
            # unpack L1
            Base.run(`unzip -q $(joinpath(dest,"archive.zip")) -d $(dest)`)
        end
        @info "done downloading and unzipping"
    end

    new_readme() = open(joinpath(root(),"README.md"),"w") do io 
        write(io,"""
        # My Reproducible Research Project

        We are building a reproducible research project. We will 

        1. Download some data from a public repository and record the citation record. 📚
        2. Use Stata to perform statistical analysis
        3. Use R to perform some more analysys
        4. Use `julia` to perform even more 🤪
        5. Collect all results and write into a paper.

        ## Outline of Analysis

        We want to run a two fixed effects regression in all three programming languages. We will build a table of results from each, and record the time it took to run the analysis. Along the way, we will take care to carefully record all info to reproduce our computational environment.

        """
        )
    end

    append_readme(s::String) = open(joinpath(root(),"README.md"),"a") do io 
        write(io,s)
    end


    function workshop()

        # 	* create a folder structure: data, code, output, paper
        createtree()

        # * create a new readme.md at root of this
        new_readme()

        #     * download example data from zenodo
        # get_packages(root())

        # write citation into readme
        append_readme("""

        ## Data Citation

        Oswald, F. (2025). Data for Reproducibility Exercise [Data set]. Zenodo. https://zenodo.org/records/15124721

        Here is a bibtex entry:

        ```
        @dataset{oswald_2025_15124721,
        author       = {Oswald, Florian},
        title        = {Data for Reproducibility Exercise},
        month        = apr,
        year         = 2025,
        publisher    = {Zenodo},
        doi          = {10.5281/zenodo.15124721},
        url          = {https://doi.org/10.5281/zenodo.15124721},
        }
        ```
        """)

        # set to read only
        chmod(joinpath(root(),"data","raw"), 0o555, recursive = true)

        # make a folder for do files
        mkpath(joinpath(root(),"code","stata","do"))

        #     * create a run.do file, setting up a config.do as well.
        stata_write_run()
        stata_write_config()
        stata_write_install()
        stata_write_read()
        stata_write_reghdf()

        @info "executing stata"
        runstata()

        append_readme("""

        ## Stata Package Versions

        ```
        +--------------------------------+
        | number    package         date |
        |--------------------------------|
        |    [6]     ftools   1 Apr 2025 |
        |    [7]      mypkg   1 Apr 2025 |
        |    [1]    reghdfe   1 Apr 2025 |
        |    [2]    regsave   1 Apr 2025 |
        |    [5]    rscript   1 Apr 2025 |
        |--------------------------------|
        |    [3]   st0085_2   1 Apr 2025 |
        |    [4]    texsave   1 Apr 2025 |
        +--------------------------------+

        +-------------------------------------
        Date and time:  1 Apr 2025 16:43:09
        Stata version: 18.5
        Updated as of: 22 May 2024
        Variant:       MP
        Processors:    2
        OS:            Unix 
        Machine type:  Mac (Apple Silicon)
        Shell:         /opt/homebrew/bin/fish
        +-------------------------------------
        ```
        """)

        append_readme("""
        
        ## Input and Output

        | Paper Object |  File name |  function |
        | ------------ |  --------- |  -------- |
        | Table 1 |  `output/tables/statareg1.tex` |  `code/stata/do/2_regression.do` |

        """)

        write_paper()

        # compile paper
        Base.run(Cmd(`latexmk main.tex`, dir = joinpath(root(),"paper")))

        # delete output
        # rm(joinpath(root(),"output"),recursive = true, force = true)

        # run stata again
        # runstata()
        # Base.run(Cmd(`latexmk main.tex`, dir = joinpath(root(),"paper")))

        # append run time to readme
        append_readme("""
        ## Stata Runtime

        0.02 minutes
        """
        )

        # Add code/R
        mkpath(joinpath(root(),"code","R"))

        r_write()
        Base.run(`Rscript $(joinpath(root(),"code","R","script.R"))`)

        write_paper2()
        # compile paper
        # Base.run(Cmd(`latexmk main.tex`, dir = joinpath(root(),"paper")))

        # add renv to R project
        r_writeenv()
        Base.run(`Rscript $(joinpath(root(),"code","R","script.R"))`)

        write_paper3()


        # Add R package citations to readme
        cites = join(readlines(joinpath(root(), "grateful-report.md")), "\n")

        append_readme(cites)


        @info "project built"
    end

    runstata() = Base.run(`stata-mp -b -e $(joinpath(root(),"code","stata","run.do"))`)

end  # module