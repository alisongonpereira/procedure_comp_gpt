extends Node
class_name WorldGenerator

const WORLD_MOTIVATIONS = ["guerra", "amor", "praga", "obsessao", "luto"]
const MINI_BOSSES = [
    {"id": "hunter", "title": "O Caçador"},
    {"id": "mist_daughter", "title": "A Filha da Névoa"},
    {"id": "watcher", "title": "O Vigilante"}
]
const NPCS = [
    {"name": "Arin", "role": "arqueiro eterno"},
    {"name": "Mira", "role": "arqueóloga do tempo"},
    {"name": "Lys", "role": "cartógrafa das memórias"}
]
const ITEMS = [
    {"id": "memory_blossom", "name": "Flor da Memória", "rarity": "raro"},
    {"id": "timeglass", "name": "Ampulheta Partida", "rarity": "comum"},
    {"id": "ember", "name": "Brasa Persistente", "rarity": "raro"},
    {"id": "echo_shard", "name": "Fragmento de Eco", "rarity": "epico"},
    {"id": "mirror_ink", "name": "Tinta Espelhada", "rarity": "comum"}
]
const EVENT_TAGS = ["chuva de memórias", "névoa estática", "crepúsculo eterno", "clarões de origem"]
const WEATHER_PATTERNS = ["chuva", "céu limpo", "eclipse", "neblina"]

const MAP_WIDTH := 48
const MAP_HEIGHT := 48

var noise := OpenSimplexNoise.new()

func generate_world(seed: int) -> Dictionary:
    randomize_with_seed(seed)
    noise.seed = seed
    noise.octaves = 3
    noise.persistence = 0.6
    noise.period = 18.0

    var corruption_roll := randf()
    var corrupted := corruption_roll <= 0.05

    var motivation := WORLD_MOTIVATIONS[randi_range(0, WORLD_MOTIVATIONS.size() - 1)]
    var weather := WEATHER_PATTERNS[randi_range(0, WEATHER_PATTERNS.size() - 1)]

    var map_data := _generate_tiles(corrupted)
    var npc_data := _generate_npcs(seed, corrupted, motivation)
    var minibosses := _generate_minibosses(seed, corrupted)
    var boss := _generate_boss(seed, motivation, corrupted)
    var items := _scatter_items(seed, corrupted)
    var shop := _generate_shop_inventory(seed, corrupted)

    return {
        "seed": seed,
        "motivation": motivation,
        "weather": weather,
        "corrupted": corrupted,
        "map": map_data,
        "npcs": npc_data,
        "minibosses": minibosses,
        "boss": boss,
        "items": items,
        "shop": shop,
        "events": _generate_events(seed, motivation, corrupted)
    }

func randomize_with_seed(seed: int) -> void:
    var s := abs(hash(str(seed))) & 0x7fffffff
    seed(s)

func _generate_tiles(corrupted: bool) -> Array:
    var tiles: Array = []
    for y in range(MAP_HEIGHT):
        var row: Array = []
        for x in range(MAP_WIDTH):
            var n = noise.get_noise_2d(float(x), float(y))
            var tile_type := "grass"
            if n > 0.35:
                tile_type = "void" if corrupted else "forest"
            elif n < -0.25:
                tile_type = "glow" if corrupted else "water"
            elif abs(n) < 0.1:
                tile_type = "ashen" if corrupted else "road"
            row.append(tile_type)
        tiles.append(row)
    return tiles

func _generate_npcs(seed: int, corrupted: bool, motivation: String) -> Array:
    var shuffled := NPCS.duplicate(true)
    shuffled.shuffle()
    var dialogue_templates := [
        "Eu senti %s ecoar antes...",
        "As memórias estão diferentes nesta semente %d.",
        "Você voltou, mas eu quase lembro da última guerra...",
        "Se o mundo é %s, então precisamos lutar de outra forma."
    ]
    var data: Array = []
    for npc in shuffled:
        var x := randi_range(1, MAP_WIDTH - 2)
        var y := randi_range(1, MAP_HEIGHT - 2)
        var template := dialogue_templates[randi_range(0, dialogue_templates.size() - 1)]
        var dialogue := template
        if template.find("%d") != -1:
            dialogue = template % seed
        elif template.find("%s") != -1:
            dialogue = template % motivation
        data.append({
            "name": npc["name"],
            "role": npc["role"],
            "position": Vector2i(x, y),
            "dialogue": dialogue,
            "remembers_player": randf() < 0.5
        })
    return data

func _generate_minibosses(seed: int, corrupted: bool) -> Array:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed + 99
    var results: Array = []
    for archetype in MINI_BOSSES:
        var pos := Vector2i(rng.randi_range(3, MAP_WIDTH - 4), rng.randi_range(3, MAP_HEIGHT - 4))
        var stats_scale := 1.35 if corrupted else 1.0
        var base_power := 10 + rng.randi_range(0, 6)
        results.append({
            "id": archetype["id"],
            "title": archetype["title"],
            "position": pos,
            "power": int(base_power * stats_scale),
            "motivation": WORLD_MOTIVATIONS[rng.randi_range(0, WORLD_MOTIVATIONS.size() - 1)]
        })
    return results

func _generate_boss(seed: int, motivation: String, corrupted: bool) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed * 13 + 7
    var names = ["Vesper", "Calyx", "Ruvian", "Namar", "Ilyth"]
    var final_name := names[rng.randi_range(0, names.size() - 1)]
    var statements = {
        "guerra": "Eu luto em cada ciclo porque não sei parar.",
        "amor": "Guardo cada memória para lembrar de você.",
        "praga": "Deixe tudo apodrecer, assim ninguém mais sofre.",
        "obsessao": "Só dominando cada eco eu descansarei.",
        "luto": "Se eles se foram, o mundo irá também."
    }
    var corrupted_twist := " A corrupção reescreve minhas lembranças." if corrupted else ""
    return {
        "name": final_name,
        "title": "Guardião das Mudanças",
        "motivation": motivation,
        "position": Vector2i(rng.randi_range(5, MAP_WIDTH - 6), rng.randi_range(5, MAP_HEIGHT - 6)),
        "speech": statements.get(motivation, "Eu mudo porque devo.") + corrupted_twist,
        "power": int(25 * (1.5 if corrupted else 1.0))
    }

func _scatter_items(seed: int, corrupted: bool) -> Array:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed * 5 + 17
    var total := rng.randi_range(8, 14)
    var scattered: Array = []
    for i in range(total):
        var item := ITEMS[rng.randi_range(0, ITEMS.size() - 1)]
        var rare_seed := rng.randi() % 23 == 0
        if corrupted:
            rare_seed = !rare_seed
        scattered.append({
            "id": item["id"],
            "name": item["name"],
            "rarity": "lendario" if rare_seed else item["rarity"],
            "position": Vector2i(rng.randi_range(1, MAP_WIDTH - 2), rng.randi_range(1, MAP_HEIGHT - 2))
        })
    return scattered

func _generate_shop_inventory(seed: int, corrupted: bool) -> Array:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed - 33
    var stock: Array = []
    var pool := ITEMS.duplicate(true)
    pool.shuffle()
    var count := 4
    for i in range(count):
        var item := pool[i % pool.size()]
        var price := 10 + rng.randi_range(0, 25)
        if corrupted:
            price = max(5, int(price * 0.7))
        stock.append({
            "id": item["id"],
            "name": item["name"],
            "price": price,
            "rarity": item["rarity"]
        })
    return stock

func _generate_events(seed: int, motivation: String, corrupted: bool) -> Array:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed + 321
    var events: Array = []
    for i in range(3):
        events.append({
            "tag": EVENT_TAGS[rng.randi_range(0, EVENT_TAGS.size() - 1)],
            "impact": motivation,
            "memory_echo": corrupted and rng.randf() < 0.4
        })
    return events
