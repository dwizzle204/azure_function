PYTHON ?= python
APP_DIR ?= src/function_app
DIST_DIR ?= dist
PACKAGE ?= $(DIST_DIR)/function_app.zip

.PHONY: install-dev lint test package clean

install-dev:
	$(PYTHON) -m pip install --upgrade pip
	@if [ -f $(APP_DIR)/requirements.txt ]; then $(PYTHON) -m pip install -r $(APP_DIR)/requirements.txt; fi
	$(PYTHON) -m pip install flake8 pytest

lint:
	flake8 $(APP_DIR) --count --select=E9,F63,F7,F82 --show-source --statistics
	flake8 $(APP_DIR) --count --max-complexity=10 --max-line-length=127 --statistics

test:
	pytest -q tests

package:
	mkdir -p $(DIST_DIR)
	cd $(APP_DIR) && zip -r ../../$(PACKAGE) .
	test -s $(PACKAGE)

clean:
	rm -rf $(DIST_DIR) .pytest_cache
