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
var failure_chance_percent: int = 0
var success_chance_percent: int = 100
var outcome: StringName = OUTCOME_PENDING
var random_roll: float = -1.0
var message: String = ""
var success_result: TrainingState
var failure_result: TrainingState
var result: TrainingState
