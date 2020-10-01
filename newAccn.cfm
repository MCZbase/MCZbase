<cfinclude template="includes/_header.cfm">
<script language="javascript" type="text/javascript">
	jQuery(document).ready(function() {
		$("#rec_date").datepicker();
		$("#ent_Date").datepicker();
	});
</script>
<cfset title = "New Accession">
<cfif #action# is "nothing">
<cfoutput>
	<cfquery name="ctcoll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select collection,collection_id from collection order by collection
	</cfquery>
	<cfquery name="ctStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select accn_status from ctaccn_status order by accn_status
	</cfquery>
	<cfquery name="ctType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select accn_type from ctaccn_type order by accn_type
	</cfquery>
	<cfset thisDate = #dateformat(now(),"yyyy-mm-dd")#>
        <div style="width: 54em;margin: 0 auto;padding-bottom: 4em;">
	<cfform action="newAccn.cfm" method="post" name="newAccn">
		<input type="hidden" name="Action" value="createAccession">
			<h2 class="wikilink" style="margin-left:0;">Create Accession <img class="infoLink" src="/images/info_i_2.gif" alt="[help]" onClick="getMCZDocs('Create Accession')"/></h2>
        <table>
			<tr>
				<td valign="top">
					<table class="newRec" style="padding:1em 1em 0 1em;border: 1px solid ##ccc;">
						<tr>
							<td colspan="6">

							</td>
						</tr>
						<tr>
							<td>
								<label for="collection_id">Collection:</label>
								<select name="collection_id" size="1" id="collection_id" class="reqdClr">
										<option selected value="">Pick One...</option>
										<cfloop query="ctcoll">
											<option value="#ctcoll.collection_id#">#ctcoll.collection#</option>
										</cfloop>
								</select>
							</td>
							<td>
								<label for="accn_number">Accn Number:</label>
								<input type="text" name="accn_number" id="accn_number" class="reqdClr" required="true">
							</td>
							<td>
								<label for="accn_status">Status:</label>
								<select name="accn_status" size="1" class="reqdClr" required="true">
									<cfloop query="ctStatus">
										<option
											<cfif #ctStatus.accn_status# is "in process">selected </cfif>
											value="#ctStatus.accn_status#">#ctStatus.accn_status#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<label for="rec_date">Date Received:</label>
								<input type="text" name="rec_date" id="rec_date" class="reqdClr" required="true">
							</td>
						</tr>
						<tr>
							<td colspan="9">
								<label for="nature_of_material">Nature of Material:</label>
								<textarea name="nature_of_material" rows="5" cols="90" class="reqdClr" required="true"></textarea>
							</td>
						</tr>
						<tr>
							<td colspan="2">
								<label for="rec_agent">Received From:</label>
								<input type="text" name="rec_agent" class="reqdClr" size="40"
									readonly autocomplete="off" onfocus="this.removeAttribute('readonly');"
									onchange="getAgent('received_agent_id','rec_agent','newAccn',this.value); return false;"
								 	onKeyPress="return noenter(event);"
									required="true"
									>
								<input type="hidden" name="received_agent_id">
								<!---
							</td>
							<td>
								<label for="rec_agent">From Agency:</label>
								<input type="text" name="trans_agency" readonly autocomplete="off" onfocus="this.removeAttribute('readonly');"
									onchange="getAgent('trans_agency_id','trans_agency','newAccn',this.value); return false;"
								 	onKeyPress="return noenter(event);">
								<input type="hidden" name="trans_agency_id">
								--->
							</td>
							<td>
								<label for="accn_type">Accn Type</label>
								<select name="accn_type" size="1"  class="reqdClr">
									<cfloop query="cttype">
										<option value="#cttype.accn_type#">#cttype.accn_type#</option>
									</cfloop>
								</select>
							</td>
							<td>
								<label for="estimated_count">Estimated Count</label>
								<input type="text" id="estimated_count" name="estimated_count">
							</td>
						</tr>
						<tr>
							<td colspan="1">
								<label for="radio1">To be MCZ cataloged</label>
								<input type="radio" name="for_use_by" value="" checked="checked" id="radio1">
							</td>
							<td colspan="1">
								<label for="radio2">For use by HMNH Exhibits</label>
								<input type="radio" name="for_use_by" value="116195" id="radio2">
							</td>
							<td colspan="2">
								<label for="radio3">For use by HMNH Education</label>
								<input type="radio" name="for_use_by" value="91906" id="radio3">
							</td>
						</tr>
						<tr>
							<td colspan="6">
								<label for="remarks">Remarks:</label>
								<textarea name="remarks" rows="5" cols="90"></textarea>
							</td>
						</tr>
						<tr>
							
							<td colspan="2">
								<label for="ent_Date">Entry Date:</label>
								<cfinput type="text" name="ent_Date_dis" id="ent_Date_dis" value="#thisDate#" disabled="true">
								<input type="hidden" name="ent_Date" id="ent_Date" value="#thisDate#">
							</td>
							<td>
								<!---
								<label for="">Has Correspondence?</label>
								<select name="correspFg">
									<option value="1">Yes</option>
									<option value="0">No</option>
								</select>
								--->
							</td>
							<td>
								<!---
								<label for="is_public_fg">Public?</label>
								<select name="is_public_fg">
									<option value="1">public</option>
									<option selected="selected" value="0">private</option>
								</select>
								--->
							</td>
							<td>&nbsp;</td>
						</tr>
						<tr style="line-height: 4em">
							<td colspan="6" align="center">
							<input type="submit"
								value="Save this Accession"
								class="savBtn">
							<input type="button"
									value="Quit without saving"
									class="qutBtn"
									onClick="document.location = 'editAccn.cfm'">

							</td>
						</tr>
					</table>
				</td>
				<td valign="top">
					<div class="nextnum" id="nextNumDiv" style="width: auto;">
						<p>Next Number</p>
						<cfquery name="gnn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select max(to_number(accn_number)) + 1 as an from accn where to_number(accn_number) < 10000000
						</cfquery>
						<span class="likeLink" onclick="document.getElementById('accn_number').value='#gnn.an#';">#gnn.an#</span>
					</div><!--- end nextNumDiv --->
				</td>
			</tr>
		</table>
	</cfform>
    </div>
</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "createAccession">
	<cfoutput>
		<cftransaction>
			<cfquery name="n" datasource="user_login" username="#session.username#" password="#decrypt(session.epw,cfid)#">
				select sq_transaction_id.nextval n from dual
			</cfquery>
			<cfquery name="newTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans (
					TRANSACTION_ID,
					TRANS_DATE,
					CORRESP_FG,
					collection_id,
					TRANSACTION_TYPE
					<cfif len(#NATURE_OF_MATERIAL#) gt 0>
						,NATURE_OF_MATERIAL
					</cfif>
					<cfif len(#REMARKS#) gt 0>
						,TRANS_REMARKS
					</cfif>,
					is_public_fg
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#n.n#'>,
					<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value='#dateformat(ent_Date,"yyyy-mm-dd")#'>,
					null,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#collection_id#'>,
					'accn'
					<cfif len(#NATURE_OF_MATERIAL#) gt 0>
						, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#NATURE_OF_MATERIAL#'>
					</cfif>
					<cfif len(#REMARKS#) gt 0>
						, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#REMARKS#'>
					</cfif>,
					null
				)
			</cfquery>
			<cfquery name="newAccn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO accn (
					TRANSACTION_ID,
					ACCN_TYPE
					,accn_number
					,RECEIVED_DATE,
					ACCN_STATUS,
					estimated_count
					)
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#n.n#'>
					, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#accn_type#'>
					, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#accn_number#'>
					, <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value='#dateformat(rec_Date,"yyyy-mm-dd")#'>
					, <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value='#accn_status#'>
					<cfif len(estimated_count) gt 0>
						, <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#estimated_count#'>
					<cfelse>
						, null
					</cfif>
					)
			</cfquery>
			<cfquery name="newAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into trans_agent (
					transaction_id,
					agent_id,
					trans_agent_role
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#n.n#'>,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#received_agent_id#'>,
					'received from'
				)
			</cfquery>
			<cfif len(#for_use_by#) gt 0>
				<cfquery name="newAgent" datasource="user_login" username="#session.username#" password="#decrypt(session.epw,cfid)#">
					insert into trans_agent (
						transaction_id,
						agent_id,
						trans_agent_role
					) values (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#n.n#'>,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value='#for_use_by#'>,
						'for_use_by'
					)
				</cfquery>
			</cfif>
		</cftransaction>
		<cflocation url="editAccn.cfm?Action=edit&transaction_id=#n.n#" addtoken="false">
  </cfoutput>
</cfif>
<cfinclude template="includes/_footer.cfm">
