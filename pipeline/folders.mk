$(FOLDERS):
	mkdir -p $@

# Just specify a folder with '/' at the end, if it's needed as dependency.
# This is a lot easier to distinguish
data/%/:
	mkdir -p $@
