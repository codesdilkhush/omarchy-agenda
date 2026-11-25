#!/usr/bin/env python3
"""Entry point. Run as `python3 -I -B agenda_backend.py serve`.

-I keeps the user's environment and the current directory out of the import
path, so only this plugin's own `agenda` package is added back below.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from agenda import server  # noqa: E402

if __name__ == "__main__":
    sys.exit(server.main(sys.argv))
