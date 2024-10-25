from pathlib import Path

# Common imports for ipython
lines = """
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import scipy.stats as stats
import beautifulsoup4 as bs4
import nltk
import toml
import pickle
import os
import sys
import re
import time
import datetime
import random
import json
import requests
from pathlib import Path
from collections import Counter
from hypy_utils import *
from hypy_utils.tqdm_utils import *
"""

# Generate ipython_init.py
f = "print()"
for l in [l for l in lines.splitlines() if l]:
    f += f"""
try:
    print("\\033[2K\\r\\033[0;33m+ {l}", end="")
    {l}
except ImportError:
    print("\\033[2K\\r\\033[0;31m- {l} failed")
    pass
"""

f += """
print("\\033[2K\\r\\033[1;92m🐱 Common imports for ipython are ready meow~")
"""

(Path(__file__).parent / "ipython_init.py").write_text(f, "utf-8")