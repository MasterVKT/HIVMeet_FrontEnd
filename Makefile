# Makefile for HIVMeet

.PHONY: help
help:
	@echo "Available commands:"
	@echo "  make setup          - Initial project setup"
	@echo "  make clean          - Clean build files"
	@echo "  make get            - Get dependencies"
	@echo "  make generate       - Generate code (build_runner)"
	@echo "  make run-dev        - Run app in development"
	@echo "  make run-staging    - Run app in staging"
	@echo "  make run-prod       - Run app in production"
	@echo "  make build-dev      - Build development APK"
	@echo "  make build-staging  - Build staging APK"
	@echo "  make build-prod     - Build production bundle"
	@echo "  make test           - Run all tests"
	@echo "  make test-unit      - Run unit tests"
	@echo "  make test-widget    - Run widget tests"
	@echo "  make analyze        - Run flutter analyze"
	@echo "  make format         - Format code"

.PHONY: setup
setup:
	flutter pub get
	flutter pub run build_runner build --delete-conflicting-outputs

.PHONY: clean
clean:
	flutter clean
	rm -rf .dart_tool
	rm -rf .packages
	rm -rf pubspec.lock

.PHONY: get
get:
	flutter pub get

.PHONY: generate
generate:
	flutter pub run build_runner build --delete-conflicting-outputs

.PHONY: watch
watch:
	flutter pub run build_runner watch --delete-conflicting-outputs

.PHONY: run-dev
run-dev:
	flutter run --flavor dev --dart-define=ENV=development

.PHONY: run-staging
run-staging:
	flutter run --flavor staging --dart-define=ENV=staging

.PHONY: run-prod
run-prod:
	flutter run --flavor prod --dart-define=ENV=production

.PHONY: build-dev
build-dev:
	./scripts/build_dev.sh

.PHONY: build-staging
build-staging:
	./scripts/build_staging.sh

.PHONY: build-prod
build-prod:
	./scripts/build_prod.sh

.PHONY: test
test:
	flutter test

.PHONY: test-unit
test-unit:
	flutter test test/unit/

.PHONY: test-widget
test-widget:
	flutter test test/widget/

.PHONY: test-integration
test-integration:
	flutter test integration_test/

.PHONY: analyze
analyze:
	flutter analyze

.PHONY: format
format:
	dart format . --fix

.PHONY: icons
icons:
	flutter pub run flutter_launcher_icons

.PHONY: splash
splash:
	flutter pub run flutter_native_splash:create