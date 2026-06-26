<cfset pageTitle = "Specimen Part Attribute Controls">
<!---
/Admin/ctspec_part_att_att.cfm

Manage the ctspec_part_att_att controlled vocabulary table. Maps specimen part
attribute types to their value and unit controlled vocabulary (code) tables.

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
<cfinclude template="/shared/_header.cfm">

<cfset variables.action = "entryPoint">
<cfif isDefined("form.action") AND len(trim(form.action)) GT 0>
<cfset variables.action = trim(form.action)>
<cfelseif isDefined("url.action") AND len(trim(url.action)) GT 0>
<cfset variables.action = trim(url.action)>
</cfif>

<cfif variables.action IS "saveEdit">
<cfif isDefined("form.attribute_type") AND len(trim(form.attribute_type)) GT 0>
 name="upd" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
ctspec_part_att_att SET
= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.value_code_table)#">,
it_code_table  = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.unit_code_table)#">
attribute_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.attribute_type)#">
>
</cfif>
<cflocation url="/Admin/ctspec_part_att_att.cfm" addtoken="false">
</cfif>

<cfif variables.action IS "deleteValue">
<cfif isDefined("form.attribute_type") AND len(trim(form.attribute_type)) GT 0>
 name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
FROM ctspec_part_att_att
attribute_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.attribute_type)#">
>
</cfif>
<cflocation url="/Admin/ctspec_part_att_att.cfm" addtoken="false">
</cfif>

<cfif variables.action IS "newValue">
<cfif isDefined("form.attribute_type") AND len(trim(form.attribute_type)) GT 0>
 name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
SERT INTO ctspec_part_att_att (attribute_type, value_code_table, unit_code_table)
(
param cfsqltype="CF_SQL_VARCHAR" value="#trim(form.attribute_type)#">,
param cfsqltype="CF_SQL_VARCHAR" value="#trim(form.value_code_table)#">,
param cfsqltype="CF_SQL_VARCHAR" value="#trim(form.unit_code_table)#">
>
</cfif>
<cflocation url="/Admin/ctspec_part_att_att.cfm" addtoken="false">
</cfif>

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

<cfoutput>
<main id="content" aria-labelledby="pageHeading">
<div class="container-fluid">
class="row">
class="col-12">
id="pageHeading" class="h3 mt-3 mb-2">Specimen Part Attribute Controls</h1>
class="text-muted small mb-3">Maps each specimen part attribute type to its value controlled vocabulary table and (optionally) its unit controlled vocabulary table.</p>

 aria-labelledby="addControlHeading">
id="addControlHeading" class="h5 mt-3 mb-2 text-success">Add Attribute Control</h2>
class="row border rounded my-2 mx-1 p-2 bg-light">
method="post" action="/Admin/ctspec_part_att_att.cfm">
put type="hidden" name="action" value="newValue">
class="form-row mb-2 flex-nowrap align-items-end">
class="col">
class="form-label" for="new_attribute_type">Attribute Type</label>
id="new_attribute_type" class="data-entry-select w-100" name="attribute_type">
 value=""></option>
query="ctAttribute_type">
 value="#HTMLEditFormat(ctAttribute_type.attribute_type)#">#HTMLEditFormat(ctAttribute_type.attribute_type)#</option>
class="col">
class="form-label" for="new_value_code_table">Value Code Table</label>
id="new_value_code_table" class="data-entry-select w-100" name="value_code_table">
 value="">none</option>
query="allCTs">
 value="#HTMLEditFormat(allCTs.tablename)#">#HTMLEditFormat(allCTs.tablename)#</option>
class="col">
class="form-label" for="new_unit_code_table">Unit Code Table</label>
id="new_unit_code_table" class="data-entry-select w-100" name="unit_code_table">
 value="">none</option>
query="allCTs">
 value="#HTMLEditFormat(allCTs.tablename)#">#HTMLEditFormat(allCTs.tablename)#</option>
class="col-auto">
put type="submit" value="Create" class="btn btn-xs btn-secondary mt-4">
>

 aria-labelledby="editControlsHeading">
id="editControlsHeading" class="h5 mt-3 mb-2">Edit Attribute Controls</h2>
thisRec.recordCount EQ 0>
class="text-muted">No attribute controls have been defined yet.</p>
class="row border rounded my-2 mx-1 p-2">
class="d-table w-100">
class="d-table-row bg-light border-bottom">
class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Attribute Type</div>
class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Value Code Table</div>
class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Unit Code Table</div>
class="d-table-cell fw-bold small text-muted pb-1 pr-3 text-nowrap">Actions</div>
variables.i = 1>
query="thisRec">
variables.fid = "att" & variables.i>
variables.thisValueTable = thisRec.value_code_table>
variables.thisUnitTable = thisRec.unit_code_table>
class="d-table-row" name="#variables.fid#" id="#variables.fid#" method="post" action="/Admin/ctspec_part_att_att.cfm">
put type="hidden" name="action" value="">
put type="hidden" name="attribute_type" value="#HTMLEditFormat(thisRec.attribute_type)#">
class="d-table-cell py-1 pr-3 align-middle" style="min-width:10rem">
pe)#
class="d-table-cell py-1 pr-3 align-middle">
class="sr-only" for="val_#variables.i#">Value Code Table for #HTMLEditFormat(thisRec.attribute_type)#</label>
id="val_#variables.i#" class="data-entry-select w-100" name="value_code_table">
 value="">none</option>
query="allCTs">
variables.selVal = (variables.thisValueTable IS allCTs.tablename) ? "selected='selected'" : "">
 #variables.selVal# value="#HTMLEditFormat(allCTs.tablename)#">#HTMLEditFormat(allCTs.tablename)#</option>
class="d-table-cell py-1 pr-3 align-middle">
class="sr-only" for="unit_#variables.i#">Unit Code Table for #HTMLEditFormat(thisRec.attribute_type)#</label>
id="unit_#variables.i#" class="data-entry-select w-100" name="unit_code_table">
 value="">none</option>
query="allCTs">
variables.selUnit = (variables.thisUnitTable IS allCTs.tablename) ? "selected='selected'" : "">
 #variables.selUnit# value="#HTMLEditFormat(allCTs.tablename)#">#HTMLEditFormat(allCTs.tablename)#</option>
class="d-table-cell py-1 align-middle text-nowrap">
put type="button"
 btn-xs btn-primary"
click="#variables.fid#.action.value='saveEdit';#variables.fid#.submit();">
put type="button"
 btn-xs btn-danger"
click="if(confirm('Delete this attribute control?')){#variables.fid#.action.value='deleteValue';#variables.fid#.submit();}">
variables.i = variables.i + 1>
>

>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
