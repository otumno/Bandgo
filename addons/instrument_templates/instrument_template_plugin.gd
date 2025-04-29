@tool
extends EditorPlugin

const PLUGIN_NAME = "Instrument Templates"
var editor_instance = null

func _enter_tree():
	# Проверяем, что мы в редакторе
	if Engine.is_editor_hint():
		editor_instance = preload("res://addons/instrument_templates/InstrumentTemplateEditor.tscn").instantiate()
		add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UL, editor_instance)
		print(PLUGIN_NAME + " plugin loaded")

func _exit_tree():
	if editor_instance:
		remove_control_from_docks(editor_instance)
		editor_instance.queue_free()
		print(PLUGIN_NAME + " plugin unloaded")
