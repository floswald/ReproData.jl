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
    and `N/K` categories for Fixed effects respectively. We generate 7 regressors.
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
    root() = get(ENV,"REPRO_ROOT","/Users/floswald/git/ReproWorkshop")

    subdirs() = ["output","paper","code","data"]
    function wipe(; rawdata = true, git = true)
        decision = Base.prompt("This will delete all. Good? Y / N ") in ("y","Y") ? "Y" : "N" 
        if decision == "Y"
            if rawdata && git
                @info "deleting all"
                if isdir(joinpath(root(),"data","raw"))
                    chmod(joinpath(root(),"data","raw"), 0o777, recursive = true)
                    rm(joinpath(root(),"data","raw"), recursive = true, force = true)
                end
                rm(root(), recursive = true, force = true)
            elseif rawdata && !git
                @info "deleting all but git"
                rm(joinpath(root(),"README.md"),force = true)
                rm(joinpath(root(),"data"), recursive = true, force = true)
                rm(joinpath(root(),"output"), recursive = true, force = true)
                rm(joinpath(root(),"paper"), recursive = true, force = true)
                rm(joinpath(root(),"code"), recursive = true, force = true)
            elseif !rawdata && git
                @info "deleting all but raw data"
                rm(joinpath(root(),"README.md"),force = true)
                rm(joinpath(root(),"data","processed"), recursive = true, force = true)
                rm(joinpath(root(),"output"), recursive = true, force = true)
                rm(joinpath(root(),"paper"), recursive = true, force = true)
                rm(joinpath(root(),"code"), recursive = true, force = true)
                rm(joinpath(root(),".git"), recursive = true, force = true)
            else
                @info "not deleting anything"
            end
            
        else
            @info "not deleting anything"
        end
    end

    function createtree(;dataloc = "/Users/floswald/Downloads/data.csv")
        map(x -> mkpath(joinpath(root(),x)), subdirs())
        map(x -> touch(joinpath(root(),x,".keep")), subdirs())
        mkpath(joinpath(root(),"data","raw"))
        touch(joinpath(root(),"data","raw",".keep"))
        cp(dataloc, joinpath(root(),"data","raw","data.csv"),force = true)
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

        > Caution: this is not meant to be an exhaustive example or indeed a template of a valid README file for your package. Please refer to [this link](https://social-science-data-editors.github.io/template_README/) for such a template. This readme here will be built up during our workshop, where we want to point out some selected aspects of the whole process.

        We are building a reproducible research project. We will 

        1. Download some data from a public repository and record the citation record. 📚
        2. Use Stata to perform statistical analysis
        3. Use R to perform some more analysys
        4. Collect all results and write into a paper.

        ## Outline of Analysis

        We want to run a two fixed effects regression in all two programming languages. We will build a table of results from each, and record the time it took to run the analysis. Along the way, we will take care to carefully record all info to reproduce our computational environment.

        """
        )
    end

    append_readme(s::String) = open(joinpath(root(),"README.md"),"a") do io 
        write(io,s)
    end

    function workshop(; with_git = false)
        wipe(rawdata = true, git = true)
        for s in 1:10
            workshopstep(step = s, git = with_git)
        end
    end

    function gitter(st,dir,message)
        Base.run(Cmd(`git add "$(join(dir))"`, dir = root())) 
        Base.run(Cmd(`git commit -m "$message"`, dir = root())) 
        Base.run(Cmd(`git tag -a step$st -m "tagging step $st"`, dir = root())) 
    end
    function gitter(st,dir1,dir2,message)
        Base.run(Cmd(`git add "$dir1"`, dir = root())) 
        Base.run(Cmd(`git add "$dir2"`, dir = root())) 
        Base.run(Cmd(`git commit -m "$message"`, dir = root())) 
        Base.run(Cmd(`git tag -a step$st -m "tagging step $st"`, dir = root())) 
    end
    function gitter(st,dir1,dir2,dir3,message)
        Base.run(Cmd(`git add "$dir1"`, dir = root())) 
        Base.run(Cmd(`git add "$dir2"`, dir = root())) 
        Base.run(Cmd(`git add "$dir3"`, dir = root())) 
        Base.run(Cmd(`git commit -m "$message"`, dir = root())) 
        Base.run(Cmd(`git tag -a step$st -m "tagging step $st"`, dir = root())) 
    end


    function workshopstep(; step = 1, git = false)

        if step == 1



            @info "step 1"
            # 	* create a folder structure: data, code, output, paper
            createtree()
            #initialize a git repo at root()
            if git 
                Base.run(Cmd(`git init`, dir = root())) 
                open(joinpath(root(),".gitignore"),"w") do io 
                    write(io,
                    """
                    data/processed/*.dta
                    data/raw/data.csv
                    paper/*.aux
                    paper/*.log
                    paper/*.out
                    paper/*.fdb_latexmk
                    paper/*.fls
                    """
                    )
                end
            end

            # * create a new readme.md at root of this
            new_readme()

            if git 
                gitter("1a",".", "create project structure")
            end

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

            # set data to read only
            chmod(joinpath(root(),"data","raw","data.csv"), 0o555, recursive = true)

            if git 
                gitter("1b",".", "cite data and set read only")
            end
        end

        if step == 2
            @info "step 2"

            # make a folder for do files
            mkpath(joinpath(root(),"code","stata","do"))

            #     * create a run.do file, setting up a config.do as well.
            stata_write_run()
            stata_write_config()
            stata_write_install()
            if git 
                gitter(step,".", "stata setup")
            end
        end

        if step == 3
            @info "step 3"
            # create stata pipeline
            stata_write_read()
            stata_write_reghdf()

            @info "executing stata"
            runstata()
            if git 
                gitter(step,"code/stata","output", "stata code and interm data")
            end

        end

        if step == 4
            @info "step 4"
            append_readme("""

            ## Stata Package Versions

            Both tables below are generated in our `_config.do` file.

            > output of `mypkg` command collected from `run.log`

            ```
            +--------------------------------+
            | number    package         date |
            |--------------------------------|
            |    [2]     ftools   6 May 2025 |
            |    [3]      mypkg   6 May 2025 |
            |    [1]    reghdfe   6 May 2025 |
            |    [4]   st0085_2   6 May 2025 |
            +--------------------------------+
            ```

            > output of `_print_timestamp` command

            ```
            -----------------------------------
            Date and time:  6 May 2025 21:10:49
            Stata version: 18.5
            Updated as of: 22 May 2024
            Variant:       MP
            Processors:    2
            OS:            Unix 
            Machine type:  Mac (Apple Silicon)
            Shell:         /opt/homebrew/bin/fish
            -------------------------------------
            ```
            """)

            append_readme("""
            
            ## Input and Output

            | Paper Object |  File name |  function |
            | ------------ |  --------- |  -------- |
            | Table 1 |  `output/tables/statareg1.tex` |  `code/stata/do/2_regression.do` |

            """)
            if git 
                gitter(step,"README.md", "update readme")
            end
        end

        if step == 5
            @info "step 5"
            write_paper()

            # compile paper
            # Base.run(Cmd(`latexmk main.tex`, dir = joinpath(root(),"paper")))

            # delete output
            # rm(joinpath(root(),"output"),recursive = true, force = true)

            # run stata again
            # runstata()
            # Base.run(Cmd(`latexmk main.tex`, dir = joinpath(root(),"paper")))

            # append run time to readme
            append_readme("""
            ## Stata Runtime

            0.2 minutes
            """
            )
            if git 
                gitter(step,"paper/main.tex","README.md","wrote paper")
            end
        end

        if step == 6
            @info "step 6"

            # Add code/R
            mkpath(joinpath(root(),"code","R"))

            r_write()
            Base.run(`Rscript $(joinpath(root(),"code","R","script.R"))`)
            if git 
                gitter(step,"code/R","output", "added R code")
            end
        end

        if step == 7
            @info "step 7"

            write_paper2()
            rm_latex_aux()
            # compile paper
            # Base.run(Cmd(`latexmk main.tex`, dir = joinpath(root(),"paper")))

            if git 
                gitter(step,"paper/main.tex", "updated paper")
            end
        end

        if step == 8
            @info "step 8"

            # add renv to R project
            r_writeenv()
            Base.run(`Rscript $(joinpath(root(),"code","R","script.R"))`)

            write_paper3()
            # rm_latex_aux()
            # Base.run(Cmd(`latexmk main.tex`, dir = joinpath(root(),"paper")))
            if git 
                gitter(step,"code/R", "paper/main.tex", "output", "added renv and updated paper")
            end
        end

        if step == 9
            @info "step 9"

            # Add R package citations to readme
            cites = join(readlines(joinpath(root(), "paper","grateful-report.md")), "\n")

            append_readme(cites)

            # compile paper
            Base.run(Cmd(`latexmk -pdf -f main.tex`, dir = joinpath(root(),"paper")))


            if git 
                gitter(step,"README.md","paper/grateful-report.md", "paper/main.pdf", "compiled pdf paper and added R package citations")

                # now checkout first tag again and remove all files with appear untracked
                Base.run(Cmd(`git checkout step1a`, dir = root()))
                Base.run(Cmd(`rm -r data/processed`, dir = root()))
                foreach(nothidden(readdir(joinpath(ReproData.root(), "code"), join=true))) do filename
                    rm(filename, recursive=true, force=true)
                end
                foreach(nothidden(readdir(joinpath(ReproData.root(), "paper"), join=true))) do filename
                    rm(filename, recursive=true, force=true)
                end
                foreach(nothidden(readdir(joinpath(ReproData.root(), "output"), join=true))) do filename
                    rm(filename, recursive=true, force=true)
                end
                rm(joinpath(root(),"run.log"),force = true,recursive = true)
            end
        end
    end

    runstata() = Base.run(Cmd(`stata-mp -b -e $(joinpath(root(),"code","stata","run.do"))`, dir = root()))

    nothidden(y) = filter(x -> !endswith(x,".keep"), y)

end  # module