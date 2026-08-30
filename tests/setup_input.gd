extends SceneTree
# One-time project setup: sets the main scene and the `roll_dice` input map,
# then persists via ProjectSettings.save() so project.godot gets the canonical
# Godot [input] serialization. Safe to delete after use.

func _init():
	InputMap.add_action("roll_dice")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	InputMap.action_add_event("roll_dice", key)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("roll_dice", mouse)
	ProjectSettings.set_setting("application/run/main_scene", "res://Main.tscn")
	for action in InputMap.get_actions():
		if InputMap.action_get_events(action).size() > 0:
			ProjectSettings.set_setting("input/%s" % action, InputMap.action_get_events(action))
			ProjectSettings.set_setting("input/%s/deadzone" % action, InputMap.action_get_deadzone(action))
	ProjectSettings.save()
	quit()