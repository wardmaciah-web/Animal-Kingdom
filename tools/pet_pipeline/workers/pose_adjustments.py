"""Recipe-driven soft-selection deformations of existing anatomy, never new limbs.

Coordinates are normalized Blender Z-up review coordinates, scaled by unit.
Each operation records an explicit region, pivot and displacement for review.
"""
import math


def deform_point(point, operation, unit=1.0):
    bounds = operation['bounds']
    feather = operation.get('feather', 0.08) * unit
    if feather <= 0:
        raise ValueError('Pose feather must be positive')
    weight = 1.0
    for value, limits in zip(point, bounds):
        low, high = (v * unit for v in limits)
        if low >= high:
            raise ValueError('Pose bounds must have positive extent')
        distance = min(value - low, high - value)
        if distance <= 0:
            return tuple(point), 0.0
        t = min(1.0, distance / feather)
        weight *= t*t*(3.0-2.0*t)
    pivot = [v * unit for v in operation.get('pivot', [0, 0, 0])]
    moved = [v - p for v, p in zip(point, pivot)]
    for axis, degrees in enumerate(operation.get('rotation_degrees', [0, 0, 0])):
        a, b = ((1, 2), (2, 0), (0, 1))[axis]
        c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
        moved[a], moved[b] = c*moved[a]-s*moved[b], s*moved[a]+c*moved[b]
    translation = operation.get('translation', [0, 0, 0])
    target = [v+p+t*unit for v, p, t in zip(moved, pivot, translation)]
    return tuple(v+(t-v)*weight for v, t in zip(point, target)), weight


def apply_to_mesh(mesh, operations, unit=1.0):
    if not operations:
        return []
    reports = []
    for operation in operations:
        if not operation.get('name') or not operation.get('reason'):
            raise ValueError('Pose operation needs a name and anatomical reason')
        affected, maximum = 0, 0.0
        for vertex in mesh.vertices:
            before = tuple(vertex.co)
            after, weight = deform_point(before, operation, unit)
            if weight:
                vertex.co = after
                affected += 1
                maximum = max(maximum, math.dist(before, after))
        if not affected:
            raise ValueError('Pose region touches no vertices: '+operation['name'])
        reports.append({'name': operation['name'], 'reason': operation['reason'],
                        'affected_vertices': affected, 'maximum_displacement': maximum})
    mesh.update()
    return reports
