<cfset pageTitle = "Manage Controlled Vocabularies">
<!---
/vocabularies/manageControlledVocabulary.cfm

Manage controlled vocabulary (code table) values. Provides list view of all CT* tables
and edit/add/delete forms for each, replacing /CodeTableEditor.cfm.

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2026 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--->
<!---

MAINTAINABILITY REFERENCE: manageControlledVocabulary.cfm
==========================================================

This file provides a list view of all CT* (code table) database tables and a
unified edit/add/delete interface for each. It replaces the legacy
/CodeTableEditor.cfm page. The entry point for editing a table is:
  /vocabularies/manageControlledVocabulary.cfm?action=edit&tbl=<TABLENAME>

The file uses three handling approaches for different tables:

--------------------------------------------------------------------------------
1. EXTERNALLY MANAGED - handled by cflocation redirect to another page
--------------------------------------------------------------------------------
These tables have dedicated UIs elsewhere; this file redirects to those pages
when selected from the list.

  CTGEOLOGY_ATTRIBUTE_HIERARCHY  -> /vocabularies/GeologicalHierarchies.cfm
    Reason: Hierarchical/tree structure requires dedicated tree-editing UI.

  CTJOURNAL_NAME                 -> /publications/Journals.cfm
    Reason: Journal name management is integrated with publication management
            and requires a dedicated search/picker UI.

  ctspecimen_part_name           -> /vocabularies/ctspecimen_part_name.cfm
    Reason: Has a boolean is_tissue field, per-collection scoping, and uses
            a jquery-ui dialog for edit and AJAX for delete; dedicated page.

  ctspec_part_att_att            -> /vocabularies/ctspec_part_att_att.cfm
    Reason: Maps attribute types to code tables (value + unit selects populated
            from all CT* tables); dedicated page.

  ctmedia_license                -> /vocabularies/ctmedia_license.cfm
    Reason: Has dedicated display/description/URI fields not in the generic
            pattern; dedicated page.

--------------------------------------------------------------------------------
2. INLINE SPECIAL CASES - handled by tbl-specific branches in this file
--------------------------------------------------------------------------------
These tables require custom form layouts, hard-coded domain selects, cross-table
FK selects, or essential contextual help text that cannot be inferred from
schema metadata alone.

  ctattribute_code_tables
    Reason: Composite PK (attribute_type + optional code table references);
            two FK selects (value_code_table, units_code_table) populated from
            all CT* tables; NULL handling in composite WHERE clauses.

  ctcountry_code
    Reason: Two-column layout (code + country); country is the natural PK
            value but code is the functional key. Clear separation needed.

  ctguid_type
    Reason: Eight specialized fields including pattern_regex, resolver_regex,
            resolver_replacement, and search_uri with contextual explanations
            that are essential for correct data entry. Not inferable from schema.

  ctloan_type
    Reason: Hard-coded scope select domain (Loan/Gift). The two-value domain
            is not stored in the schema and is functionally significant.

  ctspecific_permit_type
    Reason: FK select for permit_type (from ctpermit_type); boolean select
            for accn_show_on_shipment. Cannot infer domain from schema.

  CTAUTHORSHIP_ROLE
    Reason: FK select for nomenclatural_code (from ctnomenclatural_code);
            ordinal field with integer semantics.

  ctcitation_type_status
    Reason: Hard-coded category select (Primary/Secondary/Voucher/Voucher Not)
            with specific sort-order semantics; values are not in schema.
            NOTE: If new categories are added, update BOTH the add and edit
            picklists in this file.

  ctgeology_attributes
    Reason: Hard-coded type select (lithologic/lithostratigraphic/
            chronostratigraphic). Values are not stored in schema.
            NOTE: If new type values are added, update BOTH picklists.

  ctpublication_attribute
    Reason: FK select for control (from all CT* tables); extra field
            (mcz_publication_fg) with decimal semantics.

  ctbiol_relations
    Reason: Hard-coded rel_type select (biological/curatorial/functional).
            Values are semantically significant and not in schema.

  ctcoll_other_id_type
    Reason: Boolean select for encumber_as_field_num; boolean semantics
            need a select for clarity rather than a text input.

  cttaxon_relation
    Reason: Delete is suppressed when taxon_relations usage count > 0;
            this business rule requires the join and conditional button logic.

  ctnomenclatural_code
    Reason: Has sort_order (integer) field with numeric ordering semantics.

  ctspecimen_part_list_order
    Reason: Composite PK (partname + list_order); partname select is
            populated from ctspecimen_part_name (cross-table FK).

  ctunderscore_collection_type
    Reason: Retained for contextual description text ("Types of Named Groups
            of Cataloged Items") that is operationally important.

  ctunderscore_coll_agent_role
    Reason: Has ordinal (integer) field and label/inverse_label fields with
            specific semantics.

  ctmedia_relationship
    Reason: Essential help text ("Last word in Media Relationship must be a
            table name... Adding new relationship also involves code changes
            to MCZBASE.get_media_descriptor and MCZBASE.get_media_title")
            cannot be lost; code-change warnings require inline documentation.

  CTTAXON_CATEGORY
    Reason: hidden_fg boolean select; category_type field with specific
            functional meaning.

  CTTAXON_ATTRIBUTE_TYPE
    Reason: hidden_fg boolean select controlling public/hidden visibility.

  CTSTATE
    Reason: state_curie field with CURIE-format semantics; contextual
            explanation of CURIE format is important for correct data entry.

--------------------------------------------------------------------------------
3. GENERIC SCHEMA-DRIVEN HANDLING - the cfelse branch (line ~2049)
--------------------------------------------------------------------------------
All CT* tables not matched above fall through to generic handling, which:
  - Queries sys.user_tab_columns to discover all columns for the table.
  - Identifies the primary key column(s) via sys.user_constraints.
  - Identifies whether collection_cde and description columns are present.
  - Builds insert/update/delete queries dynamically using cfqueryparam.
  - Renders text inputs for all non-PK, non-collection_cde, non-description
    columns (labeled with column name).
  - Renders a collection_cde select (from ctcollection_cde) if present.
  - Renders a description textarea if present.

What generic handling supports without editing this file:
  - Adding new CT* tables with simple text/varchar fields and a single string PK.
  - Tables with an optional collection_cde column (automatically collection-scoped).
  - Tables with an optional description column (rendered as textarea).
  - Tables with a composite PK: all PK columns are included in WHERE clauses.
  - Tables with extra non-PK non-description columns: rendered as text inputs.

What still requires file edits:
  - Any table needing a hard-coded select domain (e.g., enum-like values).
  - Any table needing a cross-table FK select (populated from another table).
  - Any table with integer/numeric semantics (ordinal, boolean flags) that
    should be selects or validated as numbers rather than free-text inputs.
  - Any table requiring contextual help text, field-level instructions, or
    business rule validation not expressible via schema constraints.
  - Any table with delete-protection rules (e.g., check usage count first).


--->
<cfinclude template="/shared/_header.cfm">
<script src="/lib/misc/sorttable.js"></script>
<cfquery name="ctcollcde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select distinct collection_cde from ctcollection_cde
</cfquery>
<cfset tbl="">
<cfset variables.hasGlobalAdmin = isdefined("session.roles") AND listfindnocase(session.roles,"global_admin")>
<!--- obtain tbl variable from form post or get parameter with url scope taking precedence, and force to uppercase --->
<cfif isdefined("url.tbl")>
	<cfset tbl = ucase(url.tbl)>
<cfelseif isdefined("form.tbl")>
	<cfset tbl = ucase(form.tbl)>
</cfif>
<cfif not isdefined("action")><cfset action="listTables"></cfif>
<cfif action is "entryPoint"><cfset action="listTables"></cfif>
<!--- TODO: Not all actions involve output, move them to a backing method put this block only in actions that have output --->
<cfoutput>
	<main id="content" aria-labelledby="pageHeading">
		<div class="container">
			<div class="row">
				<div class="col-12">

					<cfswitch expression="#action#">
						<cfcase value="listTables">
							<cfquery name="getCTName" datasource="uam_god">
								SELECT
									t.table_name,
									nvl(c.comments,'') comments,
									nvl(cc.has_collection_cde, 0) has_collection_cde,
									nvl(fk.inbound_fk_count, 0) inbound_fk_count,
									CASE WHEN nvl(pk.pk_col_count,0) > 1 THEN 1 ELSE 0 END composite_pk
								FROM (
									SELECT distinct(table_name) table_name
									FROM sys.user_tables
									WHERE table_name like 'CT%'
									UNION
									SELECT 'CTGEOLOGY_ATTRIBUTE_HIERARCHY' table_name FROM dual
								) t
								LEFT JOIN all_tab_comments c ON c.table_name = t.table_name AND c.owner = 'MCZBASE'
								LEFT JOIN (
									SELECT
										table_name,
										1 has_collection_cde
									FROM all_tab_columns
									WHERE
										owner = 'MCZBASE'
										AND table_name like 'CT%'
										AND column_name = 'COLLECTION_CDE'
								) cc ON cc.table_name = t.table_name
								LEFT JOIN (
									SELECT
										p.table_name,
										count(distinct fk.constraint_name) inbound_fk_count
									FROM all_constraints fk
									JOIN all_constraints p ON fk.r_owner = p.owner AND fk.r_constraint_name = p.constraint_name
									WHERE
										fk.owner = 'MCZBASE'
										AND fk.constraint_type = 'R'
										AND p.owner = 'MCZBASE'
									GROUP BY p.table_name
								) fk ON fk.table_name = t.table_name
								LEFT JOIN (
									SELECT
										ac.table_name,
										count(acc.column_name) pk_col_count
									FROM all_constraints ac
									JOIN all_cons_columns acc ON ac.owner = acc.owner AND ac.constraint_name = acc.constraint_name
									WHERE
										ac.owner = 'MCZBASE'
										AND ac.constraint_type = 'P'
									GROUP BY ac.table_name
								) pk ON pk.table_name = t.table_name
			 					ORDER BY t.table_name
							</cfquery>
							<!--- Pre-compute edit permissions for the 5 externally managed vocabulary pages.
								  Uses the same role-check logic as /CustomTags/rolecheck.cfm. --->
							<cfquery name="variables.qExtPerms" datasource="uam_god" cachedWithin="#CreateTimeSpan(0,1,0,0)#">
								SELECT DISTINCT form_path, role_name FROM cf_form_permissions
								WHERE form_path IN (<cfqueryparam cfsqltype="CF_SQL_VARCHAR"
									value="/vocabularies/GeologicalHierarchies.cfm,/publications/Journals.cfm,/vocabularies/ctspecimen_part_name.cfm,/vocabularies/ctspec_part_att_att.cfm,/vocabularies/ctmedia_license.cfm"
									list="yes">)
							</cfquery>
							<!--- Build form_path -> comma-separated required roles --->
							<cfset variables.extPathRoles = structNew()>
							<cfloop query="variables.qExtPerms">
								<cfif NOT structKeyExists(variables.extPathRoles, variables.qExtPerms.form_path)>
									<cfset variables.extPathRoles[variables.qExtPerms.form_path] = "">
								</cfif>
								<cfset variables.extPathRoles[variables.qExtPerms.form_path] = listAppend(variables.extPathRoles[variables.qExtPerms.form_path], variables.qExtPerms.role_name)>
							</cfloop>
							<!--- Default all 5 external tables to no-access; updated below where permissions exist --->
							<cfset variables.externalCanEdit = structNew()>
							<cfset variables.externalCanEdit["CTGEOLOGY_ATTRIBUTE_HIERARCHY"] = false>
							<cfset variables.externalCanEdit["CTJOURNAL_NAME"] = false>
							<cfset variables.externalCanEdit["CTSPECIMEN_PART_NAME"] = false>
							<cfset variables.externalCanEdit["CTSPEC_PART_ATT_ATT"] = false>
							<cfset variables.externalCanEdit["CTMEDIA_LICENSE"] = false>
							<cfset variables.extCheckMap = {
								"CTGEOLOGY_ATTRIBUTE_HIERARCHY": "/vocabularies/GeologicalHierarchies.cfm",
								"CTJOURNAL_NAME":                "/publications/Journals.cfm",
								"CTSPECIMEN_PART_NAME":          "/vocabularies/ctspecimen_part_name.cfm",
								"CTSPEC_PART_ATT_ATT":           "/vocabularies/ctspec_part_att_att.cfm",
								"CTMEDIA_LICENSE":               "/vocabularies/ctmedia_license.cfm"
							}>
							<cfloop collection="#variables.extCheckMap#" item="variables.extCheckTbl">
								<cfset variables.extCheckPath = variables.extCheckMap[variables.extCheckTbl]>
								<cfif structKeyExists(variables.extPathRoles, variables.extCheckPath)>
									<cfset variables.extCheckRoles = variables.extPathRoles[variables.extCheckPath]>
									<cfif listLen(variables.extCheckRoles) EQ 1 AND listFirst(variables.extCheckRoles) IS "public">
										<cfset variables.externalCanEdit[variables.extCheckTbl] = true>
									<cfelse>
										<cfset variables.extCheckOK = true>
										<cfloop list="#variables.extCheckRoles#" index="variables.extCheckRole">
											<cfif NOT listfindnocase(session.roles, variables.extCheckRole)>
												<cfset variables.extCheckOK = false>
											</cfif>
										</cfloop>
										<cfset variables.externalCanEdit[variables.extCheckTbl] = variables.extCheckOK>
									</cfif>
								</cfif>
							</cfloop>
							<h1 id="pageHeading" class="h3 mt-2">Manage Controlled Vocabularies</h1>
							<section aria-labelledby="controlledVocabularyNotesHeading" class="my-2">
								<h2 id="controlledVocabularyNotesHeading" class="sr-only">Controlled Vocabulary Notes</h2>
								<div class="alert alert-info py-2 px-3 mb-2">
									<cfif variables.hasGlobalAdmin>
										<p class="mb-1 small">This table lists editable controlled vocabularies with metadata checks. <strong>Collection Specific</strong> is <strong>Yes</strong> when a table contains a <code>collection_cde</code> field.</p>
										<ul class="mb-0 small">
											<li><strong>Inbound FK Count</strong> is the number of incoming foreign keys to the table.</li>
											<li><strong>Composite PK</strong> is <strong>Yes</strong> when the table primary key has more than one column.</li>
											<li><strong>Status</strong> values:
												<ul class="mb-0">
													<li><span class="text-warning" aria-hidden="true">&##9888;</span><span class="sr-only">Warning</span> <strong>Deprecate</strong> for empty tables with no composite PK and no inbound FKs.</li>
													<li><span class="text-warning" aria-hidden="true">&##9888;</span><span class="sr-only">Warning</span> <strong>Add FKs</strong> for non-empty tables with no composite PK and no inbound FKs.</li>
												</ul>
											</li>
										</ul>
									<cfelse>
										<p class="mb-0 small">This table lists editable controlled vocabularies and in comments, descriptions of the vocabularies. In the MCZbase database, these controlled vocabularies are in tables prefixed with the letters CT (for Code Table), e.g. AGENT_RANK values are found in CTAGENT_RANK.</p>
										<ul class="mb-0 small">
											<li><strong>Collection Specific</strong> is <strong>Yes</strong> when a table contains a <code>collection_cde</code> field and can set collection specific values.</li>
											<li><strong>Records</strong> is the number of values in the controlled vocabulary table.</li>
											<li>Edit with care.  You should be able to safely add new values to department specific controlled vocabularies such as SEX_CDE to support new data entry needs for your collection.  Some controlled vocabularies are used for functional purposes and changing values may break functionality.  Changes to existing controlled values that are in use in other tables are likely to fail, and alterations to a controlled vocabulary will almost certainly involve a data cleanup project.  If you are unsure, please file a bug report.</li>
										</ul>
									</cfif>
								</div>
							</section>
							<section aria-labelledby="controlledVocabularyListHeading" class="my-2">
								<h2 id="controlledVocabularyListHeading" class="h5">Editable Controlled Vocabulary Tables</h2>
								<div class="table-responsive">
									<table id="controlledVocabularyListTable" class="sortable table table-striped table-sm d-xl-table">
										<thead>
											<tr>
												<th scope="col">Table</th>
												<th scope="col">Records</th>
												<th scope="col">Actions</th>
												<th scope="col">Comment</th>
												<th scope="col">Collection Specific</th>
												<cfif variables.hasGlobalAdmin>
													<th scope="col">Inbound FK Count</th>
													<th scope="col">Composite PK</th>
													<th scope="col">Status</th>
												</cfif>
											</tr>
										</thead>
										<tbody>
											<cfloop query="getCTName">
												<cfquery name="getRowCounts" datasource="uam_god">
													SELECT count(*) ct
													FROM
													<cfif getCTName.table_name is "CTGEOLOGY_ATTRIBUTE_HIERARCHY">
														GEOLOGY_ATTRIBUTE_HIERARCHY
													<cfelse>
														#getCTName.table_name#
													</cfif>
												</cfquery>
												<cfset variables.displayName = REReplace(getCTName.table_name,"^CT","") ><!--- strip CT from names in list for better readability --->
												<tr>
													<td>#variables.displayName#</td>
													<td>#getRowCounts.ct#</td>
													<td class="text-nowrap">
														<cfif structKeyExists(variables.externalCanEdit, getCTName.table_name) AND NOT variables.externalCanEdit[getCTName.table_name]>
															<span class="btn btn-xs btn-primary disabled" aria-disabled="true" title="You do not have permission to edit this vocabulary">Edit</span>
														<cfelse>
															<a href="/vocabularies/manageControlledVocabulary.cfm?action=edit&tbl=#getCTName.table_name#" class="btn btn-xs btn-primary">Edit</a>
														</cfif>
														<a href="/vocabularies/ControlledVocabulary.cfm?table=#getCTName.table_name#" class="btn btn-xs btn-outline-primary">View</a>
													</td>
													<td>
														<cfif len(trim(getCTName.comments)) GT 0>#getCTName.comments#</cfif>
													</td>
													<td>
														<cfif getCTName.has_collection_cde EQ 1>Yes</cfif>
													</td>
													<cfif variables.hasGlobalAdmin>
														<td>#getCTName.inbound_fk_count#</td>
														<td>
															<cfif getCTName.composite_pk EQ 1>Yes<cfelse>No</cfif>
														</td>
														<td>
															<cfif getCTName.inbound_fk_count EQ 0 AND getCTName.composite_pk EQ 0>
																<cfif getRowCounts.ct EQ 0>
																	<span class="text-warning" aria-hidden="true">&##9888;</span><span class="sr-only">Warning</span>&nbsp;Deprecate
																<cfelseif getRowCounts.ct GT 0>
																	<span class="text-warning" aria-hidden="true">&##9888;</span><span class="sr-only">Warning</span>&nbsp;Add&nbsp;FKs
																</cfif>
															</cfif>
														</td>
													</cfif>
												</tr>
											</cfloop>
										</tbody>
									</table>
								</div>
							</section>
						</cfcase>
					</cfswitch>

<cfif action is "edit">
	<cfset variables.editTitle = trim(replaceNoCase(REReplace(tbl, "(?i)^CT", ""), "_", " ", "ALL"))>
	<div class="d-flex justify-content-between align-items-center mt-3 mb-2">
		<h2 class="h4 mb-0">Edit: #variables.editTitle#</h2>
		<a href="/vocabularies/manageControlledVocabulary.cfm" class="btn btn-xs btn-outline-primary">Go to controlled vocabulary list</a>
	</div>
	<cfif tbl is "CTGEOLOGY_ATTRIBUTE_HIERARCHY"><!---------------------------------------------------->
		<cflocation url="/vocabularies/GeologicalHierarchies.cfm" addtoken="false">
	<cfelseif tbl is "CTJOURNAL_NAME"><!---------------------------------------------------->
		<cflocation url="/publications/Journals.cfm" addtoken="false">
	<cfelseif tbl is "ctspecimen_part_name"><!---------------------------------------------------->
		<cflocation url="/vocabularies/ctspecimen_part_name.cfm" addtoken="false">
	<cfelseif tbl is "ctspec_part_att_att"><!---------------------------------------------------->
		<cflocation url="/vocabularies/ctspec_part_att_att.cfm" addtoken="false">
	<cfelseif tbl is "ctmedia_license"><!---------------------------------------------------->
		<cflocation url="/vocabularies/ctmedia_license.cfm" addtoken="false">
	<!--- RETAINED SPECIAL CASE: Composite PK; two FK selects (value_code_table, units_code_table) from all CT* tables; NULL in composite WHERE clauses. --->
	<cfelseif tbl is "ctattribute_code_tables"><!---------------------------------------------------->
		<cfquery name="ctAttribute_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select distinct(attribute_type) from ctAttribute_type
		</cfquery>
		<cfquery name="thisRec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			Select * from ctattribute_code_tables
			order by attribute_type
		</cfquery>
		<cfquery name="allCTs" datasource="uam_god">
			select distinct(table_name) as tablename from sys.user_tables where table_name like 'CT%' order by table_name
		</cfquery>
		<h3 class="h5 mt-3 mb-2 text-success">Add Attribute Control</h3>
		<div class="row border rounded my-2 mx-1 p-2 bg-light">
			<form method="post" action="/vocabularies/manageControlledVocabulary.cfm">
				<input type="hidden" name="action" value="newValue">
				<input type="hidden" name="tbl" value="#tbl#">
				<div class="form-row mb-1">
					<div class="col">				
						<label class="form-label" for="add_attribute_type">Attribute</label>
						<select id="add_attribute_type" class="data-entry-select" name="attribute_type" size="1">
							<option value=""></option>
							<cfloop query="ctAttribute_type">
							<option 
								value="#ctAttribute_type.attribute_type#">#ctAttribute_type.attribute_type#</option>
							</cfloop>
						</select>
					</div>
					<div class="col">
						<label class="form-label" for="add_value_code_table">Value Controlled Vocabulary</label>
						<cfset thisValueTable = #thisRec.value_code_table#>
						<select id="add_value_code_table" class="data-entry-select" name="value_code_table" size="1">
							<option value="">none</option>
							<cfloop query="allCTs">
							<option 
							value="#allCTs.tablename#">#allCTs.tablename#</option>
							</cfloop>
						</select>			
					</div>
					<div class="col">
						<label class="form-label" for="add_units_code_table">Units Controlled Vocabulary</label>
						<cfset thisUnitsTable = #thisRec.units_code_table#>
						<select id="add_units_code_table" class="data-entry-select" name="units_code_table" size="1">
							<option value="">none</option>
							<cfloop query="allCTs">
							<option 
							value="#allCTs.tablename#">#allCTs.tablename#</option>
							</cfloop>
						</select>
					</div>
					<div class="col">
						<input type="submit" 
							value="Create" 
							class="btn btn-xs btn-secondary mt-4">	
					</div>
				</div>
			</form>
		</div>
		<h3 class="h5 mt-3 mb-2">Edit Attribute Controls</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
			<div class="d-table-row bg-light border-bottom">
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Attribute</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Value Controlled Vocabulary</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Units Controlled Vocabulary</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
			</div>
			<cfset i=1>
			<cfloop query="thisRec">
				<form class="d-table-row" name="att#i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
					<input type="hidden" name="action" value="">
					<input type="hidden" name="tbl" value="#tbl#">
					<input type="hidden" name="oldAttribute_type" value="#Attribute_type#">
					<input type="hidden" name="oldvalue_code_table" value="#value_code_table#">
					<input type="hidden" name="oldunits_code_table" value="#units_code_table#">
					<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
						<cfset thisAttType = #thisRec.attribute_type#>
							<select class="data-entry-select w-100" name="attribute_type" size="1">
								<option value=""></option>
								<cfloop query="ctAttribute_type">
								<option 
											<cfif #thisAttType# is "#ctAttribute_type.attribute_type#"> selected </cfif>value="#ctAttribute_type.attribute_type#">#ctAttribute_type.attribute_type#</option>
								</cfloop>
							</select>
					</div>
					<div class="d-table-cell py-1 pr-3 align-middle">
						<cfset thisValueTable = #thisRec.value_code_table#>
						<select class="data-entry-select" name="value_code_table" size="1">
							<option value="">none</option>
							<cfloop query="allCTs">
							<option 
							<cfif #thisValueTable# is "#allCTs.tablename#"> selected </cfif>value="#allCTs.tablename#">#allCTs.tablename#</option>
							</cfloop>
						</select>
					</div>
					<div class="d-table-cell py-1 pr-3 align-middle">
						<cfset thisUnitsTable = #thisRec.units_code_table#>
						<select class="data-entry-select" name="units_code_table" size="1">
							<option value="">none</option>
							<cfloop query="allCTs">
							<option 
							<cfif #thisUnitsTable# is "#allCTs.tablename#"> selected </cfif>value="#allCTs.tablename#">#allCTs.tablename#</option>
							</cfloop>
						</select>
					</div>
					<div class="d-table-cell py-1 align-middle text-nowrap">
						<input type="button" 
							value="Save" 
							class="btn btn-xs btn-primary"
						 	onclick="att#i#.action.value='saveEdit';submit();">	
						<input type="button" 
							value="Delete" 
							class="btn btn-xs btn-danger"
							onclick="att#i#.action.value='deleteValue';submit();">	
					</div>
				</form>
			<cfset i=#i#+1>
		</cfloop>
			</div>
		</div>
	<!--- RETAINED SPECIAL CASE: Dual-key layout (country + code); contextual help text about ISO codes and historical name exclusions. --->
	<cfelseif tbl is "ctcountry_code"><!---------------------------------------------------->
		<p>ISO 2 letter country codes for country names.  A country name can appear more than once to represent alternative forms of the name for the country, all mapping to the same country code, but each country name string must be unique.   Do not include strings which map onto historical country names which may map onto more than one current country, even if on ISO list (e.g. 'Congo').</p>
		<!---   Country/Country Code code table includes fields for country and country code, thus needs custom form  --->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select country, code from ctcountry_code order by code, country
		</cfquery>
		<h3 class="h5 mt-3 mb-2 text-success">Add Country Code</h3>
		<form name="newData" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="#tbl#">
			<div class="row border rounded my-2 mx-1 p-2 bg-light">
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_code">Country Code</label>
						<input id="add_code" class="data-entry-input reqdClr" type="text" name="code" maxlength="3" required>
					</div>
					<div class="col">
						<label class="form-label" for="add_newData">Country</label>
						<input id="add_newData" class="data-entry-input reqdClr" type="text" name="newData"  required>
					</div>
					<div class="col">
						<input type="submit" 
							value="Insert" 
							class="btn btn-xs btn-secondary mt-4">
					</div>
				</div>
			</div>
		</form>
		<h3 class="h5 mt-3 mb-2">Edit Country Codes</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
			<div class="d-table-row bg-light border-bottom">
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Country Code</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Country</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
			</div>
			<cfset i = 1>
			<cfloop query="q">
					<form class="d-table-row" name="#tbl##i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="#tbl#">
						<!---  Need to pass current value as it is the PK for the code table --->
						<input type="hidden" name="origData" value="#country#">
						<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
							<input class="data-entry-input w-100" type="text" name="code" value="#code#" maxlength="3">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input class="data-entry-input w-100" type="text" name="country" value="#country#">
						</div>
						<div class="d-table-cell py-1 align-middle text-nowrap">
							<input type="button" 
								value="Save" 
								class="btn btn-xs btn-primary"
								onclick="#tbl##i#.action.value='saveEdit';submit();">
							<input type="button" 
								value="Delete" 
								class="btn btn-xs btn-danger"
								onclick="#tbl##i#.action.value='deleteValue';submit();">
						</div>
					</form>
				<cfset i = #i#+1>
			</cfloop>
			</div>
		</div>

	<!--- RETAINED SPECIAL CASE: Eight specialized fields (pattern_regex, resolver_regex, resolver_replacement, search_uri, etc.) with per-field contextual help text. --->
	<cfelseif tbl is "ctguid_type"><!---------------------------------------------------->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select guid_type, description, applies_to, placeholder, pattern_regex, resolver_regex, resolver_replacement, search_uri
			from ctguid_type
			order by guid_type
		</cfquery>
		<h3 class="h5 mt-3 mb-2 text-success">Add GUID Type</h3>
		<form name="newData" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="#tbl#">
			<div class="row border rounded my-2 mx-1 p-2 bg-light">
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_guid_type">GUID Type</label>
						<input id="add_guid_type" type="text" name="newData" class="data-entry-input reqdClr w-100" required>
						<small class="form-text text-muted">Name for picklist</small>
					</div>
					<div class="col">
						<label class="form-label" for="add_description">Description</label>
						<input id="add_description" class="data-entry-input w-100" type="text" name="description">
					</div>
				</div>
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_applies_to">Applies To</label>
						<input id="add_applies_to" type="text" name="applies_to" class="data-entry-input reqdClr w-100" required>
						<small class="form-text text-muted">space delimited list of table.field</small>
					</div>
					<div class="col">
						<label class="form-label" for="add_placeholder">Placeholder</label>
						<input id="add_placeholder" class="data-entry-input w-100" type="text" name="placeholder">
						<small class="form-text text-muted">Hint for data entry, e.g. doi:</small>
					</div>
				</div>
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_pattern_regex">Pattern Regex</label>
						<input id="add_pattern_regex" type="text" name="pattern_regex" class="data-entry-input reqdClr w-100" required>
						<small class="form-text text-muted">To validate entry, e.g. ^doi:10[.].+$</small>
					</div>
					<div class="col">
						<label class="form-label" for="add_resolver_regex">Resolver Regex</label>
						<input id="add_resolver_regex" class="data-entry-input w-100" type="text" name="resolver_regex">
						<small class="form-text text-muted">Regex pattern for conversion to a uri, e.g. ^doi:</small>
					</div>
				</div>
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_resolver_replacement">Resolver Replacement</label>
						<input id="add_resolver_replacement" class="data-entry-input w-100" type="text" name="resolver_replacement">
						<small class="form-text text-muted">Replacement string for match to pattern, e.g. https://doi.org/</small>
					</div>
					<div class="col">
						<label class="form-label" for="add_search_uri">Search URI</label>
						<input id="add_search_uri" class="data-entry-input w-100" type="text" name="search_uri">
						<small class="form-text text-muted">URI for searching by text string (appended to end). Leave blank if not applicable.</small>
					</div>
				</div>
				<div class="form-row mb-1">
					<div class="col-auto">
						<input type="submit" 
							value="Insert" 
							class="btn btn-xs btn-secondary">
					</div>
				</div>
			</div>
		</form>
		<h3 class="h5 mt-3 mb-2">Edit GUID Types</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<cfset i = 1>
			<cfloop query="q">
					<form name="#tbl##i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="#tbl#">
						<!---  Need to pass current value as it is the PK for the code table --->
						<input type="hidden" name="origData" value="#guid_type#">
					<div class="row border rounded my-2 mx-1 p-2">
						<div class="form-row mb-1">
							<div class="col">GUID Type:</div>
							<div class="col">
								<input type="text" name="guid_type" value="#guid_type#" class="data-entry-input reqdClr" required >
							</div>
							<div class="col">Name for picklist</div>
						</div>
						<div class="form-row mb-1">
							<div class="col">Description:</div>
							<div class="col">
								<input class="data-entry-input" type="text" name="description" value="#description#" size="80">
							</div>
						</div>
						<div class="form-row mb-1">
							<div class="col">Applies to</div>
							<div class="col">
								<input type="text" name="applies_to" value="#applies_to#" size="80" class="data-entry-input reqdClr" required>
							</div>
							<div class="col">space delimited list of table.field</div>
						</div>
						<div class="form-row mb-1">
							<div class="col">Placeholder</div>
							<div class="col">
								<input class="data-entry-input" type="text" name="placeholder" value="#placeholder#" size="80" >
							</div>
							<div class="col">Hint for data entry, e.g. doi:</div>
						</div>
						<div class="form-row mb-1">
							<div class="col">Pattern Regex</div>
							<div class="col">
								<input type="text" name="pattern_regex" value="#pattern_regex#" size="80" class="data-entry-input reqdClr" required>
							</div>
							<div class="col">Regex to validate entry, e.g. ^doi:10[.].+$</div>
						</div>
						<div class="form-row mb-1">
							<div class="col">Resolver Regex</div>
							<div class="col">
								<input class="data-entry-input" type="text" name="resolver_regex" value="#resolver_regex#" size="80">
							</div>
							<div class="col">Regex pattern for conversion to a uri, e.g. ^doi:</div>
						</div>
						<div class="form-row mb-1">
							<div class="col">Resolver Replacement</div>
							<div class="col">
								<input class="data-entry-input" type="text" name="resolver_replacement" value="#resolver_replacement#" size="80">
							</div>
							<div class="col">Replacement string for match to pattern, e.g. https://doi.org/</div>
						</div>
						<div class="form-row mb-1">
							<div class="col">Search URI</div>
							<div class="col">
								<input class="data-entry-input" type="text" name="search_uri" value="#search_uri#" size="80">
							</div>
							<div class="col">URI where guid can be searched for by a relevant text string which is appended to the end of the specified URI, blank if no search by text function.</div>
						</div>
						<div class="form-row mb-1">
							<div class="col"></div>
							<div class="col">
								<input type="button" 
									value="Save" 
									class="btn btn-xs btn-primary"
									onclick="#tbl##i#.action.value='saveEdit';submit();">
							</div>
							<div class="col">
								<input type="button" 
									value="Delete" 
									class="btn btn-xs btn-danger"
									onclick="#tbl##i#.action.value='deleteValue';submit();">
							</div>
						</div>
					</div>
					</form>
				<cfset i = #i#+1>
			</cfloop>
		</div>

	<!--- RETAINED SPECIAL CASE: Hard-coded scope select domain (Loan/Gift); not stored in schema. --->
	<cfelseif tbl is "ctloan_type"><!---------------------------------------------------->
		<!---   Loan type code table includes fields for scope (loan or gift) and sort order, thus needs custom form  --->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select loan_type, scope, ordinal from ctloan_type order by scope desc, ordinal, loan_type
		</cfquery>
		<h3 class="h5 mt-3 mb-2 text-success">Add Loan Type</h3>
		<form name="newData" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="#tbl#">
			<div class="row border rounded my-2 mx-1 p-2 bg-light">
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_newData">Loan Type</label>
						<input id="add_newData" class="data-entry-input reqdClr" type="text" name="newData"  required>
					</div>
					<div class="col">
						<label class="form-label" for="add_scope">Loan/Gift</label>
						<select id="add_scope" class="data-entry-select reqdClr" name="scope" required>
							<option value="Loan">Loan</option>
							<option value="Gift">Gift</option>
						</select>
					</div>
					<div class="col">
						<label class="form-label" for="add_ordinal">Sort Order</label>
						<input id="add_ordinal" class="data-entry-input reqdClr" type="text" name="ordinal" required>
					</div>
					<div class="col">
						<input type="submit" 
							value="Insert" 
							class="btn btn-xs btn-secondary mt-4">
					</div>
				</div>
			</div>
		</form>
		<h3 class="h5 mt-3 mb-2">Edit Loan Types</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
			<div class="d-table-row bg-light border-bottom">
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Loan Type</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Loan/Gift</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Sort Order</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
			</div>
			<cfset i = 1>
			<cfloop query="q">
					<form class="d-table-row" name="#tbl##i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="#tbl#">
						<!---  Need to pass current value as it is the PK for the code table --->
						<input type="hidden" name="origData" value="#loan_type#">
						<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
							<input class="data-entry-input w-100" type="text" name="loan_type" value="#loan_type#">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<cfif scope EQ "Loan"> 
								<cfset scopeloanselected = "selected='selected'">
								<cfset scopegiftselected = "">
							<cfelse>
								<cfset scopeloanselected = "">
								<cfset scopegiftselected = "selected='selected'">
							</cfif>
							<select class="data-entry-select" name="scope">
								<option value="Loan" #scopeloanselected# >Loan</option>
								<option value="Gift" #scopegiftselected# >Gift</option>
							</select>
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input class="data-entry-input" type="text" name="ordinal" value="#ordinal#">
						</div>
						<div class="d-table-cell py-1 align-middle text-nowrap">
							<input type="button" 
								value="Save" 
								class="btn btn-xs btn-primary"
								onclick="#tbl##i#.action.value='saveEdit';submit();">
							<input type="button" 
								value="Delete" 
								class="btn btn-xs btn-danger"
								onclick="#tbl##i#.action.value='deleteValue';submit();">
						</div>
					</form>
				<cfset i = #i#+1>
			</cfloop>
			</div>
		</div>
	<!--- RETAINED SPECIAL CASE: FK select for permit_type from ctpermit_type; boolean select for accn_show_on_shipment. --->
	<cfelseif tbl is "ctspecific_permit_type">
		<!---------------------------------------------------->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select * from ctspecific_permit_type order by specific_type
		</cfquery>
		<cfquery name="ptypes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select permit_type from ctpermit_type order by permit_type
		</cfquery>
		<h2>Specific Types of Permissions and Rights documents (permits)</h2>
		<h3 class="h5 mt-3 mb-2 text-success">Add Specific Permit Type</h3>
		<form name="newData" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="ctspecific_permit_type">
			<div class="row border rounded my-2 mx-1 p-2 bg-light">
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_newData">Specific Type</label>
						<input id="add_newData" class="data-entry-input reqdClr" type="text" name="newData" size=80  required>
					</div>
					<div class="col">
						<label class="form-label" for="add_permit_type">General Type</label>
						<select id="add_permit_type" class="data-entry-select" name="permit_type">
							<option value=""></option>
							<cfloop query="ptypes">
								<option value="#permit_type#">#permit_type#</option>
							</cfloop>
						</select>
					</div>
					<div class="col">
						<label class="form-label" for="add_accn_show_on_shipment">Carry Accession Document to Loans</label>
						<select id="add_accn_show_on_shipment" class="data-entry-select" name="accn_show_on_shipment">
							<option value="1" selected="selected" >Yes</option>
							<option value="0">No</option>
						</select>
					</div>
					<div class="col">
						<input type="submit" 
							value="Insert" 
							class="btn btn-xs btn-secondary mt-4">
					</div>
				</div>
			</div>
		</form>
		<cfset i = 1>
		<h3 class="h5 mt-3 mb-2">Edit Specific Permit Types</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
			<div class="d-table-row bg-light border-bottom">
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Specific Type</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">General Type</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Carry Accession Document to Loans</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
			</div>
			<cfloop query="q">
					<form class="d-table-row" name="#tbl##i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="ctspecific_permit_type">
						<input type="hidden" name="origData" value="#q.specific_type#">
						<input type="hidden" name="fld" value="specific_type">
						<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
							<input class="data-entry-input w-100" type="text" name="specific_type" value="#q.specific_type#">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<select class="data-entry-select" name="permit_type">
								<option value=""></option>
								<cfloop query="ptypes" >
									<option <cfif q.permit_type is ptypes.permit_type > selected="selected" </cfif>value="#ptypes.permit_type#">#ptypes.permit_type#</option>
								</cfloop>
							</select>
						</div>				
						<div class="d-table-cell py-1 pr-3 align-middle">
							<select class="data-entry-select" name="accn_show_on_shipment">
								<option <cfif q.accn_show_on_shipment EQ 1 > selected="selected" </cfif>value="1">Yes</option>
								<option <cfif q.accn_show_on_shipment EQ 0 > selected="selected" </cfif>value="0">No</option>
							</select>
						</div>				
						<div class="d-table-cell py-1 align-middle text-nowrap">
							<input type="button" 
								value="Save" 
								class="btn btn-xs btn-primary"
								onclick="#tbl##i#.action.value='saveEdit';submit();">
							<input type="button" 
								value="Delete" 
								class="btn btn-xs btn-danger"
								onclick="#tbl##i#.action.value='deleteValue';submit();">
						</div>
					</form>
				<cfset i = #i#+1>
			</cfloop>
			</div>
		</div>
	<!--- RETAINED SPECIAL CASE: FK select for nomenclatural_code from ctnomenclatural_code; ordinal integer field. --->
	<cfelseif tbl is "CTAUTHORSHIP_ROLE"><!-------------------------------------------------------->
		<!--- Authorship Role code table includes fields for nomenclatural code and sort order, thus needs custom form  --->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT authorship_role, ordinal, nomenclatural_code, description	
			FROM ctauthorship_role 
			ORDER BY ordinal, authorship_role
		</cfquery>
		<cfquery name="getNomenclaturalCodes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select nomenclatural_code from ctnomenclatural_code order by nomenclatural_code
		</cfquery>
		<h2>Authorship roles for agents involved in creating scientific names</h2>
		<h3 class="h5 mt-3 mb-2 text-success">Add Authorship Role</h3>
		<form name="newData" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="#tbl#">
			<div class="row border rounded my-2 mx-1 p-2 bg-light">
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_newData">Authorship Role</label>
						<input id="add_newData" class="data-entry-input reqdClr" type="text" name="newData"  required>
					</div>
					<div class="col">
						<label class="form-label" for="add_ordinal">Sort Order</label>
						<input id="add_ordinal" class="data-entry-input" type="text" name="ordinal" pattern="\d*" title="Integer value only">
					</div>
					<div class="col">
						<label class="form-label" for="add_nomenclatural_code">Nomenclatural Code</label>
						<select id="add_nomenclatural_code" class="data-entry-select" name="nomenclatural_code" >
							<cfloop query="getNomenclaturalCodes">
								<option value="#nomenclatural_code#">#nomenclatural_code#</option>
							</cfloop>
						</select>
					</div>
					<div class="col">
						<label class="form-label" for="add_description">Description</label>
						<input id="add_description" class="data-entry-input" type="text" name="description" title="description">
					</div>
					<div class="col">
						<input type="submit" value="Insert" class="btn btn-xs btn-secondary mt-4">
					</div>
				</div>
			</div>
		</form>
		<h3 class="h5 mt-3 mb-2">Edit Authorship Roles</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
			<div class="d-table-row bg-light border-bottom">
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Authorship Role</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Sort Order</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Nomenclatural Code</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Description</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
			</div>
			<cfset i = 1>
			<cfloop query="q">
					<form class="d-table-row" name="#tbl##i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="#tbl#">
						<!---  Need to pass current value as it is the PK for the code table --->
						<input type="hidden" name="origData" value="#authorship_role#">
						<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
							<input class="data-entry-input w-100" type="text" name="authorship_role" value="#authorship_role#">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input class="data-entry-input" type="text" name="ordinal" value="#ordinal#" pattern="\d*" title="Integer value only">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<cfset thisNomenclaturalCode = #q.nomenclatural_code#>
							<select class="data-entry-select" name="nomenclatural_code" >
								<cfloop query="getNomenclaturalCodes">
									<cfif thisNomenclaturalCode is "#getNomenclaturalCodes.nomenclatural_code#" ><cfset selected="selected"><cfelse><cfset selected=""></cfif>
									<option value="#nomenclatural_code#" #selected#>#nomenclatural_code#</option>
								</cfloop>
							</select>
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input class="data-entry-input" type="text" name="description" value="#description#">
						</div>
						<div class="d-table-cell py-1 align-middle text-nowrap">
							<input type="button" 
								value="Save" 
								class="btn btn-xs btn-primary"
								onclick="#tbl##i#.action.value='saveEdit';submit();">
							<input type="button" 
								value="Delete" 
								class="btn btn-xs btn-danger"
								onclick="#tbl##i#.action.value='deleteValue';submit();">
						</div>
					</form>
				<cfset i = #i#+1>
			</cfloop>
			</div>
		</div>
	<!--- RETAINED SPECIAL CASE: Hard-coded category select (Primary/Secondary/Voucher/Voucher Not); values not in schema. --->
	<cfelseif tbl is "ctcitation_type_status"><!---------------------------------------------------->
		<!---  Type status code table includes fields for category and sort order, thus needs custom form  --->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT type_status, description, category, ordinal 
			FROM ctcitation_type_status 
			ORDER by category, ordinal, type_status
		</cfquery>
		<h2>Citation type, type status terms and other kinds of citation</h2>
		<h3 class="h5 mt-3 mb-2 text-success">Add Citation Type Status</h3>
		<form name="newData" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="#tbl#">
			<div class="row border rounded my-2 mx-1 p-2 bg-light">
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_newData">Type Status</label>
						<input id="add_newData" class="data-entry-input reqdClr" type="text" name="newData"  required>
					</div>
					<div class="col">
						<label class="form-label" for="add_category">Kind of Type</label>
						<select id="add_category" class="data-entry-select" name="category">
							<option value="Primary">Primary</option>
							<option value="Secondary">Secondary</option>
							<option value="Voucher">Voucher (non-type)</option>
							<option value="Voucher Not">Not Voucher (non-type)</option>
							<!---  NOTE: If you add a value here, you also need to add it to the edit picklist below --->
							<!---  NOTE: Alphabetic sort of these values is used to order Primary/Secondary/other type status --->
							<!---  If new category values are added for non-types, they should sort after Secondary. --->
						</select>
					</div>
					<div class="col">
						<label class="form-label" for="add_ordinal">Sort Order</label>
						<input id="add_ordinal" class="data-entry-input" type="text" name="ordinal">
					</div>
					<div class="col">
						<label class="form-label" for="add_description">Description</label>
						<input id="add_description" class="data-entry-input" type="text" name="description">
					</div>
					<div class="col">
						<input type="submit" 
							value="Insert" 
							class="btn btn-xs btn-secondary mt-4">
					</div>
				</div>
			</div>
		</form>
		<h3 class="h5 mt-3 mb-2">Edit Citation Type Status</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
			<div class="d-table-row bg-light border-bottom">
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Type Status</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Kind of Type</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Sort Order</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Description</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
			</div>
			<cfset i = 1>
			<cfloop query="q">
					<form class="d-table-row" name="#tbl##i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="#tbl#">
						<!---  Need to pass current value as it is the PK for the code table --->
						<input type="hidden" name="origData" value="#type_status#">
						<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
							<input class="data-entry-input w-100" type="text" name="type_status" value="#type_status#">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<cfif category EQ "Primary"> 
								<cfset scopepriselected = "selected='selected'">
								<cfset scopesecselected = "">
								<cfset scopevouselected = "">
								<cfset scopenvouselected = "">
							<cfelseif category EQ "Secondary"> 
								<cfset scopepriselected = "">
								<cfset scopesecselected = "selected='selected'">
								<cfset scopevouselected = "">
								<cfset scopenvouselected = "">
							<cfelseif category EQ "Voucher Not"> 
								<cfset scopepriselected = "">
								<cfset scopesecselected = "">
								<cfset scopevouselected = "">
								<cfset scopenvouselected = "selected='selected'">
							<cfelse>
								<!-- Caution: failover case will select Voucher as the value --->
								<cfset scopepriselected = "">
								<cfset scopesecselected = "">
								<cfset scopevouselected = "selected='selected'">
								<cfset scopenvouselected = "">
							</cfif>
							<select class="data-entry-select" name="category">
								<option value="Primary" #scopepriselected# >Primary</option>
								<option value="Secondary" #scopesecselected# >Secondary</option>
								<option value="Voucher" #scopevouselected# >Voucher (non-type)</option>
								<option value="Voucher Not" #scopenvouselected#>Not Voucher (non-type)</option>
							</select>
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input class="data-entry-input" type="text" name="ordinal" value="#ordinal#">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
						<!---	<input class="data-entry-input" type="description" name="description" value="#stripQuotes(description)#">--->
							<input class="data-entry-input" type="description" name="description" value="#description#">
						</div>
						<div class="d-table-cell py-1 align-middle text-nowrap">
							<input type="button" 
								value="Save" 
								class="btn btn-xs btn-primary"
								onclick="#tbl##i#.action.value='saveEdit';submit();">
							<input type="button" 
								value="Delete" 
								class="btn btn-xs btn-danger"
								onclick="#tbl##i#.action.value='deleteValue';submit();">
						</div>
					</form>
				<cfset i = #i#+1>
			</cfloop>
			</div>
		</div>
	<!--- RETAINED SPECIAL CASE: Hard-coded type select (lithologic/lithostratigraphic/chronostratigraphic); values not in schema. --->
	<cfelseif tbl is "ctgeology_attributes"><!---------------------------------------------------->
		<!---  geology attributes code table includes fields for typing and sort order, thus needs custom form  --->
		<!--- note, ctgeology_attribute (singluar), is view with sort by ordinal on table ctgeology_attributes (plural) --->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select geology_attribute, type, ordinal, description from ctgeology_attributes order by ordinal
		</cfquery>
<a class="btn btn-xs btn-secondary px-2 float-right" role="button" href="/vocabularies/GeologicalHierarchies.cfm?action=list">Geological Hierarchy List</a>
		
					<h2>Geological attribute types, and their categories.</h2>
					<h4>Categories are lithologic, for rock type terms (probably just the single term lithology), lithostratigraphic for rock unit names, and geochronologic/chronostratigraphic for time and rock/time related terms)</h4>
					<h3 class="h5 mt-3 mb-2 text-success">Add Geology Attribute</h3>
					<form name="newData" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
						<input type="hidden" name="action" value="newValue">
						<input type="hidden" name="tbl" value="#tbl#">
						<div class="row border rounded my-2 mx-1 p-2 bg-light">
							<div class="form-row mb-1">
								<div class="col">
									<label class="form-label" for="add_newData">Geology Attribute</label>
									<input id="add_newData" type="text" name="newData" class="data-entry-input reqdClr" required>
								</div>
								<div class="col">
									<label class="form-label" for="add_type">Category</label>
									<select id="add_type" name="type" class="data-entry-select">
										<option value="lithologic">Lithologic</option>
										<option value="lithostratigraphic">Lithostratigraphic</option>
										<option value="chronostratigraphic">Geochronologic/Chronstratigraphic</option>
								 		<!---  NOTE: If you add a value here, you also need to add it to the edit picklist below --->
									</select>
								</div>
								<div class="col">
									<label class="form-label" for="add_ordinal">Sort Order</label>
									<input id="add_ordinal" type="text" name="ordinal" class="data-entry-input">
								</div>
								<div class="col">
									<label class="form-label" for="add_description">Description</label>
									<input id="add_description" type="text" name="description" class="data-entry-input">
								</div>
								<div class="col">
									<input type="submit" 
										value="Insert" 
										class="btn btn-xs btn-secondary mt-4">
								</div>
							</div>
						</div>
					</form>
					<h3 class="h5 mt-3 mb-2">Edit Geology Attributes</h3>
					<div class="row border rounded my-2 mx-1 p-2">
						<div class="d-table w-100">
						<div class="d-table-row bg-light border-bottom">
							<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Geological Attribute</div>
							<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Category</div>
							<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Sort Order</div>
							<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Description</div>
							<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
						</div>
						<cfset i = 1>
						<cfloop query="q">
								<form class="d-table-row" name="#tbl##i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
									<input type="hidden" name="action" value="">
									<input type="hidden" name="tbl" value="#tbl#">
									<!---  Need to pass current value as it is the PK for the code table --->
									<input type="hidden" name="origData" value="#geology_attribute#">
									<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
										<input type="text" name="geology_attribute" class="data-entry-input w-100" value="#geology_attribute#">
									</div>
									<div class="d-table-cell py-1 pr-3 align-middle">
										<cfif type EQ "lithologic"> 
											<cfset scopelithselected = "selected='selected'">
											<cfset scopestratselected = "">
											<cfset scopechronselected = "">
										<cfelseif type EQ "lithostratigraphic"> 
											<cfset scopelithselected = "">
											<cfset scopestratselected = "selected='selected'">
											<cfset scopechronselected = "">
										<cfelse> 
											<cfset scopelithselected = "">
											<cfset scopestratselected = "">
											<cfset scopechronselected = "selected='selected'">
										</cfif>
										<select name="type" class="data-entry-select">
											<option value="lithologic" #scopelithselected# >Lithologic</option>
											<option value="lithostratigraphic" #scopestratselected# >Lithostratigraphic</option>
											<option value="chronostratigraphic" #scopechronselected# >Geochronologic/Chronostratigraphic</option>
										</select>
									</div>
									<div class="d-table-cell py-1 pr-3 align-middle">
										<input type="text" name="ordinal" class="data-entry-input" value="#ordinal#">
									</div>
									<div class="d-table-cell py-1 pr-3 align-middle">
										<!---<input class="data-entry-input" type="description" name="description" value="#stripQuotes(description)#">--->
										<input type="description" name="description" class="data-entry-input" value="#description#">
									</div>
									<div class="d-table-cell py-1 align-middle text-nowrap">
										<input type="button" 
											value="Save" 
											class="btn btn-xs btn-primary"
											onclick="#tbl##i#.action.value='saveEdit';submit();">
										<input type="button" 
											value="Delete" 
											class="btn btn-xs btn-danger px-2"
											onclick="#tbl##i#.action.value='deleteValue';submit();">
									</div>
								</form>
							<cfset i = #i#+1>
						</cfloop>
						</div>
					</div>
	<!--- RETAINED SPECIAL CASE: FK select for control from all CT* tables; mcz_publication_fg decimal field. --->
	<cfelseif tbl is "ctpublication_attribute"><!---------------------------------------------------->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select * from ctpublication_attribute order by publication_attribute
		</cfquery>
		<cfquery name="allCTs" datasource="uam_god">
			select distinct(table_name) as tablename from sys.user_tables where table_name like 'CT%' order by table_name
		</cfquery>
		<h3 class="h5 mt-3 mb-2 text-success">Add Publication Attribute</h3>
		<form name="newData" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="ctpublication_attribute">
			<div class="row border rounded my-2 mx-1 p-2 bg-light">
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_newData">Publication Attribute</label>
						<input id="add_newData" class="data-entry-input reqdClr" type="text" name="newData"  required>
					</div>
					<div class="col">
						<label class="form-label" for="add_description">Description</label>
						<textarea id="add_description" class="data-entry-textarea" name="description" rows="4" cols="40"></textarea>
					</div>
					<div class="col">
						<label class="form-label" for="add_control">Control</label>
						<select id="add_control" class="data-entry-select" name="control">
							<option value=""></option>
							<cfloop query="allCTs">
								<option value="#tablename#">#tablename#</option>
							</cfloop>
						</select>
					</div>
					<div class="col">
						<input type="submit" 
							value="Insert" 
							class="btn btn-xs btn-secondary mt-4">
					</div>
				</div>
			</div>
		</form>
		<cfset i = 1>
		<h3 class="h5 mt-3 mb-2">Edit Publication Attributes</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
			<div class="d-table-row bg-light border-bottom">
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Type</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Description</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Control</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
			</div>
			<cfloop query="q">
					<form class="d-table-row" name="#tbl##i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="ctpublication_attribute">
						<input type="hidden" name="origData" value="#publication_attribute#">
						<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
							<input class="data-entry-input w-100" type="text" name="publication_attribute" value="#publication_attribute#">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<textarea class="data-entry-textarea" name="description" rows="4" cols="40">#description#</textarea>
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<select class="data-entry-select" name="control">
								<option value=""></option>
								<cfloop query="allCTs">
									<option <cfif q.control is allCTs.tablename> selected="selected" </cfif>value="#tablename#">#tablename#</option>
								</cfloop>
							</select>
						</div>
						<div class="d-table-cell py-1 align-middle text-nowrap">
							<input type="button" 
								value="Save" 
								class="btn btn-xs btn-primary"
								onclick="#tbl##i#.action.value='saveEdit';submit();">
							<input type="button" 
								value="Delete" 
								class="btn btn-xs btn-danger"
								onclick="#tbl##i#.action.value='deleteValue';submit();">
						</div>
					</form>
				<cfset i = #i#+1>
			</cfloop>
			</div>
		</div>
	<!--- RETAINED SPECIAL CASE: Hard-coded rel_type select (biological/curatorial/functional); values not in schema. --->
	<cfelseif tbl is "ctbiol_relations"><!---------------------------------------------------->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select * from ctbiol_relations order by biol_indiv_relationship
		</cfquery>
		<h3 class="h5 mt-3 mb-2 text-success">Add Biological Relationship</h3>
		<form name="newData" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="ctbiol_relations">
			<div class="row border rounded my-2 mx-1 p-2 bg-light">
				<div class="form-row mb-1">
						<div class="col">
							<label class="form-label" for="add_newData">Relationship</label>
							<input id="add_newData" class="data-entry-input reqdClr" type="text" name="newData" size="50" required>
						</div>
						<div class="col">
							<label class="form-label" for="add_inverse_relation">Inverse Relation</label>
							<input id="add_inverse_relation" class="data-entry-input" type="text" name="inverse_relation" size="50">
						</div>
						<div class="col">
							<label class="form-label" for="add_rel_type">Type</label>
							<select id="add_rel_type" class="data-entry-select" name="rel_type">
								<option value="biological" selected='selected'>Biological</option>
								<option value="curatorial">Curatorial</option>
								<option value="functional">Functional</option>
							</select>
						</div>				
					<div class="col">
						<input type="submit" 
							value="Insert" 
							class="btn btn-xs btn-secondary mt-4">
					</div>
				</div>
			</div>
		</form>
		<cfset i = 1>
		<h3 class="h5 mt-3 mb-2">Edit Biological Relationships</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
			<div class="d-table-row bg-light border-bottom">
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Relationship</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Inverse Relation</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Type</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
			</div>
			<cfloop query="q">
					<form class="d-table-row" name="#tbl##i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="ctbiol_relations">
						<input type="hidden" name="origData" value="#biol_indiv_relationship#">
						<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
							<input class="data-entry-input w-100" type="text" name="biol_indiv_relationship" value="#biol_indiv_relationship#">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input class="data-entry-input" type="text" name="inverse_relation" value="#inverse_relation#">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<cfif rel_type EQ "biological">
								<cfset scopepriselected = "selected='selected'">
								<cfset scopesecselected = "">
								<cfset scopevouselected = "">
							<cfelseif rel_type EQ "curatorial">
								<cfset scopepriselected = "">
								<cfset scopesecselected = "selected='selected'">
								<cfset scopevouselected = "">
							<cfelse>
								<cfset scopepriselected = "">
								<cfset scopesecselected = "">
								<cfset scopevouselected = "selected='selected'">
							</cfif>
							<select class="data-entry-select" name="rel_type">
								<option value="biological" #scopepriselected# >Biological</option>
								<option value="curatorial" #scopesecselected# >Curatorial</option>
								<option value="functional" #scopevouselected# >Functional</option>
							</select>
						</div>
						<div class="d-table-cell py-1 align-middle text-nowrap">
							<input type="button" 
								value="Save" 
								class="btn btn-xs btn-primary"
								onclick="#tbl##i#.action.value='saveEdit';submit();">
							<input type="button" 
								value="Delete" 
								class="btn btn-xs btn-danger"
								onclick="#tbl##i#.action.value='deleteValue';submit();">
						</div>
					</form>
				<cfset i = #i#+1>
			</cfloop>
			</div>
		</div>
	<!--- RETAINED SPECIAL CASE: Boolean select for encumber_as_field_num; boolean semantics need select not free-text. --->
	<cfelseif tbl is "ctcoll_other_id_type"><!--------------------------------------------------------------->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select * from ctcoll_other_id_type order by other_id_type
		</cfquery>	
		<h3 class="h5 mt-3 mb-2 text-success">Add Other ID Type</h3>
		<form name="newData" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="ctcoll_other_id_type">
			<div class="row border rounded my-2 mx-1 p-2 bg-light">
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_newData">ID Type</label>
						<input id="add_newData" class="data-entry-input reqdClr" type="text" name="newData"  required>
					</div>
					<div class="col">
						<label class="form-label" for="add_description">Description</label>
						<textarea id="add_description" class="data-entry-textarea" name="description" rows="4" cols="40"></textarea>
					</div>
					<div class="col">
						<label class="form-label" for="add_base_url">Base URL</label>
						<input id="add_base_url" class="data-entry-input" type="text" name="base_url" size="50">
					</div>
					<div class="col">
						<label class="form-label" for="add_encumber_as_field_num">Mask As Field Number</label>
						<select id="add_encumber_as_field_num" class="data-entry-select" name="encumber_as_field_num">
							<option value="0">No</option>
							<option value="1">Yes</option>
						</select>
					</div>
					<div class="col">
						<input type="submit" 
							value="Insert" 
							class="btn btn-xs btn-secondary mt-4">					
					</div>
				</div>
			</div>
		</form>
		<cfset i = 1>
		<h3 class="h5 mt-3 mb-2">Edit Other ID Types</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
			<div class="d-table-row bg-light border-bottom">
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Type</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Description</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Base URL</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Encumber</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
			</div>
			<cfloop query="q">
					<form class="d-table-row" name="#tbl##i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="ctcoll_other_id_type">
						<input type="hidden" name="origData" value="#other_id_type#">
						<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
							<input class="data-entry-input w-100" type="text" name="other_id_type" value="#other_id_type#">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<textarea class="data-entry-textarea" name="description" rows="4" cols="40">#description#</textarea>
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input class="data-entry-input" type="text" name="base_url" value="#base_url#">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<cfif encumber_as_field_num EQ "1">
								<cfset select1 = "selected">
								<cfset select0 = "">
							<cfelse>
								<cfset select1 = "">
								<cfset select0 = "1">
							</cfif>
							<select class="data-entry-select" name="encumber_as_field_num">
								<option value="0" #select0#>No</option>
								<option value="1" #select1#>Yes</option>
							</select>
						</div>
						<div class="d-table-cell py-1 align-middle text-nowrap">
							<input type="button" 
								value="Save" 
								class="btn btn-xs btn-primary"
								onclick="#tbl##i#.action.value='saveEdit';submit();">
							<input type="button" 
								value="Delete" 
								class="btn btn-xs btn-danger"
								onclick="#tbl##i#.action.value='deleteValue';submit();">
						</div>
					</form>
				<cfset i = #i#+1>
			</cfloop>
			</div>
		</div>
	<!--- RETAINED SPECIAL CASE: Delete suppressed when taxon_relations usage count > 0; business rule requires cross-table join and conditional button. --->
	<cfelseif tbl is "cttaxon_relation"><!--------------------------------------------------------------->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT count(taxon_relations.taxon_name_id) ct, cttaxon_relation.taxon_relationship, description, inverse_relation
			FROM cttaxon_relation 
				LEFT JOIN taxon_relations on cttaxon_relation.taxon_relationship = taxon_relations.taxon_relationship
			GROUP BY
				cttaxon_relation.taxon_relationship, description, inverse_relation
			ORDER BY taxon_relationship
		</cfquery>	
		<h3 class="h5 mt-3 mb-2 text-success">Add Taxon Relationship</h3>
		<form name="newData" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="cttaxon_relation">
			<h2>Phrase taxon relationships and inverse relations in the form</h2>
			<ul>
				<li>A taxon_relationship B inverse_relation A</li>
				<li>A junior homonym of B senior homonym of A</li>
			</ul>
			<div class="row border rounded my-2 mx-1 p-2 bg-light">
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_newData">Taxon Relationship</label>
						<input id="add_newData" class="data-entry-input reqdClr" type="text" name="newData"  required>
					</div>
					<div class="col">
						<label class="form-label" for="add_description">Description</label>
						<textarea id="add_description" class="data-entry-textarea" name="description" rows="4" cols="40"></textarea>
					</div>
					<div class="col">
						<label class="form-label" for="add_inverse_relation">Inverse Relation</label>
						<input id="add_inverse_relation" class="data-entry-input" type="text" name="inverse_relation">
					</div>
					<div class="col">
						<input type="submit" 
							value="Insert" 
							class="btn btn-xs btn-secondary mt-4">					
					</div>
				</div>
			</div>
		</form>
		<cfset i = 1>
		<h3 class="h5 mt-3 mb-2">Edit Taxon Relationships</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
			<div class="d-table-row bg-light border-bottom">
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Taxon Relationship</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Description</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Inverse Relation</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Instances</div>
			</div>
			<cfloop query="q">
					<form class="d-table-row" name="#tbl##i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="cttaxon_relation">
						<input type="hidden" name="origData" value="#taxon_relationship#">
						<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
							<input class="data-entry-input w-100" type="text" name="taxon_relationship" value="#taxon_relationship#">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<textarea class="data-entry-textarea" name="description" rows="4" cols="40">#description#</textarea>
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input class="data-entry-input" type="text" name="inverse_relation" value="#inverse_relation#">
						</div>
						<div class="d-table-cell py-1 align-middle text-nowrap">
							<input type="button" 
								value="Save" 
								class="btn btn-xs btn-primary"
								onclick="#tbl##i#.action.value='saveEdit';submit();">
							<cfif q.ct EQ 0>
								<input type="button" 
									value="Delete" 
									class="btn btn-xs btn-danger"
									onclick="#tbl##i#.action.value='deleteValue';submit();">
							</cfif>
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							#ct#
						</div>
					</form>
				<cfset i = #i#+1>
			</cfloop>
			</div>
		</div>
	<!--- RETAINED SPECIAL CASE: sort_order integer field with numeric ordering semantics. --->
	<cfelseif tbl is "ctnomenclatural_code"><!--------------------------------------------------------------->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select nomenclatural_code, description, sort_order from ctnomenclatural_code order by sort_order
		</cfquery>	
		<h3 class="h5 mt-3 mb-2 text-success">Add Nomenclatural Code</h3>
		<form name="newData" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="ctnomenclatural_code">
			<div class="row border rounded my-2 mx-1 p-2 bg-light">
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_newData">Nomenclatural Code</label>
						<input id="add_newData" class="data-entry-input reqdClr" type="text" name="newData"  required>
					</div>
					<div class="col">
						<label class="form-label" for="add_description">Description</label>
						<textarea id="add_description" class="data-entry-textarea" name="description" rows="4" cols="70"></textarea>
					</div>
					<div class="col">
						<label class="form-label" for="add_sort_order">Sort Order</label>
						<input id="add_sort_order" class="data-entry-input" type="text" name="sort_order" size="3">
					</div>
					<div class="col">
						<input type="submit" 
							value="Insert" 
							class="btn btn-xs btn-secondary mt-4">					
					</div>
				</div>
			</div>
		</form>
		<cfset i = 1>
		<h3 class="h5 mt-3 mb-2">Edit Nomenclatural Codes</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
			<div class="d-table-row bg-light border-bottom">
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Nomenclatural Code</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Description</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Sort Order</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
			</div>
			<cfloop query="q">
					<form class="d-table-row" name="#tbl##i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="ctnomenclatural_code">
						<input type="hidden" name="origData" value="#nomenclatural_code#">
						<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
							<input class="data-entry-input w-100" type="text" name="nomenclatural_code" value="#nomenclatural_code#">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<textarea class="data-entry-textarea" name="description" rows="4" cols="70">#description#</textarea>
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input class="data-entry-input" type="text" name="sort_order" size="3" value="#sort_order#">
						</div>
						<div class="d-table-cell py-1 align-middle text-nowrap">
							<input type="button" 
								value="Save" 
								class="btn btn-xs btn-primary"
								onclick="#tbl##i#.action.value='saveEdit';submit();">
							<input type="button" 
								value="Delete" 
								class="btn btn-xs btn-danger"
								onclick="#tbl##i#.action.value='deleteValue';submit();">
						</div>
					</form>
				<cfset i = #i#+1>
			</cfloop>
			</div>
		</div>
	<cfelseif tbl is "ctspecimen_part_list_order"><!--- special section to handle  another  funky code table --->
		<cfquery name="thisRec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select * from ctspecimen_part_list_order order by
			list_order,partname
		</cfquery>
		<cfquery name="ctspecimen_part_name" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select collection_cde, part_name partname from ctspecimen_part_name
		</cfquery>
		<cfquery name="mo" dbtype="query">
			select max(list_order) +1 maxNum from thisRec
		</cfquery>
		<p>
			This application sets the order part names appear in certain reports and forms. 
			Nothing prevents you from making several parts the same
			order, and doing so will just cause them to not be ordered. You don't have to order things you don't care about.	
		</p>
		<h3 class="h5 mt-3 mb-2 text-success">Add Part Ordering</h3>
		<div class="row border rounded my-2 mx-1 p-2 bg-light">
			<form name="newPart" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
				<input type="hidden" name="action" value="newValue">
				<input type="hidden" name="tbl" value="#tbl#">
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_partname">Part Name</label>
						<cfset thisPart = #thisRec.partname#>
						<select id="add_partname" class="data-entry-select" name="partname" size="1">
							<cfloop query="ctspecimen_part_name">
							<option 
							value="#ctspecimen_part_name.partname#">#ctspecimen_part_name.partname# (#ctspecimen_part_name.collection_cde#)</option>
							</cfloop>
						</select>
					</div>
					<cfquery name="mo" dbtype="query">
						select max(list_order) +1 maxNum from thisRec
					</cfquery>
					<div class="col">
						<label class="form-label" for="add_list_order">List Order</label>
						<cfset thisLO = #thisRec.list_order#>
						<select id="add_list_order" class="data-entry-select" name="list_order" size="1">
							<cfloop from="1" to="#mo.maxNum#" index="n">
								<option value="#n#">#n#</option>
							</cfloop>
						</select>
					</div>
					<div class="col">
						<input type="submit" 
							value="Create" 
							class="btn btn-xs btn-secondary mt-4">	
					</div>
				</div>
			</form>	
		</div>
		<h3 class="h5 mt-3 mb-2">Edit Part Orderings</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
			<div class="d-table-row bg-light border-bottom">
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Part Name</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">List Order</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
			</div>
			<cfset i=1>
			<cfloop query="thisRec">
				<form class="d-table-row" name="part#i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
					<input type="hidden" name="action" value="ctspecimen_part_list_order">
					<input type="hidden" name="tbl" value="#tbl#">
					<input type="hidden" name="oldlist_order" value="#list_order#">
					<input type="hidden" name="oldpartname" value="#partname#">
					<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
						<cfset thisPart = #thisRec.partname#>
						<select class="data-entry-select w-100" name="partname" size="1">
							<cfloop query="ctspecimen_part_name">
							<option 
							<cfif #thisPart# is "#ctspecimen_part_name.partname#"> selected </cfif>value="#ctspecimen_part_name.partname#">#ctspecimen_part_name.partname#</option>
							</cfloop>
						</select>
					</div>
					<div class="d-table-cell py-1 pr-3 align-middle">
						<cfset thisLO = #thisRec.list_order#>
						<select class="data-entry-select" name="list_order" size="1">
							<cfloop from="1" to="#mo.maxNum#" index="n">
								<option <cfif #thisLO# is "#n#"> selected </cfif>value="#n#">#n#</option>
							</cfloop>
						</select>
					</div>
					<div class="d-table-cell py-1 align-middle text-nowrap">
						<input type="button" 
							value="Save" 
							class="btn btn-xs btn-primary"
							onclick="part#i#.action.value='saveEdit';submit();">	
						<input type="button" 
							value="Delete" 
							class="btn btn-xs btn-danger"
						 	onclick="part#i#.action.value='deleteValue';submit();">	
					</div>
				</form>
				<cfset i=#i#+1>
			</cfloop>
			</div>
		</div>
	<!--- RETAINED SPECIAL CASE: Important contextual description text for operators; operational help required. --->
	<cfelseif tbl is "ctunderscore_collection_type">
		<cfquery name="thisRec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT * FROM ctunderscore_collection_type 
			ORDER BY
				underscore_collection_type
		</cfquery>
		<p>
			Types of Named Groups of Cataloged Items.
		</p>
		<h3 class="h5 mt-3 mb-2 text-success">Add Named Group Type</h3>
		<div class="row border rounded my-2 mx-1 p-2 bg-light">
			<form name="newType" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
				<input type="hidden" name="action" value="newValue">
				<input type="hidden" name="tbl" value="#tbl#">
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_newData">Type</label>
						<input id="add_newData" class="data-entry-input reqdClr" type="text" name="newData"  required>
					</div>
					<div class="col">
						<label class="form-label" for="add_description">Description</label>
						<textarea id="add_description" class="data-entry-textarea" name="description" rows="4" cols="70"></textarea>
					</div>
					<div class="col">
						<label class="form-label" for="add_allowed_agent_roles">Allowed Agent Roles</label>
						<input id="add_allowed_agent_roles" class="data-entry-input" type="text" name="allowed_agent_roles" >
					</div>
					<div class="col">
						<input type="submit" 
							value="Create" 
							class="btn btn-xs btn-secondary mt-4">	
					</div>
				</div>
			</form>	
		</div>
		<h3 class="h5 mt-3 mb-2">Edit Named Group Types</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
			<div class="d-table-row bg-light border-bottom">
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Type</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Description</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Allowed Agent Roles</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
			</div>
			<cfset i=1>
			<cfloop query="thisRec">
				<form class="d-table-row" name="type#i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
					<input type="hidden" name="action" value="replacedinbuttonclick">
					<input type="hidden" name="tbl" value="#tbl#">
					<input type="hidden" name="oldunderscore_collection_type" value="#underscore_collection_type#">
					<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
						<input class="data-entry-input w-100" type="text" name="underscore_collection_type" value="#underscore_collection_type#" >
					</div>
					<div class="d-table-cell py-1 pr-3 align-middle">
						<input class="data-entry-input" type="text" name="description" value="#description#" >
					</div>
					<div class="d-table-cell py-1 pr-3 align-middle">
						<input class="data-entry-input" type="text" name="allowed_agent_roles" value="#allowed_agent_roles#" >
					</div>
					<div class="d-table-cell py-1 align-middle text-nowrap">
						<input type="button" 
							value="Save" 
							class="btn btn-xs btn-primary"
							onclick="type#i#.action.value='saveEdit';submit();">	
						<input type="button" 
							value="Delete" 
							class="btn btn-xs btn-danger"
						 	onclick="type#i#.action.value='deleteValue';submit();">	
					</div>
				</form>
				<cfset i=#i#+1>
			</cfloop>
			</div>
		</div>
	<!--- RETAINED SPECIAL CASE: ordinal integer field; label/inverse_label fields with specific semantics. --->
	<cfelseif tbl is "ctunderscore_coll_agent_role"><!---------------------------------------------------->
		<!---   underscore_collection agent role table has sort order and labels, thus needs custom form  --->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT role, description, ordinal, label, inverse_label
			FROM CTUNDERSCORE_COLL_AGENT_ROLE 
			ORDER BY ordinal, role
		</cfquery>
		<h3 class="h5 mt-3 mb-2 text-success">Add Collection Agent Role</h3>
		<form name="newData" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="#tbl#">
			<div class="row border rounded my-2 mx-1 p-2 bg-light">
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_newData">Role</label>
						<input id="add_newData" type="text" name="newData" class="data-entry-input reqdClr" required>
					</div>
					<div class="col">
						<label class="form-label" for="add_description">Description</label>
						<input id="add_description" class="data-entry-input" type="text" name="description">
					</div>
					<div class="col">
						<label class="form-label" for="add_ordinal">Sort Order</label>
						<input id="add_ordinal" type="text" name="ordinal" class="data-entry-input reqdClr" required>
					</div>
					<div class="col">
						<label class="form-label" for="add_label">Label (group-label-agent)</label>
						<input id="add_label" class="data-entry-input" type="text" name="label">
					</div>
					<div class="col">
						<label class="form-label" for="add_inverse_label">Inverse Label (agent-label-group)</label>
						<input id="add_inverse_label" class="data-entry-input" type="text" name="inverse_label">
					</div>
					<div class="col">
						<input type="submit" 
							value="Insert" 
							class="btn btn-xs btn-secondary mt-4">
					</div>
				</div>
			</div>
		</form>
		<h3 class="h5 mt-3 mb-2">Edit Collection Agent Roles</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
			<div class="d-table-row bg-light border-bottom">
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Role</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Description</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Sort Order</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Label</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Inverse Label</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
			</div>
			<cfset i = 1>
			<cfloop query="q">
					<form class="d-table-row" name="#tbl##i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="#tbl#">
						<!---  Need to pass current value as it is the PK for the code table --->
						<input type="hidden" name="origData" value="#role#">
						<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
							<input type="text" name="role" value="#role#" required class="data-entry-input reqdClr w-100">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input class="data-entry-input" type="text" name="description" value="#description#">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input type="text" name="ordinal" value="#ordinal#" required class="data-entry-input reqdClr">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input class="data-entry-input" type="text" name="label" value="#label#">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input class="data-entry-input" type="text" name="inverse_label" value="#inverse_label#">
						</div>
						<div class="d-table-cell py-1 align-middle text-nowrap">
							<input type="button" 
								value="Save" 
								class="btn btn-xs btn-primary"
								onclick="#tbl##i#.action.value='saveEdit';submit();">
							<input type="button" 
								value="Delete" 
								class="btn btn-xs btn-danger"
								onclick="#tbl##i#.action.value='deleteValue';submit();">
						</div>
					</form>
				<cfset i = #i#+1>
			</cfloop>
			</div>
		</div>
	<!--- RETAINED SPECIAL CASE: Essential warning text: last word must be a table name; adding new relationship requires code changes to MCZBASE.get_media_descriptor and MCZBASE.get_media_title. --->
	<cfelseif tbl is "ctmedia_relationship"><!---------------------------------------------------->
		<!---  Media relationship code table includes field for label, thus needs custom form  --->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select media_relationship, description, label, auto_table from ctmedia_relationship order by media_relationship
		</cfquery>
		<h2>Relationships between media records and other tables.</h2>
		<p>Last word in Media Relationship must be a table name.  Adding new relationship also involves code changes to MCZBASE.get_media_descriptor and MCZBASE.get_media_title.</p>
		<p>If adding relationships to a new table, additions are needed to MCZBASE.MEDIA_RELATION_SUMMARY</p>
		<h3 class="h5 mt-3 mb-2 text-success">Add Media Relationship</h3>
		<form name="newData" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="#tbl#">
			<div class="row border rounded my-2 mx-1 p-2 bg-light">
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_newData">Media Relationship</label>
						<input id="add_newData" class="data-entry-input reqdClr" type="text" name="newData"  required>
					</div>
					<div class="col">
						<label class="form-label" for="add_label">Label</label>
						<input id="add_label" class="data-entry-input" type="text" name="label">
					</div>
					<div class="col">
						<label class="form-label" for="add_description">Description</label>
						<input id="add_description" class="data-entry-input" type="text" name="description">
					</div>
					<div class="col">
						<input type="submit" 
							value="Insert" 
							class="btn btn-xs btn-secondary mt-4">
					</div>
				</div>
			</div>
		</form>
		<h3 class="h5 mt-3 mb-2">Edit Media Relationships</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
			<div class="d-table-row bg-light border-bottom">
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Media Relationship</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Table</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Label</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Description</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
			</div>
			<cfset i = 1>
			<cfloop query="q">
					<form class="d-table-row" name="#tbl##i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="#tbl#">
						<!---  Need to pass current value as it is the PK for the code table --->
						<input type="hidden" name="origData" value="#media_relationship#">
						<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
							<input class="data-entry-input w-100" type="text" name="media_relationship" value="#media_relationship#">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<span>#auto_table#</span>
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input class="data-entry-input" type="text" name="label" value="#label#">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input class="data-entry-input" type="text" name="description" value="#description#">
						</div>
						<div class="d-table-cell py-1 align-middle text-nowrap">
							<input type="button" 
								value="Save" 
								class="btn btn-xs btn-primary"
								onclick="#tbl##i#.action.value='saveEdit';submit();">
							<input type="button" 
								value="Delete" 
								class="btn btn-xs btn-danger"
								onclick="#tbl##i#.action.value='deleteValue';submit();">
						</div>
					</form>
				<cfset i = #i#+1>
			</cfloop>
			</div>
		</div>
	<!--- RETAINED SPECIAL CASE: hidden_fg boolean select; category_type field with functional meaning. --->
	<cfelseif tbl is "CTTAXON_CATEGORY"><!---------------------------------------------------->
		<!---  taxon category code table includes field for category type, thus needs custom form  --->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select taxon_category, category_type, description, hidden_fg from cttaxon_category order by taxon_category
		</cfquery>
		<h2>Categorization of taxonomy records.</h2>
		<p>Each taxon_category must have a category_type, some category types have functional roles in the code, category types may be set to public or internal only visibility.</p>
		<h3 class="h5 mt-3 mb-2 text-success">Add Taxon Category</h3>
		<form name="newData" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="#tbl#">
			<div class="row border rounded my-2 mx-1 p-2 bg-light">
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_newData">Taxon Category</label>
						<input id="add_newData" class="data-entry-input reqdClr" type="text" name="newData"  required>
					</div>
					<div class="col">
						<label class="form-label" for="add_category_type">Category Type</label>
						<input id="add_category_type" class="data-entry-input" type="text" name="category_type">
					</div>
					<div class="col">
						<label class="form-label" for="add_description">Description</label>
						<input id="add_description" class="data-entry-input" type="text" name="description">
					</div>
					<div class="col">
						<label class="form-label" for="add_hidden_fg">Visibility</label>
						<select id="add_hidden_fg" class="data-entry-select" name="hidden_fg">
							<option value="0" selected="selected" >Public</option>
							<option value="1">Hidden</option>
						</select>
					</div>
					<div class="col">
						<input type="submit" 
							value="Insert" 
							class="btn btn-xs btn-secondary mt-4">
					</div>
				</div>
			</div>
		</form>
		<h3 class="h5 mt-3 mb-2">Edit Taxon Categories</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
			<div class="d-table-row bg-light border-bottom">
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Taxon Category</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Category Type</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Description</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Visibility</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
			</div>
			<cfset i = 1>
			<cfloop query="q">
					<form class="d-table-row" name="#tbl##i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="#tbl#">
						<!---  Need to pass current value as it is the PK for the code table --->
						<input type="hidden" name="origData" value="#taxon_category#">
						<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
							<input type="text" name="taxon_category" value="#taxon_category#" class="data-entry-input reqdClr w-100">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input type="text" name="category_type" value="#category_type#" class="data-entry-input reqdClr">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input class="data-entry-input" type="text" name="description" value="#description#">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<cfif hidden_fg EQ 0>
								<cfset publicselected = "selected='selected'">
								<cfset hiddenselected = "">
							<cfelse>
								<cfset publicselected = "">
								<cfset hiddenselected = "selected='selected'">
							</cfif>
							<select class="data-entry-select" name="hidden_fg">
								<option value="0" #publicselected#>Public</option>
								<option value="1" #hiddenselected#>Hidden</option>
							</select>
						</div>
						<div class="d-table-cell py-1 align-middle text-nowrap">
							<input type="button" 
								value="Save" 
								class="btn btn-xs btn-primary"
								onclick="#tbl##i#.action.value='saveEdit';submit();">
							<input type="button" 
								value="Delete" 
								class="btn btn-xs btn-danger"
								onclick="#tbl##i#.action.value='deleteValue';submit();">
						</div>
					</form>
				<cfset i = #i#+1>
			</cfloop>
			</div>
		</div>
	<!--- RETAINED SPECIAL CASE: hidden_fg boolean select controlling public/hidden visibility. --->
	<cfelseif tbl is "CTTAXON_ATTRIBUTE_TYPE"><!---------------------------------------------------->
		<!---  taxon attribute type table includes field for visibility, thus needs custom form  --->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select taxon_attribute_type, hidden_fg, description from cttaxon_attribute_type order by taxon_attribute_type
		</cfquery>
		<h2>Types of taxonomy attributes.</h2>
		<p>Each taxon_attribute must have a type, types can have visibility public or hidden, hidden taxon attributes are shown to internal users only.</p>
		<h3 class="h5 mt-3 mb-2 text-success">Add Taxon Attribute Type</h3>
		<form name="newData" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="#tbl#">
			<div class="row border rounded my-2 mx-1 p-2 bg-light">
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_newData">Taxon Attribute Type</label>
						<input id="add_newData" class="data-entry-input reqdClr" type="text" name="newData"  required>
					</div>
					<div class="col">
						<label class="form-label" for="add_hidden_fg">Visibility</label>
						<select id="add_hidden_fg" class="data-entry-select" name="hidden_fg">
							<option value="0" selected="selected" >Public</option>
							<option value="1">Hidden</option>
						</select>
					</div>
					<div class="col">
						<label class="form-label" for="add_description">Description</label>
						<input id="add_description" class="data-entry-input" type="text" name="description">
					</div>
					<div class="col">
						<input type="submit" 
							value="Insert" 
							class="btn btn-xs btn-secondary mt-4">
					</div>
				</div>
			</div>
		</form>
		<h3 class="h5 mt-3 mb-2">Edit Taxon Attribute Types</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
			<div class="d-table-row bg-light border-bottom">
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Taxon Attribute Type</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Visibility</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Description</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
			</div>
			<cfset i = 1>
			<cfloop query="q">
					<form class="d-table-row" name="#tbl##i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="#tbl#">
						<!---  Need to pass current value as it is the PK for the code table --->
						<input type="hidden" name="origData" value="#taxon_attribute_type#">
						<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
							<input type="text" name="taxon_attribute_type" value="#taxon_attribute_type#" class="data-entry-input reqdClr w-100">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<cfif hidden_fg EQ 0>
								<cfset publicselected = "selected='selected'">
								<cfset hiddenselected = "">
							<cfelse>
								<cfset publicselected = "">
								<cfset hiddenselected = "selected='selected'">
							</cfif>
							<select class="data-entry-select" name="hidden_fg">
								<option value="0" #publicselected#>Public</option>
								<option value="1" #hiddenselected#>Hidden</option>
							</select>
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input class="data-entry-input" type="text" name="description" value="#description#">
						</div>
						<div class="d-table-cell py-1 align-middle text-nowrap">
							<input type="button" 
								value="Save" 
								class="btn btn-xs btn-primary"
								onclick="#tbl##i#.action.value='saveEdit';submit();">
							<input type="button" 
								value="Delete" 
								class="btn btn-xs btn-danger"
								onclick="#tbl##i#.action.value='deleteValue';submit();">
						</div>
					</form>
				<cfset i = #i#+1>
			</cfloop>
			</div>
		</div>
	<!--- RETAINED SPECIAL CASE: state_curie field with CURIE-format semantics; important format explanation for correct data entry. --->
	<cfelseif tbl is "CTSTATE"><!---------------------------------------------------->
		<!---  ctstate annotation state table includes field for state_curie, thus needs custom form  --->
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT 
				state, description, state_curie
			FROM ctstate
			ORDER BY state
		</cfquery>
		<h2>Annotation States.</h2>
		<p>Each annotation state must have a state and may be mapped to an ontology term by CURIE (namespaceabbreviation:term).</p>
		<h3 class="h5 mt-3 mb-2 text-success">Add Annotation State</h3>
		<form name="newData" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
			<input type="hidden" name="action" value="newValue">
			<input type="hidden" name="tbl" value="#tbl#">
			<div class="row border rounded my-2 mx-1 p-2 bg-light">
				<div class="form-row mb-1">
					<div class="col">
						<label class="form-label" for="add_newData">Annotation State</label>
						<input id="add_newData" class="data-entry-input reqdClr" type="text" name="newData"  required>
					</div>
					<div class="col">
						<label class="form-label" for="add_state_curie">Mapped to CURIE</label>
						<input id="add_state_curie" class="data-entry-input" type="text" name="state_curie" >
					</div>
					<div class="col">
						<label class="form-label" for="add_description">Description</label>
						<input id="add_description" class="data-entry-input" type="text" name="description">
					</div>
					<div class="col">
						<input type="submit" 
							value="Insert" 
							class="btn btn-xs btn-secondary mt-4">
					</div>
				</div>
			</div>
		</form>
		<h3 class="h5 mt-3 mb-2">Edit Annotation States</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
			<div class="d-table-row bg-light border-bottom">
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Annotation State</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Mapped to CURIE</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Description</div>
				<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
			</div>
			<cfset i = 1>
			<cfloop query="q">
					<form class="d-table-row" name="#tbl##i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="tbl" value="#tbl#">
						<!---  Need to pass current value as it is the PK for the code table --->
						<input type="hidden" name="origData" value="#state#">
						<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
							<input type="text" name="state" value="#state#" class="data-entry-input reqdClr w-100">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input class="data-entry-input" type="text" name="state_curie" value="#state_curie#">
						</div>
						<div class="d-table-cell py-1 pr-3 align-middle">
							<input class="data-entry-input" type="text" name="description" value="#description#">
						</div>
						<div class="d-table-cell py-1 align-middle text-nowrap">
							<input type="button" 
								value="Save" 
								class="btn btn-xs btn-primary"
								onclick="#tbl##i#.action.value='saveEdit';submit();">
							<input type="button" 
								value="Delete" 
								class="btn btn-xs btn-danger"
								onclick="#tbl##i#.action.value='deleteValue';submit();">
						</div>
					</form>
				<cfset i = #i#+1>
			</cfloop>
			</div>
		</div>
	<cfelse><!---------------------------- normal CTs --------------->
		<cfquery name="getCols" datasource="uam_god">
			SELECT column_name, column_id
			FROM sys.user_tab_columns 
			WHERE table_name = <cfqueryparam value="#ucase(tbl)#" cfsqltype="CF_SQL_VARCHAR">
			ORDER BY column_id
		</cfquery>
		<!--- Query primary key columns ordered by position within the constraint --->
		<cfquery name="getPKCols" datasource="uam_god">
			SELECT ucc.column_name, ucc.position
			FROM sys.user_constraints uc
			JOIN sys.user_cons_columns ucc ON uc.constraint_name = ucc.constraint_name
			WHERE uc.table_name = <cfqueryparam value="#ucase(tbl)#" cfsqltype="CF_SQL_VARCHAR">
				AND uc.constraint_type = 'P'
			ORDER BY ucc.position
		</cfquery>
		<cfset variables.pkColList = valuelist(getPKCols.column_name)>
		<cfset collcde = listfindnocase(valuelist(getCols.column_name), "collection_cde")>
		<cfset hasDescn = listfindnocase(valuelist(getCols.column_name), "description")>
		<!--- fld: first non-collection_cde PK column by PK position;
				fallback to first non-collection_cde/description column if no PK is defined --->
		<cfset fld = "">
		<cfif variables.pkColList neq "">
			<cfloop list="#variables.pkColList#" index="variables.pkc">
				<cfif fld eq "" and not listfindnocase("collection_cde", variables.pkc)>
					<cfset fld = variables.pkc>
				</cfif>
			</cfloop>
		</cfif>
		<cfif fld eq "">
			<cfloop list="#valuelist(getCols.column_name)#" index="variables.c">
				<cfif fld eq "" and not listfindnocase("collection_cde,description", variables.c)>
					<cfset fld = variables.c>
				</cfif>
			</cfloop>
		</cfif>
		<cfif fld eq "" and getCols.recordCount gt 0>
			<cfset fld = listFirst(valuelist(getCols.column_name))>
		</cfif>
		<!--- pkExtraCols: additional PK columns that are not fld and not collection_cde;
				included in WHERE clauses for uniqueness with multi-column primary keys --->
		<cfset variables.pkExtraCols = "">
		<cfif variables.pkColList neq "">
			<cfloop list="#variables.pkColList#" index="variables.pkc">
				<cfif variables.pkc neq fld and not listfindnocase("collection_cde", variables.pkc)>
					<cfset variables.pkExtraCols = listAppend(variables.pkExtraCols, variables.pkc)>
				</cfif>
			</cfloop>
		</cfif>
		<!--- extraCols: non-PK, non-collection_cde, non-description, non-fld columns (descriptive/data columns) --->
		<cfset variables.extraCols = "">
		<cfloop list="#valuelist(getCols.column_name)#" index="variables.c">
			<cfif variables.c neq fld
				and not listfindnocase("collection_cde,description", variables.c)
				and (variables.pkColList eq "" or not listfindnocase(variables.pkColList, variables.c))>
				<cfset variables.extraCols = listAppend(variables.extraCols, variables.c)>
			</cfif>
		</cfloop>
		<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT #fld# as data 
			<cfif variables.pkExtraCols neq "">
				,#variables.pkExtraCols#
			</cfif>
			<cfif variables.extraCols neq "">
				,#variables.extraCols#
			</cfif>
			<cfif collcde gt 0>
				,collection_cde
			</cfif>
			<cfif hasDescn gt 0>
				,description
			</cfif>
			FROM #tbl#
			ORDER BY
			<cfif collcde gt 0>
				collection_cde,
			</cfif>
			<cfif variables.pkExtraCols neq "">
				#variables.pkExtraCols#,
			</cfif>
			#fld#
		</cfquery>
		<h3 class="h5 mt-3 mb-2 text-success">Add New Value to #fld#</h3>
		<div class="row border rounded my-2 mx-1 p-2 bg-light">
			<form name="newData" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
				<input type="hidden" name="collcde" value="#collcde#">
				<input type="hidden" name="action" value="newValue">
				<input type="hidden" name="tbl" value="#tbl#">
				<input type="hidden" name="hasDescn" value="#hasDescn#">
				<input type="hidden" name="fld" value="#fld#">
				<input type="hidden" name="pkExtraCols" value="#variables.pkExtraCols#">
				<input type="hidden" name="extraCols" value="#variables.extraCols#">
				<div class="form-row mb-1 flex-nowrap align-items-end">
					<cfif collcde gt 0>
						<div class="col">
							<label class="form-label" for="add_collection_cde">Collection Type</label>
							<select id="add_collection_cde" class="data-entry-select" name="collection_cde" size="1">
								<cfloop query="ctcollcde">
									<option value="#ctcollcde.collection_cde#">#ctcollcde.collection_cde#</option>
								</cfloop>
							</select>
						</div>
					</cfif>
					<div class="col">
						<label class="form-label" for="newData_#tbl#">#fld#</label>
						<input class="data-entry-input reqdClr" type="text" name="newData" id="newData_#tbl#" required>
					</div>
					<cfif variables.pkExtraCols neq "">
						<cfloop list="#variables.pkExtraCols#" index="variables.pkc">
							<div class="col">
								<label class="form-label" for="ec_#variables.pkc#_#tbl#">#variables.pkc#</label>
								<input class="data-entry-input" type="text" name="ec_#variables.pkc#" id="ec_#variables.pkc#_#tbl#">
							</div>
						</cfloop>
					</cfif>
					<cfif variables.extraCols neq "">
						<cfloop list="#variables.extraCols#" index="variables.ec">
							<div class="col">
								<label class="form-label" for="ec_#variables.ec#_#tbl#">#variables.ec#</label>
								<input class="data-entry-input" type="text" name="ec_#variables.ec#" id="ec_#variables.ec#_#tbl#">
							</div>
						</cfloop>
					</cfif>
					<cfif hasDescn gt 0>
						<div class="col">
							<label class="form-label" for="description">Description</label>
							<textarea class="data-entry-textarea" name="description" id="description" rows="4" cols="40"></textarea>
						</div>
					</cfif>
					<div class="col-auto">
						<input type="submit" 
							value="Insert" 
							class="btn btn-xs btn-secondary mt-4">	
					</div>
				</div>
			</form>
		</div>
		<cfset i = 1>
		<h3 class="h5 mt-3 mb-2">Edit Existing Values to #fld#</h3>
		<div class="row border rounded my-2 mx-1 p-2">
			<div class="d-table w-100">
				<div class="d-table-row bg-light border-bottom">
					<cfif collcde gt 0>
						<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Collection Type</div>
					</cfif>
					<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">#fld#</div>
					<cfif variables.pkExtraCols neq "">
						<cfloop list="#variables.pkExtraCols#" index="variables.pkc">
							<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">#variables.pkc#</div>
						</cfloop>
					</cfif>
					<cfif variables.extraCols neq "">
						<cfloop list="#variables.extraCols#" index="variables.ec">
							<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">#variables.ec#</div>
						</cfloop>
					</cfif>
					<cfif hasDescn gt 0>
						<div class="d-table-cell fw-bold small text-muted pb-1 pr-3">Description</div>
					</cfif>
					<div class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
				</div>
				<cfloop query="q">
					<form class="d-table-row" name="#tbl##i#" method="post" action="/vocabularies/manageControlledVocabulary.cfm">
						<input type="hidden" name="Action">
						<input type="hidden" name="tbl" value="#tbl#">
						<input type="hidden" name="fld" value="#fld#">
						<input type="hidden" name="collcde" value="#collcde#">
						<input type="hidden" name="hasDescn" value="#hasDescn#">
						<input type="hidden" name="origData" value="#q.data#">
						<input type="hidden" name="pkExtraCols" value="#variables.pkExtraCols#">
						<input type="hidden" name="extraCols" value="#variables.extraCols#">
						<cfif collcde gt 0>
							<input type="hidden" name="origcollection_cde" value="#q.collection_cde#">
							<cfset thisColl=#q.collection_cde#>
							<div class="d-table-cell py-1 pr-3 align-middle">
								<select class="data-entry-select" name="collection_cde" size="1">
									<cfloop query="ctcollcde">
										<option 
											<cfif #thisColl# is "#ctcollcde.collection_cde#"> selected </cfif>value="#ctcollcde.collection_cde#">#ctcollcde.collection_cde#</option>
									</cfloop>
								</select>
							</div>
						</cfif>
						<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
							<input class="data-entry-input w-100" type="text" name="thisField" value="#q.data#">
						</div>
						<cfif variables.pkExtraCols neq "">
							<cfloop list="#variables.pkExtraCols#" index="variables.pkc">
								<cfset variables.pkcVal = q[variables.pkc][q.currentrow]>
								<input type="hidden" name="origpk_#variables.pkc#" value="#variables.pkcVal#">
								<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:8rem">
									<input class="data-entry-input w-100" type="text" name="ec_#variables.pkc#" value="#variables.pkcVal#">
								</div>
							</cfloop>
						</cfif>
						<cfif variables.extraCols neq "">
							<cfloop list="#variables.extraCols#" index="variables.ec">
								<cfset variables.ecVal = q[variables.ec][q.currentrow]>
								<div class="d-table-cell py-1 pr-3 align-middle" style="min-width:8rem">
									<input class="data-entry-input w-100" type="text" name="ec_#variables.ec#" value="#variables.ecVal#">
								</div>
							</cfloop>
						</cfif>
						<cfif hasDescn gt 0>
							<div class="d-table-cell py-1 pr-3 align-middle">
								<textarea class="data-entry-textarea" name="description" rows="4" cols="40">#q.description#</textarea>
							</div>
						</cfif>
						<div class="d-table-cell py-1 align-middle text-nowrap">
							<input type="button" 
								value="Save" 
								class="btn btn-xs btn-primary"
								onclick="#tbl##i#.Action.value='saveEdit';submit();">
							<input type="button" 
								value="Delete" 
								class="btn btn-xs btn-danger"
								onclick="#tbl##i#.Action.value='deleteValue';submit();">
						</div>
					</form>
					<cfset i = #i#+1>
				</cfloop>
			</div>
		</div>
	</cfif>
<cfelseif action is "deleteValue">
	<cfif tbl is "ctpublication_attribute">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			delete from ctpublication_attribute 
			where
				publication_attribute=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctnomenclatural_code">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			delete from ctnomenclatural_code 
			where
				nomenclatural_code=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctguid_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			delete from ctguid_type
			where
				GUID_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctloan_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			delete from ctloan_type
			where
				LOAN_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctcountry_code">
		<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			delete from ctcountry_code
			where
				COUNTRY = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctbiol_relations">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			delete from ctbiol_relations
			where
				BIOL_INDIV_RELATIONSHIP=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#">
		</cfquery>
	<cfelseif tbl is "CTAUTHORSHIP_ROLE">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			DELETE FROM ctauthorship_role
			WHERE
				authorship_role=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#">
		</cfquery>
	<cfelseif tbl is "ctcitation_type_status">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			delete from ctcitation_type_status
			where
				type_status=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#">
		</cfquery>
	<cfelseif tbl is "ctgeology_attributes">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			delete from ctgeology_attributes
			where
				geology_attribute=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#">
		</cfquery>
	<cfelseif tbl is "ctcoll_other_id_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			delete from ctcoll_other_id_type
			where
				OTHER_ID_TYPE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "cttaxon_relation">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			DELETE FROM cttaxon_relation
			WHERE
				taxon_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctattribute_code_tables">
		<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			DELETE FROM ctattribute_code_tables
			WHERE
				Attribute_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#oldAttribute_type#" />
				<cfif len(oldvalue_code_table) gt 0>
					AND	value_code_table = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#oldvalue_code_table#" />
				</cfif>
				<cfif len(oldunits_code_table) gt 0>
					AND	units_code_table = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#oldunits_code_table#" />
				</cfif>
		</cfquery>
	<cfelseif tbl is "ctspecimen_part_list_order">
		<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			DELETE FROM ctspecimen_part_list_order
			WHERE
				partname = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#oldpartname#" /> AND
				list_order = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oldlist_order#" />
		</cfquery>
	<cfelseif tbl is "ctunderscore_collection_type">
		<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			DELETE FROM ctunderscore_collection_type
			WHERE
				underscore_collection_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#oldunderscore_collection_type#">
		</cfquery>
	<cfelseif tbl is "ctunderscore_coll_agent_role">
		<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			DELETE FROM ctunderscore_coll_agent_role 
			WHERE
				role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#">
		</cfquery>
	<cfelseif tbl is "ctspecific_permit_type">
		<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			DELETE FROM ctspecific_permit_type
			WHERE
				specific_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctmedia_relationship">
		<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			DELETE FROM ctmedia_relationship
			WHERE
				MEDIA_RELATIONSHIP = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "CTTAXON_CATEGORY">
		<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			DELETE FROM CTTAXON_CATEGORY
			WHERE
				taxon_category = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "CTTAXON_ATTRIBUTE_TYPE">
		<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			DELETE FROM CTTAXON_ATTRIBUTE_TYPE
			WHERE
				taxon_attribute_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "CTSTATE">
		<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			DELETE FROM CTSTATE
			WHERE
				state = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelse>
		<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			DELETE FROM #tbl# 
			WHERE #fld# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
			<cfif isdefined("form.pkExtraCols") and len(form.pkExtraCols) gt 0>
				<cfloop list="#form.pkExtraCols#" index="variables.pkc">
					AND #variables.pkc# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form['origpk_' & variables.pkc]#" />
				</cfloop>
			</cfif>
			<cfif isdefined("collection_cde") and len(collection_cde) gt 0>
				AND collection_cde=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origcollection_cde#" />
			</cfif>
		</cfquery>
	</cfif>
	<cflocation url="/vocabularies/manageControlledVocabulary.cfm?action=edit&tbl=#tbl#" addtoken="false">
<cfelseif action is "saveEdit">
	<cfif tbl is "ctpublication_attribute">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			update ctpublication_attribute set 
				publication_attribute=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#publication_attribute#">,
				DESCRIPTION=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">,
				control=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#control#">,
				mcz_publication_fg=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#mcz_publication_fg#">
			where
				publication_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctnomenclatural_code">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			update ctnomenclatural_code set 
				nomenclatural_code=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nomenclatural_code#">,
				DESCRIPTION=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">,
				sort_order=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#sort_order#">
			where
				nomenclatural_code = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctguid_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			update ctguid_type set 
				GUID_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#guid_type#" />,
				description= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />,
				applies_to= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#applies_to#" />,
				search_uri = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#search_uri#" />,
				placeholder= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#placeholder#" />,
				pattern_regex= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pattern_regex#" />,
				resolver_regex= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#resolver_regex#" />,
				resolver_replacement= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#resolver_replacement#" />
			where
				GUID_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctloan_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			update ctloan_type set 
				LOAN_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#loan_type#" />,
				SCOPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#scope#" />,
				ORDINAL= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ordinal#" />
			where
				LOAN_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctcountry_code">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			update ctcountry_code set 
				COUNTRY= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#country#" />,
				CODE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#code#" />
			where
				COUNTRY= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctspecific_permit_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			update ctspecific_permit_type set 
				SPECIFIC_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#specific_type#" />,
				PERMIT_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_type#" />,
				ACCN_SHOW_ON_SHIPMENT= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accn_show_on_shipment#" />
			where
				SPECIFIC_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctbiol_relations">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			update ctbiol_relations set 
				BIOL_INDIV_RELATIONSHIP= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#biol_indiv_relationship#" />,
				INVERSE_RELATION= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#inverse_relation#" />,
				REL_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#rel_type#" />
			where
				BIOL_INDIV_RELATIONSHIP= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "CTAUTHORSHIP_ROLE">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE ctauthorship_role 
			SET 
				authorship_role= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#authorship_role#" />,
				ordinal = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ordinal#" />,
				nomenclatural_code = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nomenclatural_code#" />,
				description= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />
			WHERE
				AUTHORSHIP_ROLE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctcitation_type_status">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			update ctcitation_type_status set 
				TYPE_STATUS= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#type_status#" />,
				CATEGORY= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#category#" />,
				ORDINAL= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ordinal#" />,
				DESCRIPTION= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />
			where
				TYPE_STATUS= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctgeology_attributes">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE ctgeology_attributes SET 
				geology_attribute= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#geology_attribute#" />,
				TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#type#" />,
				ORDINAL= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ordinal#" />,
				DESCRIPTION= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />
			WHERE
				geology_attribute= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctcoll_other_id_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			update ctcoll_other_id_type set 
				OTHER_ID_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#other_id_type#" />,
				DESCRIPTION= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />,
				BASE_URL = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#base_url#" />,
				encumber_as_field_num = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumber_as_field_num#" />
			where
				OTHER_ID_TYPE= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "cttaxon_relation">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE cttaxon_relation SET 
				taxon_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxon_relationship#" />,
				description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />,
				inverse_relation = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#inverse_relation#" />
			WHERE
				taxon_relationship = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "ctattribute_code_tables">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE ctattribute_code_tables SET
				Attribute_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Attribute_type#" />,
				value_code_table = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#value_code_table#" />,
				units_code_table = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#units_code_table#" />
			WHERE
				Attribute_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#oldAttribute_type#" />
				<cfif len(oldvalue_code_table) gt 0>
					AND value_code_table = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#oldvalue_code_table#" />
				</cfif>
				<cfif len(oldunits_code_table) gt 0>
					AND units_code_table = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#oldunits_code_table#" />
				</cfif>
		</cfquery>
	<cfelseif tbl is "ctspecimen_part_list_order">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE ctspecimen_part_list_order SET
				partname = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#partname#" />,
				list_order = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#list_order#" />
			WHERE
				partname = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#oldpartname#" /> AND
				list_order = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#oldlist_order#" />
		</cfquery>
	<cfelseif tbl is "ctunderscore_collection_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE ctunderscore_collection_type SET 
				underscore_collection_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#underscore_collection_type#" />,
				description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />,
				allowed_agent_roles = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#allowed_agent_roles#" />
			WHERE
				underscore_collection_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#oldunderscore_collection_type#" />
		</cfquery>
	<cfelseif tbl is "ctunderscore_coll_agent_role">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE ctunderscore_coll_agent_role 
			SET
				role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#role#">,
				description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">,
				ordinal = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ordinal#">,
				label = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#label#">,
				inverse_label = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#inverse_label#">
			WHERE
				role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#">
		</cfquery>
	<cfelseif tbl is "ctmedia_relationship">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			update ctmedia_relationship set 
				MEDIA_RELATIONSHIP = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#media_relationship#" />,
				DESCRIPTION = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />,
				LABEL = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#label#" />
			where
				MEDIA_RELATIONSHIP = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "CTTAXON_CATEGORY">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE cttaxon_category 
			SET 
				taxon_category = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxon_category#" />,
				description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />,
				category_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#category_type#" />,
				hidden_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#hidden_fg#" />
			WHERE
				taxon_category = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "CTTAXON_ATTRIBUTE_TYPE">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE cttaxon_attribute_type 
			SET 
				taxon_attribute_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#taxon_attribute_type#" />,
				description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />,
				hidden_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#hidden_fg#" />
			WHERE
				taxon_attribute_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelseif tbl is "CTSTATE">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE ctstate 
			SET 
				state = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#state#" />,
				description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />,
				state_curie = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#state_curie#" />
			WHERE
				state = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
		</cfquery>
	<cfelse>
		<cfquery name="up" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE #tbl# SET #fld# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#thisField#" />
			<cfif isdefined("form.pkExtraCols") and len(form.pkExtraCols) gt 0>
				<cfloop list="#form.pkExtraCols#" index="variables.pkc">
					,#variables.pkc# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form['ec_' & variables.pkc]#" />
				</cfloop>
			</cfif>
			<cfif isdefined("form.extraCols") and len(form.extraCols) gt 0>
				<cfloop list="#form.extraCols#" index="variables.ec">
					,#variables.ec# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form['ec_' & variables.ec]#" />
				</cfloop>
			</cfif>
			<cfif isdefined("collection_cde") and len(collection_cde) gt 0>
				,collection_cde=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_cde#" />
			</cfif>
			<cfif isdefined("description")>
				,description=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />
			</cfif>
			WHERE #fld# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origData#" />
			<cfif isdefined("form.pkExtraCols") and len(form.pkExtraCols) gt 0>
				<cfloop list="#form.pkExtraCols#" index="variables.pkc">
					AND #variables.pkc# = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form['origpk_' & variables.pkc]#" />
				</cfloop>
			</cfif>
			<cfif isdefined("collection_cde") and len(collection_cde) gt 0>
				AND collection_cde=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#origcollection_cde#" />
			</cfif>
		</cfquery>
	</cfif>
	<cflocation url="/vocabularies/manageControlledVocabulary.cfm?action=edit&tbl=#tbl#" addtoken="false">
<cfelseif action is "newValue">
	<cfif tbl is "ctpublication_attribute">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			insert into ctpublication_attribute (
				publication_attribute,
				DESCRIPTION,
				control
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#newData#'>,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#description#'>,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#control#'>,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#mcz_publication_fg#'>
			)
		</cfquery>
	<cfelseif tbl is "ctnomenclatural_code">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			insert into ctnomenclatural_code(
				nomenclatural_code,
				DESCRIPTION,
				sort_order
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#newData#'>,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#description#'>,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#sort_order#'>
			)
		</cfquery>
	<cfelseif tbl is "ctguid_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			insert into ctguid_type (
				 guid_type, description, applies_to, search_uri, placeholder, pattern_regex, resolver_regex, resolver_replacement
			) VALUES (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#applies_to#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#search_uri#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#placeholder#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#pattern_regex#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#resolver_regex#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#resolver_replacement#" />
			)
		</cfquery>
	<cfelseif tbl is "ctloan_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			insert into ctloan_type (
				loan_type,
				scope,
				ordinal
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#scope#" />,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ordinal#" />
			)
		</cfquery>
	<cfelseif tbl is "ctcountry_code">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			insert into ctcountry_code (
				country,
				code
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#code#" />
			)
		</cfquery>
	<cfelseif tbl is "ctspecific_permit_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			insert into ctspecific_permit_type (
				specific_type,
				permit_type,
				accn_show_on_shipment
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#permit_type#" />,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#accn_show_on_shipment#" />
			)
		</cfquery>
	<cfelseif tbl is "ctbiol_relations">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			insert into ctbiol_relations (
				biol_indiv_relationship,
				inverse_relation,
				rel_type
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#inverse_relation#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#rel_type#" />
			)
		</cfquery>
	<cfelseif tbl is "CTAUTHORSHIP_ROLE">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO ctauthorship_role (
				authorship_role,
				ordinal,
				nomenclatural_code,
				description
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ordinal#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nomenclatural_code#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />
			)
		</cfquery>
	<cfelseif tbl is "ctcitation_type_status">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO ctcitation_type_status (
				type_status,
				category,
				ordinal,
				description
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#category#" />,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ordinal#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />
			)
		</cfquery>
	<cfelseif tbl is "ctgeology_attributes">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO ctgeology_attributes (
				geology_attribute,
				type,
				ordinal,
				description
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#type#" />,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ordinal#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />
			)
		</cfquery>
	<cfelseif tbl is "ctcoll_other_id_type">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			insert into ctcoll_other_id_type (
				OTHER_ID_TYPE,
				DESCRIPTION,
				base_URL,
				encumber_as_field_num
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#base_url#" />,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumber_as_field_num#" />
			)
		</cfquery>
	<cfelseif tbl is "cttaxon_relation">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			insert into cttaxon_relation (
				taxon_relationship,
				DESCRIPTION,
				inverse_relation
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#inverse_relation#" />
			)
		</cfquery>
	<cfelseif tbl is "ctattribute_code_tables">
		<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO ctattribute_code_tables (
				Attribute_type
				<cfif len(value_code_table) gt 0>
					,value_code_table
				</cfif>
				<cfif len(units_code_table) gt 0>
					,units_code_table
				</cfif>
				)
			VALUES (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#Attribute_type#" />
				<cfif len(value_code_table) gt 0>
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#value_code_table#" />
				</cfif>
				<cfif len(units_code_table) gt 0>
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#units_code_table#" />
				</cfif>
			)
		</cfquery>
	<cfelseif tbl is "ctspecimen_part_list_order">
		<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO ctspecimen_part_list_order (
				partname,
				list_order
				)
			VALUES (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#partname#" />,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#list_order#" />
			)
		</cfquery>
	<cfelseif tbl is "ctunderscore_collection_type">
		<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO ctunderscore_collection_type (
				underscore_collection_type,
				description,
				allowed_agent_roles
				)
			VALUES (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#allowed_agent_roles#">
			)
		</cfquery>
	<cfelseif tbl is "ctunderscore_coll_agent_role">
		<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO ctunderscore_coll_agent_role (
				role,
				description,
				ordinal,
				label,
				inverse_label
				)
			VALUES (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#ordinal#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#label#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#inverse_label#">
			)
		</cfquery>
	<cfelseif tbl is "CTMEDIA_RELATIONSHIP">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO ctmedia_relationship (
				media_relationship,
				label,
				description
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#label#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />
			)
		</cfquery>
	<cfelseif tbl is "CTTAXON_CATEGORY">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO cttaxon_category (
				taxon_category,
				category_type,
				description,
				hidden_fg
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#category_type#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#hidden_fg#" />
			)
		</cfquery>
	<cfelseif tbl is "CTTAXON_ATTRIBUTE_TYPE">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO cttaxon_attribute_type (
				taxon_attribute_type,
				hidden_fg,
				description
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#hidden_fg#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />
			)
		</cfquery>
	<cfelseif tbl is "CTSTATE">
		<cfquery name="sav" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO ctstate (
				state,
				state_curie,
				description
			) values (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#state_curie#" />,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#" />
			)
		</cfquery>
	<cfelse>
		<cfquery name="new" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO #tbl# 
				(#fld#
				<cfif isdefined("form.pkExtraCols") and len(form.pkExtraCols) gt 0>
					<cfloop list="#form.pkExtraCols#" index="variables.pkc">
						,#variables.pkc#
					</cfloop>
				</cfif>
				<cfif isdefined("form.extraCols") and len(form.extraCols) gt 0>
					<cfloop list="#form.extraCols#" index="variables.ec">
						,#variables.ec#
					</cfloop>
				</cfif>
				<cfif isdefined("collection_cde") and len(collection_cde) gt 0>
					 ,collection_cde
				</cfif>
				<cfif isdefined("description") and len(description) gt 0>
					 ,description
				</cfif>
				)
			VALUES 
				(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newData#" />
				<cfif isdefined("form.pkExtraCols") and len(form.pkExtraCols) gt 0>
					<cfloop list="#form.pkExtraCols#" index="variables.pkc">
						, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form['ec_' & variables.pkc]#" />
					</cfloop>
				</cfif>
				<cfif isdefined("form.extraCols") and len(form.extraCols) gt 0>
					<cfloop list="#form.extraCols#" index="variables.ec">
						, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#form['ec_' & variables.ec]#" />
					</cfloop>
				</cfif>
				<cfif isdefined("collection_cde") and len(collection_cde) gt 0>
					 , <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#collection_cde#'>
				</cfif>
				<cfif isdefined("description") and len(description) gt 0>
					 , <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#description#'>
				</cfif>
			)
		</cfquery>
	</cfif>
	<cflocation url="/vocabularies/manageControlledVocabulary.cfm?action=edit&tbl=#tbl#" addtoken="false">
</cfif>
				</div>
			</div>
		</div>
	</main>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
