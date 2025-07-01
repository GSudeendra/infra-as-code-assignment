#!/bin/bash
# Run all Python tests using pytest and show output

set -e

# Create virtual environment if it doesn't exist
if [ ! -d .venv ]; then
    python3 -m venv .venv
fi

# Activate the virtual environment
source .venv/bin/activate

# Install dependencies if needed
if [ -f tests/requirements.txt ]; then
    pip install -r tests/requirements.txt
fi

# Add project root to PYTHONPATH
export PYTHONPATH=$PYTHONPATH:$(pwd)

# Run pytest in the tests directory
pytest tests/
