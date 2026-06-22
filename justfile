set dotenv-load := true

# Version used when building the packages locally / for testing
export VERSION := env_var_or_default("VERSION", "1.0.0")

# Install python virtual environment
venv:
  [ -d .venv ] || python3 -m venv .venv
  ./.venv/bin/pip3 install -r tests/requirements.txt -r requirements.txt -r requirements.dev.txt

# Format python code
format:
    .venv/bin/python3 -m black .

# Run python linter
lint:
    .venv/bin/python3 -m pylint operations
    .venv/bin/python3 -m pylint tedge_modbus

# Build linux packages
build:
    mkdir -p dist/
    nfpm package --packager deb --target dist/
    nfpm package --packager rpm --target dist/

# Run tests
test *args='':
  ./.venv/bin/python3 -m robot.run --outputdir output {{args}} tests
