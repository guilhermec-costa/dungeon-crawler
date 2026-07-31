extends Node

signal locale_changed

const SETTINGS_PATH := "user://settings.cfg"
const PORTUGUESE_LOCALE := "pt_BR"
const ENGLISH_LOCALE := "en"


func _ready() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) == OK:
		set_locale(settings.get_value("localization", "locale", _get_system_locale()))
	else:
		set_locale(_get_system_locale())


func toggle_locale() -> void:
	set_locale(ENGLISH_LOCALE if TranslationServer.get_locale().begins_with("pt") else PORTUGUESE_LOCALE)


func set_locale(locale: String) -> void:
	var normalized_locale := PORTUGUESE_LOCALE if locale.begins_with("pt") else ENGLISH_LOCALE
	if TranslationServer.get_locale() == normalized_locale:
		return
	TranslationServer.set_locale(normalized_locale)
	var settings := ConfigFile.new()
	settings.set_value("localization", "locale", normalized_locale)
	settings.save(SETTINGS_PATH)
	locale_changed.emit()


func get_language_name() -> String:
	return "PORTUGUÊS" if TranslationServer.get_locale().begins_with("pt") else "ENGLISH"


func _get_system_locale() -> String:
	return PORTUGUESE_LOCALE if OS.get_locale_language() == "pt" else ENGLISH_LOCALE
