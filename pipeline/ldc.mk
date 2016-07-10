LDC_DIR=build/ldc2-$(LDC_VERSION)-linux-$(PLATFORM)
LDC_BIN_PATH=$(LDC_DIR)/bin
LDC_LIB_PATH=$(LDC_LIB_PATH)/bin
LDC=$(LDC_BIN_PATH)/ldc2

build/ldc2-$(LDC_VERSION)-linux-$(PLATFORM): | build
	curl -fSL --retry 3 "https://github.com/ldc-developers/ldc/releases/download/v$(LDC_VERSION)/ldc2-$(LDC_VERSION)-linux-$(PLATFORM).tar.xz" \
	| tar -Jxf - -C $|

$(LDC): $(LDC_DIR)
