# Test fixtures

## Redmine 1031, specimen search SQL baseline

Two artifacts capturing what `/includes/SearchSql.cfm` generated **before** its
criteria assembly was parameterized, produced by `/tools/searchSqlBaseline.cfm`
and committed unedited.

| file | what it is |
|---|---|
| `searchSql_baseline_before.txt` | full report: every entry with its constructed query |
| `searchSql_baseline_before_hashes.tsv` | same run with `?showSql=0`: the compact one line per entry form |

Capture conditions, which have to be matched for a later run to be comparable:

- captured 2026-09-02 from commit `0b756c2994`
- `session.flatTableName` = `flat`, i.e. an **internal** user. External users get
  `filtered_flat`, and that token appears throughout the generated SQL.
  `SearchSql.cfm` never branches on its value, only interpolates it as an
  identifier, so it is the only difference between the two user classes.
- corpus: the 523 saved searches in `cf_canned_search` whose URL targets
  `SpecimenResults.cfm`
- result: 523 OK, 0 ABORTED, 0 ERROR

### Reading a report

Summary lines are `seq, canned_id, status, sqlHash, criteria, note`, tab
separated. `grep "^[0-9]"` selects them alone. In the full report each summary
line is followed by a tab-indented block holding the section of the report that
the hash covers: `basJoin`, `basWhere`, `basOrder`, `basQual` and `mapurl`.

`sqlHash` is the MD5 of that block. Header lines that legitimately differ
between runs, such as the run label and the session roles, are outside the
hashed range, so a hash change always means the generated SQL actually moved.

### Using it to verify phase 3

Re-run `/tools/searchSqlBaseline.cfm` after the criteria assembly has been
parameterized, as the same user class, and compare against
`searchSql_baseline_before_hashes.tsv` keyed on `canned_id`, not on `seq`: the
corpus shifts whenever anyone saves or deletes a search.

Every entry whose hash moved is a behaviour change that has to be explained
before phase 3 can be called done. Some are expected — binding a value changes
the SQL text even when the semantics are identical — so the check is not "no
hashes moved" but "every moved hash is accounted for". That is what the full
report is for: the earlier SQL cannot be reproduced once phase 3 has landed
without checking out this commit, so it is kept here to be diffed against the
new query directly.

Two quirks the baseline exposed, both to be dealt with in phase 5 rather than
carried forward:

- `SearchSql.cfm:798` hardcodes `&searchUnaccepted=Yes` into `mapurl` whenever
  `any_taxa_term` is supplied, regardless of what was asked for. Nothing in the
  codebase reads that parameter back, so it is inert, but it has propagated into
  many stored saved-search URLs.
- The `ShowObservations` url parameter is ignored. `SearchSql.cfm:277` consults
  `session.ShowObservations` instead. Saved searches differing only in that
  parameter therefore produce identical SQL, which accounts for several of the
  six hashes that appear more than once among the 523 entries. The rest are
  duplicate saved searches.

## Comparing two baselines

`tests/compareSearchSqlBaselines.py` performs the comparison that hashes cannot.
Once a criteria block binds its value the hash necessarily moves, so hash
equality can only confirm that nothing changed, never that a change was
harmless. The script substitutes each bound value back into the predicate it
came from and compares that against the literal predicate text of an earlier
baseline, treating a difference in AND clause order as equivalent — a converted
clause leaves `basQual` and is appended from `whereClauses` at the end, so
AND-ed predicates move position without changing meaning.

```bash
python3 tests/compareSearchSqlBaselines.py \
	tests/fixtures/searchSql_baseline_before.txt \
	tests/fixtures/searchSql_baseline_<commit>.txt
```

It exits non-zero if any entry differs by more than clause order. Run it against
`searchSql_baseline_before.txt` rather than against the immediately preceding
baseline, so that the check is always against the original unparameterized SQL
rather than against an intermediate state.

## Result at 715147e7e6

The baseline captured at `715147e7e6`, the point at which every criteria block
except the `catnum` helpers binds its values, compares clean against the
pre-conversion baseline:

```
compared 523 corpus entries
  predicate identical                        : 523
  predicate identical up to AND clause order : 0
  predicate DIFFERS                          : 0
```

Every hash moved from the preceding baseline, as expected: this is the commit
that converted `collection_cde not in ('HerpOBS')`, a predicate that fires for
every entry in the corpus. The clause ordering that made six entries differ at
`bfdcb20eae` resolved itself here, because with only `catnum` left on the string
path there is no longer an unconverted predicate for a converted one to be
reordered around.

Across the corpus this baseline carries 1079 bound parameters over 1331 clauses,
against 489 of each at `bfdcb20eae`. Scanning it for any supplied criteria value
that still reaches the SQL as a quoted literal returns `catnum` alone.

Note the corpus exercises 45 of the 163 criteria names `SearchSql.cfm` tests for.
A clean comparison is therefore strong evidence about those 45 and says nothing
about the rest, which need to be checked by hand.

## Result at 2550dee4ba

The baseline captured after `basQual` was removed and the last criteria bound.
It compares clean against the pre-conversion baseline:

```
compared 523 corpus entries
  predicate identical                        : 523
  predicate identical up to AND clause order : 0
  predicate DIFFERS                          : 0
```

223 hashes moved against `715147e7e6`. 222 of those entries carry a `catnum` or
`searchOtherIDs` criterion, whose clause moved out of `basQual` and into the
clause array, changing the clause list the report prints. The 223rd is entry 21,
which supplies `listcatnum`; `SearchSql.cfm` assigns that to `catnum` and it
takes the same path. No entry carrying one of those criteria failed to move.

Bound parameters went from 1079 to 1082, one for each of the three corpus
entries that use `searchOtherIDs`, whose other-identifier predicates previously
interpolated raw list elements into quoted literals.

Scanning for a supplied criteria value still reaching the SQL as a literal
returns two entries, both `catnum`, both the `cat_num_prefix` literal that
`listcatnumToBasQualTable` emits. That helper whitelists its input to digits,
letters, percent, comma and hyphen, so no quote can survive it; see the unit
tests in `tests/TestListcatnumToBasQual.cfc`.

## Result at fe1302b9aa

Captured after `checkSql` was removed from the callers, four criteria gates were
given a length test beside their `isdefined`, and the criteria were copied out of
the url and form scopes into the variables scope explicitly. Compares clean
against the pre-conversion baseline:

```
compared 523 corpus entries
  predicate identical                        : 523
  predicate identical up to AND clause order : 0
  predicate DIFFERS                          : 0
```

Three hashes moved against `2550dee4ba`, entries 58, 59 and 111, each of which
supplies `CustomOidOper` with an empty value. The difference is confined to
`mapurl`, which now records `CustomOidOper=LIKE` where it previously recorded an
empty value: the gate that defaults the operator to `LIKE` now fires for an
empty value as well as an absent one. The SQL is unchanged, because the operator
branches already end in a catch-all `<cfelse>` that produces the `LIKE`
predicate, so an empty operator was never dropped from the statement.

Note this baseline cannot exercise the url and form population loop. The driver
sets criteria in the variables scope and includes the file directly, so the loop
finds nothing in either request scope and leaves those values alone. A clean
comparison here shows the include path is unchanged and says nothing about the
loop, which needs checking through real GET and POST requests.
