.PHONY: build_runner launcher_icons

build_runner:
	dart run build_runner build --delete-conflicting-outputs

launcher_icons:
	dart run flutter_launcher_icons
