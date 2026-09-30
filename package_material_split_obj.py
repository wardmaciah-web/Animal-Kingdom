"""Package the already-verified material split FBXs as shared-space ASCII OBJs.

This does not regenerate or alter geometry. It applies only the source model's
recorded rotation/scaling (the same transform used by the split audit) and
writes each verified material piece as a named OBJ object/group.
"""
import json
import math
import pathlib
import re

SPLIT = pathlib.Path("/Users/jefferypryor/Downloads/RobloxBatches/TownBuildings/MaterialSplitTownAssets")
OUT = pathlib.Path("/Users/jefferypryor/Downloads/RobloxBatches/TownBuildings/StudioImportTownAssetsV2")
AUDIT = pathlib.Path("/Users/jefferypryor/Downloads/RobloxBatches/.tools/town_obj_package_audit.txt")
NAMES = {
    "Inn.fbx": "TradingHall_MaterialSplit",
    "House_4.fbx": "Rewards_MaterialSplit",
    "House_2.fbx": "GeneralStore_MaterialSplit",
    "Blacksmith.fbx": "Blacksmith_MaterialSplit",
    "Well.fbx": "Well_MaterialSplit",
    "MarketStand_1.fbx": "MarketStand1_MaterialSplit",
    "MarketStand_2.fbx": "MarketStand2_MaterialSplit",
    "Cart.fbx": "Cart_MaterialSplit",
}


def array(text, label):
    match = re.search(r"\b" + re.escape(label) + r":\s*\*\d+\s*\{\s*a:\s*([^}]*)}", text, re.S)
    if not match:
        raise RuntimeError(f"missing {label}")
    return [float(value) for value in match.group(1).split(",") if value.strip()]


def transform(point, rotation, scaling):
    x, y, z = [point[i] * scaling[i] / 100 for i in range(3)]
    rx, ry, rz = map(math.radians, rotation)
    y, z = y * math.cos(rx) - z * math.sin(rx), y * math.sin(rx) + z * math.cos(rx)
    x, z = x * math.cos(ry) + z * math.sin(ry), -x * math.sin(ry) + z * math.cos(ry)
    x, y = x * math.cos(rz) - y * math.sin(rz), x * math.sin(rz) + y * math.cos(rz)
    return x, y, z


def parse_piece(path, rotation, scaling):
    text = path.read_text(encoding="utf-8")
    raw = array(text, "Vertices")
    stream = [int(value) for value in array(text, "PolygonVertexIndex")]
    vertices = [transform(tuple(raw[index:index + 3]), rotation, scaling) for index in range(0, len(raw), 3)]
    faces, face = [], []
    for value in stream:
        ending = value < 0
        face.append(-value - 1 if ending else value)
        if ending:
            if len(face) < 3:
                raise RuntimeError(f"degenerate polygon in {path}")
            faces.append(tuple(face))
            face = []
    if face:
        raise RuntimeError(f"unterminated polygon in {path}")
    return vertices, faces


def bounds(points):
    return ([min(point[axis] for point in points) for axis in range(3)],
            [max(point[axis] for point in points) for axis in range(3)])


def parse_obj(path):
    vertices, groups, current = [], {}, None
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        fields = line.split()
        if fields[0] == "v":
            vertices.append(tuple(map(float, fields[1:4])))
        elif fields[0] in ("o", "g"):
            if fields[0] == "o":
                current = fields[1]
                groups.setdefault(current, [])
        elif fields[0] == "f":
            if current is None:
                raise RuntimeError(f"face before object in {path}")
            face = []
            for token in fields[1:]:
                value = int(token.split("/", 1)[0])
                face.append(value - 1 if value > 0 else len(vertices) + value)
            groups[current].append(tuple(face))
    return vertices, groups


def close(a, b, tolerance=1e-7):
    return max(abs(a[i] - b[i]) for i in range(3)) <= tolerance


manifest = json.loads((SPLIT / "material_split_manifest.json").read_text())
OUT.mkdir(parents=True, exist_ok=True)
reports = []
for source_name, data in manifest.items():
    output_stem = NAMES[source_name]
    lines = ["# Animal Kingdom verified material-split OBJ", f"# source {source_name}"]
    source_faces = data["sourceFaces"]
    offset = 0
    expected_groups = {}
    all_expected_points = []
    for piece in data["pieces"]:
        vertices, faces = parse_piece(pathlib.Path(piece["file"]), data["rotation"], data["scaling"])
        role = piece["role"]
        object_name = "AK_" + role
        if object_name in expected_groups:
            suffix = 2
            while f"{object_name}_{suffix:02d}" in expected_groups:
                suffix += 1
            object_name = f"{object_name}_{suffix:02d}"
        expected_groups[object_name] = faces
        lines.extend((f"o {object_name}", f"g {object_name}"))
        lines.extend(f"v {x:.9g} {y:.9g} {z:.9g}" for x, y, z in vertices)
        for face in faces:
            lines.append("f " + " ".join(str(index + 1 + offset) for index in face))
        offset += len(vertices)
        all_expected_points.extend(vertices)
    destination = OUT / f"{output_stem}.obj"
    destination.write_text("\n".join(lines) + "\n", encoding="utf-8")

    parsed_vertices, parsed_groups = parse_obj(destination)
    packaged_faces = sum(len(faces) for faces in parsed_groups.values())
    expected_face_keys = []
    cursor = 0
    for piece in data["pieces"]:
        vertices, faces = parse_piece(pathlib.Path(piece["file"]), data["rotation"], data["scaling"])
        expected_face_keys.extend(tuple(index + cursor for index in face) for face in faces)
        cursor += len(vertices)
    parsed_face_keys = [face for faces in parsed_groups.values() for face in faces]
    missing = len(set(expected_face_keys) - set(parsed_face_keys))
    duplicates = len(parsed_face_keys) - len(set(parsed_face_keys))
    expected_min, expected_max = data["sourceBoundsMin"], data["sourceBoundsMax"]
    actual_min, actual_max = bounds(parsed_vertices)
    difference = max(abs(actual_min[i] - expected_min[i]) for i in range(3))
    difference = max(difference, max(abs(actual_max[i] - expected_max[i]) for i in range(3)))
    passed = (len(parsed_groups) == len(data["pieces"]) and packaged_faces == source_faces
              and missing == 0 and duplicates == 0 and difference <= 1e-7)
    report = {
        "building": output_stem, "groups": len(parsed_groups), "faces": packaged_faces,
        "sourceFaces": source_faces, "missingFaces": missing, "duplicateFaces": duplicates,
        "boundsDifference": difference, "PASS": passed,
    }
    reports.append(report)
    print("AK_OBJ_PACKAGE_VERIFY")
    for key, value in report.items():
        print(f"{key}={value}")

if len(reports) != 8 or sum(item["groups"] for item in reports) != 33 or not all(item["PASS"] for item in reports):
    raise SystemExit("OBJ package verification failed")
AUDIT.write_text(json.dumps(reports, indent=2) + "\n", encoding="utf-8")
print("OBJ_PACKAGE_SUMMARY buildings=8 groups=33 geometryCoverage=100% status=PASS")
