"""The app mark's geometry, shared by the PNG renderer and the vector
writer: a coin marked C at the exact centre, inside two opposing turning
arrows (rotationally symmetric, so it reads centred under any mask).

Units are the adaptive icon's 108 × 108 canvas; centre (54, 54); the safe
zone is a circle of radius 33.
"""
import math

C = 54.0
COIN_R = 17.0
LETTER_R = 8.2
LETTER_W = 4.6
ARC_R = 25.0
ARC_W = 4.2
# Each arrow sweeps 90° clockwise (screen angles, 0 = 3 o'clock).
ARCS = [(260.0, 350.0), (80.0, 170.0)]
HEAD = 5.0


def point(angle, r, cx=C, cy=C):
    a = math.radians(angle)
    return (cx + r * math.cos(a), cy + r * math.sin(a))


def chevron(end_angle, r=ARC_R, head=HEAD, cx=C, cy=C):
    """Arrowhead at the end of a clockwise arc: wing, tip, wing."""
    a = math.radians(end_angle)
    ex, ey = point(end_angle, r, cx, cy)
    tx, ty = -math.sin(a), math.cos(a)  # clockwise tangent
    nx, ny = math.cos(a), math.sin(a)  # outward normal
    tip = (ex + 0.3 * head * tx, ey + 0.3 * head * ty)
    w1 = (tip[0] - head * tx + head * nx, tip[1] - head * ty + head * ny)
    w2 = (tip[0] - head * tx - head * nx, tip[1] - head * ty - head * ny)
    return [w1, tip, w2]
