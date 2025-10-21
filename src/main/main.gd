extends Node2D

const TILE_SIZE := 32
const Player = preload("res://src/entities/player.gd")
const Enemy = preload("res://src/entities/enemy.gd")
const NPC = preload("res://src/entities/npc.gd")
const TILE_DEFS := {
    "grass": {"color": Color(0.25, 0.45, 0.28), "accent": Color(0.18, 0.3, 0.18)},
    "forest": {"color": Color(0.1, 0.25, 0.1), "accent": Color(0.05, 0.15, 0.07)},
    "water": {"color": Color(0.1, 0.3, 0.6), "accent": Color(0.05, 0.2, 0.4)},
    "road": {"color": Color(0.45, 0.35, 0.2), "accent": Color(0.3, 0.2, 0.1)},
    "void": {"color": Color(0.2, 0.0, 0.25), "accent": Color(0.05, 0.0, 0.1)},
    "glow": {"color": Color(0.5, 0.6, 0.9), "accent": Color(0.8, 0.9, 1.0)},
    "ashen": {"color": Color(0.5, 0.5, 0.5), "accent": Color(0.3, 0.3, 0.3)}
}

var generator: WorldGenerator
var diary: GameDiary
var tilemap: TileMap
var hud: Control
var player: Player
var tile_ids := {}
var world_data: Dictionary = {}
var npc_nodes: Dictionary = {}
var enemy_nodes: Dictionary = {}
var items_map: Dictionary = {}
var blocked_tiles: Array = []
var current_seed: int = 0
var event_queue: Array = []
var narrator_memory: Array = []
var last_death_summary := ""
var world_recorded := false

var audio_generator := AudioStreamGenerator.new()
var audio_playback: AudioStreamGeneratorPlayback
var audio_phase := 0.0
var audio_rng := RandomNumberGenerator.new()

func _ready() -> void:
    generator = WorldGenerator.new()
    add_child(generator)
    diary = GameDiary.new()
    add_child(diary)
    tilemap = $TileMap
    hud = $CanvasLayer/HUD
    _setup_tileset()
    hud.start_requested.connect(start_run)
    hud.update_diary(diary.entries)
    hud.show_start_panel(true)
    hud.show_status("Escolha uma seed para lembrar deste mundo.")
    _setup_audio()

func _setup_tileset() -> void:
    var tileset := TileSet.new()
    var source_id := 0
    for tile_name in TILE_DEFS.keys():
        var definition = TILE_DEFS[tile_name]
        var source := TileSetAtlasSource.new()
        source.texture = _create_tile_texture(definition.color, definition.accent)
        source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
        source.create_tile(Vector2i.ZERO)
        tileset.add_source(source, source_id)
        tile_ids[tile_name] = source_id
        source_id += 1
    tilemap.tile_set = tileset
    tilemap.tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
    tilemap.clear()

func _create_tile_texture(color: Color, accent: Color) -> Texture2D:
    var image := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
    image.fill(color)
    for y in range(0, TILE_SIZE, 4):
        for x in range(0, TILE_SIZE, 4):
            image.set_pixel(x, y, accent)
    return ImageTexture.create_from_image(image)

func start_run(seed: int) -> void:
    if not world_data.is_empty() and not world_recorded:
        diary.add_entry(world_data)
        hud.update_diary(diary.entries)
    current_seed = seed
    world_data = generator.generate_world(seed)
    world_data["seed"] = seed
    world_recorded = false
    event_queue = world_data.get("events", []).duplicate(true)
    narrator_memory.insert(0, world_data.get("boss", {}).get("name", "?"))
    if narrator_memory.size() > 5:
        narrator_memory.pop_back()
    _save_world_log(world_data)
    hud.show_start_panel(false)
    hud.set_world_info(world_data)
    hud.show_shop(world_data.get("shop", []))
    hud.show_status("O mundo ressoa com %s." % world_data.get("motivation", "memórias"))
    _build_world()
    _narrate("Você desperta novamente, lembrando de %s." % ", ".join(narrator_memory))

func _build_world() -> void:
    tilemap.clear()
    for child in $Entities.get_children():
        child.queue_free()
    npc_nodes.clear()
    enemy_nodes.clear()
    items_map.clear()
    if world_data.get("corrupted", false):
        blocked_tiles = ["road", "grass"]
    else:
        blocked_tiles = ["water", "forest", "void"]

    var map_data: Array = world_data.get("map", [])
    for y in range(map_data.size()):
        var row: Array = map_data[y]
        for x in range(row.size()):
            var tile_name := row[x]
            if not tile_ids.has(tile_name):
                tile_name = "grass"
            tilemap.set_cell(0, Vector2i(x, y), tile_ids[tile_name], Vector2i.ZERO)

    var spawn := _find_spawn(map_data)
    player = Player.new()
    $Entities.add_child(player)
    player.set_grid_position(spawn)
    player.health = player.max_health
    player.clear_inventory()
    hud.update_health(player.health, player.max_health)
    hud.update_inventory(player.inventory)

    _place_npcs(map_data)
    _place_enemies(map_data)
    _place_items(map_data)

func _find_spawn(map_data: Array) -> Vector2i:
    if map_data.is_empty():
        return Vector2i.ONE
    var start := Vector2i(map_data[0].size() / 2, map_data.size() / 2)
    for radius in range(1, 20):
        for dx in range(-radius, radius + 1):
            for dy in range(-radius, radius + 1):
                var pos := start + Vector2i(dx, dy)
                if _is_walkable(pos, map_data):
                    return pos
    return Vector2i(1, 1)

func _is_walkable(pos: Vector2i, map_data: Array = world_data.get("map", [])) -> bool:
    if map_data.is_empty():
        return false
    if pos.x < 0 or pos.y < 0:
        return false
    if pos.y >= map_data.size():
        return false
    if pos.x >= map_data[0].size():
        return false
    var tile := map_data[pos.y][pos.x]
    return not blocked_tiles.has(tile)

func _place_npcs(map_data: Array) -> void:
    var npcs := world_data.get("npcs", [])
    for npc_info in npcs:
        var pos: Vector2i = npc_info.get("position", Vector2i(2, 2))
        if not _is_walkable(pos, map_data):
            pos = _find_spawn(map_data)
        npc_info["position"] = pos
        var npc := NPC.new()
        npc.setup(npc_info)
        npc.set_grid_position(pos)
        $Entities.add_child(npc)
        npc_nodes[pos] = npc
    hud.show_status("NPCs vagam por locais diferentes. Procure-os!")

func _place_enemies(map_data: Array) -> void:
    var minibosses := world_data.get("minibosses", [])
    for data in minibosses:
        var pos: Vector2i = data.get("position", Vector2i(5, 5))
        if not _is_walkable(pos, map_data):
            pos = _find_spawn(map_data)
        data["id"] = data.get("id", "mini")
        var enemy := Enemy.new()
        enemy.setup(data)
        enemy.set_grid_position(pos)
        $Entities.add_child(enemy)
        enemy_nodes[pos] = enemy
    var boss_data := world_data.get("boss", {})
    boss_data["id"] = "boss"
    var boss := Enemy.new()
    boss.setup(boss_data)
    var boss_pos: Vector2i = boss_data.get("position", Vector2i(10, 10))
    if not _is_walkable(boss_pos, map_data):
        boss_pos = _find_spawn(map_data)
    boss.set_grid_position(boss_pos)
    $Entities.add_child(boss)
    enemy_nodes[boss_pos] = boss

func _place_items(map_data: Array) -> void:
    var item_color := Color(0.9, 0.85, 0.2)
    var outline := Color(0.6, 0.5, 0.1)
    for item in world_data.get("items", []):
        var pos: Vector2i = item.get("position", Vector2i.ZERO)
        if not _is_walkable(pos, map_data):
            continue
        var node := Node2D.new()
        var sprite := Sprite2D.new()
        sprite.texture = _create_item_texture(item_color, outline)
        sprite.centered = true
        node.add_child(sprite)
        node.position = Vector2(pos * TILE_SIZE) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
        $Entities.add_child(node)
        items_map[pos] = {"data": item, "node": node}

func _create_item_texture(color: Color, outline: Color) -> Texture2D:
    var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
    img.fill(outline)
    for y in range(6, TILE_SIZE - 6):
        for x in range(6, TILE_SIZE - 6):
            img.set_pixel(x, y, color)
    return ImageTexture.create_from_image(img)

func _process(delta: float) -> void:
    if world_data.is_empty():
        return
    _handle_input()
    _update_audio(delta)

func _handle_input() -> void:
    if player == null:
        return
    var direction := Vector2i.ZERO
    if Input.is_action_just_pressed("move_up"):
        direction = Vector2i.UP
    elif Input.is_action_just_pressed("move_down"):
        direction = Vector2i.DOWN
    elif Input.is_action_just_pressed("move_left"):
        direction = Vector2i.LEFT
    elif Input.is_action_just_pressed("move_right"):
        direction = Vector2i.RIGHT

    if direction != Vector2i.ZERO:
        _try_move_player(direction)

    if Input.is_action_just_pressed("interact"):
        _interact()
    if Input.is_action_just_pressed("attack"):
        _attack_nearby()
    if Input.is_action_just_pressed("open_diary"):
        hud.toggle_diary_visibility()
        hud.update_diary(diary.entries)

func _try_move_player(direction: Vector2i) -> void:
    var target := player.grid_position + direction
    if not _is_walkable(target):
        hud.show_status("O caminho se distorce. (%s)" % str(world_data.get("motivation", "")))
        return
    player.set_grid_position(target)
    _on_player_moved(target)

func _on_player_moved(pos: Vector2i) -> void:
    var messages: Array = []
    if items_map.has(pos):
        var info := items_map[pos]
        player.add_item(info["data"])
        hud.update_inventory(player.inventory)
        messages.append("Você encontrou %s!" % info["data"].get("name", "algo"))
        info["node"].queue_free()
        items_map.erase(pos)
    if enemy_nodes.has(pos):
        _engage_enemy(pos)
        return
    if npc_nodes.has(pos):
        var npc: NPC = npc_nodes[pos]
        messages.append(_talk_to_npc(npc))
    var event_message := _tick_events()
    if event_message != "":
        messages.append(event_message)
    if messages.size() > 0:
        hud.show_status("\n".join(messages))

func _talk_to_npc(npc: NPC) -> String:
    var info := npc.data
    var dialogue := info.get("dialogue", "...")
    if info.get("remembers_player", false) and diary.entries.size() > 0:
        dialogue += "\nEu lembro de você enfrentando %s." % diary.entries[0].get("boss", "alguém")
    if world_data.get("corrupted", false):
        dialogue = dialogue.replace("memórias", "fragmentos quebrados")
    var message := "%s: %s" % [info.get("name", "NPC"), dialogue]
    if world_data.get("shop", []).size() > 0 and info == world_data.get("npcs", [])[0]:
        message += "\n%s oferece mercadorias únicas nesta seed." % info.get("name", "NPC")
    return message

func _attack_nearby() -> void:
    for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
        var target := player.grid_position + dir
        if enemy_nodes.has(target):
            _engage_enemy(target)
            return
    hud.show_status("Você golpeia o ar. Os ecos riem.")

func _engage_enemy(pos: Vector2i) -> void:
    var enemy: Enemy = enemy_nodes[pos]
    var info := enemy.data
    var enemy_health := enemy.health
    var enemy_attack := enemy.base_attack
    var combat_log := []
    while enemy_health > 0 and player.health > 0:
        enemy_health -= player.attack_power
        combat_log.append("Você causa %d de dano." % player.attack_power)
        if enemy_health <= 0:
            combat_log.append("%s cai." % info.get("title", info.get("name", "Inimigo")))
            break
        player.take_damage(enemy_attack)
        combat_log.append("%s fere você por %d." % [info.get("title", info.get("name", "Inimigo")), enemy_attack])
    enemy.health = max(0, enemy_health)
    hud.update_health(player.health, player.max_health)
    hud.show_status("\n".join(combat_log))
    if enemy_health <= 0:
        enemy.queue_free()
        enemy_nodes.erase(pos)
        if info.get("id", "") == "boss":
            _on_boss_defeated(info)
    elif player.health <= 0:
        _on_player_defeated(info)

func _on_boss_defeated(info: Dictionary) -> void:
    hud.show_status("Você venceu %s! A motivação deles era %s." % [info.get("name", "?"), info.get("motivation", "mistério")])
    _narrate("O guardião cai, mas a mudança continua. Registre esta vitória.")
    diary.add_entry(world_data)
    hud.update_diary(diary.entries)
    world_recorded = true
    hud.show_start_panel(true)
    last_death_summary = "Vitória! Seed %d superada." % world_data.get("seed", 0)
    hud.show_run_summary(last_death_summary)

func _on_player_defeated(info: Dictionary) -> void:
    last_death_summary = "Derrota para %s sob a motivação %s." % [info.get("title", "inimigo"), info.get("motivation", world_data.get("motivation", "?"))]
    hud.show_status(last_death_summary + "\nVocê ainda lembra. Tente outra seed.")
    _narrate("A morte é só mais um eco.")
    diary.add_entry(world_data)
    hud.update_diary(diary.entries)
    world_recorded = true
    hud.show_start_panel(true)
    hud.show_run_summary(last_death_summary)

func _tick_events() -> String:
    if event_queue.is_empty():
        return ""
    var event := event_queue.pop_front()
    var line := "Um evento ecoa: %s (motivo: %s)" % [event.get("tag", "mistério"), event.get("impact", "?")]
    if event.get("memory_echo", false):
        line += " | Ecos da corrupção distorcem-no."
    event_queue.append(event)
    return line

func _interact() -> void:
    if npc_nodes.has(player.grid_position):
        hud.show_status(_talk_to_npc(npc_nodes[player.grid_position]))
        return
    if items_map.has(player.grid_position):
        var info := items_map[player.grid_position]
        player.add_item(info["data"])
        hud.update_inventory(player.inventory)
        info["node"].queue_free()
        items_map.erase(player.grid_position)
        return
    hud.show_status("Nada para interagir aqui.")

func _setup_audio() -> void:
    audio_generator.mix_rate = 44100
    audio_generator.buffer_length = 0.5
    $Audio.stream = audio_generator
    $Audio.play()
    audio_playback = $Audio.get_stream_playback()
    audio_rng.randomize()

func _update_audio(delta: float) -> void:
    if audio_playback == null:
        return
    var frames_available := int(audio_generator.mix_rate * audio_generator.buffer_length)
    if audio_playback.get_frames_available() >= frames_available:
        return
    var frames_to_fill := frames_available - audio_playback.get_frames_available()
    var base_freq := 220.0 + float(world_data.get("seed", 0) % 50)
    if world_data.get("corrupted", false):
        base_freq *= 0.5
    for i in range(frames_to_fill):
        var freq_variation := audio_rng.randf_range(-30.0, 30.0)
        var freq := base_freq + freq_variation
        audio_phase += (freq * TAU) / audio_generator.mix_rate
        var sample := sin(audio_phase) * 0.15
        audio_playback.push_frame(Vector2(sample, sample))

func _narrate(text: String) -> void:
    hud.show_status(text)

func _save_world_log(data: Dictionary) -> void:
    var file := FileAccess.open("user://last_world.json", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data, "  "))
        file.close()
