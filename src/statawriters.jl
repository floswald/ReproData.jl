
function stata_write_run()
    open(joinpath(root(),"code","stata","run.do"),"w") do io 
        write(io,"""
        *** Stata run script ***

        global root "$(root())"
        global stataroot "\$root/code/stata"
        local ProjectDir "\$stataroot"

        cap assert !mi("\$stataroot")
        if _rc {
            noi di as error "Error: need to define the global in run.do"
            error 9
        }

        * Re-install stata libraries into this project? 1 = yes
        global install = 0

        * run analysis on smaller sample? 1 = yes
        global subset = 0

        * rebuild data? 1 = yes
        global rebuild = 1

        * Configure Stata's library environment and record system parameters
        do "\$stataroot/do/_config.do"

        * Record start time and initialize log
        local datetime1 = clock("\$S_DATE \$S_TIME", "DMYhms")
        clear
        timer clear

        * Run analysis code
        if "\$rebuild" == "1" {
            do "\$stataroot/do/1_read_data.do"
        }
        do "\$stataroot/do/2_regression.do"

        *** output timers
        timer list

        *** total runtime
        local datetime2 = clock("\$S_DATE \$S_TIME", "DMYhms")
        di "Runtime (minutes): " %-12.2fc (`datetime2' - `datetime1')/(1000*60)

        display in red "++++ STATA DONE +++++"
        """
        )
    end
end

    # set up a config.do
function stata_write_config()
    open(joinpath(root(),"code","stata","do","_config.do"),"w") do io 
        write(io,
        """
        * Stata version control
        version 18

        * Display reinstallation info
        cap program drop _print_install
        program define _print_install 
            args pdir
            di in red "******************"
            di in red "Re-installing Stata packages"
            di in red "******************"
            
            do "`pdir'/do/_install_packages.do"

            di in red "******************"
            di in red "Re-installing Stata packages: DONE"
            di in red "******************"
        end

        * Display system parameters and record the date and time
        cap program drop _print_timestamp 
        program define _print_timestamp 
            di "{hline `=min(79, c(linesize))'}"

            di "Date and time: \$S_DATE \$S_TIME"
            di "Stata version: `c(stata_version)'"
            di "Updated as of: `c(born_date)'"
            di "Variant:       `=cond( c(MP),"MP",cond(c(SE),"SE",c(flavor)) )'"
            di "Processors:    `c(processors)'"
            di "OS:            `c(os)' `c(osdtl)'"
            di "Machine type:  `c(machine_type)'"
            local hostname : env HOSTNAME
            local shell : env SHELL
            if !mi("`hostname'") di "Hostname:      `hostname'"
            if !mi("`shell'") di "Shell:         `shell'"
            
            di "{hline `=min(79, c(linesize))'}"
        end

        /* install any packages locally */
        di "=== Redirecting where Stata searches for ado files ==="
        capture mkdir "\$stataroot/ado"
        adopath - PERSONAL
        adopath - OLDPLACE
        adopath - SITE
        sysdir set PLUS     "\$stataroot/ado/plus"
        sysdir set PERSONAL "\$stataroot/ado"       // may be needed for some packages
        sysdir

        * install libraries if required
        if "\$install"=="1" {
            noi _print_install "\$stataroot"
            mata: mata mlib index
        }

        di "*** Stata Packages installed this project ***"
        mypkg

        ** print system info
        noi _print_timestamp


        * folder structure
        cap mkdir "\$root/data/processed"
        cap mkdir "\$root/output"
        cap mkdir "\$root/output/tables"
        cap mkdir "\$root/output/plots"

        """)
    end
end

    # set up a install_packages.do
function stata_write_install()
    open(joinpath(root(),"code","stata","do","_install_packages.do"),"w") do io 
        write(io,
        """
        * list of ssc packages
        local ssc_packages "reghdfe ftools mypkg"
            

        display in red "============ Installing packages/commands from SSC ============="
        display in red "== Packages: `ssc_packages'"
        if !missing("`ssc_packages'") {
            foreach pkg in `ssc_packages' {
                capture which `pkg'
                if _rc == 111 {                 
                    dis "Installing `pkg'"
                    ssc install `pkg', replace
                }
                which `pkg'
            }
        } 
        else {
            display in red "== no ssc packages to install"
        }

        * Install latest developer's version of the package from online location
        net install st0085_2.pkg, from("http://www.stata-journal.com/software/sj14-2/") replace  
        """)
    end
end

function stata_write_read()
    open(joinpath(root(),"code","stata","do","1_read_data.do"),"w") do io 
        write(io,
        """

        *** time csv read ***
        timer on 1
        
        *** read data ***
        insheet using "\$root/data/raw/data.csv", clear

        timer off 1

        *** drop a few columns
        drop id1_int id2_int w

        if "\$subset" == "1" {
            * take a smaller subset
            generate random = runiform()
            sort random
            generate insample = _n <= 100000
            keep if insample==1
        } 

        *** save on disk
        save "\$root/data/processed/cleaned.dta", replace

        """)
    end
end

function stata_write_reghdf()
    open(joinpath(root(),"code","stata","do","2_regression.do"),"w") do io 
        write(io,
        """
        *** read data ***
        use "\$root/data/processed/cleaned.dta", clear

        *** time the estimation ***
        timer on 2

        eststo m0: reg y x1 x2 
        quietly estadd local fe1 "No", replace
        quietly estadd local fe2 "No" , replace 

        eststo m1: reghdfe y x1 x2 , absorb(id1) 
        quietly estadd local fe1 "Yes", replace
        quietly estadd local fe2 "No" , replace 

        eststo m2: reghdfe y x1 x2 , absorb(id1 id2) 
        quietly estadd local fe1 "Yes", replace
        quietly estadd local fe2 "Yes" , replace 

        eststo m3: reghdfe y x1-x7 , absorb(id1 id2) 
        quietly estadd local fe1 "Yes", replace
        quietly estadd local fe2 "Yes" , replace 

        timer off 2

        #delimit ;
        esttab m0 m1 m2 m3 using "\$root/output/tables/statareg.tex", 
	    replace label se star(* 0.10 ** 0.05 *** 0.01) 
        s(fe1 fe2 N,label("FE 1" "FE 2" "Observations")) 
        booktabs;
        #delimit cr


        """)
    end
end