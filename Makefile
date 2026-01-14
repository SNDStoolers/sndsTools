# check package
check:
	Rscript -e 'devtools::check(error_on="error")'
# install the package
install:
	Rscript -e 'devtools::install(upgrade="never")'
# Build the package documentation
docs-r:
	Rscript -e 'pkgload::load_all();devtools::document()'
# Build the package website
docs-html:
	Rscript -e 'pkgdown::clean_site();pkgdown::build_site()'
# Build the package sources as .tar.gz
build:
	Rscript -e 'devtools::install(upgrade="never");devtools::build()'
	mv ../sndsTools_* .
# Lint the package
lint:
	Rscript -e 'lintr::lint_package()'
# Lint a file : usage make lint-file FILE=R/01-setup.R
lint-file:
	Rscript -e 'lintr::lint("${FILE}")'
# Style the package
style:
	air format .
# Style a file : usage make style-file FILE=R/01-setup.R
style-file:
	air format ${FILE}
# Test the package
test:
	Rscript -e 'devtools::test()'
# Auto-test (only code or tests that change)
autotest:
	Rscript -e 'devtools::load_all();testthat::auto_test(code_path = "R/", test_path = "tests/testthat/")'
# Test a single file : usage make test-file FILE=tests/testthat/test-01-setup.R
test-file:
	Rscript -e 'devtools::load_all();testthat::test_file("${FILE}")'
# Move binary to the right place
mv-binary:
	Rscript -e 'file.copy(from="~/Citrix_documents/IMPORT/sndsTools_0.0.0.1.tar.gz", to="~/sasdata1/prg/", overwrite = TRUE)'
# Concatenate all R functions into a single file to move into the CNAM server
concat-functions:
	cat R/* > sndsTools_all.R
