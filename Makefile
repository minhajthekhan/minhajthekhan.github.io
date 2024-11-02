.PHONY: build
build:
	@echo "Building..."
	hugo
	cp -R public/* docs/
	rm -rf public/