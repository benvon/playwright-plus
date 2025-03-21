# Define all Dockerfiles found in the repository root
DOCKERFILES := $(wildcard Dockerfile.*)

# Variables
IMAGE_NAME = playwright-plus
TEST_TAG = test-security
# Extract tags from Dockerfile names: e.g., Dockerfile.foo => foo
IMAGE_TAGS := $(patsubst Dockerfile.%,%,$(notdir $(DOCKERFILES)))
CONTAINER_TEST_VERSION = latest
HADOLINT_VERSION = v2.12.0
TOOLS_DIR = .tools
PLATFORM = $(shell uname -s | tr '[:upper:]' '[:lower:]')-$(shell uname -m)

# Get Playwright versions using the script
PLAYWRIGHT_VERSIONS := $(shell bash -c 'npm view playwright versions --json | jq -r ".[]" | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$$" | sort -V | tail -n 3')

# Install all test dependencies
install-deps:
	@echo "Installing test dependencies..."
	@mkdir -p $(TOOLS_DIR)
	
	# Install container-structure-test
	@if [ ! -f $(TOOLS_DIR)/container-structure-test ]; then \
		curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64 && \
		chmod +x container-structure-test-linux-amd64 && \
		mv container-structure-test-linux-amd64 $(TOOLS_DIR)/container-structure-test; \
	fi
	
	# Install Trivy
	@if [ ! -f $(TOOLS_DIR)/trivy ]; then \
		TRIVY_VERSION=$$(curl -s "https://api.github.com/repos/aquasecurity/trivy/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/') && \
		curl -L -o $(TOOLS_DIR)/trivy.tar.gz https://github.com/aquasecurity/trivy/releases/download/v$${TRIVY_VERSION}/trivy_$${TRIVY_VERSION}_Linux-64bit.tar.gz && \
		tar -xzf $(TOOLS_DIR)/trivy.tar.gz -C $(TOOLS_DIR) trivy && \
		rm $(TOOLS_DIR)/trivy.tar.gz && \
		chmod +x $(TOOLS_DIR)/trivy; \
	fi
	
	# Install Hadolint
	@if [ ! -f $(TOOLS_DIR)/hadolint ]; then \
		curl -L -o $(TOOLS_DIR)/hadolint https://github.com/hadolint/hadolint/releases/download/$(HADOLINT_VERSION)/hadolint-Linux-x86_64 && \
		chmod +x $(TOOLS_DIR)/hadolint; \
	fi
	
	# Install Dockle
	@if [ ! -f $(TOOLS_DIR)/dockle ]; then \
		VERSION=$$(curl --silent "https://api.github.com/repos/goodwithtech/dockle/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/') && \
		curl -L -o $(TOOLS_DIR)/dockle.tar.gz https://github.com/goodwithtech/dockle/releases/download/v$${VERSION}/dockle_$${VERSION}_Linux-64bit.tar.gz && \
		tar -xzf $(TOOLS_DIR)/dockle.tar.gz -C $(TOOLS_DIR) dockle && \
		rm $(TOOLS_DIR)/dockle.tar.gz && \
		chmod +x $(TOOLS_DIR)/dockle; \
	fi

# Build Docker images for all versions
build:
	@echo "Building Docker images for Playwright versions: $(PLAYWRIGHT_VERSIONS)"
	@for version in $(PLAYWRIGHT_VERSIONS); do \
		echo "Building $(IMAGE_NAME):$$version"; \
		docker build \
			--build-arg PLAYWRIGHT_VERSION=$$version \
			-t $(IMAGE_NAME):$$version \
			-f Dockerfile .; \
	done

# Test each Docker image
test: install-deps build
	@echo "Testing Docker images for all Playwright versions..."
	@for version in $(PLAYWRIGHT_VERSIONS); do \
		full_tag="$(IMAGE_NAME):$$version"; \
		echo "Testing image $$full_tag"; \
		echo "Running security tests..."; \
		mkdir -p $(TOOLS_DIR)/.trivy-cache; \
		echo "\n=== Running Trivy scan ==="; \
		$(TOOLS_DIR)/trivy image --cache-dir $(TOOLS_DIR)/.trivy-cache --format json --output trivy-results.$$version.json --ignore-unfixed --scanners vuln --pkg-types os,library --severity CRITICAL,HIGH --skip-files '/root/.npm/_cacache/content-v2/**/*' $$full_tag; \
		echo "\n=== Running Hadolint ==="; \
		$(TOOLS_DIR)/hadolint --format json Dockerfile > hadolint-results.$$version.json || true; \
		echo "\n=== Running Dockle ==="; \
		$(TOOLS_DIR)/dockle --timeout 600s --format json --output dockle-results.$$version.json --ignore CIS-DI-0010 $$full_tag; \
		echo "\n=== Running Container Structure Tests ==="; \
		$(TOOLS_DIR)/container-structure-test test --image $$full_tag --config .container-structure-test.yaml; \
		echo "\n=== Test Summary ==="; \
		echo "Trivy vulnerabilities: $$(jq '.Results[].Vulnerabilities | length // 0' trivy-results.$$version.json | jq -s 'add // 0')"; \
		echo "Hadolint issues: $$(jq '. | length // 0' hadolint-results.$$version.json)"; \
		echo "Dockle failures: $$(jq '.Failures | length // 0' dockle-results.$$version.json)"; \
	done

# Clean up test artifacts
clean:
	@echo "Cleaning up..."
	rm -rf $(TOOLS_DIR)
	rm -f trivy-results.*.json
	rm -f hadolint-results.*.json
	rm -f dockle-results.*.json
	@for version in $(PLAYWRIGHT_VERSIONS); do \
		docker rmi $(IMAGE_NAME):$$version || true; \
	done

# Add a new target to show current versions
versions:
	@echo "Current Playwright versions to be built:"
	@for version in $(PLAYWRIGHT_VERSIONS); do \
		echo "- $$version"; \
	done

.PHONY: install-deps build test clean versions
