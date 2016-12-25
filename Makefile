BASE=$(shell pwd)
FILES=$(shell find lib t pod -type f -not -name '*~')
AUTHORDEPS=deps/author-$(shell hostname -s)
BUILDLIB=$(BASE)/build/lib
TESTLIB=$(BUILDLIB):$(BASE)/build/t/lib

build: build/Makefile.PL

build/Makefile.PL: $(FILES) authordeps
	dzil build --in build --notgz | grep -v 'Skipping: no "our'
	dzil listdeps --missing | cpanm

author: build
	cd build && export PERL5LIB=$(BUILDLIB) && \
	AUTHOR_TESTING=1 prove xt/author/ 2>&1 && \
	RELEASE_TESTING=1 prove xt/release/ 2>&1

test: build
	./deps.pl build/META.json test missing | cpanm
	cd build && export PERL5LIB=$(TESTLIB) && prove -cr t

vtest: build
	./deps.pl build/META.json test missing | cpanm
	cd build && export PERL5LIB=$(TESTLIB) && prove -crv t

.PHONY: pod
pod:
	dzil build --in build --notgz | grep -v 'Skipping: no "our'
	rm html/*; scripts/check_pod.pl; open html/Class.html

authordeps: $(AUTHORDEPS)

$(AUTHORDEPS): dist.ini weaver.ini
	dzil authordeps --missing | cpanm
	mkdir -p deps
	touch $(AUTHORDEPS)

clean:
	rm -rf build deps/*
