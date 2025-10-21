extends Control

signal start_requested(seed: int)
signal diary_closed()

@onready var world_info: Label = $MarginContainer/VBox/WorldInfo
@onready var health_bar: TextureProgressBar = $MarginContainer/VBox/Health
@onready var inventory_label: RichTextLabel = $MarginContainer/VBox/Inventory
@onready var status_label: RichTextLabel = $MarginContainer/VBox/Status
@onready var shop_panel: Panel = $MarginContainer/VBox/ShopPanel
@onready var shop_items: RichTextLabel = $MarginContainer/VBox/ShopPanel/ShopVBox/ShopItems
@onready var toggle_diary: Button = $MarginContainer/VBox/ToggleDiary
@onready var diary_panel: Panel = $MarginContainer/VBox/DiaryPanel
@onready var diary_entries: RichTextLabel = $MarginContainer/VBox/DiaryPanel/DiaryVBox/DiaryEntries
@onready var start_panel: Panel = $StartPanel
@onready var seed_input: LineEdit = $StartPanel/StartVBox/SeedInput
@onready var start_button: Button = $StartPanel/StartVBox/StartButton

var cached_inventory: Array = []

func _ready() -> void:
    toggle_diary.pressed.connect(_on_toggle_diary)
    $MarginContainer/VBox/DiaryPanel/DiaryVBox/CloseDiary.pressed.connect(_on_toggle_diary)
    start_button.pressed.connect(_on_start_pressed)

func show_start_panel(show: bool) -> void:
    start_panel.visible = show

func _on_start_pressed() -> void:
    var text := seed_input.text.strip_edges()
    var seed := 0
    if text == "":
        seed = randi()
    else:
        seed = int(hash(text))
    start_requested.emit(seed)

func set_world_info(data: Dictionary) -> void:
    var info := "Seed %d | Motivo: %s | Tempo: %s" % [data.get("seed", 0), data.get("motivation", "?"), data.get("weather", "--")]
    if data.get("corrupted", false):
        info += " | MUNDO CORROMPIDO"
    world_info.text = info

func update_health(current: int, max_health: int) -> void:
    health_bar.max_value = max_health
    health_bar.value = clamp(current, 0, max_health)

func update_inventory(items: Array) -> void:
    cached_inventory = items
    if items.is_empty():
        inventory_label.text = "[center]Inventário vazio[/center]"
        return
    var lines := []
    for item in items:
        lines.append("• %s (%s)" % [item.get("name", "?"), item.get("rarity", "?")])
    inventory_label.text = "[left]%s[/left]" % "\n".join(lines)

func show_shop(stock: Array) -> void:
    if stock.is_empty():
        shop_panel.visible = false
        return
    shop_panel.visible = true
    var info := []
    for item in stock:
        info.append("%s [%s] - %d ecos" % [item.get("name", "?"), item.get("rarity", "?"), item.get("price", 0)])
    shop_items.text = "[left]%s[/left]" % "\n".join(info)

func toggle_diary_visibility() -> void:
    diary_panel.visible = !diary_panel.visible
    if not diary_panel.visible:
        diary_closed.emit()

func _on_toggle_diary() -> void:
    toggle_diary_visibility()

func update_diary(entries_data: Array) -> void:
    if entries_data.is_empty():
        diary_entries.text = "[i]Nenhuma memória registrada ainda.[/i]"
        return
    var blocks := []
    for entry in entries_data:
        var line := "Seed %d - Boss: %s (%s)" % [entry.get("seed", 0), entry.get("boss", "?"), entry.get("motivation", "?")]
        if entry.get("corrupted", false):
            line += " [corrompido]"
        var event_lines := []
        for event in entry.get("events", []):
            event_lines.append("    • %s" % event.get("tag", "evento"))
        if event_lines.size() > 0:
            line += "\n" + "\n".join(event_lines)
        blocks.append(line)
    diary_entries.text = "\n\n".join(blocks)

func show_run_summary(summary: String) -> void:
    $StartPanel/StartVBox/RunInfo.text = summary

func show_status(message: String) -> void:
    status_label.text = message
