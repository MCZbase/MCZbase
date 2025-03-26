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
<cfquery name="getParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select F.INSTITUTION_ACRONYM,
		F.COLLECTION_CDE,
		'catalog number' as OTHER_ID_TYPE,
		F.CAT_NUM as OTHER_ID_NUMBER,
		F.SCIENTIFIC_NAME,
		SP.collection_object_id as PART_COLLECTION_OBJECT_ID,
		SP.PART_NAME,
		SP.PRESERVE_METHOD,
		CO.COLL_OBJ_DISPOSITION,
		CO.LOT_COUNT_MODIFIER,
		CO.LOT_COUNT,
		CO.CONDITION,
		<cfif action IS "downloadBulkloader" OR action IS "downloadBulkloaderAll">
			pc.barcode as CONTAINER_UNIQUE_ID,
		<cfelseif action IS "downloadBulkPartContainer">
			pc.barcode as CONTAINER_BARCODE,
		<cfelseif action IS "downloadBulkPartContainerMove">
			pc.barcode as CONTAINER_BARCODE,
			 '' as NEW_CONTAINER_BARCODE,
		<cfelse>
			pc.barcode as CONTAINER_BARCODE,
			nvl(pc1.barcode,pc1.label) as P1_BARCODE,
			nvl(pc2.barcode,pc2.label) as P2_BARCODE,
			nvl(pc3.barcode,pc3.label) as P3_BARCODE,
			nvl(pc4.barcode,pc4.label) as P4_BARCODE,
			nvl(pc5.barcode,pc5.label) as P5_BARCODE,
			nvl(pc6.barcode,pc6.label) as P6_BARCODE,
		</cfif>
		COR.COLL_OBJECT_REMARKS as CURRENT_REMARKS
		<cfif action IS "downloadBulkloader" OR action IS "downloadBulkloaderAll">
			, '' as APPEND_TO_REMARKS
			, '' AS CHANGED_DATE
			, '' AS NEW_PART_NAME
			, '' AS NEW_PRESERVE_METHOD
			, '' AS NEW_LOT_COUNT
			, '' AS NEW_LOT_COUNT_MODIFIER
			, '' AS NEW_COLL_OBJ_DISPOSITION
			, '' AS NEW_CONDITION
		</cfif>
		<cfif action IS "downloadBulkPartContainerMove">
			, '' as NEW_CONTAINER_BARCODE
		</cfif>
		<cfif action IS "downloadPartLoanItems">
			, '' as ITEM_INSTRUCTIONS
			, '' AS ITEM_REMARKS
			, '' AS LOAN_NUMBER
			, '' AS TRANSACTION_ID
			, '' AS SUBSAMPLE
			, COR.COLL_OBJECT_REMARKS as PART_REMARKS
		</cfif>
		<cfif action IS "downloadBulkloaderAll">
			, '' as PART_ATT_NAME_1
			, '' as PART_ATT_VAL_1
			, '' as PART_ATT_UNITS_1
			, '' as PART_ATT_DETBY_1
			, '' as PART_ATT_MADEDATE_1
			, '' as PART_ATT_REM_1
			, '' as PART_ATT_NAME_2
			, '' as PART_ATT_VAL_2
			, '' as PART_ATT_UNITS_2
			, '' as PART_ATT_DETBY_2
			, '' as PART_ATT_MADEDATE_2
			, '' as PART_ATT_REM_2
			, '' as PART_ATT_NAME_3
			, '' as PART_ATT_val_3
			, '' as PART_ATT_UNITS_3
			, '' as PART_ATT_DETBY_3
			, '' as PART_ATT_MADEDATE_3
			, '' as PART_ATT_REM_3
			, '' as PART_ATT_NAME_4
			, '' as PART_ATT_VAL_4
			, '' as PART_ATT_UNITS_4
			, '' as PART_ATT_DETBY_4
			, '' as PART_ATT_MADEDATE_4
			, '' as PART_ATT_REM_4
			, '' as PART_ATT_NAME_5
			, '' as PART_ATT_VAL_5
			, '' as PART_ATT_UNITS_5
			, '' as PART_ATT_DETBY_5
			, '' as PART_ATT_MADEDATE_5
			, '' as part_ATT_REM_5
			, '' as PART_ATT_NAME_6
			, '' as PART_ATT_VAL_6
			, '' as part_ATT_UNITS_6
			, '' as PART_ATT_DETBY_6
			, '' as PART_ATT_MADEDATE_6
			, '' as PART_ATT_REM_6
		</cfif>
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
	SELECT distinct COLL_OBJ_DISPOSITION AS DISPOSITION
	FROM getParts
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
<cfelseif action is "downloadBulkloaderAll">
	<!--- download csv without the storage heirarchy suitable for rountrip edits with the part bulkloader including empty fields for attributes --->
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
<!------------------------------------------------------------------------>
<cfelseif action is "downloadBulkPartContainer">
	<!--- download csv for part container bulkload --->
	<cfinclude template="/shared/component/functions.cfc">
	<cfset strOutput2 = QueryToCSV(getParts)>
	<cfheader name="Content-Type" value="text/csv">
	<cfheader name="Content-disposition" value="attachment;filename=PARTS_downloadForPartContainerBulk.csv">
	<cfoutput>#strOutput2#</cfoutput>
	<cfabort>
<!------------------------------------------------------------------------->
<cfelseif action is "downloadBulkPartContainerMove">
	<!--- download csv for part container bulkload with move to column --->
	<cfinclude template="/shared/component/functions.cfc">
	<cfset strOutput2 = QueryToCSV(getParts)>
	<cfheader name="Content-Type" value="text/csv">
	<cfheader name="Content-disposition" value="attachment;filename=PARTS_downloadForPartContainer.csv">
	<cfoutput>#strOutput2#</cfoutput>
	<cfabort>
<!------------------------------------------------------------------------->
<cfelseif action is "downloadPartLoanItems">
	<!--- download csv for loan item bulkload --->
	<cfinclude template="/shared/component/functions.cfc">
	<cfset strOutput2 = QueryToCSV(getParts)>
	<cfheader name="Content-Type" value="text/csv">
	<cfheader name="Content-disposition" value="attachment;filename=PARTS_downloadForLoanItemsBulk.csv">
	<cfoutput>#strOutput2#</cfoutput>
	<cfabort>
	<!--------------------------------------------------------------------->
<cfelse>
	<cfset pageTitle = "Download Parts">
	<cfinclude template="/shared/_header.cfm">
	<script src="/lib/misc/sorttable.js"></script>
	<cfoutput>
		<main class="container-fluid py-3" id="content">
			<div class="row mx-0">
				<div class="col-12">
					<h1 class="h2 mt-2 mx-xl-2 px-1">
						List/Download Parts from a Specimen Search
						<cfif isDefined("result_id") and len(result_id) GT 0>
							(manage result #result_id#)
						</cfif>
					</h1>
					<p class= "col-12 mt-2">
						Obtain a list of parts, including CSV downloads suitable for editing and reload into the <a href="/tools/BulkloadEditedParts.cfm" target="_blank">Bulkload Edited Parts</a> the <a href="/tools/BulkloadPartContainer.cfm" target="_blank">Bulkload Parts to Containers</a> and <a href="/tools/BulkloadLoanItems.cfm" target="_blank">Bulkload Loan Items</a> tools.
					</p>
					<form name="filterResults">
						<div class="form-row mt-2 mb-3 mx-0">
							<input type="hidden" name="table_name" value="#table_name#">
							<input type="hidden" name="action" value="nothing" id="action">
							<cfif isDefined("result_id") and len(result_id) GT 0>
								<input type="hidden" name="result_id" value="#encodeForHtml(result_id)#" id="result_id">
							</cfif>
							<div class="col-12 col-md-4 col-xl-2">
								<label class="data-entry-label" for="filterPartName">Part Name:</label>
								<select name="filterPartName" id="filterPartName" class="data-entry-select">
									<option></option>
									<cfloop query="partnames">
										<option <cfif isdefined("filterPartName") and #part_name# EQ #filterPartName#>selected</cfif>>#part_name#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4 col-xl-2">
								<label class="data-entry-label mt-1 mt-md-0" for="filterPreserveMethod">Preserve Method:</label>
								<select name="filterPreserveMethod" id="filterPreserveMehtod" class="data-entry-select">
									<option></option>
									<cfloop query="preservemethods">
										<option <cfif isdefined("filterPreserveMethod") and #preserve_method# EQ #filterPreserveMethod#>selected</cfif>>#preserve_method#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4 col-xl-2">
								<label class="data-entry-label mt-1 mt-md-0" for="filterDisposition">Disposition:</label>
								<select name="filterDisposition" id="filterDisposition" class="data-entry-select">
									<option></option>
									<cfloop query="dispositions">
										<option <cfif isdefined("filterDisposition") and #DISPOSITION# EQ #filterDisposition#>selected</cfif>>#DISPOSITION#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4 col-xl-2">
								<label class="data-entry-label mt-1 mt-md-0" for="searchRemarks">Search Remarks (substring):</label>
								<cfif not isdefined("searchremarks")><cfset searchremarks=""></cfif>
								<input type="text" id="searchremarks" name="searchremarks" class="data-entry-input" value="#searchremarks#">
							</div>
							<div class="col-12 col-md-4 col-xl-2">
								<label class="data-entry-label mt-1 mt-md-0" for="filterBarcode">Part Container:</label>
								<cfif not isdefined("filterBarcode")><cfset filterBarcode=""></cfif>
								<input type="text" id="filterBarcode" name="filterBarcode" class="data-entry-input" value="#filterBARCODE#">
							</div>
							<div class="col-12 col-md-12 col-xl-2">
								
								<input type="submit" value="Filter Parts" onClick='document.getElementById("action").value="nothing";document.forms["filterResults"].submit();' class="mt-2 mt-xl-3 btn btn-xs mb-2 btn-secondary"></input>
								<button type="button" id="toggleButton" class="btn btn-xs btn-secondary mt-0 mt-xl-2 mx-1" onclick="toggleColumns();">Show Containers</button>
							</div>
						</div>
						<div class="form-row mx-0">
							<div class="col-12">
								<h2 class="h4">Download Parts CSV for:</h2>
								<input type="button" value="Bulkloading Edited Parts" onClick='document.getElementById("action").value="downloadBulkloader";document.forms["filterResults"].submit();' title="Part fields plus: APPEND_TO_REMARKS, CHANGED_DATE, NEW_PART_NAME, NEW_PRESERVE_METHOD, NEW_LOT_COUNT, NEW_LOT_COUNT_MODIFIER, NEW_COLL_OBJ_DISPOSITION, NEW_CONDITION" class="btn btn-xs mb-2 btn-secondary"></input>
								<input type="button" value="Bulkloading Edited Parts w/Attributes" onClick='document.getElementById("action").value="downloadBulkloaderAll";document.forms["filterResults"].submit();' title="Edited Parts fields plus: PART_ATT_NAME_1, PART_ATT_VAL_1, PART_ATT_UNITS_1, PART_ATT_DETBY_1, PART_ATT_MADEDATE_1, PART_ATT_REM_1 X 6" class="btn btn-xs mb-2 btn-secondary"></input>
								<input type="button" value="Container Placements" onClick='document.getElementById("action").value="downloadBulkPartContainer";document.forms["filterResults"].submit();' title="Part fields plus container hierarchy: CONTAINER_BARCODE, P1_BARCODE, P2_BARCODE, P3_BARCODE, P4_BARCODE, P5_BARCODE, P6_BARCODE" class="btn btn-xs mb-2 btn-secondary"></input>
								<input type="button" value="Bulkloading Parts to New Containers" onClick='document.getElementById("action").value="downloadBulkPartContainerMove";document.forms["filterResults"].submit();' title="Part fields and Container Hierarchy plus: blank NEW_CONTAINER_BARCODE column" class="btn btn-xs mb-2 btn-secondary"></input>
								<input type="button" value="Bulkloading Loan Items" onClick='document.getElementById("action").value="downloadPartLoanItems";document.forms["filterResults"].submit();' title="Part fields and Container Hierarchy plus: blank ITEM_INSTRUCTIONS, ITEM_REMARKS, LOAN_NUMBER, TRANSACTION_ID, SUBSAMPLE" class="btn btn-xs mb-2 btn-secondary"></input>
							</div>
						</div>			
					</form>
				</div>
			</div>
			<div class="row mx-0">
				<div class="col-12">
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
					<table class="sortable table table-responsive table-striped w-100" id="tre" style="empty-cells:show;">
						<thead class="thead-light"
							<tr>
								<th>INSTITUTION ACRONYM</th>
								<th>COLLECTION CDE</th>
								<th>CATALOG NUMBER</th>
								<!--- Note: Not including the part_collection_object_id in this table, just in the csv dump --->
								<th>PART NAME</th>
								<th>PRESERVE METHOD</th>
								<th>DISPOSITION</th>
								<th>LOT COUNT MODIFIER</th>
								<th>LOT COUNT</th>
								<th>CURRENT REMARKS</th>
								<th>CONDITION</th>
								<th class="contcoll">PART CONTAINER</th>
								<th class="contcoll ">PARENT CONTAINER</th>
								<th class="contcoll">P2 CONTAINER</th>
								<th class="contcoll">P3 CONTAINER</th>
								<th class="contcoll">P4 CONTAINER</th>
								<th class="contcoll">P5 CONTAINER</th>
								<th class="contcoll">P6 CONTAINER</th>
							</tr>
						</thead>
						<tbody>
							<cfloop query="getParts">
								<tr>
									<td>#getParts.INSTITUTION_ACRONYM#</td>
									<td>#COLLECTION_CDE#</td>
									<td>#OTHER_ID_NUMBER#</td>
									<!--- Note: Not including the part_collection_object_id in this table, just in the csv dump --->
									<td>#PART_NAME#</td>
									<td>#PRESERVE_METHOD#</td>
									<td>#COLL_OBJ_DISPOSITION#</td>
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
						</tbody>
					</table>
				</div>
			</div>
		</main>
	</cfoutput>
	<cfinclude template="/shared/_footer.cfm">
</cfif>
