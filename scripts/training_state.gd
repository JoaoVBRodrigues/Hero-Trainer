class_name TrainingState
extends RefCounted

const ATTRIBUTE_IDS: Array[StringName] = [
	&"pot",
	&"res",
	&"tec",
	&"teo",
	&"sin",
]
const AXIS_IDS: Array[StringName] = [
	&"autonomy",
	&"solidarity",
	&"ambition",
	&"integrity",
]
const AXIS_MIN: int = -100
const AXIS_MAX: int = 100
const ROUTE_STATE_LIMITS: Dictionary[StringName, Vector2i] = {
	&"core_stability": Vector2i(0, 100),
	&"echo_pressure": Vector2i(0, 100),
	&"trusted_network": Vector2i(0, 100),
	&"identification_aids_progress": Vector2i(0, 2),
	&"honesty_to_friends": Vector2i(0, 100),
}
const ROUTE_STATE_BOOLEAN_IDS: Array[StringName] = [&"identification_aids"]
const MISSION_FLAG_IDS: Array[StringName] = [
	&"final_mission_attempted",
	&"final_mission_completed",
	&"final_mission_success",
	&"final_mission_failed_by_deadline",
	&"final_mission_resolved",
]

var week: int = 1
var actions_remaining: int = 0
var stats: Dictionary[StringName, int] = {
	&"pot": 0,
	&"res": 0,
	&"tec": 0,
	&"teo": 0,
	&"sin": 0,
}
var axes: Dictionary[StringName, int] = {
	&"autonomy": 0,
	&"solidarity": 0,
	&"ambition": 0,
	&"integrity": 0,
}
var route_state: Dictionary[StringName, Variant] = {
	&"core_stability": 0,
	&"echo_pressure": 0,
	&"trusted_network": 0,
	&"identification_aids": false,
	&"identification_aids_progress": 0,
	&"honesty_to_friends": 0,
}
var flags: Dictionary[StringName, bool] = {
	&"final_mission_attempted": false,
	&"final_mission_completed": false,
	&"final_mission_success": false,
	&"final_mission_failed_by_deadline": false,
	&"final_mission_resolved": false,
}
var mission_stage: int = 0
var ending_id: StringName = &""
var energy: int = 0
var stress: int = 0
var motivation: int = 0
var credits: int = 0
var reputation: int = 0
var bonds: Dictionary[StringName, int] = {}
var rng_seed: int = 0
var rng_state: int = 0
var inventory: Array[StringName] = []
var equipped_item_id: StringName = &""


func duplicate_state() -> TrainingState:
	var copy := TrainingState.new()
	copy.week = week
	copy.actions_remaining = actions_remaining
	copy.stats = stats.duplicate()
	copy.axes = axes.duplicate()
	copy.route_state = route_state.duplicate()
	copy.flags = flags.duplicate()
	copy.mission_stage = mission_stage
	copy.ending_id = ending_id
	copy.energy = energy
	copy.stress = stress
	copy.motivation = motivation
	copy.credits = credits
	copy.reputation = reputation
	copy.bonds = bonds.duplicate()
	copy.rng_seed = rng_seed
	copy.rng_state = rng_state
	copy.inventory = inventory.duplicate()
	copy.equipped_item_id = equipped_item_id
	return copy


func copy_from(source: TrainingState) -> void:
	week = source.week
	actions_remaining = source.actions_remaining
	stats = source.stats.duplicate()
	axes = source.axes.duplicate()
	route_state = source.route_state.duplicate()
	flags = source.flags.duplicate()
	mission_stage = source.mission_stage
	ending_id = source.ending_id
	energy = source.energy
	stress = source.stress
	motivation = source.motivation
	credits = source.credits
	reputation = source.reputation
	bonds = source.bonds.duplicate()
	rng_seed = source.rng_seed
	rng_state = source.rng_state
	inventory = source.inventory.duplicate()
	equipped_item_id = source.equipped_item_id
