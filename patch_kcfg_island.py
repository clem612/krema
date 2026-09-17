import re

with open('src/config/krema.kcfg', 'r') as f:
    c = f.read()

island_config = """
    <entry name="islandCornerRadius" type="Double">
      <label>Corner radius of the glass pill island (0 for fully rounded)</label>
      <default>0</default>
      <min>0</min>
      <max>32</max>
    </entry>

    <entry name="islandMargin" type="Int">
      <label>Horizontal margin around items inside the island</label>
      <default>8</default>
      <min>0</min>
      <max>32</max>
    </entry>
"""

c = c.replace(
    '</group>\n</kcfg>',
    island_config + '\n  </group>\n</kcfg>'
)

with open('src/config/krema.kcfg', 'w') as f:
    f.write(c)
