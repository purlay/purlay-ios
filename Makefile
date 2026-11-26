# The stable entry point. scripts/verify holds the lanes; this file only names the sets of them people and pipelines ask for.
.PHONY: setup verify verify-security verify-all

# The tools the lanes need, at the versions the repository pins.
setup:
	scripts/install-xcodegen
	scripts/install-gitleaks

# What a pull request must pass: rules, format and package tests, and the app built for iOS. No simulator, no network beyond the rules.
verify:
	scripts/verify rules
	scripts/verify packages
	scripts/verify build

# The history scanned for secrets (needs the full clone).
verify-security:
	scripts/verify security

# Every lane, the simulator's included.
verify-all:
	scripts/verify
