<cfset pageTitle = "Specimen Part Names">
<!---
/Admin/ctspecimen_part_name.cfm

Manage the ctspecimen_part_name controlled vocabulary table. Provides insert
for new specimen part name records, and in-place edit/delete via legacy
JavaScript modal and AJAX helpers (existing behavior preserved).

Delete uses $.getJSON to /component/functions.cfc?method=deleteCtPartName.
Update uses an iframe overlay with /includes/forms/f_ctspecimen_part_name.cfm.

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

<cfif variables.action IS "insert">
<cfif isDefined("form.collection_cde") AND isDefined("form.part_name") AND len(trim(form.part_name)) GT 0
D isDefined("form.is_tissue") AND isDefined("form.description")>
 name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
SERT INTO ctspecimen_part_name (collection_cde, part_name, description, is_tissue)
(
param cfsqltype="CF_SQL_VARCHAR" value="#trim(form.collection_cde)#">,
param cfsqltype="CF_SQL_VARCHAR" value="#trim(form.part_name)#">,
param cfsqltype="CF_SQL_VARCHAR" value="#trim(form.description)#">,
param cfsqltype="CF_SQL_INTEGER" value="#val(form.is_tissue)#">
>
</cfif>
<cflocation url="/Admin/ctspecimen_part_name.cfm" addtoken="false">
</cfif>

<cfquery name="q" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
SELECT ctspnid, collection_cde, part_name, is_tissue, description
FROM ctspecimen_part_name
ORDER BY collection_cde, part_name
</cfquery>
<cfquery name="ctcollcde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
SELECT DISTINCT collection_cde FROM ctcollection_cde ORDER BY collection_cde
</cfquery>

<script>
function doneSaving() {
notateDiv').remove();
ction deletePart(ctspnid) {
(confirm("Delete Part?")) {
("/component/functions.cfc",
"deleteCtPartName",
id: ctspnid,
format: "json",
format: "column"
ction(r) {
(r == ctspnid) {
+ ctspnid).remove();
else {
 error occurred!\n " + r);
ction updatePart(ctspnid) {
bgDiv = document.createElement("div");
= "bgDiv";
ame = "bgDiv";
t.body.appendChild(bgDiv);
click", "doneSaving()");
theDiv = document.createElement("div");
= "annotateDiv";
ame = "annotateBox";
nerHTML = "";
t.body.appendChild(theDiv);
notateDiv').append('<iframe id="frame_ctspid" width="100%" height="100%">');
guts = "/includes/forms/f_ctspecimen_part_name.cfm?ctspnid=" + ctspnid;
guts);
("load", function() {
it("#annotateDiv");
it("#bgDiv");
ction successUpdate(ctspnid, collection_cde, part_name, is_tissue, description, upAllDesc, upAllTiss) {
(upAllDesc == 1 || upAllTiss == 1) {
t.location = document.location;
r = '<td>' + collection_cde + '</td><td>' + part_name + '</td><td>' + is_tissue + '</td>';
+= '<td>' + unescape(description) + '</td><td class="text-nowrap">';
+= '<button type="button" class="btn btn-xs btn-danger mr-1" onclick="deletePart(' + ctspnid + ')">Delete</button>';
+= '<button type="button" class="btn btn-xs btn-primary" onclick="updatePart(' + ctspnid + ')">Update</button>';
+ ctspnid).children().remove();
+ ctspnid).append(r);
eSaving();
}
</script>

<cfoutput>
<main id="content" aria-labelledby="pageHeading">
<div class="container-fluid">
class="row">
class="col-12">
id="pageHeading" class="h3 mt-3 mb-2">Specimen Part Names</h1>
class="text-muted small mb-3">Manage the controlled vocabulary of specimen part names. Each part name is associated with a collection type and optionally flagged as tissue.</p>

 aria-labelledby="addPartNameHeading">
id="addPartNameHeading" class="h5 mt-3 mb-2 text-success">Add Specimen Part Name</h2>
class="row border rounded my-2 mx-1 p-2 bg-light">
method="post" action="/Admin/ctspecimen_part_name.cfm">
put type="hidden" name="action" value="insert">
class="form-row mb-2 flex-nowrap align-items-end">
class="col">
class="form-label" for="new_collection_cde">Collection Type</label>
id="new_collection_cde" class="data-entry-select reqdClr w-100" name="collection_cde" required>
query="ctcollcde">
 value="#HTMLEditFormat(ctcollcde.collection_cde)#">#HTMLEditFormat(ctcollcde.collection_cde)#</option>
class="col">
class="form-label" for="new_part_name">Part Name</label>
put id="new_part_name" class="data-entry-input reqdClr w-100" type="text" name="part_name" required>
class="col">
class="form-label" for="new_is_tissue">Is Tissue?</label>
id="new_is_tissue" class="data-entry-select w-100" name="is_tissue">
 value="0">No</option>
 value="1">Yes</option>
class="col">
class="form-label" for="new_description">Description</label>
id="new_description" class="data-entry-textarea w-100" name="description" rows="2"></textarea>
class="col-auto">
put type="submit" value="Insert" class="btn btn-xs btn-secondary mt-4">
>

 aria-labelledby="editPartNamesHeading">
id="editPartNamesHeading" class="h5 mt-3 mb-2">Edit Specimen Part Names</h2>
q.recordCount EQ 0>
class="text-muted">No specimen part names have been defined yet.</p>
class="table-responsive">
class="table table-sm table-striped">
class="thead-light">
scope="col">Collection Type</th>
scope="col">Part Name</th>
scope="col">Is Tissue</th>
scope="col">Description</th>
scope="col" class="text-nowrap">Actions</th>
>
query="q">
id="r#q.ctspnid#">
_cde)#</td>
ame)#</td>
)#</td>
class="text-nowrap">
 type="button" class="btn btn-xs btn-danger mr-1" onclick="deletePart(#q.ctspnid#)">Delete</button>
 type="button" class="btn btn-xs btn-primary" onclick="updatePart(#q.ctspnid#)">Update</button>
>
>

>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
