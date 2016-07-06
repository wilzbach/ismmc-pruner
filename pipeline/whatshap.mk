WHATSHAP=$(PYTHON_FOLDER)/bin/whatshap
$(WHATSHAP): | $(PIP)
	$(PIP) install --upgrade --ignore-installed whatshap==$(WHATSHAP_VERSION)
