Bootstrap: library
From: richelbilderbeek/default/ormr:0.6.2

%post
    # Install apt
    #sed -i 's/$/ universe/' /etc/apt/sources.list
    #apt-get -y update

    Rscript -e 'ormr::ormr_report(ormr_folder_name = "/opt/gcaer")'
    Rscript -e 'remotes::install_github("richelbilderbeek/plinkr")'
    Rscript -e 'remotes::install_github("richelbilderbeek/gcaer")'
    Rscript -e 'gcaer::gcaer_report(gcae_options = gcaer::create_gcae_options(gcae_folder = "/opt/gcaer"))'
    Rscript -e 'gcaer::install_gcae(gcae_options = gcaer::create_gcae_options(gcae_folder = "/opt/gcaer"), verbose = FALSE)'
    Rscript -e 'gcaer::gcaer_report(gcae_options = gcaer::create_gcae_options(gcae_folder = "/opt/gcaer"))'

# 'ormr' needs this
#%environment
#    export PATH=/miniconda/bin:$PATH

%runscript
exec R --vanilla --silent --no-echo "$@"

%test
    Rscript -e 'gcaer::is_gcae_installed(gcae_options = gcaer::create_gcae_options(gcae_folder = "/opt/gcaer"), verbose = TRUE)'

%help

This container has the R package gcaer and GCAE installed.

To make the container run a script called, e.g. `script.R`, do:

```
cat script.R | ./gcaer.sif
```

Within the script, set `gcae_options` to `create_gcae_options(gcae_folder = "/opt/gcaer")`, for example:

```
library(gcaer)
gcae_options <- create_gcae_options(gcae_folder = "/opt/gcaer")
run_gcae(args = "--help", gcae_options = gcae_options)
```

%labels

    AUTHOR Richel J.C. Bilderbeek

    NAME gcaer

    DESCRIPTION The gcaer R package, with the PLINK and Python packages installed

    USAGE simply run the container

    URL https://github.com/richelbilderbeek/gcaer

    VERSION 0.5.0.1
