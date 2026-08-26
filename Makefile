.PHONY: test

test:
	sh -n scripts/* tests/*.sh
	./tests/test-manifest.sh
	./tests/test-fetch.sh
	./tests/test-artifact-fetch.sh
	./tests/test-install.sh
	./tests/test-update.sh
	./scripts/vibe-check --manifest manifests/oneplus6t-r0.psv
