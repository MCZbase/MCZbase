<cfinclude template="/includes/_header.cfm">
<!--------------------------------------------------------------------->
<cfset title="Bulk Modify Parts">
<cfif isDefined("result_id") and len(result_id) GT 0>
	<cfset table_name="user_search_table">
</cfif>
<cfif action is "nothing">
	<cfoutput>
		<h1 class="h2">Bulk Part Management</h1>
		<cfset numParts=3>
		<cfif not isdefined("table_name")>
			Bad call.<cfabort>
		</cfif>
		<cfif isDefined("result_id") and len(result_id) GT 0>
			<cfquery name="colcde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT distinct(collection_cde) 
				FROM 
					user_search_table
					JOIN cataloged_item ON user_search_table.collection_object_id = cataloged_item.collection_object_id
				WHERE
					user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			</cfquery>
		<cfelse>
			<cfquery name="colcde" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select distinct(collection_cde) from #table_name#
			</cfquery>
		</cfif>
		<cfset colcdes = valuelist(colcde.collection_cde)>
		<cfif listlen(colcdes) is not 1>
			<cfthrow message="You can only use this form on one collection at a time. Please revise your search.">
		</cfif>
		<cfif isDefined("result_id") and len(result_id) GT 0>
			<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				SELECT count(*) c
				FROM 
					user_search_table
				WHERE
					user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			</cfquery>
		<cfelse>
			<cfquery name="c" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select count(*) c from #table_name#
			</cfquery>
		</cfif>
		<cfif c.c gte 1000>
			<cfthrow message="You can only use this form on 1000 specimens at a time. Please revise your search.">
		</cfif>
		<cfquery name="ctDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select coll_obj_disposition from ctcoll_obj_disp
		</cfquery>
		<cfquery name="ctNumericModifiers" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select modifier from ctnumeric_modifiers
		</cfquery>
		<cfquery name="ctPreserveMethod" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select preserve_method from ctspecimen_preserv_method where collection_cde = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#colcdes#">
		</cfquery>
		<h2 class="h3">Option 1: Add Part(s)</h2>
		<form name="newPart" method="post" action="bulkPart.cfm">
			<input type="hidden" name="action" value="newPart">
			<input type="hidden" name="table_name" value="#table_name#">
			<input type="hidden" name="numParts" value="#numParts#">
			<cfif isDefined("result_id") and len(result_id) GT 0>
				<input type="hidden" name="result_id" value="#result_id#">
			</cfif>
			<table border width="90%">
				<tr>
					<td>Add Part 1</td>
					<td>Add part 2 (optional)</td>
					<td>Add part 3 (optional)</td>
				</tr>
				<tr>
					<cfloop from="1" to="#numParts#" index="i">
						<td>
							<label for="part_name_#i#">Add Part (#i#)</label>
							<input type="text" name="part_name_#i#" id="part_name_#i#" class="reqdClr"
								onchange="findPart(this.id,this.value,'#colcdes#');"
								onkeypress="return noenter(event);">
							<label for="preserve_method_#i#">Preserve Method (#i#)</label>
							<select name="preserve_method_#i#" id="preserve_method_#i#" size="1">
								<cfloop query="ctPreserveMethod">
									<option value="#ctPreserveMethod.preserve_method#">#ctPreserveMethod.preserve_method#</option>
								</cfloop>
							</select>
							<label for="lot_count_modifier_#i#">Count Modifier (#i#)</label>
							<select name="lot_count_modifier_#i#" id="lot_count_modifier_#i#" size="1">
								<option value=""></option>
								<cfloop query="ctNumericModifiers">
									<option value="#ctNumericModifiers.modifier#">#ctNumericModifiers.modifier#</option>
								</cfloop>
							</select>
					   		<label for="lot_count_#i#">Part Count (#i#)</label>
					   		<input type="text" name="lot_count_#i#" id="lot_count_#i#" class="reqdClr" size="2">
					   		<label for="coll_obj_disposition_#i#">Disposition (#i#)</label>
					   		<select name="coll_obj_disposition_#i#" id="coll_obj_disposition_#i#" size="1"  class="reqdClr">
								<cfloop query="ctDisp">
									<option value="#ctDisp.coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
								</cfloop>
							</select>
							<label for="condition_#i#">Condition (#i#)</label>
					   		<input type="text" name="condition_#i#" id="condition_#i#" class="reqdClr">
					   		<label for="coll_object_remarks_#i#">Remark (#i#)</label>
					   		<input type="text" name="coll_object_remarks_#i#" id="coll_object_remarks_#i#">
						</td>
					</cfloop>
				</tr>
			</table>
			<input type="submit" value="Add Parts" class="savBtn">
		</form>
		<hr>
		<h2 class="h3">Option 2: Modify Existing Parts</h2>
		<div>(You will be able to review changes on the next screen)</div>
		<cfquery name="existParts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				specimen_part.part_name
			FROM
				specimen_part
				<cfif isDefined("result_id") and len(result_id) GT 0>
					JOIN user_search_table on specimen_part.derived_from_cat_item = user_search_table.collection_object_id
			WHERE
					user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				<cfelse>
					JOIN #table_name# on specimen_part.derived_from_cat_item=#table_name#.collection_object_id
			</cfif>
			GROUP BY specimen_part.part_name
			ORDER BY specimen_part.part_name
		</cfquery>
		<cfquery name="existPreserve" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				specimen_part.preserve_method
			FROM
				specimen_part
				<cfif isDefined("result_id") and len(result_id) GT 0>
					JOIN user_search_table on specimen_part.derived_from_cat_item = user_search_table.collection_object_id
			WHERE
					user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				<cfelse>
					JOIN #table_name# on specimen_part.derived_from_cat_item=#table_name#.collection_object_id
				</cfif>
			GROUP BY specimen_part.preserve_method
			ORDER BY specimen_part.preserve_method
		</cfquery>
		<cfquery name="existCO" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				coll_object.lot_count,
				coll_object.coll_obj_disposition
			FROM
				specimen_part
				JOIN coll_object on specimen_part.collection_object_id=coll_object.collection_object_id
				<cfif isDefined("result_id") and len(result_id) GT 0>
					JOIN user_search_table on specimen_part.derived_from_cat_item = user_search_table.collection_object_id
			WHERE
					user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				<cfelse>
					JOIN #table_name# on specimen_part.derived_from_cat_item=#table_name#.collection_object_id
				</cfif>
			GROUP BY 
				coll_object.lot_count,
				coll_object.coll_obj_disposition
		</cfquery>
		<cfquery name="existLotCount" dbtype="query">
			select lot_count from existCO group by lot_count order by lot_count
		</cfquery>
		<cfquery name="existDisp" dbtype="query">
			select coll_obj_disposition from existCO group by coll_obj_disposition order by coll_obj_disposition
		</cfquery>

		<form name="modPart" method="post" action="bulkPart.cfm">
			<input type="hidden" name="action" value="modPart">
			<input type="hidden" name="table_name" value="#table_name#">
			<cfif isDefined("result_id") and len(result_id) GT 0>
				<input type="hidden" name="result_id" value="#result_id#">
			</cfif>
			<table border>
				<tr>
					<td></td>
					<td>
						Filter specimens for part...
					</td>
					<td>
						Update to...
					</td>
				</tr>
				<tr>
					<td>Part Name</td>
					<td>
				   		<select name="exist_part_name" id="exist_part_name" size="1" class="reqdClr">
							<option selected="selected" value=""></option>
								<cfloop query="existParts">
							    	<option value="#Part_Name#">#Part_Name#</option>
								</cfloop>
						</select>
					</td>
					<td>
						<input type="text" name="new_part_name" id="new_part_name" class="reqdClr"
							onchange="findPart(this.id,this.value,'#colcdes#');"
							onkeypress="return noenter(event);">
					</td>
				</tr>
				<tr>
					<td>Preserve Method</td>
					<td>
				   		<select name="exist_preserve_method" id="exist_preserve_method" size="1" class="reqdClr">
							<option selected="selected" value=""></option>
								<cfloop query="existPreserve">
							    	<option value="#Preserve_method#">#Preserve_method#</option>
								</cfloop>
						</select>
					</td>
					<td>
						<select name="new_preserve_method" id="new_preserve_method" size="1"  class="reqdClr">
							<option value="">no update</option>
							<cfloop query="ctPreserveMethod">
								<option value="#ctPreserveMethod.preserve_method#">#ctPreserveMethod.preserve_method#</option>
							</cfloop>
						</select>
					</td>
				</tr>
	    		<tr>
					<td>Lot Count</td>
					<td>
						<select name="existing_lot_count" id="existing_lot_count" size="1" class="reqdClr">
							<option selected="selected" value="">ignore</option>
								<cfloop query="existLotCount">
							    	<option value="#lot_count#">#lot_count#</option>
								</cfloop>
						</select>
					</td>
					<td>
						<input type="text" name="new_lot_count" id="new_lot_count">
					</td>
				</tr>
				<tr>
					<td>Disposition</td>
					<td>
						<select name="existing_coll_obj_disposition" id="existing_coll_obj_disposition" size="1" class="reqdClr">
							<option selected="selected" value="">ignore</option>
								<cfloop query="existDisp">
							    	<option value="#coll_obj_disposition#">#coll_obj_disposition#</option>
								</cfloop>
						</select>
					</td>
					<td>
						<select name="new_coll_obj_disposition" id="new_coll_obj_disposition" size="1"  class="reqdClr">
							<option value="">no update</option>
							<cfloop query="ctDisp">
								<option value="#ctDisp.coll_obj_disposition#">#ctDisp.coll_obj_disposition#</option>
							</cfloop>
						</select>
					</td>
				</tr>
				<tr>
					<td>Condition</td>
					<td>
						Existing CONDITION will be ignored
					</td>
					<td>
						<input type="text" name="new_condition" id="new_condition">
					</td>
				</tr>
				<tr>
					<td>Remark</td>
					<td>
						Existing REMARKS will be ignored
					</td>
					<td>
						<input type="text" name="new_remark" id="new_remark">
					</td>
				</tr>
				<tr>
					<td colspan="3" align="center">
						<input type="submit" value="Update Parts" class="savBtn">
					</td>
				</tr>
		  	</table>
		</form>
	
		<hr>

		<h2 class="h3">Option 3: Delete parts</h2>
	
		<form name="delPart" method="post" action="bulkPart.cfm">
			<input type="hidden" name="action" value="delPart">
			<input type="hidden" name="table_name" value="#table_name#">
			<cfif isDefined("result_id") and len(result_id) GT 0>
				<input type="hidden" name="result_id" value="#result_id#">
			</cfif>
			<label for="exist_part_name">Existing Part Name</label>
			<select name="exist_part_name" id="exist_part_name" size="1" class="reqdClr">
				<option selected="selected" value=""></option>
					<cfloop query="existParts">
				    	<option value="#Part_Name#">#Part_Name#</option>
					</cfloop>
			</select>
			<select name="exist_preserve_method" id="exist_preserve_method" size="1" class="reqdClr">
				<option selected="selected" value=""></option>
					<cfloop query="existPreserve">
				    	<option value="#preserve_method#">#preserve_method#</option>
					</cfloop>
			</select>
			<label for="existing_lot_count">Existing Lot Count</label>
			<select name="existing_lot_count" id="existing_lot_count" size="1" class="reqdClr">
				<option selected="selected" value="">ignore</option>
					<cfloop query="existLotCount">
				    	<option value="#lot_count#">#lot_count#</option>
					</cfloop>
			</select>
			<label for="existing_coll_obj_disposition">Existing Disposition</label>
			<select name="existing_coll_obj_disposition" id="existing_coll_obj_disposition" size="1" class="reqdClr">
				<option selected="selected" value="">ignore</option>
					<cfloop query="existDisp">
				    	<option value="#coll_obj_disposition#">#coll_obj_disposition#</option>
					</cfloop>
			</select>
			<br><input type="submit" value="Delete Parts" class="delBtn">
		</form>

		<hr>

		<h2 class="h3">Specimens being Updated</h2>
	
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				cataloged_item.collection_object_id,
				collection.collection,
				cataloged_item.cat_num,
				identification.scientific_name,
				specimen_part.part_name,
				specimen_part.preserve_method,
				coll_object.condition,
				coll_object.lot_count_modifier,
				coll_object.lot_count,
				coll_object.coll_obj_disposition,
				coll_object_remark.coll_object_remarks
			FROM
				cataloged_item,
				collection,
				coll_object,
				specimen_part,
				identification,
				coll_object_remark,
				<cfif isDefined("result_id") and len(result_id) GT 0>
					user_search_table
				<cfelse>
					#table_name#
				</cfif>
			WHERE
				cataloged_item.collection_id=collection.collection_id and
				<cfif isDefined("result_id") and len(result_id) GT 0>
					cataloged_item.collection_object_id=user_search_table.collection_object_id and
					user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#"> and
				<cfelse>
					cataloged_item.collection_object_id=#table_name#.collection_object_id and
				</cfif>
				cataloged_item.collection_object_id=specimen_part.derived_from_cat_item and
				specimen_part.collection_object_id=coll_object.collection_object_id and
				specimen_part.collection_object_id=coll_object_remark.collection_object_id (+) and
				cataloged_item.collection_object_id=identification.collection_object_id and
				accepted_id_fg=1
			ORDER BY
				collection.collection,cataloged_item.cat_num
		</cfquery>
		<cfquery name="s" dbtype="query">
			SELECT 
				collection_object_id,collection,cat_num,scientific_name 
			FROM d 
			GROUP BY
				 collection_object_id,collection,cat_num,scientific_name
		</cfquery>
		<table border class="table">
			<tr>
				<th>Specimen</th>
				<th>ID</th>
				<th>Parts</th>
			</tr>
			<cfloop query="s">
				<tr>
					<td><a href="/SpecimenDetail.cfm?collection_object_id=#collection_object_id#">#collection# #cat_num#</a></td>
					<td>#scientific_name#</td>
					<cfquery name="sp" dbtype="query">
						select
							part_name,
							preserve_method,
							condition,
							lot_count_modifier,
							lot_count,
							coll_obj_disposition,
							coll_object_remarks
						from
							d
						where
							collection_object_id=#collection_object_id#
					</cfquery>
					<td>
						<table border width="100%">
							<th>Part</th>
							<th>Preserve Method</th>
							<th>Condition</th>
							<th>Count Modifier</th>
							<th>Count</th>
							<th>Dispn</th>
							<th>Remark</th>
							<cfloop query="sp">
								<tr>
									<td>#part_name#</td>
									<td>#preserve_method#</td>
									<td>#condition#</td>
									<td>#lot_count_modifier#</td>
									<td>#lot_count#</td>
									<td>#coll_obj_disposition#</td>
									<td>#coll_object_remarks#</td>
								</tr>
							</cfloop>
						</table>
					</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------->
<cfif action is "delPart2">
	<cfoutput>
		<cftransaction>
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				DELETE FROM
					specimen_part 
				WHERE
					collection_object_id in (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#partID#" list="yes">)
			</cfquery>
		</cftransaction>
	</cfoutput>
	<cfif isDefined("result_id") and len(result_id) GT 0>
		<cflocation url="/tools/bulkPart.cfm?result_id=#result_id#" addtoken="false">
	<cfelse>
		<cflocation url="/tools/bulkPart.cfm?table_name=#table_name#" addtoken="false">
	</cfif>
</cfif>
<!---------------------------------------------------------------------------->
<cfif action is "delPart">
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select
				specimen_part.collection_object_id partID,
				collection.collection,
				cataloged_item.cat_num,
				identification.scientific_name,
				specimen_part.part_name,
				specimen_part.preserve_method,
				coll_object.condition,
				coll_object.lot_count_modifier,
				coll_object.lot_count,
				coll_object.coll_obj_disposition,
				coll_object_remark.coll_object_remarks
			from
				cataloged_item,
				collection,
				coll_object,
				specimen_part,
				identification,
				coll_object_remark,
				<cfif isDefined("result_id") and len(result_id) GT 0>
					user_search_table
				<cfelse>
					#table_name#
				</cfif>
			where
				cataloged_item.collection_id=collection.collection_id and
				<cfif isDefined("result_id") and len(result_id) GT 0>
					cataloged_item.collection_object_id=user_search_table.collection_object_id and
					user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				<cfelse>
					cataloged_item.collection_object_id=#table_name#.collection_object_id and
				</cfif>
				cataloged_item.collection_object_id=specimen_part.derived_from_cat_item and
				specimen_part.collection_object_id=coll_object.collection_object_id and
				specimen_part.collection_object_id=coll_object_remark.collection_object_id (+) and
				cataloged_item.collection_object_id=identification.collection_object_id and
				accepted_id_fg=1 and
				part_name='#exist_part_name#'
				<cfif len(exist_preserve_method) gt 0>
					and preserve_method='#exist_preserve_method#'
				</cfif>
				<cfif len(existing_lot_count) gt 0>
					and lot_count=#existing_lot_count#
				</cfif>
				<cfif len(existing_coll_obj_disposition) gt 0>
					and coll_obj_disposition='#existing_coll_obj_disposition#'
				</cfif>
			order by
				collection.collection,cataloged_item.cat_num
		</cfquery>
		<form name="modPart" method="post" action="bulkPart.cfm">
			<input type="hidden" name="action" value="delPart2">
			<input type="hidden" name="table_name" value="#table_name#">
			<cfif isDefined("result_id") and len(result_id) GT 0>
				<input type="hidden" name="result_id" value="#result_id#">
			</cfif>
			<input type="hidden" name="partID" value="#valuelist(d.partID)#">
			<input type="submit" value="Looks good - do it" class="savBtn">
		</form>
		<table border>
			<tr>
				<th>Specimen</th>
				<th>ID</th>
				<th>PartToBeDeleted</th>
				<th>PreserveMethod</th>
				<th>Condition</th>
				<th>CntMod</th>
				<th>Cnt</th>
				<th>Dispn</th>
				<th>Remark</th>
			</tr>
			<cfloop query="d">
				<tr>
					<td>#collection# #cat_num#</td>
					<td>#scientific_name#</td>
					<td>#part_name#</td>
					<td>#preserve_method#</td>
					<td>#condition#</td>
					<td>#lot_count_modifier#</td>
					<td>#lot_count#</td>
					<td>#coll_obj_disposition#</td>
					<td>#coll_object_remarks#</td>
				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>

<!---------------------------------------------------------------------------->
<cfif action is "modPart2">
	<cfoutput>
	<cftransaction>
		<cfloop list="#partID#" index="i">
			<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				update specimen_part set
					part_name='#new_part_name#'
					<cfif len(new_preserve_method) gt 0>
							,preserve_method='#new_preserve_method#'
					</cfif>
				where collection_object_id=#i#
			</cfquery>
			<cfif len(new_lot_count) gt 0 or len(new_coll_obj_disposition) gt 0 or len(new_condition) gt 0>
				<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					update coll_object set
						flags=flags
						<cfif len(new_lot_count) gt 0>
							,lot_count=#new_lot_count#
						</cfif>
						<cfif len(new_coll_obj_disposition) gt 0>
							,coll_obj_disposition='#new_coll_obj_disposition#'
						</cfif>
						<cfif len(new_condition) gt 0>
							,condition='#new_condition#'
						</cfif>
					where collection_object_id=#i#
				</cfquery>
			</cfif>
			<cfif len(new_remark) gt 0>
				<cftry>
					<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						insert into coll_object_remark (collection_object_id,coll_object_remarks) values (#i#,'#new_remark#')
					</cfquery>
					<cfcatch>
						<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							update coll_object_remark set coll_object_remarks='#new_remark#' where collection_object_id=#i#
						</cfquery>
					</cfcatch>
				</cftry>
			</cfif>
		</cfloop>
		</cftransaction>
		<cfif isDefined("result_id") and len(result_id) GT 0>
			<cflocation url="/tools/bulkPart.cfm?result_id=#result_id#" addtoken="false">
		<cfelse>
			<cflocation url="/tools/bulkPart.cfm?table_name=#table_name#" addtoken="false">
		</cfif>
	</cfoutput>
</cfif>
<!---------------------------------------------------------------------------->
<cfif action is "modPart">
	<cfif len(exist_part_name) is 0 or len(new_part_name) is 0>
		<cfthrow message="Not enough information.  [exist_part_name or new_part_name not provided]">
	</cfif>
	<cfoutput>
		<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select
				specimen_part.collection_object_id partID,
				collection.collection,
				cataloged_item.cat_num,
				identification.scientific_name,
				specimen_part.part_name,
				specimen_part.preserve_method,
				coll_object.condition,
				coll_object.lot_count,
				coll_object.coll_obj_disposition,
				coll_object_remark.coll_object_remarks
			from
				cataloged_item,
				collection,
				coll_object,
				specimen_part,
				identification,
				coll_object_remark,
				<cfif isDefined("result_id") and len(result_id) GT 0>
					user_search_table
				<cfelse>
					#table_name#
				</cfif>
			where
				cataloged_item.collection_id=collection.collection_id and
				<cfif isDefined("result_id") and len(result_id) GT 0>
					cataloged_item.collection_object_id=user_search_table.collection_object_id and
					user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
				<cfelse>
					cataloged_item.collection_object_id=#table_name#.collection_object_id and
				</cfif>
				cataloged_item.collection_object_id=specimen_part.derived_from_cat_item and
				specimen_part.collection_object_id=coll_object.collection_object_id and
				specimen_part.collection_object_id=coll_object_remark.collection_object_id (+) and
				cataloged_item.collection_object_id=identification.collection_object_id and
				accepted_id_fg=1 and
				part_name='#exist_part_name#'
				<cfif len(existing_lot_count) gt 0>
					and lot_count=#existing_lot_count#
				</cfif>
				<cfif len(existing_coll_obj_disposition) gt 0>
					and coll_obj_disposition='#existing_coll_obj_disposition#'
				</cfif>
			order by
				collection.collection,cataloged_item.cat_num
		</cfquery>
		<form name="modPart" method="post" action="bulkPart.cfm">
			<input type="hidden" name="action" value="modPart2">
			<input type="hidden" name="table_name" value="#table_name#">
			<input type="hidden" name="exist_part_name" value="#exist_part_name#">
			<input type="hidden" name="new_part_name" value="#new_part_name#">
			<input type="hidden" name="exist_preserve_method" value="#exist_preserve_method#">
			<input type="hidden" name="new_preserve_method" value="#new_preserve_method#">
			<input type="hidden" name="existing_lot_count" value="#existing_lot_count#">
			<input type="hidden" name="new_lot_count" value="#new_lot_count#">
			<input type="hidden" name="existing_coll_obj_disposition" value="#existing_coll_obj_disposition#">
			<input type="hidden" name="new_coll_obj_disposition" value="#new_coll_obj_disposition#">
			<input type="hidden" name="new_condition" value="#new_condition#">
			<input type="hidden" name="new_remark" value="#new_remark#">
			<input type="hidden" name="partID" value="#valuelist(d.partID)#">
			<input type="submit" value="Looks good - do it" class="savBtn">
		</form>
		<table border>
			<tr>
				<th>Specimen</th>
				<th>ID</th>
				<th>OldPart</th>
				<th>NewPart</th>
				<th>OldPresMethod</th>
				<th>NewPresMethod</th>
				<th>OldCondition</th>
				<th>NewCondition</th>
				<th>OldCnt</th>
				<th>NewdCnt</th>
				<th>OldDispn</th>
				<th>NewDispn</th>
				<th>OldRemark</th>
				<th>NewRemark</th>
			</tr>
			<cfloop query="d">
				<tr>
					<td>#collection# #cat_num#</td>
					<td>#scientific_name#</td>
					<td>#part_name#</td>
					<td>#new_part_name#</td>
					<td>#preserve_method#</td>
					<td>
						<cfif len(new_preserve_method) gt 0>
							#new_preserve_method#
						<cfelse>
							NOT UPDATED
						</cfif>
					</td>
					<td>#condition#</td>
					<td>
						<cfif len(new_condition) gt 0>
							#new_condition#
						<cfelse>
							NOT UPDATED
						</cfif>
					</td>
					<td>#lot_count#</td>
					<td>
						<cfif len(new_lot_count) gt 0>
							#new_lot_count#
						<cfelse>
							NOT UPDATED
						</cfif>
					</td>
					<td>#coll_obj_disposition#</td>
					<td>
						<cfif len(new_coll_obj_disposition) gt 0>
							#new_coll_obj_disposition#
						<cfelse>
							NOT UPDATED
						</cfif>
					</td>
					<td>#coll_object_remarks#</td>
					<td>
						<cfif len(new_remark) gt 0>
							#new_remark#
						<cfelse>
							NOT UPDATED
						</cfif>
					</td>

				</tr>
			</cfloop>
		</table>
	</cfoutput>
</cfif>

<!---------------------------------------------------------------------------->
<cfif action is "newPart">
<cfoutput>
	<cfquery name="ids" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct collection_object_id from #table_name#
	</cfquery>
	<cftransaction>
		<cfloop query="ids">
			<cfloop from="1" to="#numParts#" index="n">
				<cfset thisPartName = #evaluate("part_name_" & n)#>
				<cfset thisPreserveMethod = #evaluate("preserve_method_" & n)#>
				<cfset thisLotCountModifier = #evaluate("lot_count_modifier_" & n)#>
				<cfset thisLotCount = #evaluate("lot_count_" & n)#>
				<cfset thisDisposition = #evaluate("coll_obj_disposition_" & n)#>
				<cfset thisCondition = #evaluate("condition_" & n)#>
				<cfset thisRemark = #evaluate("coll_object_remarks_" & n)#>
				<cfif len(#thisPartName#) gt 0>
					<cfquery name="insCollPart" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						INSERT INTO coll_object (
							COLLECTION_OBJECT_ID,
							COLL_OBJECT_TYPE,
							ENTERED_PERSON_ID,
							COLL_OBJECT_ENTERED_DATE,
							LAST_EDITED_PERSON_ID,
							COLL_OBJ_DISPOSITION,
							lot_count_modifier,
							LOT_COUNT,
							CONDITION,
							FLAGS )
						VALUES (
							sq_collection_object_id.nextval,
							'SP',
							#session.myAgentId#,
							sysdate,
							#session.myAgentId#,
							'#thisDisposition#',
							'#thisLotCountModifier#',
							#thisLotCount#,
							'#thisCondition#',
							0 )
					</cfquery>
					<cfquery name="newTiss" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						INSERT INTO specimen_part (
							  COLLECTION_OBJECT_ID,
							  PART_NAME,
							  Preserve_method
								,DERIVED_FROM_cat_item)
							VALUES (
								sq_collection_object_id.currval,
							  '#thisPartName#',
							  '#thisPreserveMethod#'
								,#ids.collection_object_id#)
					</cfquery>
					<cfif len(#thisRemark#) gt 0>
						<cfquery name="newCollRem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							INSERT INTO coll_object_remark (collection_object_id, coll_object_remarks)
							VALUES (sq_collection_object_id.currval, '#thisRemark#')
						</cfquery>
					</cfif>
				</cfif>
			</cfloop>
		</cfloop>
	</cftransaction>
	Success!
	<a href="/SpecimenResults.cfm?collection_object_id=#valuelist(ids.collection_object_id)#">Return to SpecimenResults</a>
</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">
