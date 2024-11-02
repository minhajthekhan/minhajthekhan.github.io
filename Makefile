.PHONY: build
build:
	@echo "Building..."
	hugo

.PHONY: copy
copy:
	cp -R public/* docs/
	rm -rf public/
