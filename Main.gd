extends Node2D
# Main.gd — Master controller
# Handles: zone timer, darkness, game over, score, layer switching visuals

# ── Zone timer settings ────────────────────────────────
const MAX_ZONE_TIME  : float = 10.0   # Seconds until game over
const DARKEN_START   : float = 7.0    # When screen starts going dark
var zone_timer       : float = 0.0    # Counts UP from 0
var game_active      : bool  = false

# ── Score ──────────────────────────────────────────────
var score            : int   = 0

# ── Node references ────────────────────────────────────
@onready var player          := $Player
@onready var spawner         := $ObstacleSpawner
@onready var darkness        := $DarknessOverlay
@onready var bg_surface      := $Backgrounds/SurfaceBG
@onready var bg_underground  := $Backgrounds/UndergroundBG

# UI references (inside UI CanvasLayer)
@onready var zone_bar        := $UI/ZoneTimerBar
@onready var score_label     := $UI/ScoreLabel
@onready var zone_label      := $UI/ZoneLabel
@onready var game_over_panel := $UI/GameOverPanel
@onready var score_display   := $UI/GameOverPanel/Container/ScoreDisplay
@onready var restart_btn     := $UI/GameOverPanel/Container/RestartButton

func _ready() -> void:
    restart_btn.connect("pressed", _on_restart_pressed)
    game_over_panel.visible = false
    darkness.color          = Color(0, 0, 0, 0)
    _start_game()

func _start_game() -> void:
    score      = 0
    zone_timer = 0.0
    game_active = true
    score_label.text = "💎 0"
    zone_label.text  = "SURFACE"
    zone_bar.value   = MAX_ZONE_TIME
    spawner.start()

func _process(delta: float) -> void:
    if not game_active:
        return

    # ── Advance zone timer ─────────────────────────────
    zone_timer += delta
    var time_remaining := MAX_ZONE_TIME - zone_timer

    # Update the timer bar
    zone_bar.value = time_remaining

    # ── Darkness effect starts at 7 seconds ───────────
    if zone_timer >= DARKEN_START:
        # Goes from alpha=0 at 7s to alpha=1 at 10s
        var t := (zone_timer - DARKEN_START) / (MAX_ZONE_TIME - DARKEN_START)
        darkness.color = Color(0, 0, 0, clamp(t, 0.0, 1.0))

    # ── Game over at 10 seconds ────────────────────────
    if zone_timer >= MAX_ZONE_TIME:
        on_player_died()

    # ── Score increases over time (survival score) ─────
    score = int(zone_timer * 10)   # 10 points per second survived
    score_label.text = "💎 %d" % score

func _physics_process(_delta: float) -> void:
    if not game_active:
        return
    _check_obstacle_collisions()

func _check_obstacle_collisions() -> void:
    # Check every obstacle against player position
    for obs in $ObstacleSpawner.get_children():
        if not obs.has_meta("zone"):
            continue

        var obs_zone : String = obs.get_meta("zone")

        # Only dangerous if player is in the same zone
        if obs_zone != player.zone:
            continue

        # Simple distance check — obstacle is 56x56, player is ~44x55
        var dist := player.global_position.distance_to(obs.global_position)
        if dist < 50:
            player.die()
            return

# ── Called by Player when zone is switched ─────────────
func on_zone_switched() -> void:
    zone_timer = 0.0   # Reset the timer!
    darkness.color = Color(0, 0, 0, 0)   # Clear darkness

    # Update zone label
    if player.zone == "surface":
        zone_label.text     = "SURFACE"
        zone_label.modulate = Color(0.4, 0.9, 1.0)
    else:
        zone_label.text     = "UNDERGROUND"
        zone_label.modulate = Color(0.8, 0.4, 1.0)

# ── Called by Player when they die ─────────────────────
func on_player_died() -> void:
    if not game_active:
        return
    game_active = false
    spawner.stop()
    score_display.text  = "Score: 💎 %d" % score
    game_over_panel.visible = true

# ── Restart ────────────────────────────────────────────
func _on_restart_pressed() -> void:
    game_over_panel.visible = false
    darkness.color = Color(0, 0, 0, 0)
    player.reset()
    spawner.restart()
    zone_label.text     = "SURFACE"
    zone_label.modulate = Color(1, 1, 1, 1)
    _start_game()
