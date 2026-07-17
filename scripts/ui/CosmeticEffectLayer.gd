class_name CosmeticEffectLayer
extends Control

const DOVE_EFFECT_COOLDOWN_MS: int = 1400
const EFFECT_SIZE := Vector2(180, 180)

var _last_dove_effect_msec: int = -DOVE_EFFECT_COOLDOWN_MS

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 90

func play_doves(center: Vector2) -> bool:
	var now_msec := Time.get_ticks_msec()
	if now_msec - _last_dove_effect_msec < DOVE_EFFECT_COOLDOWN_MS:
		return false
	_last_dove_effect_msec = now_msec
	var effect := TextureRect.new()
	effect.texture = GameArt.cosmetic_preview("efeito_pombas")
	effect.custom_minimum_size = EFFECT_SIZE
	effect.size = EFFECT_SIZE
	effect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	effect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.pivot_offset = effect.size * 0.5
	var viewport_size := get_viewport_rect().size
	effect.position = Vector2(
		clampf(center.x - effect.size.x * 0.5, 12.0, viewport_size.x - effect.size.x - 12.0),
		clampf(center.y - effect.size.y * 0.5, 12.0, viewport_size.y - effect.size.y - 12.0)
	)
	effect.modulate.a = 0.0
	effect.scale = Vector2(0.72, 0.72)
	effect.rotation = -0.08
	add_child(effect)
	var reveal := create_tween()
	reveal.set_parallel(true)
	reveal.tween_property(effect, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	reveal.tween_property(effect, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	reveal.tween_property(effect, "rotation", 0.04, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal.tween_property(effect, "position:y", effect.position.y - 24.0, 0.7).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	reveal.chain().tween_property(effect, "modulate:a", 0.0, 0.32).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	reveal.chain().tween_callback(effect.queue_free)
	return true
