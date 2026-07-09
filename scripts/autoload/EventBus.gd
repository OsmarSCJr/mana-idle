extends Node

signal faith_changed(new_amount: float)
signal generator_changed(gen_id: int)
signal generator_cycle_complete(gen_id: int, revenue: float)
signal prophet_changed(gen_id: int)
signal prestige_done()
signal ui_needs_update()
signal toast_requested(message: String)
