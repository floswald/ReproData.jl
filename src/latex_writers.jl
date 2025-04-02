
function paper_preamble()
    """
    \\documentclass[12pt]{article}
    \\usepackage{setspace}
    \\usepackage{geometry}
    \\usepackage{adjustbox}
    \\geometry{verbose,lmargin=2cm,rmargin=2cm,bmargin=2cm,tmargin=2cm}
    
    \\usepackage{booktabs}
    \\usepackage{natbib}
    
    \\newcommand{\\rootdir}{..}  % one dir up
    \\newcommand{\\plots}{\\rootdir/output/plots}
    \\newcommand{\\tables}{\\rootdir/output/tables}


    %% TITLE PAGE
    \\begin{document}
    \\onehalfspacing
        
        
    \\title{A Reproducible Benchmark of Fixed Effects Estimation}
    
    
    
    \\author{Florian Oswald and All Workshop Participants}
    \\date{\\today}
    
    
    \\maketitle
    \\begin{abstract}
    We illustrate a workflow which tries to address several pitfalls when creating a reproducible research project. We focus on preserving raw data, documenting data sources, creating a folder structure, writing stata and R code in a way which helps to preserve the package version environment, outputting results to disk and referencing them in a final output document. As a by-product, we report timings of a typical two-way fixed effects estimation exercise on a large dataset.    
    \\end{abstract}

    \\section{Introduction}

    Reproducibility is simple in theory:

    \\begin{enumerate}
    \\item Preserve raw data
    \\item Document data origin
    \\item Preserve code and document how to use it
    \\end{enumerate}

    The devil is in the details, however, and \\emph{in practice}, achieving reprocibility is far from trivial. We want to use this fictitious research project to illustrate one potential strategy when setting up code, and associated pitfalls which might occur. 

    \\section{Computational Task}

    In this paper, we want to estimate the following linear regression with two fixed effects:

    \\begin{equation}
    y_{it} = \\beta X_{it} + \\alpha_i + \\gamma_t + u_{it} \\label{eq:1}
    \\end{equation}
    where \$X_{it}\$ is the 1 by K vector \$[ x_{it1}, \\dots, x_{itK}]\$

    We generated the data such that the first \$x\$ is a function of the fixed effects, \$x_{it1} = g(\\alpha_i, \\gamma_t)\$, and we set the true values for coefficients to \$\\beta = [ 3,5,2,1,1,1,1]\$. Now let me show you the first result in table \\ref{tab:1}. The point estimates seem close to the theoretical values. Overall a big success!

    \\begin{table}
    \\centering
    \\input{\\tables/statareg.tex}
    \\caption{This is done with stata. I couldn't figure out why the FE2 row does not display a "yes" in columns 3 and 4. My bad, sorry!\\label{tab:1}}
    \\end{table}
    """
end

function paper_addingR()
    """
    Let us also have a table produced by R. We show the results in table \\ref{tab:2} and in figure \\ref{fig:1}.

    \\begin{table}
    \\centering
    \\input{\\tables/table2.tex}
    \\caption{This is done with R.\\label{tab:2}}
    \\end{table}

    \\begin{figure}
    \\centering
    \\includegraphics[width=0.8\\textwidth]{\\plots/figure1.pdf}
    \\caption{The coef plot corresponding to table \\ref{tab:2}\\label{fig:1}.}
    \\end{figure}

    \\section{Timings}

    We found that this leads to the following result in terms of run time between stata and R, which are displayed in table \\ref{tab:3}.

    \\begin{table}[]
    \\centering
    \\begin{tabular}{lcc}
    \\toprule
        Operation & Stata & R  \\\\
        \\midrule
        CSV read & 62.43 & 1.493  \\\\
        FE estimation & 85.68 & 5.5  \\\\
        \\bottomrule
    \\end{tabular}
    \\caption{Timing of operations in different languages in seconds.\\label{tab:3}}
    \\end{table}
    %%% note to replicators: those values are displayed on the console
    %%% when running:
    %%% `code/stata/run.do` and `code/R/script.R`
    """
end


function write_paper()
    open(joinpath(root(),"paper","main.tex"),"w") do io 
        write(io,string(
            paper_preamble(),
        """
        \\end{document}
        """)
        )
    end
end


"""adds R table and timings"""
function write_paper2()
    open(joinpath(root(),"paper","main.tex"),"w") do io 
        write(io,string(
            paper_preamble(),
            paper_addingR(),
        """
        \\end{document}
        """)
        )
    end
end

"""adds citations"""
function write_paper3()
    open(joinpath(root(),"paper","main.tex"),"w") do io 
        write(io,string(
            paper_preamble(),
            paper_addingR(),
        """
        \\nocite{*}

        \\newpage
        
        \\bibliography{grateful-refs}
        \\bibliographystyle{plainnat}

        \\end{document}
        """)
        )
    end
end

