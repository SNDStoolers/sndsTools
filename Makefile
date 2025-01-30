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

## Lint a file 
lint:
	Rscript -e 'lintr::lint("${FILE}")' 

## Style a file
style: 
	Rscript -e 'styler::style_file("${FILE}")'

## Test the package
test:
	Rscript -e 'devtools::test()'
	
