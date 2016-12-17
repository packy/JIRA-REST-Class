BASE=$(shell pwd)
FILES=$(shell find lib t pod -type f -not -name '*~')

build/dist.ini: $(FILES) authordeps
	dzil build --in build --notgz

author: build
	cd build && PERL5LIB=$(BASE)/.build/lib \
	AUTHOR_TESTING=1 prove xt/author/ 2>&1 && \
	RELEASE_TESTING=1 prove xt/release/ 2>&1 | less -FRX

test: build
	cd build && PERL5LIB=$(BASE)/.build/lib prove t

authordeps: dist.ini weaver.ini
	dzil authordeps --missing | cpanm
	touch authordeps

clean:
	rm -rf build authordeps
