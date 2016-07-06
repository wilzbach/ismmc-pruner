PBSIM=progs/pbsim

build/pbsim-$(PBSIM_VERSION): | build
	curl -L https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/pbsim/pbsim-$(PBSIM_VERSION).tar.gz | tar -zxf - -C $|

progs/pbsim: build/pbsim-$(PBSIM_VERSION)
	cd $< && ./configure
	cd $< && make -j $(NPROCS)
	cp ./pbsim-$(PBSIM_VERSION)/src/pbsim $@
