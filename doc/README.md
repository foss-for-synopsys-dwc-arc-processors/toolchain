# How to Build Documentation

Deploy a virtual environment for Python 3:


    python3 -m venv .venv
    source .venv/bin/activate
    pip3 install -r requirements.txt

Build HTML pages:

    make html

Pages are generated in `_build/html` directory.
