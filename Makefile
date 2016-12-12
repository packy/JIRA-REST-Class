BASE=$(shell pwd)
clean:
	rm -rf .build 

authordeps:
	dzil authordeps --missing | cpanm

build: authordeps
	dzil build --in .build --notgz

author: build
	cd .build && PERL5LIB=$(BASE)/.build/lib \
	AUTHOR_TESTING=1 prove xt/author/ 2>&1 && \
	RELEASE_TESTING=1 prove xt/release/ 2>&1 | less -FRX

test: build
	cd .build && PERL5LIB=$(BASE)/.build/lib prove t
