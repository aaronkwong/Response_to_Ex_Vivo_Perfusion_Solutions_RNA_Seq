library(renv)
options(install.opts = "--no-lock")

renv::init(bare=TRUE)
renv::restore()