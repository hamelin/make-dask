# Utility files to help with configuring worker sets.
dask-work = $(addsuffix @$(2),$(shell seq --format='%02.f' 1 $(1)))
