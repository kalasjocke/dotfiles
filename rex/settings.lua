-- Settings from Rex's Settings window, kept here under version control. Rex
-- can't read them from a file itself, so init.lua's "Reload Config and Apply
-- My Settings" (ctrl+a, then r) reads this file and sets each one.
return {
	{ "client.setting.interface.appearance.scheme", "auto" },
	{ "client.setting.interface.animation.style", "snappy" },
	{ "client.setting.interface.panes.density", "compact" },
	{ "client.setting.interface.active_panes.active_border", false },
	{ "client.setting.interface.active_panes.fade", "content" },
	{ "client.setting.interface.active_panes.inactive_window", true },
	{ "client.setting.themes.light.palette", "merino-light" },
	{ "client.setting.terminal.typography.font", "Hack" },
	{ "client.setting.terminal.typography.size", 15 },
	{ "client.setting.terminal.advanced_fonts.smoothing", true },
	{ "client.setting.terminal.colors.contrast", true },
	{ "client.setting.terminal.cursor.shaders", false },
}
