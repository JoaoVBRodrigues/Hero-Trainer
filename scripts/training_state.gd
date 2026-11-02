class_name TrainingState
extends RefCounted

const ATTRIBUTE_IDS: Array[StringName] = [
	&"pot",
	&"res",
	&"tec",
	&"teo",
	&"sin",
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
var energy: int = 0
var stress: int = 0
var motivation: int = 0
var credits: int = 0
var reputation: int = 0
var bonds: Dictionary[StringName, int] = {}


func duplicate_state() -> TrainingState:
	var copy := TrainingState.new()
	copy.week = week
	copy.actions_remaining = actions_remaining
	copy.stats = stats.duplicate()
	copy.energy = energy
	copy.stress = stress
	copy.motivation = motivation
	copy.credits = credits
	copy.reputation = reputation
	copy.bonds = bonds.duplicate()
	return copy


func copy_from(source: TrainingState) -> void:
	week = source.week
	actions_remaining = source.actions_remaining
	stats = source.stats.duplicate()
	energy = source.energy
	stress = source.stress
	motivation = source.motivation
	credits = source.credits
	reputation = source.reputation
	bonds = source.bonds.duplicate()
