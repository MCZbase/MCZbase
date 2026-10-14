<cfset pageTitle = "Specimen Part Attribute Controls">
<!---
/vocabularies/ctspec_part_att_att.cfm

Manage ctspec_part_att_att: maps specimen part attribute types to code tables for
value and unit selects. Provides update and delete of existing mappings and insert
of new mappings.

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
<cfset variables.action = "entryPoint">
<cfif isDefined("form.action") AND len(trim(form.action)) GT 0>
	<cfset variables.action = trim(form.action)>
<cfelseif isDefined("url.action") AND len(trim(url.action)) GT 0>
	<cfset variables.action = trim(url.action)>
</cfif>

<cfswitch expression="#variables.action#">
	<cfcase value="saveEdit">
		<cfif isDefined("form.attribute_type") AND len(trim(form.attribute_type)) GT 0>
			<cfquery name="upd" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				UPDATE ctspec_part_att_att SET
					value_code_table = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.value_code_table)#">,
					unit_code_table  = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.unit_code_table)#">
				WHERE attribute_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.attribute_type)#">
			</cfquery>
		</cfif>
		<cflocation url="/vocabularies/ctspec_part_att_att.cfm" addtoken="false">
	</cfcase>
	<cfcase value="deleteValue">
		<cfif isDefined("form.attribute_type") AND len(trim(form.attribute_type)) GT 0>
			<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				DELETE FROM ctspec_part_att_att
				WHERE attribute_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.attribute_type)#">
			</cfquery>
		</cfif>
		<cflocation url="/vocabularies/ctspec_part_att_att.cfm" addtoken="false">
	</cfcase>
	<cfcase value="newValue">
		<cfif isDefined("form.attribute_type") AND len(trim(form.attribute_type)) GT 0>
			<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				INSERT INTO ctspec_part_att_att (attribute_type, value_code_table, unit_code_table)
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.attribute_type)#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.value_code_table)#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.unit_code_table)#">
				)
			</cfquery>
		</cfif>
		<cflocation url="/vocabularies/ctspec_part_att_att.cfm" addtoken="false">
	</cfcase>
</cfswitch>

<cfquery name="ctAttribute_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT DISTINCT attribute_type FROM ctspecpart_attribute_type ORDER BY attribute_type
</cfquery>
<cfquery name="thisRec" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT attribute_type, value_code_table, unit_code_table
	FROM ctspec_part_att_att
	ORDER BY attribute_type
</cfquery>
<cfquery name="allCTs" datasource="uam_god">
	SELECT DISTINCT table_name AS tablename
	FROM sys.user_tables
	WHERE table_name LIKE 'CT%'
	ORDER BY table_name
</cfquery>

<cfinclude template="/shared/_header.cfm">
<cfoutput>
<main id="content" aria-labelledby="pageHeading">
	<div class="container">
		<div class="row">
			<div class="col-12">
				<div class="d-flex justify-content-between align-items-center mt-3 mb-2">
					<h1 id="pageHeading" class="h3 mb-0">Specimen Part Attribute Controls</h1>
					<a href="/vocabularies/manageControlledVocabulary.cfm" class="btn btn-xs btn-outline-primary">Controlled vocabulary list</a>
				</div>
				<p class="text-muted small">Maps specimen part attribute types to code tables for value and unit selects.</p>

				<section aria-labelledby="addHeading">
					<h2 id="addHeading" class="h5 mt-3 mb-2 text-success">Add Attribute Control</h2>
					<div class="row border rounded my-2 mx-1 p-2 bg-light">
						<form method="post" action="/vocabularies/ctspec_part_att_att.cfm">
							<input type="hidden" name="action" value="newValue">
							<div class="form-row mb-1">
								<div class="col">
									<label class="form-label" for="newAttrType">Attribute Type</label>
									<select class="data-entry-select reqdClr" id="newAttrType" name="attribute_type" required>
										<option value=""></option>
										<cfloop query="ctAttribute_type">
										<option value="#encodeForHTML(ctAttribute_type.attribute_type)#">#encodeForHTML(ctAttribute_type.attribute_type)#</option>
										</cfloop>
									</select>
								</div>
								<div class="col">
									<label class="form-label" for="newValueCT">Value Code Table</label>
									<select class="data-entry-select" id="newValueCT" name="value_code_table">
										<option value="">none</option>
										<cfloop query="allCTs">
										<option value="#encodeForHTML(allCTs.tablename)#">#encodeForHTML(allCTs.tablename)#</option>
										</cfloop>
									</select>
								</div>
								<div class="col">
									<label class="form-label" for="newUnitCT">Unit Code Table</label>
									<select class="data-entry-select" id="newUnitCT" name="unit_code_table">
										<option value="">none</option>
										<cfloop query="allCTs">
										<option value="#encodeForHTML(allCTs.tablename)#">#encodeForHTML(allCTs.tablename)#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-auto">
									<input type="submit" value="Add" class="btn btn-xs btn-secondary mt-4">
								</div>
							</div>
						</form>
					</div>
				</section>

				<section aria-labelledby="editHeading">
					<h2 id="editHeading" class="h5 mt-3 mb-2">Edit Attribute Controls</h2>
					<div class="row border rounded my-2 mx-1 p-2">
						<div class="d-table w-100">
							<div class="d-table-row bg-light font-weight-bold border-bottom">
								<div class="d-table-cell p-2">Attribute Type</div>
								<div class="d-table-cell p-2">Value Code Table</div>
								<div class="d-table-cell p-2">Unit Code Table</div>
								<div class="d-table-cell p-2">Actions</div>
							</div>
							<cfset variables.fid = "">
							<cfloop query="thisRec">
								<cfset variables.fid = "att" & thisRec.currentRow>
								<form
									class="d-table-row"
									name="#variables.fid#"
									id="#variables.fid#"
									method="post"
									action="/vocabularies/ctspec_part_att_att.cfm">
									<input type="hidden" name="action" value="">
									<input type="hidden" name="attribute_type" value="#encodeForHTML(thisRec.attribute_type)#">
									<div class="d-table-cell py-1 pr-2 align-middle">
										#encodeForHTML(thisRec.attribute_type)#
									</div>
									<div class="d-table-cell py-1 pr-2 align-middle">
										<label class="sr-only" for="#variables.fid#_value_ct">Value Code Table</label>
										<select class="data-entry-select" id="#variables.fid#_value_ct" name="value_code_table">
											<option value="">none</option>
											<cfloop query="allCTs">
												<cfset variables.selVal = (thisRec.value_code_table IS allCTs.tablename) ? " selected" : "">
												<option value="#encodeForHTML(allCTs.tablename)#"#variables.selVal#>#encodeForHTML(allCTs.tablename)#</option>
											</cfloop>
										</select>
									</div>
									<div class="d-table-cell py-1 pr-2 align-middle">
										<label class="sr-only" for="#variables.fid#_unit_ct">Unit Code Table</label>
										<select class="data-entry-select" id="#variables.fid#_unit_ct" name="unit_code_table">
											<option value="">none</option>
											<cfloop query="allCTs">
												<cfset variables.selVal = (thisRec.unit_code_table IS allCTs.tablename) ? " selected" : "">
												<option value="#encodeForHTML(allCTs.tablename)#"#variables.selVal#>#encodeForHTML(allCTs.tablename)#</option>
											</cfloop>
										</select>
									</div>
									<div class="d-table-cell py-1 align-middle text-nowrap">
										<input type="button" class="btn btn-xs btn-primary mr-1" value="Save"
											onclick="document.getElementById('#variables.fid#').elements['action'].value='saveEdit';document.getElementById('#variables.fid#').submit();">
										<input type="button" class="btn btn-xs btn-danger" value="Delete"
											onclick="deleteMapping('#variables.fid#','#JSStringFormat(thisRec.attribute_type)#')">
									</div>
								</form>
							</cfloop>
						</div>
					</div>
				</section>
			</div>
		</div>
	</div>
</main>
</cfoutput>
<script>
function deleteMapping(formId, attributeType) {
	confirmDialog('Delete the attribute type mapping \u201c' + attributeType + '\u201d?', 'Confirm Delete', function() {
		document.getElementById(formId).elements['action'].value = 'deleteValue';
		document.getElementById(formId).submit();
	});
}
</script>
<cfinclude template="/shared/_footer.cfm">
