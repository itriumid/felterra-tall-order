class_name Cage
extends RefCounted
## A company trap with a cat in it: to the company, cats are pests. A cat standing by it picks the
## lock, a little at a time, and if she leaves, the pick slips back. Opened, the cat inside runs
## for the jungle, home to the village.

## How close she has to stand, how long the lock takes, and how fast the pick slips back while
## nobody's at it, as a share of the lock a second.
const PICK_REACH := 0.6
const PICK_TIME := 3.0
const SLIP_RATE := 0.25
## How fast a freed cat runs for home.
const RUN_SPEED := 3.2
## The cats a cage might hold: their names, and their coats.
const NAMES: Array[String] = ["Belang", "Kumis", "Manis", "Cemong", "Oyen", "Bulu", "Gembul", "Mochi", "Kenari", "Tompel", "Ciko", "Lintang"]
const COATS: Array[String] = ["orange", "gray", "black", "cream"]

var body := Body.new()
## How far the lock is picked, from 0 to 1, and in how many clicks so far, for the sound.
var picked := 0.0
var clicks := 0
var opened := false
## Who's inside: {name, coat}.
var prisoner := {}
## Once opened, the freed cat running for the jungle, until it's gone into it.
var runner := Body.new()
var home := false
## How far it has run, so its legs step with the ground it covers.
var ran := 0.0


func _init(random: RandomNumberGenerator) -> void:
	body.radius = 0.25
	body.tall = 0.35
	body.kind = "cage"
	prisoner = {"name": NAMES[random.randi_range(0, NAMES.size() - 1)], "coat": COATS[random.randi_range(0, COATS.size() - 1)]}
	runner.radius = Cat.RADIUS
	runner.tall = Cat.TALL


## Picks at the lock while she's by it, or slips back. Returns true on the step it opens.
func pick(delta: float, picking: bool) -> bool:
	if opened:
		return false
	picked = clampf(picked + (delta / PICK_TIME if picking else -delta * SLIP_RATE), 0.0, 1.0)
	clicks = maxi(clicks, floori(picked * 8.0))
	if picked < 1.0:
		return false
	opened = true
	runner.position = body.position
	return true


## The freed cat runs for the nearest edge of the clearing, and is home once it reaches it.
func run_home(delta: float, size: Vector2) -> void:
	if not opened or home:
		return
	var edges := [Vector2(runner.position.x, 0.0), Vector2(runner.position.x, size.y), Vector2(0.0, runner.position.y), Vector2(size.x, runner.position.y)]
	var nearest: Vector2 = edges[0]
	for edge: Vector2 in edges:
		if runner.position.distance_to(edge) < runner.position.distance_to(nearest):
			nearest = edge
	runner.velocity = (nearest - runner.position).normalized() * RUN_SPEED
	runner.position += runner.velocity * delta
	ran += RUN_SPEED * delta
	home = runner.position.distance_to(nearest) < 0.3
