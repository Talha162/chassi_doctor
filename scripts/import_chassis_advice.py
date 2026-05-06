import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request
import urllib.error
import zipfile
import xml.etree.ElementTree as ET
from collections import OrderedDict


WORKBOOK_PATH = r"C:\Users\Talha\Downloads\chassis doctor advice db v1.xlsx"
SECTION_MARKER = 0x25B6

SYMPTOM_DESCRIPTIONS = {
    "Understeer": "The car turns less than desired while cornering, pushing wide instead of following the intended line.",
    "Oversteer": "The rear of the car rotates more than intended while cornering, making the car feel loose or unstable.",
}

ISSUE_DESCRIPTIONS = {
    "Corner Entry": "Balance issue felt during initial turn-in and the first phase of corner entry.",
    "Mid Corner": "Balance issue felt at steady-state cornering through the middle of the turn.",
    "Corner Exit": "Balance issue felt while unwinding steering and applying throttle on corner exit.",
}

TRACK_MAP = {
    "Circuit": "Circuit/Road Course",
    "Oval": "Oval",
}

SURFACE_MAP = {
    "Tarmac": "Tarmac/Paved",
    "Dirt": "Shale/Dirt/Grass",
}

WEATHER_MAP = {"Dry": "Dry", "Wet": "Wet"}

SECTION_MAP = {
    ("ENTRY", "UNDERSTEER"): ("Understeer", "Corner Entry"),
    ("MID", "UNDERSTEER"): ("Understeer", "Mid Corner"),
    ("EXIT", "UNDERSTEER"): ("Understeer", "Corner Exit"),
    ("ENTRY", "OVERSTEER"): ("Oversteer", "Corner Entry"),
    ("MID", "OVERSTEER"): ("Oversteer", "Mid Corner"),
    ("EXIT", "OVERSTEER"): ("Oversteer", "Corner Exit"),
}

PRIORITY_BASE = {"H": 3000, "M": 2000, "L": 1000}


def load_env():
    env = {}
    with open(".env", "r", encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            env[key.strip()] = value.strip().strip('"')
    return env


class SupabaseRest:
    def __init__(self, url, service_role_key):
        self.base_url = url.rstrip("/") + "/rest/v1"
        self.headers = {
            "apikey": service_role_key,
            "Authorization": f"Bearer {service_role_key}",
            "Content-Type": "application/json",
        }

    def get(self, table, query="select=*"):
        url = f"{self.base_url}/{table}?{query}"
        req = urllib.request.Request(url, headers=self.headers, method="GET")
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read().decode("utf-8"))

    def get_all(self, table, select_query="select=*"):
        all_rows = []
        offset = 0
        page_size = 1000

        while True:
            query = f"{select_query}&limit={page_size}&offset={offset}"
            rows = self.get(table, query)
            if not rows:
                break
            all_rows.extend(rows)
            if len(rows) < page_size:
                break
            offset += page_size

        return all_rows

    def post(self, table, payload, prefer="return=representation"):
        body = json.dumps(payload).encode("utf-8")
        headers = {
            **self.headers,
            "Prefer": prefer,
        }
        req = urllib.request.Request(
            f"{self.base_url}/{table}",
            headers=headers,
            data=body,
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                raw = resp.read().decode("utf-8")
                if not raw.strip():
                    return []
                return json.loads(raw)
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")
            raise RuntimeError(
                f"POST {table} failed with HTTP {exc.code}: {detail}. Payload: {json.dumps(payload, ensure_ascii=False)}"
            ) from exc


def parse_workbook(path):
    ns = {
        "a": "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
        "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
    }

    with zipfile.ZipFile(path) as zf:
        shared = []
        if "xl/sharedStrings.xml" in zf.namelist():
            root = ET.fromstring(zf.read("xl/sharedStrings.xml"))
            for si in root.findall("a:si", ns):
                shared.append("".join(t.text or "" for t in si.findall(".//a:t", ns)))

        workbook = ET.fromstring(zf.read("xl/workbook.xml"))
        rels = ET.fromstring(zf.read("xl/_rels/workbook.xml.rels"))
        relmap = {
            rel.attrib["Id"]: rel.attrib["Target"].lstrip("/") for rel in rels
        }

        def rows_for(sheet_name):
            for sheet in workbook.find("a:sheets", ns):
                if sheet.attrib["name"] != sheet_name:
                    continue
                target = relmap[
                    sheet.attrib[
                        "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id"
                    ]
                ]
                root = ET.fromstring(zf.read(target))
                rows = []
                for row in root.findall(".//a:sheetData/a:row", ns):
                    vals = {}
                    for cell in row.findall("a:c", ns):
                        ref = cell.attrib.get("r", "")
                        col_match = re.match(r"[A-Z]+", ref)
                        if not col_match:
                            continue
                        col = col_match.group(0)
                        cell_type = cell.attrib.get("t")
                        value = cell.find("a:v", ns)
                        text = ""
                        if cell_type == "s" and value is not None:
                            text = shared[int(value.text)]
                        elif cell_type == "inlineStr":
                            text = "".join(
                                t.text or "" for t in cell.findall(".//a:t", ns)
                            )
                        elif value is not None:
                            text = value.text or ""
                        vals[col] = text.strip()
                    rows.append(vals)
                return rows
            raise KeyError(sheet_name)

        combo_rows = rows_for("Combinations")
        combos = []
        for row in combo_rows[2:]:
            code = row.get("H")
            if not code:
                continue
            combos.append(
                {
                    "sheet_name": code,
                    "track_type": TRACK_MAP[row["B"]],
                    "surface_type": SURFACE_MAP[row["C"]],
                    "engine_position": row["D"],
                    "aerofoils": row["E"],
                    "weather_condition": WEATHER_MAP[row["F"]],
                    "drive_type": row["G"],
                }
            )

        recommendation_defs = OrderedDict()
        sets = []

        for combo in combos:
            current_section = None
            sequence = 0
            current_rows = []

            def flush_section():
                nonlocal sequence, current_rows, current_section
                if current_section is None or not current_rows:
                    current_rows = []
                    return

                symptom, issue = current_section
                title = (
                    f"CFG:{combo['sheet_name']} | {symptom} | {issue}"
                )
                link_priorities = {}

                for rec_row in current_rows:
                    category = "Primary" if rec_row["level"] == "PRIMARY" else "Secondary"
                    adjustment = rec_row["adjustment"]
                    reason = rec_row["reason"]
                    rec_key = (adjustment, reason, category)
                    if rec_key not in recommendation_defs:
                        recommendation_defs[rec_key] = {
                            "title": adjustment,
                            "details": reason,
                            "category": category,
                        }

                    sequence += 1
                    priority_order = PRIORITY_BASE[rec_row["priority"]] - sequence
                    existing_priority = link_priorities.get(rec_key)
                    if existing_priority is None or priority_order > existing_priority:
                        link_priorities[rec_key] = priority_order

                sets.append(
                    {
                        "title": title,
                        "symptom": symptom,
                        "issue": issue,
                        "preset": {
                            "track_type": combo["track_type"],
                            "surface_type": combo["surface_type"],
                            "weather_condition": combo["weather_condition"],
                        },
                        "links": [
                            {
                                "recommendation_key": rec_key,
                                "priority_order": priority_order,
                            }
                            for rec_key, priority_order in sorted(
                                link_priorities.items(),
                                key=lambda item: item[1],
                                reverse=True,
                            )
                        ],
                    }
                )
                current_rows = []

            for row in rows_for(combo["sheet_name"]):
                cell_a = row.get("A", "")
                if cell_a and ord(cell_a[0]) == SECTION_MARKER:
                    flush_section()
                    upper = cell_a.upper()
                    current_section = next(
                        (
                            value
                            for key, value in SECTION_MAP.items()
                            if key[0] in upper and key[1] in upper
                        ),
                        None,
                    )
                    continue

                level = row.get("B", "")
                if current_section and level in ("Secondary", "PRIMARY", "Primary"):
                    current_rows.append(
                        {
                            "level": level.upper(),
                            "priority": row.get("C", "").strip().upper(),
                            "adjustment": row.get("D", "").strip(),
                            "reason": row.get("E", "").strip(),
                        }
                    )

            flush_section()

    return {
        "combos": combos,
        "symptoms": SYMPTOM_DESCRIPTIONS,
        "issues": ISSUE_DESCRIPTIONS,
        "recommendations": list(recommendation_defs.values()),
        "recommendation_keys": list(recommendation_defs.keys()),
        "sets": sets,
    }


def ensure_map(rows, key_fn):
    return {key_fn(row): row for row in rows}


def seed(rest, dataset):
    symptoms = rest.get_all("chassis_symptoms", "select=id,title,description,is_active")
    symptom_map = ensure_map(symptoms, lambda row: row["title"].strip().lower())

    symptom_inserts = []
    for title, description in dataset["symptoms"].items():
        key = title.lower()
        if key not in symptom_map:
            symptom_inserts.append(
                {"title": title, "description": description, "is_active": True}
            )
    if symptom_inserts:
        created_rows = rest.post("chassis_symptoms", symptom_inserts)
        for created in created_rows:
            symptom_map[created["title"].strip().lower()] = created

    issue_rows = rest.get_all(
        "chassis_issue_options",
        "select=id,symptom_id,title,description,is_active",
    )
    issue_map = ensure_map(
        issue_rows,
        lambda row: (row["symptom_id"], row["title"].strip().lower()),
    )

    issue_inserts = []
    for symptom_title in dataset["symptoms"]:
        symptom_id = symptom_map[symptom_title.lower()]["id"]
        for issue_title, issue_description in dataset["issues"].items():
            key = (symptom_id, issue_title.lower())
            if key not in issue_map:
                issue_inserts.append(
                    {
                        "symptom_id": symptom_id,
                        "title": issue_title,
                        "description": issue_description,
                        "is_active": True,
                    }
                )
    if issue_inserts:
        created_rows = rest.post("chassis_issue_options", issue_inserts)
        for created in created_rows:
            issue_map[
                (created["symptom_id"], created["title"].strip().lower())
            ] = created

    preset_rows = rest.get_all(
        "track_config_presets",
        "select=id,track_type,surface_type,weather_condition",
    )
    preset_map = ensure_map(
        preset_rows,
        lambda row: (
            row["track_type"],
            row["surface_type"],
            row["weather_condition"],
        ),
    )

    coarse_presets = OrderedDict()
    for combo in dataset["combos"]:
        key = (
            combo["track_type"],
            combo["surface_type"],
            combo["weather_condition"],
        )
        coarse_presets[key] = {
            "track_type": combo["track_type"],
            "surface_type": combo["surface_type"],
            "weather_condition": combo["weather_condition"],
        }

    preset_inserts = []
    for key, payload in coarse_presets.items():
        if key not in preset_map:
            preset_inserts.append(payload)
    if preset_inserts:
        created_rows = rest.post("track_config_presets", preset_inserts)
        for created in created_rows:
            preset_map[
                (
                    created["track_type"],
                    created["surface_type"],
                    created["weather_condition"],
                )
            ] = created

    recommendation_rows = rest.get_all(
        "adjustment_recommendations",
        "select=id,title,details,category",
    )
    recommendation_map = ensure_map(
        recommendation_rows,
        lambda row: (
            row["title"].strip(),
            row["details"].strip(),
            (row.get("category") or "").strip(),
        ),
    )

    recommendation_inserts = []
    for recommendation in dataset["recommendations"]:
        key = (
            recommendation["title"],
            recommendation["details"],
            recommendation["category"],
        )
        if key not in recommendation_map:
            recommendation_inserts.append(recommendation)
    if recommendation_inserts:
        created_rows = rest.post("adjustment_recommendations", recommendation_inserts)
        for created in created_rows:
            recommendation_map[
                (
                    created["title"].strip(),
                    created["details"].strip(),
                    (created.get("category") or "").strip(),
                )
            ] = created

    set_rows = rest.get_all(
        "chassis_adjustment_sets",
        "select=id,title,symptom_id,is_active",
    )
    set_map = ensure_map(set_rows, lambda row: row["title"])

    set_inserts = []
    for set_payload in dataset["sets"]:
        symptom_id = symptom_map[set_payload["symptom"].lower()]["id"]
        if set_payload["title"] not in set_map:
            set_inserts.append(
                {
                    "title": set_payload["title"],
                    "symptom_id": symptom_id,
                    "is_active": True,
                }
            )
    if set_inserts:
        created_rows = rest.post("chassis_adjustment_sets", set_inserts)
        for created in created_rows:
            set_map[created["title"]] = created

    set_issue_rows = rest.get_all(
        "chassis_adjustment_set_issue_options",
        "select=set_id,issue_option_id",
    )
    set_issue_map = {
        (row["set_id"], row["issue_option_id"]) for row in set_issue_rows
    }

    set_preset_rows = rest.get_all(
        "chassis_adjustment_set_track_presets",
        "select=set_id,preset_id",
    )
    set_preset_map = {(row["set_id"], row["preset_id"]) for row in set_preset_rows}

    set_recommendation_rows = rest.get_all(
        "chassis_adjustment_set_recommendations",
        "select=set_id,recommendation_id,priority_order",
    )
    set_recommendation_map = {
        (row["set_id"], row["recommendation_id"]): row["priority_order"]
        for row in set_recommendation_rows
    }

    issue_link_inserts = []
    preset_link_inserts = []
    recommendation_link_inserts = []

    for set_payload in dataset["sets"]:
        set_id = set_map[set_payload["title"]]["id"]
        symptom_id = symptom_map[set_payload["symptom"].lower()]["id"]
        issue_id = issue_map[(symptom_id, set_payload["issue"].lower())]["id"]
        preset_id = preset_map[
            (
                set_payload["preset"]["track_type"],
                set_payload["preset"]["surface_type"],
                set_payload["preset"]["weather_condition"],
            )
        ]["id"]

        if (set_id, issue_id) not in set_issue_map:
            issue_link_inserts.append({"set_id": set_id, "issue_option_id": issue_id})
            set_issue_map.add((set_id, issue_id))

        if (set_id, preset_id) not in set_preset_map:
            preset_link_inserts.append({"set_id": set_id, "preset_id": preset_id})
            set_preset_map.add((set_id, preset_id))

        for link in set_payload["links"]:
            recommendation_key = (
                link["recommendation_key"][0],
                link["recommendation_key"][1],
                link["recommendation_key"][2],
            )
            recommendation_id = recommendation_map[recommendation_key]["id"]
            link_key = (set_id, recommendation_id)
            existing_priority = set_recommendation_map.get(link_key)
            if existing_priority is not None:
                continue
            recommendation_link_inserts.append(
                {
                    "set_id": set_id,
                    "recommendation_id": recommendation_id,
                    "priority_order": link["priority_order"],
                }
            )
            set_recommendation_map[link_key] = link["priority_order"]

    if issue_link_inserts:
        rest.post(
            "chassis_adjustment_set_issue_options",
            issue_link_inserts,
            prefer="return=minimal",
        )
    if preset_link_inserts:
        rest.post(
            "chassis_adjustment_set_track_presets",
            preset_link_inserts,
            prefer="return=minimal",
        )
    if recommendation_link_inserts:
        rest.post(
            "chassis_adjustment_set_recommendations",
            recommendation_link_inserts,
            prefer="return=minimal",
        )

    return {
        "symptoms": len(symptom_map),
        "issues": len(issue_map),
        "presets": len(preset_map),
        "recommendations": len(recommendation_map),
        "sets": len(set_map),
        "set_issue_links": len(set_issue_map),
        "set_preset_links": len(set_preset_map),
        "set_recommendation_links": len(set_recommendation_map),
    }


def main():
    if not os.path.exists(WORKBOOK_PATH):
        print(f"Workbook not found: {WORKBOOK_PATH}", file=sys.stderr)
        sys.exit(1)

    env = load_env()
    url = env.get("SUPABASE_URL")
    key = env.get("SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key:
        print("SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY missing in .env", file=sys.stderr)
        sys.exit(1)

    dataset = parse_workbook(WORKBOOK_PATH)
    with open("scripts/chassis_advice_seed_preview.json", "w", encoding="utf-8") as f:
        json.dump(
            {
                "combo_count": len(dataset["combos"]),
                "symptom_count": len(dataset["symptoms"]),
                "issue_count": len(dataset["issues"]),
                "recommendation_count": len(dataset["recommendations"]),
                "set_count": len(dataset["sets"]),
                "first_sets": dataset["sets"][:3],
            },
            f,
            ensure_ascii=False,
            indent=2,
        )

    rest = SupabaseRest(url, key)
    summary = seed(rest, dataset)
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
