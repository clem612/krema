import re

with open('src/config/krema.kcfg', 'r') as f:
    c = f.read()

new_setting = """    <entry name="IslandMargin" type="Int">
      <label>Symmetrical margin between the Glass Pill and the dock panel edges</label>
      <default>8</default>
      <min>0</min>
      <max>20</max>
    </entry>

    <entry name="IslandCornerRadius" type="Int">
      <label>Corner radius of island backgrounds (0 for fully rounded pill)</label>
      <default>0</default>
      <min>0</min>
      <max>32</max>
    </entry>"""

c = c.replace("""    <entry name="IslandMargin" type="Int">
      <label>Symmetrical margin between the Glass Pill and the dock panel edges</label>
      <default>8</default>
      <min>0</min>
      <max>20</max>
    </entry>""", new_setting)

with open('src/config/krema.kcfg', 'w') as f:
    f.write(c)
