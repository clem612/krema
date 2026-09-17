import re

with open('.claude/work-state.md', 'r') as f:
    c = f.read()

# Update Active Task
c = re.sub(
    r'- \*\*Dynamic Width Scaling:\*\*.*?\n\n## Next Steps',
    '- **Thumbnail Corner Radius Linking:** The user requested the album art thumbnail corner radius to match the Glass Pill Island corner radius.\n- **Fix Implemented:** Bound `maskRect.radius` inside `MediaChip.qml` to mathematically calculate `Math.max(0, bgRect.radius - bgRect.currentMargin)` so the inner radius stays perfectly concentric with the parent pill shape.\n\n## Next Steps',
    c, flags=re.DOTALL
)

with open('.claude/work-state.md', 'w') as f:
    f.write(c)

with open('docs/bugs_report.md', 'r') as f:
    b = f.read()

b = b.replace(
    '  5. Migrated the hardcoded `180px` width to a dynamic `optimalWidth` that evaluates the layout\'s `implicitWidth`, allowing the chip to horizontally expand to fit long track names (up to 450px).',
    '  5. Migrated the hardcoded `180px` width to a dynamic `optimalWidth` that evaluates the layout\'s `implicitWidth`, allowing the chip to horizontally expand to fit long track names (up to 450px).\n  6. Linked the album art mask radius to the island corner radius mathematically: `Math.max(0, bgRect.radius - bgRect.currentMargin)` for perfect concentric alignment.'
)

with open('docs/bugs_report.md', 'w') as f:
    f.write(b)
