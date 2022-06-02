REBAR3?=rebar3

all: build

clean:
	$(REBAR3) clean
	rm -rf _build
	rm -rf *.lock
	rm -f test/*.beam
	rm -rf priv/*.so
	rm -f c_src/valgrind_sample

distclean: clean
	git clean -fxd

build:
	$(REBAR3) compile

check: build
	$(REBAR3) eunit

check-valgrind:
	cc -I c_src/ -g -Wall -Werror c_src/hqueue.c c_src/valgrind_sample.c -o c_src/valgrind_sample
	valgrind --leak-check=yes c_src/valgrind_sample
