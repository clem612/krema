import re

with open('docs/bugs_report.md', 'r') as f:
    c = f.read()

# Append width logic to the last bug report
c = c.replace(
    '4. Auto-hide the artist name sub-label when in `isCompact` mode to prevent vertical crowding.',
    '4. Auto-hide the artist name sub-label when in `isCompact` mode to prevent vertical crowding.\n  5. Migrated the hardcoded `180px` width to a dynamic `optimalWidth` that evaluates the layout\'s `implicitWidth`, allowing the chip to horizontally expand to fit long track names (up to 450px).'
)
c = c.replace(
    '* **Outcome**: Success. The Media Chip is now fully responsive, scaling gracefully from 24px up to 128px panel sizes.',
    '* **Outcome**: Success. The Media Chip is now fully responsive, scaling gracefully in both height and width to perfectly wrap the text without cropping.'
)

with open('docs/bugs_report.md', 'w') as f:
    f.write(c)
