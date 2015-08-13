# Workflow

This document describes how I update the list, just so you know how it works if
I get hit by a truck. The near-future goal is to automate this process.

1. Run `brew update` and check if there are new formulae
2. If so, install them. You can also install updated formulae, they might have
   changed their binaries.
3. In the root directory of this tap, run `brew which-update executables.txt`
4. Run `git diff` and check the changes in `executables.txt`. It should
   normally show one new line per formula. It could also show some changes on
   existing lines for formulae you have upgraded since the last update. Be sure
   to have the latest formulae when updating them in the list.
5. Commit and push
