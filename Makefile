BASE=$(shell pwd)
FILES=$(shell find lib t pod -type f -not -name '*~')
AUTHORDEPS=deps/author-$(shell hostname -s)
BUILDLIB=$(BASE)/build/lib
TESTLIB=$(BUILDLIB):$(BASE)/build/t/lib

build: build/dist.ini

build/dist.ini: $(FILES) authordeps
	dzil build --in build --notgz | grep -v 'Skipping: no "our'
	dzil listdeps --missing | cpanm

author: build/dist.ini
	cd build && export PERL5LIB=$(BUILDLIB) && \
	AUTHOR_TESTING=1 prove xt/author/ 2>&1 && \
	RELEASE_TESTING=1 prove xt/release/ 2>&1

test: build/dist.ini
	./deps.pl build/META.json test missing | cpanm
	cd build && export PERL5LIB=$(TESTLIB) && prove -cr t

vtest: build/dist.ini
	./deps.pl build/META.json test missing | cpanm
	cd build && export PERL5LIB=$(TESTLIB) && prove -crv t

authordeps: $(AUTHORDEPS)

$(AUTHORDEPS): dist.ini weaver.ini
	dzil authordeps --missing | cpanm
	mkdir -p deps
	touch $(AUTHORDEPS)

clean:
	rm -rf build deps/*
