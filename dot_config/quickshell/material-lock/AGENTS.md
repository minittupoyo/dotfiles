# Independent Material lock

Read ../material-shell/AGENTS.md, DESIGN_SYSTEM.md and Theme.qml before changes. Reuse shared tokens and components.
Keep the locker separate from the bar. Unlock only after PAM success; never add an IPC unlock.
Never execute real lock/unlock/suspend/logout/power operations during automated verification. Use MATERIAL_LOCK_PREVIEW=1 for visual tests.
