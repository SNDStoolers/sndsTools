## Build the package documentation
docs-r:
	Rscript -e 'library(devtools);pkgload::load_all();devtools::document();devtools::check(error_on="error")'


## Build the package website
docs-html:
	Rscript -e 'library(devtools);pkgload::load_all();devtools::document();devtools::check(error_on="error")'
	Rscript -e 'pkgdown::clean_site();devtools::install();pkgdown::build_site()'
	
## Build the package sources as .tar.gz
build:
	Rscript -e 'devtools::install();devtools::build()'
	mv ../sndsTools_* .

## Lint the package
lint-pkg:
	Rscript -e 'lintr::lint_package()'

## Lint a file : usage make lint FILE=R/01-setup.R
lint:
	Rscript -e 'lintr::lint("${FILE}")' 

## Style the package	
style-pkg: 
	Rscript -e 'styler::style_pkg()'

## Style a file
style: 
	Rscript -e 'styler::style_file("${FILE}")'

## Test the package
test-pkg:
	Rscript -e 'devtools::test()'

## Auto-test (only code or tests that change)
autotest:
	Rscript -e 'devtools::load_all();testthat::auto_test(code_path = "R/", test_path = "tests/testthat/")'

testf: 
	Rscript -e 'devtools::load_all();testthat::test_file("${FILE}")'

## Move binary to the right place
mv-binary:
	Rscript -e 'file.copy(from="~/Citrix_documents/IMPORT/sndsTools_0.0.0.1.tar.gz", to="~/sasdata1/prg/", overwrite = TRUE)'

concat-functions:
	cat R/* > sndsTools_all.R
