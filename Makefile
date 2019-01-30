REBAR?=rebar

all: build


clean:
	$(REBAR) clean
	rm -rf .eunit
	rm -f test/*.beam
	rm -rf priv/*.so
	rm -f c_src/valgrind_sample


distclean: clean
	git clean -fxd


build:
	$(REBAR) compile


check: build
	$(REBAR) eunit

check-valgrind:
	cc -I c_src/ -g -Wall -Werror c_src/hqueue.c c_src/valgrind_sample.c -o c_src/valgrind_sample
	valgrind --leak-check=yes c_src/valgrind_sample

