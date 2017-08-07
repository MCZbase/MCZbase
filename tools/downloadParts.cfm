<cfinclude template="/includes/_header.cfm">
<!--------------------------------------------------------------------->

<cfset title="Download Parts">

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
				CO.CONDITION
		from
				flat f, specimen_part sp, coll_object_remark cor, CTSPECIMEN_PART_NAME pn, COLL_OBJ_CONT_HIST ch, container c, container pc, COLL_OBJECT co, #table_name# T
		where f.collection_object_id = SP.DERIVED_FROM_CAT_ITEM
				and SP.COLLECTION_OBJECT_ID = COR.COLLECTION_OBJECT_ID(+)
				and SP.PART_NAME = PN.PART_NAME
				and pn.collection_cde = F.COLLECTION_CDE
				and SP.COLLECTION_OBJECT_ID = CH.COLLECTION_OBJECT_ID
				and CH.CONTAINER_ID = C.CONTAINER_ID
				and C.PARENT_CONTAINER_ID = PC.CONTAINER_ID(+)
				and SP.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
				AND F.COLLECTION_OBJECT_ID = T.COLLECTION_OBJECT_ID
				<cfif isdefined("filterPartName") and len(#filterPartName#) GT 0>
					and sp.part_name='#filterPartName#'
				</cfif>
				<cfif isdefined("filterPreserveMethod") and len(#filterPreserveMethod#) GT 0>
					and sp.PRESERVE_METHOD='#filterPreserveMethod#'
				</cfif>
				<cfif isdefined("filterDisposition") and len(#filterDisposition#) GT 0>
					and CO.COLL_OBJ_DISPOSITION='#filterDisposition#'
				</cfif>
				<cfif isdefined("searchRemarks") and len(#searchRemarks#) GT 0>
					and upper(COR.COLL_OBJECT_REMARKS) like '%#ucase(searchRemarks)#%'
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

				<td><input type="submit" value="Filter Parts" onClick='document.getElementById("action").value="nothing";document.forms["filterResults"].submit();'></input></td>
				<td><input type="button" value="Download Parts" onClick='document.getElementById("action").value="download";document.forms["filterResults"].submit();'></input></td>



			</tr>
		</table>
		</form>



			<!---cfdump var="#getParts#"--->
			<table class="specResultTab">
				<TR>
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
					<th>CONTAINER_BARCODE</th>
					<th>CONDITION</th>
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
					<td>#CONTAINER_BARCODE#</td>
					<td>#CONDITION#</td>
				</tr>
			</cfloop>
            </table>

			</cfoutput>

		<cfinclude template="/includes/_footer.cfm">

		<cfelseif action is "download">
			<cfset strOutput = QueryToCSV(getParts, "INSTITUTION_ACRONYM,COLLECTION_CDE,OTHER_ID_TYPE,OTHER_ID_NUMBER,PART_NAME,PRESERVE_METHOD,DISPOSITION,LOT_COUNT_MODIFIER,LOT_COUNT,CURRENT_REMARKS,CONTAINER_BARCODE,CONDITION") />
			<cfheader name="Content-disposition" value="attachment;filename=PARTS_download.csv">
			<cfcontent type="text/csv"><cfoutput>#strOutput#</cfoutput>
		</cfif>
	</cfif>


