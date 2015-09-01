
all: init create fetch

init:
	@echo '' > benchmarks.log

create:
	@./run 1 Resource.Create
	@./run 10 Resource.Create
	@./run 50 Resource.Create
	@./run 100 Resource.Create
	@./run 1000 Resource.Create
	@./run 10000 Resource.Create
	@echo

fetch:
	@./run 1 Resource.Fetch
	@./run 10 Resource.Fetch
	@./run 50 Resource.Fetch
	@./run 100 Resource.Fetch
	@./run 1000 Resource.Fetch
	@./run 10000 Resource.Fetch
	@echo

.PHONY: all
