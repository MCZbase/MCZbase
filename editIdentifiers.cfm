<cfinclude template="/includes/alwaysInclude.cfm">
<div class="basic_box">
<cfset title = "Edit Identifiers">
<cfquery name="getIDs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT
		COLL_OBJ_OTHER_ID_NUM_ID,
		cat_num,
		cat_num_prefix,
		cat_num_integer,
		cat_num_suffix,
		other_id_prefix,
		other_id_number,
		other_id_suffix,
		other_id_type,
		display_value, 
		cataloged_item.collection_id,
		collection.collection_cde,
		institution_acronym
	FROM 
		cataloged_item, 
		join collection on cataloged_item.collection_id=collection.collection_id and
		left join coll_obj_other_id_num on cataloged_item.collection_object_id=coll_obj_other_id_num.collection_object_id
	WHERE
		cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
</cfquery>
<cfquery name="ctType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT other_id_type 
	FROM ctcoll_other_id_type
</cfquery>
<cfquery name="cataf" dbtype="query">
	SELECT cat_num 
	FROM getIDs 
	GROUP BY cat_num
</cfquery>
<cfquery name="oids" dbtype="query">
	SELECT 
		COLL_OBJ_OTHER_ID_NUM_ID,
		other_id_prefix,
		other_id_number,
		other_id_suffix,
		other_id_type,
		display_value 
	FROM 
		getIDs 
	GROUP BY 
		COLL_OBJ_OTHER_ID_NUM_ID,
		other_id_prefix,
		other_id_number,
		other_id_suffix,
		other_id_type,
		display_value
</cfquery>
<cfquery name="ctcoll_cde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT 
		institution_acronym,
		collection_cde,
		collection_id 
	FROM collection
</cfquery>
<cfoutput>
	<h3>Edit existing identifiers:</h3>
<table>
	<form name="ids" method="post" action="editIdentifiers.cfm">
	<input type="hidden" name="collection_object_id" value="#collection_object_id#">
	<input type="hidden" name="Action" value="saveCatEdits">
		<tr class="evenRow"> 
			<td align="right">Catalog&nbsp;Number:</td>
			<td colspan="3">
				<select name="collection_id" size="1" class="reqdClr">
					<cfset thisCollId=#getIDs.collection_id#>
					<cfloop query="ctcoll_cde">
					<option 
						<cfif #thisCollId# is #collection_id#> selected </cfif>
					value="#collection_id#">#institution_acronym# #collection_cde#</option>
					</cfloop>
				</select>
				<input type="text" name="cat_num" value="#catAF.cat_num#" class="reqdClr">
				<!---input type="text" name="catalog_number_prefix" value="#catAF.catalog_number_prefix#">
				<input type="text" name="catalog_number" value="#catAF.catalog_number#" class="reqdClr">
				<input type="text" name="catalog_number_suffix" value="#catAF.catalog_number_suffix#"--->
				<input type="submit" value="Save" class="savBtn" onmouseover="this.className='savBtn btnhov'" onmouseout="this.className='savBtn'">
			</td>
		</tr>
	</form>
	<cfset i=1>
	<cfloop query="oids">
		<cfif len(#other_id_type#) gt 0>
			<tr #iif(i MOD 2,DE("class='oddRow'"),DE("class='evenRow'"))#><td>
				<form name="oids#i#" method="post" action="editIdentifiers.cfm">
					<input type="hidden" name="collection_object_id" value="#collection_object_id#">
					<input type="hidden" name="COLL_OBJ_OTHER_ID_NUM_ID" value="#COLL_OBJ_OTHER_ID_NUM_ID#">
					<input type="hidden" name="Action">
					<td><cfset thisType = #oids.other_id_type#>
						<select name="other_id_type" size="1">
							<cfloop query="ctType">
								<option 
									<cfif #ctType.other_id_type# is #thisType#> selected </cfif>
									value="#ctType.other_id_type#">#ctType.other_id_type#</option>
							</cfloop>			
						</select>
					</td>
					<td nowrap="nowrap">
						<input type="text" value="#oids.display_value#" size="25"  name="display_value">
					</td>
					<td nowrap="nowrap">
						<input type="button" value="Save" class="savBtn" onmouseover="this.className='savBtn btnhov'" onmouseout="this.className='savBtn'" onclick="oids#i#.Action.value='saveOIDEdits';submit();">
						<input type="button" value="Delete" class="delBtn" onmouseover="this.className='delBtn btnhov'" onmouseout="this.className='delBtn'" onclick="oids#i#.Action.value='deleOID';confirmDelete('oids#i#');">
					</td>
				</form>
			</tr>
		<cfset i=#i#+1>
		</cfif>
	</cfloop>
	</table>
	<table class="newRec" style="padding: 1em;width: 100%;">
		<tr>
		<td>
		<b>Add New Identifier:</b> 
			<img class="likeLink" src="/images/ctinfo.gif" onMouseOver="self.status='Code Table Value Definition';return true;" onmouseout="self.status='';return true;" border="0" alt="Code Table Value Definition" onClick="getCtDoc('ctcoll_other_id_type','')">
			<table>
				<tr>
				<form name="newOID" method="post" action="editIdentifiers.cfm">
					<input type="hidden" name="collection_object_id" value="#collection_object_id#">
					<input type="hidden" name="Action" value="newOID">
					<td>
						<select name="other_id_type" size="1" class="reqdClr">
						<cfloop query="ctType">
							<option 
								value="#ctType.other_id_type#">#ctType.other_id_type#</option>
						</cfloop>
						</select>
					</td>
					<td>
						<input type="text" class="reqdClr" name="display_value" size="25">		
					</td>
					<td>
						<input type="submit" value="Save" class="insBtn" onmouseover="this.className='insBtn btnhov'" onmouseout="this.className='insBtn'">
					</td>
					</form>
				</tr>
			</table>
		</td>
	</tr>
</table>
</cfoutput>
</table>
<!-------------------------------------------------------->
<cfif #Action# is "saveCatEdits">
<cfoutput>
	<cftransaction>
		<cfquery name="upCat" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE cataloged_item SET 
				cat_num = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cat_num#">,
				collection_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
			WHERE 
				collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
		</cfquery>
	</cftransaction>
	<cflocation url="editIdentifiers.cfm?collection_object_id=#collection_object_id#">
</cfoutput>
</cfif>
<!-------------------------------------------------------->
<cfif #Action# is "saveOIDEdits">
<cfoutput>
	<cfstoredproc procedure="update_other_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		<cfprocparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
		<cfprocparam cfsqltype="CF_SQL_DECIMAL" value="#COLL_OBJ_OTHER_ID_NUM_ID#">
		<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#display_value#">
		<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#other_id_type#">
	</cfstoredproc>	
	<cflocation url="editIdentifiers.cfm?collection_object_id=#collection_object_id#">
</cfoutput>
</cfif>
<!-------------------------------------------------------->
<cfif #Action# is "deleOID">
<cfoutput>
	<cfquery name="delOIDt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM
			coll_obj_other_id_num
		WHERE 
			COLL_OBJ_OTHER_ID_NUM_ID= <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#COLL_OBJ_OTHER_ID_NUM_ID#">
	</cfquery>
	<cflocation url="editIdentifiers.cfm?collection_object_id=#collection_object_id#">
</cfoutput>
</cfif>
<!-------------------------------------------------------->
<cfif #Action# is "newOID">
<cfoutput>
	<cfstoredproc procedure="parse_other_id" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		<cfprocparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
		<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#display_value#">
		<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#other_id_type#">
	</cfstoredproc>>
	<cflocation url="editIdentifiers.cfm?collection_object_id=#collection_object_id#">
</cfoutput>
</cfif>
<!-------------------------------------------------------->
</div>
<cf_customizeIFrame>
