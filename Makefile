.PHONY: build
build: 
	@echo "Building..."
	hugo

.PHONY: copy
copy: build
	cp -R public/* docs/
	rm -rf public/
