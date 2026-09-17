import re

with open('.claude/work-state.md', 'r') as f:
    c = f.read()

# Update Active Task
c = re.sub(
    r'- \*\*Fix Implemented:\*\* Bound `maskRect.radius` inside `MediaChip.qml` to mathematically calculate `Math.max.*?parent pill shape.',
    '- **Fix Implemented:** Re-bound `maskRect.radius` inside `MediaChip.qml` to literally equal `bgRect.radius` as directly requested by the user.',
    c, flags=re.DOTALL
)

with open('.claude/work-state.md', 'w') as f:
    f.write(c)

with open('docs/bugs_report.md', 'r') as f:
    b = f.read()

b = b.replace(
    '  6. Linked the album art mask radius to the island corner radius mathematically: `Math.max(0, bgRect.radius - bgRect.currentMargin)` for perfect concentric alignment.',
    '  6. Linked the album art mask radius directly to the island corner radius: `bgRect.radius` per user preference for literal linked values.'
)

with open('docs/bugs_report.md', 'w') as f:
    f.write(b)
