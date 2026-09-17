import os
import re

cl_path = "CHANGELOG.md"
with open(cl_path, "r") as f:
    cl = f.read()

# Add to the unreleased section or at the top
new_entry = "- **Fixed:** Media Chip will now prioritize the actively playing media player instead of binding to idle players (like background Chromium instances), fixing the \"No Media\" bug.\n"
if "## [Unreleased]" in cl:
    cl = cl.replace("## [Unreleased]", "## [Unreleased]\n" + new_entry)
else:
    cl = "## [Unreleased]\n" + new_entry + cl

with open(cl_path, "w") as f:
    f.write(cl)
