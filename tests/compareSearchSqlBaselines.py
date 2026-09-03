#!/usr/bin/env python3
#
# tests/compareSearchSqlBaselines.py
#
# Copyright 2026 President and Fellows of Harvard College
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Compare two /tools/searchSqlBaseline.cfm reports for behaviour change.

Hash equality only shows that nothing moved.  Once a criteria block binds its value,
the hash necessarily moves, so hashes cannot show that the move was harmless.  This
script substitutes each bound value back into the predicate text it came from and
compares the result against the literal predicate text of an earlier baseline.  Two
baselines agree when every corpus entry yields the same predicate, allowing for the
reordering that binding causes: a converted clause leaves basQual and is appended
from whereClauses at the end, so AND-ed predicates change position but not meaning.

Usage:
    python3 tests/compareSearchSqlBaselines.py <before.txt> <after.txt> [maxDetail]

Exits non-zero if any entry differs by more than AND-clause order.
"""

import html
import io
import re
import sys

PARAM = re.compile(r"([A-Za-z_][A-Za-z0-9_]*)\s*\|\s*(CF_SQL_\w+|)\s*\|\s*list=(true|false)\s*\|\s*")
SUMMARY = re.compile(r"^(\d+)\t(\d+)\t(\S+)\t(\S+)\t(.*?)\t*$")
NUMERIC = ("DECIMAL", "INTEGER", "BIGINT", "DOUBLE", "FLOAT", "NUMERIC")


def parseBaseline(path):
    """Read a baseline report into a mapping of sequence number to entry.

    @param path the baseline report file, as saved from the browser.
    @return a dict of sequence number to {crit, basQual, params}.
    """
    text = html.unescape(io.open(path, encoding="utf-8").read())
    entries = {}
    current = None
    for line in text.split("\n"):
        summary = SUMMARY.match(line)
        if summary:
            current = {"seq": int(summary.group(1)), "crit": summary.group(5),
                       "basQual": "", "paramText": "", "section": None}
            entries[current["seq"]] = current
            continue
        if current is None:
            continue
        stripped = line.strip()
        if stripped.startswith("--- "):
            if stripped.startswith("--- basQual"):
                current["section"] = "basQual"
            elif stripped.startswith("--- sqlParams"):
                current["section"] = "params"
            else:
                current["section"] = None
            continue
        if not stripped:
            continue
        if current["section"] == "basQual":
            current["basQual"] += " " + stripped
        elif current["section"] == "params":
            current["paramText"] += " " + stripped
    # The report packs several parameters onto one physical line, so the boundary
    # between one parameter's value and the next parameter's name is the header
    # pattern itself rather than a line break.
    for entry in entries.values():
        entry["params"] = {}
        headers = list(PARAM.finditer(entry["paramText"]))
        for index, header in enumerate(headers):
            end = headers[index + 1].start() if index + 1 < len(headers) else len(entry["paramText"])
            entry["params"][header.group(1)] = {
                "type": header.group(2),
                "list": header.group(3),
                "value": entry["paramText"][header.end():end].rstrip(),
            }
    return entries


def renderAsLiteral(param):
    """Render a bound parameter the way the unparameterized code would have written it.

    @param param a dict of type, list and value as printed by the harness.
    @return SQL literal text.
    """
    numeric = any(n in param["type"] for n in NUMERIC)
    if param["list"] == "true":
        values = [v.strip() for v in param["value"].split(",")]
        return ",".join(values) if numeric else ",".join("'%s'" % v for v in values)
    return param["value"] if numeric else "'%s'" % param["value"]


def substituteBinds(entry):
    """Replace every :name token in an entry's predicate with its bound value.

    Longest name first, so that :foo_1 is not consumed by a shorter :foo.

    @param entry an entry from parseBaseline.
    @return the predicate text with binds resolved to literals.
    """
    predicate = entry["basQual"]
    for name in sorted(entry["params"], key=len, reverse=True):
        predicate = predicate.replace(":" + name, renderAsLiteral(entry["params"][name]))
    return predicate


def collapseWhitespace(sql):
    return re.sub(r"\s+", " ", sql).strip().lower()


def splitTopLevelPredicates(sql):
    """Split a predicate string on its top level AND operators.

    Parenthesized subqueries are kept whole, and the AND belonging to a BETWEEN is
    not a separator.

    @param sql predicate text.
    @return a sorted list of whitespace-free predicate atoms.
    """
    sql = collapseWhitespace(sql)
    if sql.startswith("and "):
        sql = sql[4:]
    atoms = []
    depth = 0
    current = ""
    pendingBetween = 0
    i = 0
    while i < len(sql):
        char = sql[i]
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
        if sql[i:i + 8] == " between":
            pendingBetween += 1
        if depth == 0 and sql[i:i + 5] == " and ":
            if pendingBetween:
                pendingBetween -= 1
            else:
                atoms.append(current.strip())
                current = ""
                i += 5
                continue
        current += char
        i += 1
    atoms.append(current.strip())
    return sorted(re.sub(r"\s", "", a) for a in atoms if a.strip())


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    before = parseBaseline(sys.argv[1])
    after = parseBaseline(sys.argv[2])
    maxDetail = int(sys.argv[3]) if len(sys.argv) > 3 else 8

    identical = reordered = 0
    differing = []
    missing = []
    for seq in sorted(before):
        if seq not in after:
            missing.append(seq)
            continue
        beforeSql = before[seq]["basQual"]
        afterSql = substituteBinds(after[seq])
        if re.sub(r"\s", "", collapseWhitespace(beforeSql)) == re.sub(r"\s", "", collapseWhitespace(afterSql)):
            identical += 1
        elif splitTopLevelPredicates(beforeSql) == splitTopLevelPredicates(afterSql):
            reordered += 1
        else:
            differing.append((seq, after[seq]["crit"], beforeSql, afterSql))

    total = identical + reordered + len(differing)
    print("compared %d corpus entries" % total)
    print("  predicate identical                        : %d" % identical)
    print("  predicate identical up to AND clause order : %d" % reordered)
    print("  predicate DIFFERS                          : %d" % len(differing))
    if missing:
        print("  absent from the after baseline             : %d %s" % (len(missing), missing[:20]))

    for seq, crit, beforeSql, afterSql in differing[:maxDetail]:
        print("\n  entry %d  criteria=%s" % (seq, crit[:90]))
        beforeAtoms = set(splitTopLevelPredicates(beforeSql))
        afterAtoms = set(splitTopLevelPredicates(afterSql))
        for atom in sorted(beforeAtoms - afterAtoms):
            print("     only before: " + atom[:200])
        for atom in sorted(afterAtoms - beforeAtoms):
            print("     only after : " + atom[:200])

    sys.exit(1 if (differing or missing) else 0)


if __name__ == "__main__":
    main()
