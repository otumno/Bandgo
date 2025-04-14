extends TextureRect

# Настройки ритма
@export var bpm := 120
@export var beat_pattern := [true, false, true, true]  # Твой паттерн 1-да 2-нет 3-да 4-да
var current_beat := 0

# Эффект пульсации
@export var max_scale := 1.1  # Максимальное увеличение (10%)
@export var attack_time := 0.05  # Быстрое увеличение (резкий старт)
@export var release_time := 0.3  # Медленное возвращение (плавный финиш)

var base_scale: Vector2
var tween: Tween

func _ready():
	base_scale = scale
	set_pivot_center()  # Центрируем точку трансформации
	start_rhythm()

func set_pivot_center():
	# Устанавливаем точку трансформации в центр
	pivot_offset = size / 2

func start_rhythm():
	var beat_interval = 60.0 / bpm
	get_tree().create_timer(beat_interval).timeout.connect(_on_beat)

func _on_beat():
	if beat_pattern[current_beat % beat_pattern.size()]:
		pulse()
	
	current_beat += 1
	start_rhythm()

func pulse():
	if tween:
		tween.kill()
	
	tween = create_tween()
	
	# Резкое увеличение (attack)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(max_scale, max_scale), attack_time)
	
	# Плавное уменьшение (release)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", base_scale, release_time)
