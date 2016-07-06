WGSIM=progs/wgsim

build/wgsim-$(WGSIM_VERSION): | build
	curl -L https://github.com/lh3/wgsim/archive/$(WGSIM_VERSION).tar.gz | tar -zxf - -C $|

progs/wgsim: build/wgsim-$(WGSIM_VERSION)
	gcc -g -O2 -Wall -o $@ $</wgsim.c -lz -lm
