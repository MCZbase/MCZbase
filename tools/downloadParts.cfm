<cfinclude template="/includes/_header.cfm">
    <script src="/lib/misc/sorttable.js"></script>
<!--------------------------------------------------------------------->

<cfset title="Download Parts">

	<cfif isDefined("result_id") and len(result_id) GT 0>
		<cfset table_name="user_search_table">
	</cfif>

	<cfif not isdefined("table_name")>
		You need to do a search first before using the part downloader
	<cfelse>
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
				pc.barcode as CONTAINER_BARCODE,
                                nvl(pc1.barcode,pc1.label) as P1_BARCODE,
                                nvl(pc2.barcode,pc2.label) as P2_BARCODE,
                                nvl(pc3.barcode,pc3.label) as P3_BARCODE,
                                nvl(pc4.barcode,pc4.label) as P4_BARCODE,
                                nvl(pc5.barcode,pc5.label) as P5_BARCODE,
                                nvl(pc6.barcode,pc6.label) as P6_BARCODE,
            
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
	
		<cfif action is "nothing">
		<cfoutput>


		<table>
		<form name="filterResults">
			<input type="hidden" name="table_name" value="#table_name#">
			<input type="hidden" name="action" value="nothing" id="action">
			<cfif isDefined("result_id") and len(result_id) GT 0>
				<input type="hidden" name="result_id" value="#encodeForHtml(result_id)#" id="result_id">
			</cfif>
			<tr>
				<td>Part Name:
				<select name="filterPartName" style="width:150px">
					<option></option>
					<cfloop query="partnames">
						<option <cfif isdefined("filterPartName") and #part_name# EQ #filterPartName#>selected</cfif>>#part_name#</option>
					</cfloop>
				</td>
				<td>Preserve Method:
				<select name="filterPreserveMethod" style="width:150px">
					<option></option>
					<cfloop query="preservemethods">
						<option <cfif isdefined("filterPreserveMethod") and #preserve_method# EQ #filterPreserveMethod#>selected</cfif>>#preserve_method#</option>
					</cfloop>
				</td>
				<td>Disposition:
				<select name="filterDisposition" style="width:150px">
					<option></option>
					<cfloop query="dispositions">
						<option <cfif isdefined("filterDisposition") and #DISPOSITION# EQ #filterDisposition#>selected</cfif>>#DISPOSITION#</option>
					</cfloop>
				</td>

				<td>Search Remarks (substring):
					<input type="text" style="width:200px" name="searchremarks" <cfif isdefined("searchremarks") and len(#searchremarks#) GT 0>value="#searchremarks#"</cfif></input>
				</td>
 <td>Part Container:
				<input type="text" style="width:200px" name="filterBarcode" <cfif isdefined("filterBarcode") and len(#filterBarcode#) GT 0>value="#filterBARCODE#"</cfif></input>
				</td>
<td><input type="button" style="width:auto" value="Toggle Containers" onclick="toggleColumn(10);toggleColumn(11);toggleColumn(12);toggleColumn(13);toggleColumn(14);toggleColumn(15);toggleColumn(16);"></input></td>
				<td><input type="submit" value="Filter Parts" onClick='document.getElementById("action").value="nothing";document.forms["filterResults"].submit();'></input></td>
	            <td><input type="button" value="Download Parts" onClick='document.getElementById("action").value="downloadBulkloader";document.forms["filterResults"].submit();'></input></td>
				<td><input type="button" value="Download Parts with Containers" onClick='document.getElementById("action").value="download";document.forms["filterResults"].submit();'></input></td>



			</tr>
		</table>
		</form>

  <script>
function toggleColumn(n) {
    var currentClass = document.getElementById("tre").className;
    if (currentClass.indexOf("show"+n) != -1) {
        document.getElementById("tre").className = currentClass.replace("show"+n, "");
    }
    else {
        document.getElementById("tre").className += " " + "show"+n;
    }
}
    </script>
   <!--- <div style="width: 640px;border: 1px solid gray;padding: .5em;">
       <a class="schBtn" onclick="toggleColumn(1);toggleColumn(2);toggleColumn(3);toggleColumn(4);toggleColumn(5);toggleColumn(6);toggleColumn(7);">Show/Hide: Containers</a>
    </div>--->


			<!---cfdump var="#getParts#"--->
			<table border class="specResultTab sortable" id="tre" style="empty-cells:show;">
				<TR>
					<th class="col1" style="background: ##eee;color:##666;">INSTITUTION_ACRONYM</th>
					<th class="col2" style="background: ##eee;color:##666;">COLLECTION_CDE</th>
					<!---th>OTHER_ID_TYPE</th--->
					<th class="col3" style="background: ##eee;color:##666;">CATALOG_NUMBER</th>
					<th class="col4" style="background: ##eee;color:##666;">PART_NAME</th>
					<th class="col5" style="background: ##eee;color:##666;">PRESERVE_METHOD</th>
					<th class="col6" style="background: ##eee;color:##666;">DISPOSITION</th>
					<th class="col7" style="background: ##eee;color:##666;">LOT_COUNT_MODIFIER</th>
					<th class="col8" style="background: ##eee;color:##666;">LOT_COUNT</th>
					<th class="col9" style="background: ##eee;color:##666;">CURRENT_REMARKS</th>
					<th class="col10" style="background: ##eee;color:##666;">PART CONTAINER</th>
					<th class="col11" style="background: ##eee;color:##666;">PARENT CONTAINER</th>
					<th class="col12" style="background: ##eee;color:##666;">P2 CONTAINER</th>
					<th class="col13" style="background: ##eee;color:##666;">P3 CONTAINER</th>
					<th class="col14" style="background: ##eee;color:##666;">P4 CONTAINER</th>
					<th class="col15" style="background: ##eee;color:##666;">P5_CONTAINER</th>
					<th class="col16" style="background: ##eee;color:##666;">P6 CONTAINER</th>
					<th class="col17" style="background: ##eee;color:##666;">CONDITION</th>
				</TR>


			<cfloop query="getParts">

				<tr>
					<td class="col1">#getParts.INSTITUTION_ACRONYM#</td>
					<td class="col2">#COLLECTION_CDE#</td>
					<!---td>#OTHER_ID_TYPE#</td--->
					<td class="col3">#OTHER_ID_NUMBER#</td>
					<td class="col4">#PART_NAME#</td>
					<td class="col5">#PRESERVE_METHOD#</td>
					<td class="col6">#DISPOSITION#</td>
					<td class="col7">#LOT_COUNT_MODIFIER#</td>
					<td class="col8">#LOT_COUNT#</td>
					<td class="col9">#CURRENT_REMARKS#</td>
					<td class="col10">#CONTAINER_BARCODE#</td>
					<td class="col11">#P1_BARCODE#</td>
					<td class="col12">#P2_BARCODE#</td>
					<td class="col13">#P3_BARCODE#</td>
					<td class="col14">#P4_BARCODE#</td>
					<td class="col15">#P5_BARCODE#</td>
					<td class="col16">#P6_BARCODE#</td>
					<td class="col17">#CONDITION#</td>
				</tr>
			</cfloop>
</table>


			</cfoutput>

		<cfinclude template="/includes/_footer.cfm">

		<cfelseif action is "downloadBulkloader">
			<cfset strOutput = QueryToCSV(getParts, "INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,PRESERVE_METHOD,DISPOSITION,LOT_COUNT_MODIFIER,LOT_COUNT,CURRENT_REMARKS,CONDITION") />
			<cfheader name="Content-disposition" value="attachment;filename=PARTS_downloadBulk.csv">
			<cfcontent type="text/csv"><cfoutput>#strOutput#</cfoutput>
                
      <cfelseif action is "download">
			<cfset strOutput2 = QueryToCSV(getParts, "INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,PRESERVE_METHOD,DISPOSITION,LOT_COUNT_MODIFIER,LOT_COUNT,CURRENT_REMARKS,CONTAINER_BARCODE,P1_BARCODE,P2_BARCODE,P3_BARCODE,P4_BARCODE,P5_BARCODE,P6_BARCODE,CONDITION") />
			<cfheader name="Content-disposition" value="attachment;filename=PARTS_download.csv">
			<cfcontent type="text/csv"><cfoutput>#strOutput2#</cfoutput>
		</cfif>
	</cfif>
