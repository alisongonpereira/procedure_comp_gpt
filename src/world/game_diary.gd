extends Node
class_name GameDiary

const DIARY_PATH := "user://diary.json"

var entries: Array = []

func _ready() -> void:
    load_entries()

func load_entries() -> void:
    entries.clear()
    if not FileAccess.file_exists(DIARY_PATH):
        return
    var file := FileAccess.open(DIARY_PATH, FileAccess.READ)
    if file:
        var text := file.get_as_text()
        file.close()
        if text.length() > 0:
            entries = JSON.parse_string(text) if text != "" else []
            if typeof(entries) != TYPE_ARRAY:
                entries = []

func add_entry(run_data: Dictionary) -> void:
    var summary := {
        "seed": run_data.get("seed", 0),
        "boss": run_data.get("boss", {}).get("name", "?"),
        "motivation": run_data.get("motivation", ""),
        "corrupted": run_data.get("corrupted", false),
        "events": run_data.get("events", [])
    }
    entries.push_front(summary)
    entries = entries.slice(0, 10)
    _save()

func _save() -> void:
    var file := FileAccess.open(DIARY_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(entries))
        file.close()
