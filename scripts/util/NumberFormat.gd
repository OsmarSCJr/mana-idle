class_name NumberFormat
extends RefCounted

const SUFFIXES = [
	"", "K", "M", "B", "T",
	"aa", "ab", "ac", "ad", "ae", "af", "ag", "ah", "ai", "aj",
	"ak", "al", "am", "an", "ao", "ap", "aq", "ar", "as", "at",
	"au", "av", "aw", "ax", "ay", "az"
]

static func format(num: float) -> String:
	if num < 0:
		return "-" + format(-num)
	if num < 1000:
		return str(int(num))

	var order: int = int(log(num) / log(1000.0))
	if order >= SUFFIXES.size():
		order = SUFFIXES.size() - 1
	if order < 0:
		order = 0

	var scaled: float = num / pow(1000.0, order)

	if scaled >= 100.0:
		return "%.0f%s" % [scaled, SUFFIXES[order]]
	elif scaled >= 10.0:
		return "%.1f%s" % [scaled, SUFFIXES[order]]
	else:
		return "%.2f%s" % [scaled, SUFFIXES[order]]

static func format_time(seconds: float) -> String:
	var secs_int: int = int(seconds)
	if seconds < 60:
		return "%.1fs" % seconds
	if seconds < 3600:
		return "%dm%ds" % [secs_int / 60, secs_int % 60]
	if seconds < 86400:
		return "%dh%dm" % [secs_int / 3600, (secs_int % 3600) / 60]
	return "%dd%dh" % [secs_int / 86400, (secs_int % 86400) / 3600]
