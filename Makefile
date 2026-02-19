.PHONY: release check-version check-branch check-status tag

# Main entrypoint
release: check-version check-branch check-status tag

check-version:
	@if [ -z "$(VERSION)" ]; then \
		echo "ERROR: VERSION is not set."; \
		echo "Usage: make release VERSION=v0.4.1"; \
		exit 1; \
	fi
	@if ! echo "$(VERSION)" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+.*$$'; then \
		echo "ERROR: VERSION must follow Semantic Versioning and start with 'v' (e.g., v1.0.0)."; \
		exit 1; \
	fi

check-branch:
	@BRANCH=$$(git rev-parse --abbrev-ref HEAD); \
	if [ "$$BRANCH" != "main" ]; then \
		echo "ERROR: Releases must be tagged from the 'main' branch."; \
		echo "Current branch: $$BRANCH"; \
		exit 1; \
	fi

check-status:
	@IS_CLEAN=$$(git status --porcelain); \
	if [ -n "$$IS_CLEAN" ]; then \
		echo "ERROR: Working directory is not clean."; \
		echo "Please commit or stash changes before cutting a release."; \
		exit 1; \
	fi

tag:
	@echo "Syncing latest changes from remote main..."
	git pull origin main --rebase
	@echo "Creating annotated tag $(VERSION)..."
	git tag -a $(VERSION) -m "Release $(VERSION)"
	@echo "Pushing tag $(VERSION) to origin..."
	git push origin $(VERSION)
	@echo "Success. GitHub Actions will now build the release for $(VERSION)."
