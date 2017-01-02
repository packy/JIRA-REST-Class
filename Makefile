BASE=$(shell pwd)
FILES=$(shell find lib t pod -type f -not -name '*~')
AUTHORDEPS=deps/author-$(shell hostname -s)
BUILDLIB=$(BASE)/build/lib
TESTLIB=$(BUILDLIB):$(BASE)/build/t/lib

build: deps/last_build

deps/last_build: $(FILES) $(AUTHORDEPS)
	dzil build --in build --notgz
	if ! diff build/META.json deps/META.json 2>/dev/null; then \
            dzil listdeps --missing | cpanm; \
            cp build/META.json deps/META.json; \
        fi
	touch deps/last_build

author: build
	cd build && export PERL5LIB=$(BUILDLIB) && \
	AUTHOR_TESTING=1 prove xt/author/ 2>&1 && \
	RELEASE_TESTING=1 prove xt/release/ 2>&1

test: build
	scripts/deps.pl build/META.json test missing | cpanm
	cd build && export PERL5LIB=$(TESTLIB) && prove -cr t

vtest: build
	scripts/deps.pl build/META.json test missing | cpanm
	cd build && export PERL5LIB=$(TESTLIB) && prove -crv t

.PHONY: pod
pod: build
	rm html/*; scripts/check_pod.pl; open html/Class.html

$(AUTHORDEPS): dist.ini weaver.ini
	dzil authordeps --missing | cpanm
	mkdir -p deps
	touch $(AUTHORDEPS)

clean:
	rm -rf build deps/*
