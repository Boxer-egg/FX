APP_NAME = ParticleFX
VERSION ?= 0.1
BUNDLE_NAME = $(APP_NAME).app
BUILD_DIR = .build/release
APP_PATH = $(BUNDLE_NAME)
MACOS_DIR = $(APP_PATH)/Contents/MacOS
RESOURCES_DIR = $(APP_PATH)/Contents/Resources

all: build bundle

build:
	swift build -c release

bundle: build
	@echo "Creating app bundle..."
	mkdir -p $(MACOS_DIR)
	mkdir -p $(RESOURCES_DIR)
	cp $(BUILD_DIR)/$(APP_NAME) $(MACOS_DIR)/
	
	@echo "Copying resources..."
	# Find lproj directories inside the build products and copy them to Resources
	# Use -mindepth 1 to avoid copying the parent directory itself
	find .build -name "*.lproj" -type d -exec cp -R {} $(RESOURCES_DIR)/ \;
	
	@echo "Creating Info.plist..."
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > $(APP_PATH)/Contents/Info.plist
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $(APP_PATH)/Contents/Info.plist
	@echo '<plist version="1.0">' >> $(APP_PATH)/Contents/Info.plist
	@echo '<dict>' >> $(APP_PATH)/Contents/Info.plist
	@echo '    <key>CFBundleExecutable</key><string>$(APP_NAME)</string>' >> $(APP_PATH)/Contents/Info.plist
	@echo '    <key>CFBundleIdentifier</key><string>com.user.ParticleFX</string>' >> $(APP_PATH)/Contents/Info.plist
	@echo '    <key>CFBundleName</key><string>$(APP_NAME)</string>' >> $(APP_PATH)/Contents/Info.plist
	@echo '    <key>CFBundlePackageType</key><string>APPL</string>' >> $(APP_PATH)/Contents/Info.plist
	@echo '    <key>CFBundleShortVersionString</key><string>$(VERSION)</string>' >> $(APP_PATH)/Contents/Info.plist
	@echo '    <key>LSMinimumSystemVersion</key><string>13.0</string>' >> $(APP_PATH)/Contents/Info.plist
	@echo '    <key>LSUIElement</key><true/>' >> $(APP_PATH)/Contents/Info.plist
	@echo '    <key>NSHighResolutionCapable</key><true/>' >> $(APP_PATH)/Contents/Info.plist
	@echo '</dict>' >> $(APP_PATH)/Contents/Info.plist
	@echo '</plist>' >> $(APP_PATH)/Contents/Info.plist

run: bundle
	open $(BUNDLE_NAME)

clean:
	rm -rf .build $(BUNDLE_NAME)

.PHONY: all build bundle clean
