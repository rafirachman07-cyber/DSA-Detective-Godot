extends Node

var selected_suspect: Dictionary = {}
var suspect_already_selected := false
var current_odp: Dictionary = {}
var kept_suspects: Array = []

var tutorials_completed: Dictionary = {
	# nanti ditambahin semua dialog
	"prolog": false,
	"suspect_menu": false,
	"stack_menu": false,
	"queue_orang_menu": false,
	"queue_fax_menu": false,
	"hasmap_menu": false,
	"choose_suspect_menu": false,
}
