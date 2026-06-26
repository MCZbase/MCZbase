<cfset pageTitle = "Specimen Part Names">
<!---
/Admin/ctspecimen_part_name.cfm

Manage ctspecimen_part_name: specimen part names with collection scope and tissue flag.
Provides insert of new part names. Update and delete use existing AJAX/iframe helpers
(deletePart via /component/functions.cfc, updatePart via f_ctspecimen_part_name.cfm iframe).

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

<cfif variables.action IS "insert">
	<cfif isDefined("form.collection_cde") AND isDefined("form.part_name") AND len(trim(form.part_name)) GT 0
		AND isDefined("form.is_tissue") AND isDefined("form.description")>
		<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO ctspecimen_part_name (collection_cde, part_name, description, is_tissue)
			VALUES (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.collection_cde)#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.part_name)#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.description)#">,
				<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#val(form.is_tissue)#">
			)
		</cfquery>
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
		$('#frame_ctspid').remove();
		$('#annotateDiv').remove();
		$('#bgDiv').remove();
	}
	function deletePart(ctspnid) {
		if (confirm("Delete Part?")) {
			$.getJSON("/component/functions.cfc",
				{
					method : "deleteCtPartName",
					ctspnid : ctspnid,
					returnformat : "json",
					queryformat : "column"
				},
				function(r) {
					if (r == ctspnid) {
						$('tr#r' + ctspnid).remove();
					} else {
						alert('An error occurred!\n ' + r);
					}
				}
			);
		}
	}
	function updatePart(ctspnid) {
		var bgDiv = document.createElement("div");
		bgDiv.id = "bgDiv";
		bgDiv.className = "bgDiv";
		document.body.appendChild(bgDiv);
		bgDiv.setAttribute("onclick", "doneSaving()");
		var theDiv = document.createElement("div");
		theDiv.id = "annotateDiv";
		theDiv.className = "annotateBox";
		theDiv.innerHTML = "";
		document.body.appendChild(theDiv);
		$('#annotateDiv').append('<iframe id="frame_ctspid" width="100%" height="100%">');
		var guts = "/includes/forms/f_ctspecimen_part_name.cfm?ctspnid=" + ctspnid;
		$('iframe#frame_ctspid').attr("src", guts);
		$('iframe#frame_ctspid').on("load", function() {
			viewport.init("#annotateDiv");
			viewport.init("#bgDiv");
		});
	}
	function successUpdate(ctspnid, collection_cde, part_name, is_tissue, description, upAllDesc, upAllTiss) {
		if (upAllDesc == 1 || upAllTiss == 1) {
			document.location = document.location;
		}
		var r = '<td>' + collection_cde + '</td><td>' + part_name + '</td><td>' + is_tissue + '</td>';
		r += '<td>' + unescape(description) + '</td><td class="text-nowrap">';
		r += '<button type="button" class="btn btn-xs btn-danger mr-1" onclick="deletePart(' + ctspnid + ')">Delete</button>';
		r += '<button type="button" class="btn btn-xs btn-primary" onclick="updatePart(' + ctspnid + ')">Update</button>';
		r += '</td>';
		$('tr#r' + ctspnid).children().remove();
		$('tr#r' + ctspnid).append(r);
		doneSaving();
	}
</script>

<cfinclude template="/shared/_header.cfm">
<cfoutput>
<main id="content" aria-labelledby="pageHeading">
	<div class="row">
		<div class="col-12">
			<h1 id="pageHeading" class="h3 mt-3 mb-1">Specimen Part Names</h1>
			<p class="text-muted small">Manage specimen part names by collection type. Update and delete use the inline editor.</p>
		</div>
	</div>

	<section aria-labelledby="addHeading">
		<h2 id="addHeading" class="h5 mt-3 mb-2 text-success">Add Part Name</h2>
		<div class="border rounded p-3 bg-light mb-4">
			<form method="post" action="/Admin/ctspecimen_part_name.cfm">
				<input type="hidden" name="action" value="insert">
				<div class="form-row align-items-end">
					<div class="col-auto">
						<label class="col-form-label-sm font-weight-bold" for="newCollCde">Collection <span class="text-danger">*</span></label>
						<select class="form-control form-control-sm" id="newCollCde" name="collection_cde">
							<cfloop query="ctcollcde">
							<option value="#encodeForHTML(ctcollcde.collection_cde)#">#encodeForHTML(ctcollcde.collection_cde)#</option>
							</cfloop>
						</select>
					</div>
					<div class="col-auto">
						<label class="col-form-label-sm font-weight-bold" for="newPartName">Part Name <span class="text-danger">*</span></label>
						<input type="text" class="form-control form-control-sm" id="newPartName" name="part_name" required>
					</div>
					<div class="col-auto">
						<label class="col-form-label-sm font-weight-bold" for="newIsTissue">Is Tissue?</label>
						<select class="form-control form-control-sm" id="newIsTissue" name="is_tissue">
							<option value="0">no</option>
							<option value="1">yes</option>
						</select>
					</div>
					<div class="col">
						<label class="col-form-label-sm font-weight-bold" for="newDescription">Description</label>
						<textarea class="form-control form-control-sm" id="newDescription" name="description" rows="2"></textarea>
					</div>
					<div class="col-auto">
						<button type="submit" class="btn btn-sm btn-success">Add</button>
					</div>
				</div>
			</form>
		</div>
	</section>

	<section aria-labelledby="listHeading">
		<h2 id="listHeading" class="h5 mt-2 mb-2">Part Names</h2>
		<table class="table table-sm table-bordered table-striped">
			<thead class="thead-light">
				<tr>
					<th scope="col">Collection</th>
					<th scope="col">Part Name</th>
					<th scope="col">Is Tissue</th>
					<th scope="col">Description</th>
					<th scope="col">Actions</th>
				</tr>
			</thead>
			<tbody>
			<cfloop query="q">
				<tr id="r#ctspnid#">
					<td>#encodeForHTML(collection_cde)#</td>
					<td>#encodeForHTML(q.part_name)#</td>
					<td>#encodeForHTML(is_tissue)#</td>
					<td>#encodeForHTML(q.description)#</td>
					<td class="text-nowrap">
						<button type="button" class="btn btn-xs btn-danger mr-1" onclick="deletePart(#ctspnid#)">Delete</button>
						<button type="button" class="btn btn-xs btn-primary" onclick="updatePart(#ctspnid#)">Update</button>
					</td>
				</tr>
			</cfloop>
			</tbody>
		</table>
	</section>
</main>
</cfoutput>
<cfinclude template="/shared/_footer.cfm">
