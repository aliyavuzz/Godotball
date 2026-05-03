extends Node2D

const PITCH_W := 105.0
const PITCH_H := 68.0
const VP_W := 2048.0
const VP_H := 1024.0
const LINE_W := 3.5

func _draw() -> void:
	var c := Color.WHITE

	# Boundary + halfway line
	_rect(Vector2(-52.5, -34.0), Vector2(52.5, 34.0), c)
	_line(Vector2(0.0, -34.0), Vector2(0.0, 34.0), c)

	# Centre circle (r=9.15m) + spot
	_ellipse(Vector2(0.0, 0.0), 9.15, c)
	draw_circle(_p(Vector2(0.0, 0.0)), 5.0, c)

	# Penalty areas (16.5m deep × 40.32m wide → ±20.16)
	_rect(Vector2(-52.5, -20.16), Vector2(-36.0, 20.16), c)
	_rect(Vector2(36.0, -20.16), Vector2(52.5, 20.16), c)

	# Goal areas (5.5m deep × 18.32m wide → ±9.16)
	_rect(Vector2(-52.5, -9.16), Vector2(-47.0, 9.16), c)
	_rect(Vector2(47.0, -9.16), Vector2(52.5, 9.16), c)

	# Penalty spots (11m from goal line)
	draw_circle(_p(Vector2(-41.5, 0.0)), 5.0, c)
	draw_circle(_p(Vector2(41.5, 0.0)), 5.0, c)

	# Penalty arcs — only the segment outside the penalty area (~±53°)
	_arc_deg(Vector2(-41.5, 0.0), 9.15, -53.0,  53.0, c)
	_arc_deg(Vector2( 41.5, 0.0), 9.15, 127.0, 233.0, c)

	# Corner arcs (r=1m), one per corner
	_arc_deg(Vector2(-52.5, -34.0), 1.0,   0.0,  90.0, c)
	_arc_deg(Vector2( 52.5, -34.0), 1.0,  90.0, 180.0, c)
	_arc_deg(Vector2( 52.5,  34.0), 1.0, 180.0, 270.0, c)
	_arc_deg(Vector2(-52.5,  34.0), 1.0, 270.0, 360.0, c)

# ── helpers ──────────────────────────────────────────────────────────────────

# Pitch coords (metres, origin=centre) → SubViewport pixels
func _p(pitch: Vector2) -> Vector2:
	return Vector2(
		(pitch.x + 52.5) / PITCH_W * VP_W,
		(pitch.y + 34.0) / PITCH_H * VP_H
	)

func _line(a: Vector2, b: Vector2, color: Color) -> void:
	draw_line(_p(a), _p(b), color, LINE_W)

func _rect(a: Vector2, b: Vector2, color: Color) -> void:
	var pa := _p(a)
	var pb := _p(b)
	draw_line(pa,              Vector2(pb.x, pa.y), color, LINE_W)
	draw_line(Vector2(pb.x, pa.y), pb,              color, LINE_W)
	draw_line(pb,              Vector2(pa.x, pb.y), color, LINE_W)
	draw_line(Vector2(pa.x, pb.y), pa,              color, LINE_W)

# Non-uniform ellipse so that circle pitch coords → circle on 3D mesh
func _ellipse(center: Vector2, radius_m: float, color: Color, segs: int = 64) -> void:
	var pc := _p(center)
	var rx := radius_m / PITCH_W * VP_W
	var ry := radius_m / PITCH_H * VP_H
	var pts := PackedVector2Array()
	for i in range(segs + 1):
		var a := i * TAU / float(segs)
		pts.append(pc + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, color, LINE_W)

func _arc_deg(center: Vector2, radius_m: float, start_deg: float, end_deg: float,
		color: Color, segs: int = 32) -> void:
	var pc := _p(center)
	var rx := radius_m / PITCH_W * VP_W
	var ry := radius_m / PITCH_H * VP_H
	var pts := PackedVector2Array()
	for i in range(segs + 1):
		var t := float(i) / float(segs)
		var a := deg_to_rad(lerp(start_deg, end_deg, t))
		pts.append(pc + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, color, LINE_W)
