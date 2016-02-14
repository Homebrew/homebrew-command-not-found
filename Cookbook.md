# Cookbook

This document describes how I update the list, just so you know how it works if
I get hit by a truck. The near-future goal is to automate this process.

1. Run `brew update` and check if there are new formulae
2. If so, install them. You can also install updated formulae, they might have
   changed their binaries.
3. In the root directory of this tap, run `brew which-update --commit executables.txt`
4. Push.

You can also run `brew which-update --stats executables.txt` to see which
formulae are missing.
