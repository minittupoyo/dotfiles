# Material Shell implementation

Read DESIGN_SYSTEM.md and Theme.qml before changing UI. DESIGN_SYSTEM.md is the visual and interaction specification; Theme.qml is the runtime token source.
Preserve the user's choices: Material 3 Expressive with desktop density, full-width borderless bar, Inter with Noto Sans JP fallback, Material Symbols Outlined, no emoji.
Use shared components and semantic/component tokens. If a new design value is needed, document it in DESIGN_SYSTEM.md and Theme.qml before using it. Do not expose OS-default styled controls.
Keep staged migration progress and remaining Noctalia dependencies in MIGRATION.md. Validate running QML, keyboard interaction and both monitors for panel changes. Do not execute shutdown/logout/suspend or lock the user's session as part of automated verification.
