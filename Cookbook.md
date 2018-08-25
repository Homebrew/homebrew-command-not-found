# Cookbook

This document describes how I update the list, just so you know how it works if
I get hit by a truck.

1. Run `brew update`
2. Run `brew which-update --commit`. It’ll update installed formulae and fetch
   the bottles of the ones that are missing in order to get their executables
   without installing anything.
3. Push.

The process above doesn’t support non-bottled formulae; you can  run `brew
which-update --stats` to see which formulae are missing.
