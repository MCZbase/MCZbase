<!--- tools/downloadParts.cfm obtain lists of parts for reports of bulkload roundtrip editing..

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2023 President and Fellows of Harvard College

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
<cfif isDefined("result_id") and len(result_id) GT 0>
	<cfset table_name="user_search_table">
</cfif>
<cfif not isdefined("action")>
	<cfset action="entryPoint">
</cfif>

<cfif not isdefined("table_name")>
	<cfthrow message="You need to do a search first before using the part downloader">
</cfif>
<cf_rolecheck>
<cfquery name="getParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select F.INSTITUTION_ACRONYM,
		F.COLLECTION_CDE,
		'catalog number' as OTHER_ID_TYPE,
		F.CAT_NUM as OTHER_ID_NUMBER,
		F.SCIENTIFIC_NAME,
		SP.PART_NAME,
		SP.PRESERVE_METHOD,
		CO.COLL_OBJ_DISPOSITION AS DISPOSITION,
		CO.LOT_COUNT_MODIFIER,
		CO.LOT_COUNT,
		COR.COLL_OBJECT_REMARKS as CURRENT_REMARKS,
		<cfif action IS "downloadBulkloader">
			pc.barcode as CONTAINER_UNIQUE_ID,
		<cfelse>
			pc.barcode as CONTAINER_BARCODE,
			nvl(pc1.barcode,pc1.label) as P1_BARCODE,
			nvl(pc2.barcode,pc2.label) as P2_BARCODE,
			nvl(pc3.barcode,pc3.label) as P3_BARCODE,
			nvl(pc4.barcode,pc4.label) as P4_BARCODE,
			nvl(pc5.barcode,pc5.label) as P5_BARCODE,
			nvl(pc6.barcode,pc6.label) as P6_BARCODE,
		</cfif>
		CO.CONDITION
	from
		flat f, 
		specimen_part sp, 
		coll_object_remark cor, 
		CTSPECIMEN_PART_NAME pn, 
		COLL_OBJ_CONT_HIST ch, 
		container c, 
		container pc, 
		COLL_OBJECT co, 
		#table_name# T, 
		container PC1, container PC2, container PC3, container PC4, container PC5, container PC6
	where 
		f.collection_object_id = SP.DERIVED_FROM_CAT_ITEM
		<cfif isDefined("result_id") and len(result_id) GT 0>
			and T.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
		</cfif>
		and SP.COLLECTION_OBJECT_ID = COR.COLLECTION_OBJECT_ID(+)
		and SP.PART_NAME = PN.PART_NAME
		and pn.collection_cde = F.COLLECTION_CDE
		and SP.COLLECTION_OBJECT_ID = CH.COLLECTION_OBJECT_ID
		and CH.CONTAINER_ID = C.CONTAINER_ID
		and C.PARENT_CONTAINER_ID = PC.CONTAINER_ID(+)
		and PC.parent_container_id = PC1.container_id(+)
		and PC1.parent_container_id = PC2.container_id(+)
		and PC2.parent_container_id = PC3.container_id(+)
		and PC3.parent_container_id = PC4.container_id(+)
		and PC4.parent_container_id = PC5.container_id(+)
		and PC5.parent_container_id = PC6.container_id(+)
		and SP.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
		AND F.COLLECTION_OBJECT_ID = T.COLLECTION_OBJECT_ID
		<cfif isdefined("filterPartName") and len(#filterPartName#) GT 0>
			and sp.part_name= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#filterPartName#">
		</cfif>
		<cfif isdefined("filterPreserveMethod") and len(#filterPreserveMethod#) GT 0>
			and sp.PRESERVE_METHOD= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#filterPreserveMethod#">
		</cfif>
		<cfif isdefined("filterDisposition") and len(#filterDisposition#) GT 0>
			and CO.COLL_OBJ_DISPOSITION= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#filterDisposition#">
		</cfif>
		<cfif isdefined("filterBarcode") and len(#filterBarcode#) GT 0>
			and upper(PC.BARCODE) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(filterBARCODE)#%">
		</cfif>
		<cfif isdefined("searchRemarks") and len(#searchRemarks#) GT 0>
			and upper(COR.COLL_OBJECT_REMARKS) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(searchRemarks)#%">
		</cfif>
	order by F.CAT_NUM_INTEGER
</cfquery>

<cfquery name="partnames" dbtype="query">
	select distinct part_name from getParts
</cfquery>

<cfquery name="preservemethods" dbtype="query">
	select distinct preserve_method from getParts
</cfquery>

<cfquery name="dispositions" dbtype="query">
	select distinct DISPOSITION from getParts
</cfquery>

<!--------------------------------------------------------------------->
<cfif action is "downloadBulkloader">
	<!--- download csv without the storage heirarchy suitable for rountrip edits with the part bulkloader --->
	<cfinclude template="/shared/component/functions.cfc">
	<cfset strOutput = QueryToCSV(getParts)>
	<cfheader name="Content-Type" value="text/csv">
	<cfheader name="Content-disposition" value="attachment;filename=PARTS_downloadBulk.csv">
	<cfoutput>#strOutput#</cfoutput>
	<cfabort>
	<!--------------------------------------------------------------------->
<cfelseif action is "download">
	<!--- download csv including the storage heirarchy --->
	<cfinclude template="/shared/component/functions.cfc">
	<cfset strOutput2 = QueryToCSV(getParts)>
	<cfheader name="Content-Type" value="text/csv">
	<cfheader name="Content-disposition" value="attachment;filename=PARTS_download.csv">
	<cfoutput>#strOutput2#</cfoutput>
	<cfabort>
	<!--------------------------------------------------------------------->
<cfelse>
	<cfset pageTitle = "Download Parts">
	<cfinclude template="/shared/_header.cfm">
	<script src="/lib/misc/sorttable.js"></script>
	<cfoutput>
		<main class="container-fluid px-4 py-3" id="content">
			<h1 class="h2 mt-2">
				List/Download Parts from a Specimen Search
				<cfif isDefined("result_id") and len(result_id) GT 0>
					(manage result #result_id#)
				</cfif>
			</h1>
			<div>
				Obtain a list of parts, including CSV downloads suitable for editing and reload into the <a href="/tools/BulkloadEditedParts.cfm" target="_blank">Bulkload Edited Parts</a>Tool.
			</div>
			<form name="filterResults">
				<div class="form-row">
					<input type="hidden" name="table_name" value="#table_name#">
					<input type="hidden" name="action" value="nothing" id="action">
					<cfif isDefined("result_id") and len(result_id) GT 0>
						<input type="hidden" name="result_id" value="#encodeForHtml(result_id)#" id="result_id">
					</cfif>
					<div class="col-12 col-md-2">
						<label class="data-entry-label" for="filterPartName">Part Name:</label>
						<select name="filterPartName" id="filterPartName" class="data-entry-select">
							<option></option>
							<cfloop query="partnames">
								<option <cfif isdefined("filterPartName") and #part_name# EQ #filterPartName#>selected</cfif>>#part_name#</option>
							</cfloop>
						</select>
					</div>
					<div class="col-12 col-md-2">
						<label class="data-entry-label" for="filterPreserveMethod">Preserve Method:</label>
						<select name="filterPreserveMethod" id="filterPreserveMehtod" class="data-entry-select">
							<option></option>
							<cfloop query="preservemethods">
								<option <cfif isdefined("filterPreserveMethod") and #preserve_method# EQ #filterPreserveMethod#>selected</cfif>>#preserve_method#</option>
							</cfloop>
						</select>
					</div>
					<div class="col-12 col-md-2">
						<label class="data-entry-label" for="filterDisposition">Disposition:</label>
						<select name="filterDisposition" id="filterDisposition" class="data-entry-select">
							<option></option>
							<cfloop query="dispositions">
								<option <cfif isdefined("filterDisposition") and #DISPOSITION# EQ #filterDisposition#>selected</cfif>>#DISPOSITION#</option>
							</cfloop>
						</select>
					</div>
					<div class="col-12 col-md-2">
						<label class="data-entry-label" for="searchRemarks">Search Remarks (substring):</label>
						<cfif not isdefined("searchremarks")><cfset searchremarks=""></cfif>
						<input type="text" id="searchremarks" name="searchremarks" class="data-entry-input" value="#searchremarks#">
					</div>
					<div class="col-12 col-md-2">
						<label class="data-entry-label" for="filterBarcode">Part Container:</label>
						<cfif not isdefined("filterBarcode")><cfset filterBarcode=""></cfif>
						<input type="text" id="filterBarcode" name="filterBarcode" class="data-entry-input" value="#filterBARCODE#">
					</div>
					<div class="col-12 col-md-2">
						<button type="button" id="toggleButton" class="btn btn-xs btn-secondary mt-3" onclick="toggleColumns();">Show Containers</button>
					</div>
				</div>
				<div class="form-row">
					<div class="col-12">
						<input type="submit" value="Filter Parts" onClick='document.getElementById("action").value="nothing";document.forms["filterResults"].submit();' class="btn btn-xs mb-2 btn-secondary"></input>
						<input type="button" value="Download Parts CSV" onClick='document.getElementById("action").value="downloadBulkloader";document.forms["filterResults"].submit();' class="btn btn-xs mb-2 btn-secondary"></input>
						<input type="button" value="Download Parts CSV including Containers" onClick='document.getElementById("action").value="download";document.forms["filterResults"].submit();' class="btn btn-xs mb-2 btn-secondary"></input>
					</div>
				</div>			
			</form>

			<div class="row mx-0">
				<script>
					var toggleState = "show";
					function toggleColumns() {
						if (toggleState=="show") {
							$(".contcoll").hide();
							toggleState = "hidden";
							$("##toggleButton").html("Show Containers");
						} else {
							$(".contcoll").show();
							toggleState = "show";
							$("##toggleButton").html("Hide Containers");
						}
					}
					$(document).ready(function() { 
						$(".contcoll").hide();
						toggleState = "hidden";
						$("##toggleButton").html("Show Containers");
					});
				</script>
				<table class="sortable table table-responsive table-striped d-xl-table w-100" id="tre" style="empty-cells:show;">
					<tr>
						<th>INSTITUTION_ACRONYM</th>
						<th>COLLECTION_CDE</th>
						<!---th>OTHER_ID_TYPE</th--->
						<th>CATALOG_NUMBER</th>
						<th>PART_NAME</th>
						<th>PRESERVE_METHOD</th>
						<th>DISPOSITION</th>
						<th>LOT_COUNT_MODIFIER</th>
						<th>LOT_COUNT</th>
						<th>CURRENT_REMARKS</th>
						<th>CONDITION</th>
						<th class="contcoll">PART CONTAINER</th>
						<th class="contcoll ">PARENT CONTAINER</th>
						<th class="contcoll">P2 CONTAINER</th>
						<th class="contcoll">P3 CONTAINER</th>
						<th class="contcoll">P4 CONTAINER</th>
						<th class="contcoll">P5_CONTAINER</th>
						<th class="contcoll">P6 CONTAINER</th>
					</tr>
					<cfloop query="getParts">
						<tr>
							<td>#getParts.INSTITUTION_ACRONYM#</td>
							<td>#COLLECTION_CDE#</td>
							<!---td>#OTHER_ID_TYPE#</td--->
							<td>#OTHER_ID_NUMBER#</td>
							<td>#PART_NAME#</td>
							<td>#PRESERVE_METHOD#</td>
							<td>#DISPOSITION#</td>
							<td>#LOT_COUNT_MODIFIER#</td>
							<td>#LOT_COUNT#</td>
							<td>#CURRENT_REMARKS#</td>
							<td>#CONDITION#</td>
							<td class="contcoll">#CONTAINER_BARCODE#</td>
							<td class="contcoll">#P1_BARCODE#</td>
							<td class="contcoll">#P2_BARCODE#</td>
							<td class="contcoll">#P3_BARCODE#</td>
							<td class="contcoll">#P4_BARCODE#</td>
							<td class="contcoll">#P5_BARCODE#</td>
							<td class="contcoll">#P6_BARCODE#</td>
						</tr>
					</cfloop>
				</table>
			</div>
		</main>
	</cfoutput>
	<cfinclude template="/shared/_footer.cfm">
</cfif>
