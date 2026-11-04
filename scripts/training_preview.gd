class_name TrainingPreview
extends RefCounted

const OUTCOME_PENDING: StringName = &"pending"
const OUTCOME_SUCCESS: StringName = &"success"
const OUTCOME_FAILURE: StringName = &"failure"
const OUTCOME_DETERMINISTIC: StringName = &"deterministic"

var is_valid: bool = false
var was_applied: bool = false
var activity_id: StringName = &""
var can_fail: bool = false
var base_failure_chance_percent: int = 0
var failure_chance_percent: int = 0
var success_chance_percent: int = 100
var aptitude_multiplier: float = 1.0
var motivation_multiplier: float = 1.0
var mentor_available: bool = false
var equipment_id: StringName = &""
var energy_cost: int = 0
var stress_delta: int = 0
var calculated_attribute_gains: Dictionary[StringName, int] = {}
var attribute_gains: Dictionary[StringName, int] = {}
var outcome: StringName = OUTCOME_PENDING
var random_roll: float = -1.0
var message: String = ""
var success_result: TrainingState
var failure_result: TrainingState
var result: TrainingState
