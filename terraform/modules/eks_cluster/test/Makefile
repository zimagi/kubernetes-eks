.DEFAULT_GOAL : all

.PHONY: all
all: test

.PHONY : init
init:
	@exit 0

.PHONY : test
test:
	go mod download -x
	go test -v -timeout 60m

.PHONY : clean
clean:
	rm -rf ../*.tfstate*