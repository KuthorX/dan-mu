extends RefCounted

## Language selection helpers. Strings live in res://i18n/translations.csv
## (registered under [internationalization] in project.godot).

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "settings"
const SETTINGS_KEY := "language"
const LOCALE_ZH := "zh"
const LOCALE_EN := "en"

static func apply_saved_or_default() -> void:
	var locale := _load_saved_locale()
	if locale == "":
		locale = LOCALE_ZH if OS.get_locale_language() == LOCALE_ZH else LOCALE_EN
	TranslationServer.set_locale(locale)

static func current_locale() -> String:
	return LOCALE_ZH if TranslationServer.get_locale().begins_with(LOCALE_ZH) else LOCALE_EN

static func toggle_locale() -> void:
	var next := LOCALE_EN if current_locale() == LOCALE_ZH else LOCALE_ZH
	TranslationServer.set_locale(next)
	_save_locale(next)

## Finds the entry (Dictionary with "key" and "label" translation key) matching a stored value.
## Accepts the entry key, its translation key, or a legacy Chinese label from older saves.
static func find_entry(entries: Array, value: String) -> Dictionary:
	var zh_catalog: Translation = TranslationServer.get_translation_object(LOCALE_ZH)
	for entry_variant in entries:
		var entry: Dictionary = entry_variant
		var label_key := str(entry.get("label", ""))
		if value == str(entry.get("key", "")) or value == label_key:
			return entry
		if zh_catalog and value == str(zh_catalog.get_message(label_key)):
			return entry
	return {}

static func _load_saved_locale() -> String:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return ""
	var value := str(config.get_value(SETTINGS_SECTION, SETTINGS_KEY, ""))
	if value == LOCALE_ZH or value == LOCALE_EN:
		return value
	return ""

static func _save_locale(locale: String) -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION, SETTINGS_KEY, locale)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Failed to save language setting (error %d)." % error)
