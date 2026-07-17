# DebugConfig
extends Node

const SHOW_PATROL_RADIUS = true

func can_show_patrol_radius():
	return OS.is_debug_build() and SHOW_PATROL_RADIUS
