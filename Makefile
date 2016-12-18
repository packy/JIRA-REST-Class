BASE=$(shell pwd)
FILES=$(shell find lib t pod -type f -not -name '*~')
AUTHORDEPS=authordeps/$(shell hostname)

build: build/dist.ini

build/dist.ini: $(FILES) authordeps
	dzil build --in build --notgz

author: build/dist.ini
	cd build && PERL5LIB=$(BASE)/.build/lib \
	AUTHOR_TESTING=1 prove xt/author/ 2>&1 && \
	RELEASE_TESTING=1 prove xt/release/ 2>&1 | less -FRX

test: build/dist.ini
	cd build && PERL5LIB=$(BASE)/.build/lib prove t

authordeps: $(AUTHORDEPS)

$(AUTHORDEPS): dist.ini weaver.ini
	dzil authordeps --missing | cpanm
	mkdir -p authordeps
	touch $(AUTHORDEPS)

clean:
	rm -rf build authordeps
