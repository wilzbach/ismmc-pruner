PYTHON_FOLDER=progs/python
PYTHON=$(PYTHON_FOLDER)/bin/python3
PIP=$(PYTHON_FOLDER)/bin/pip3

# PYTHON_MAJOR_MINOR
__python_major_minor= $(subst ., ,$(PYTHON_VERSION))
PYTHON_MAJOR_MINOR=$(word 1, $(__python_major_minor)).$(word 2, $(__python_major_minor))

PYTHON_SITE_PACKAGES=$(PYTHON_FOLDER)/lib/python$(PYTHON_MAJOR_MINOR)/site-packages

build/python-$(PYTHON_VERSION): | build
	curl -fSL --retry 3  https://www.python.org/ftp/python/$(PYTHON_VERSION)/Python-$(PYTHON_VERSION).tar.xz | \
		tar -Jxf - -C $|
	mv $|/Python-$(PYTHON_VERSION) $|/python-$(PYTHON_VERSION)

build/python-$(PYTHON_VERSION)/local/bin/python3: build/python-$(PYTHON_VERSION)
	cd $< && ./configure --prefix=$(shell pwd)/$</local
	mkdir -p $</local
	cd $< && make -j $(NPROCS) && make install

build/python-$(PYTHON_VERSION)/local/bin/pyvenv: build/python-$(PYTHON_VERSION)/local/bin/python3

# setup clean working directory
$(PYTHON_FOLDER): build/python-$(PYTHON_VERSION)/local/bin/pyvenv
	$< $@

$(PYTHON): $(PYTHON_FOLDER)
$(PIP): $(PYTHON_FOLDER)

BIOPYTHON=$(PYTHON_SITE_PACKAGES)/Bio

$(BIOPYTHON): | $(PIP)
	@echo $(BIOPYTHON)
	$(PIP) install --ignore-installed biopython==$(BIOPYTHON_VERSION)

NUMPY=$(PYTHON_SITE_PACKAGES)/numpy

$(NUMPY): | $(PIP)
	$(PIP) install --ignore-installed numpy==$(NUMPY_VERSION)

MATPLOTLIB=$(PYTHON_SITE_PACKAGES)/matplotlib

$(MATPLOTLIB): | $(PIP)
	$(PIP) install --ignore-installed matplotlib==$(MATPLOTLIB_VERSION)

SCIPY=$(PYTHON_SITE_PACKAGES)/scipy

$(SCIPY): | $(PIP)
	$(PIP) install --ignore-installed scipy==$(SCIPY_VERSION)
