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
