# Product Quality Lessons Learned

This file contains the "burned-in" anti-patterns to prevent recurring mistakes.

## 2026-05-19: QML Binding Race Conditions
- **Anti-Pattern:** Assuming that global singletons (DockSettings, etc.) and model data are available synchronously during the `onCompleted` phase or initial property binding of instantiated components (AppIcon).
- **Observation:** Persistent `Unable to assign [undefined] to bool` warnings in logs during startup.
- **Root Cause:** AppIcon properties bind to model/settings values before those values are populated by the backend, leading to temporary `undefined` states.
- **Prevention Rule:** In non-critical visual components, expect and tolerate initial binding warnings if the property eventually stabilizes. Do not over-engineer complex null-guarding logic (e.g., unnecessary property resets) unless the UI exhibits flickering or functional failure.

