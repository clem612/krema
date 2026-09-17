import re

with open('.claude/work-state.md', 'r') as f:
    c = f.read()

# Update Active Task
c = re.sub(
    r'- \*\*Thumbnail Corner Radius Linking:.*?\n\n## Next Steps',
    '- **Media Chip Transport Controls:** The user noted the Media Chip lacked next/previous buttons.\n- **Fix Implemented:** Added `media-skip-backward` and `media-skip-forward` buttons flanking the play/pause button, wired to `Mpris.previous()` and `Mpris.next()`. The buttons scale to 80% of the play/pause button height to maintain visual hierarchy.\n\n## Next Steps',
    c, flags=re.DOTALL
)

with open('.claude/work-state.md', 'w') as f:
    f.write(c)

with open('docs/bugs_report.md', 'r') as f:
    b = f.read()

b = b.replace(
    '  6. Linked the album art mask radius directly to the island corner radius: `bgRect.radius` per user preference for literal linked values.',
    '  6. Linked the album art mask radius directly to the island corner radius: `bgRect.radius` per user preference for literal linked values.\n  7. Injected Previous and Next transport controls alongside the Play/Pause button.'
)

with open('docs/bugs_report.md', 'w') as f:
    f.write(b)
