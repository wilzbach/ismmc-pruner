# we need cmake3
ifeq "$$(cmake -version | head -n 1 | cut -f 3 -d ' ' | cut -f 1 -d .)" "3"
CMAKE=cmake
else
CMAKE=build/cmake-$(CMAKE_VERSION)-Linux-$(PLATFORM)/bin/cmake
endif

# transform cmake version in space-delimited
_cmake_version_sp= $(subst ., ,$(CMAKE_VERSION))

# select major and minor version for cMake
build/cmake-$(CMAKE_VERSION)-Linux-$(PLATFORM): | build
	curl -L http://www.cmake.org/files/v$(word 1, $(_cmake_version_sp)).$(word 2, $(_cmake_version_sp))/cmake-$(CMAKE_VERSION)-Linux-$(PLATFORM).tar.gz | gunzip - | tar -xf - -C $|

build/cmake-$(CMAKE_VERSION)-Linux-$(PLATFORM)/bin/cmake: | build/cmake-$(CMAKE_VERSION)-Linux-$(PLATFORM)
