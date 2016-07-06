# setup latest DCC if none is defined
ifeq ($(wildcard $(DCC)),)
	DCC=build/dmd2/linux/bin64/dmd
endif

build/dmd2: | build
	curl -fSL --retry 3 "http://downloads.dlang.org/releases/2.x/$(DMD_VERSION)/dmd.$(DMD_VERSION).linux.tar.xz" | tar -Jxf - -C $|
build/dmd2/linux/bin64/dmd: build/dmd2
