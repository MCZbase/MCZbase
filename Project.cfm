<cfset jquery11=true>
<cfinclude template="includes/_header.cfm">
<script type='text/javascript' src='/includes/internalAjax.js'></script>
<cfoutput>
<script language="javascript" type="text/javascript">
	$(document).ready(function() {
		$("##start_date").datepicker({ dateFormat: "yy-mm-dd"});  
		$("##end_date").datepicker({ dateFormat: "yy-mm-dd"});
		//$("##began_date").datepicker({dateFormat: "yy-mm-dd",showOn: "button",
		//	buttonImage: "images/cal_icon.png",
		//	buttonImageOnly: true });
		//$("##ended_date").datepicker({dateFormat: "yy-mm-dd",showOn: "button",
		//	buttonImage: "images/cal_icon.png",
		//	buttonImageOnly: true });
      $(".ui-datepicker-trigger").css("margin-bottom","-7px");	
	});
	function addProjTaxon() {
		if (document.getElementById('newTaxId').value.length == 0){
			alert('Choose a taxon name, then click the button');
			return false;
		} else {
			document.tpick.submit();
		}
	}
</script>
</cfoutput>
<div style="width: 55em; margin: 0 auto;padding:2em 0 5em 0;">

<cfif action is "nothing">
	<cfheader statuscode="301" statustext="Moved permanently">
	<cfheader name="Location" value="/SpecimenUsage.cfm">
</cfif>
<cfquery name="ctProjAgRole" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select project_agent_role from ctproject_agent_role
</cfquery>
<!------------------------------------------------------------------------------------------->
<cfif Action is "makeNew">
	<cfset title="create project">

<h2 class="wikilink">Create New Project:</h2>
<div class="content_box_proj" style="background-color: #f8f8f8; border: 1px dotted #ccc;padding: .75em 1.25em 1.25em 1.25em;margin-top: .5em;">
<cfoutput>
	<form name="project" action="Project.cfm" method="post">
		<input type="hidden" name="Action" value="createNew">
		<table>
			<tr>
				<td>
					<label for="project_name">Project Title</label>
					<textarea name="project_name" id="project_name" cols="70" rows="2" class="reqdClr"></textarea>
				</td>
				<td>
					<span class="infoLink helpers" style="margin-top: 11px;" onclick="italicize('project_name')">italicize selected text</span>				<span class="infoLink helpers" onclick="bold('project_name')">bold selected text</span>
					<span class="infoLink helpers" onclick="superscript('project_name')">superscript selected text</span>
                    <span class="infoLink helpers" onclick="subscript('project_name')">subscript selected text</span>
				</td>
			</tr>
		</table>
			<label for="start_date">Start&nbsp;Date</label>
				<input type="text" name="start_date" id="start_date" placeholder="yyyy-mm-dd">
				<label for="end_date">End&nbsp;Date</label>
				<input type="text" name="end_date" id="end_date" placeholder="yyyy-mm-dd">
				<label for="end_date">Description</label>
				<textarea name="project_description" id="project_description" cols="100" rows="6"></textarea>
				<label for="project_remarks">Remarks</label>
				<textarea name="project_remarks" id="project_remarks" cols="100" rows="3"></textarea>
				<br>
	
 </div>
       <input type="submit" value="Create Project" class="insBtn" style="margin-top: 1.5em;">
				<p style="margin-top: 1em;">You can add Agents, Publications, Media, Transactions, and Taxonomy after you create the basic project.</p>
    			
			</form>
</cfoutput>

</cfif>
<!------------------------------------------------------------------------------------------->
<cfif Action is "createNew">
	<cfoutput>
		<cfquery name="nextID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select sq_project_id.nextval nextid from dual
		</cfquery>
		<cfquery name="newProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		INSERT INTO project (
			PROJECT_ID,
			PROJECT_NAME
			<cfif len(#START_DATE#) gt 0>
				,START_DATE
			</cfif>
			
			<cfif len(#END_DATE#) gt 0>
				,END_DATE
			</cfif>
			<cfif len(#PROJECT_DESCRIPTION#) gt 0>
				,PROJECT_DESCRIPTION
			</cfif>
			<cfif len(#PROJECT_REMARKS#) gt 0>
				,PROJECT_REMARKS
			</cfif>
			 )
		VALUES ( 
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextID.nextid#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#PROJECT_NAME#">
			<cfif len(#START_DATE#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(START_DATE,"yyyy-mm-dd")#">
			</cfif>
			
			<cfif len(#END_DATE#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(END_DATE,"yyyy-mm-dd")#">
			</cfif>
			<cfif len(#PROJECT_DESCRIPTION#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#PROJECT_DESCRIPTION#">
			</cfif>
			<cfif len(#PROJECT_REMARKS#) gt 0>
				,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#PROJECT_REMARKS#">
			</cfif>
			 )   
	</cfquery>  
	<cflocation url="Project.cfm?Action=editProject&project_id=#nextID.nextid#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif action is "editProject">

	<cfset title="Edit Project">
	<cfoutput>
		<h2 class="wikiedit">Edit Project</h2> 
        <a href="/ProjectDetail.cfm?project_id=#project_id#">[ Detail Page ]</a>
		<cfquery name="getDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT 
				project.project_id,
				project_name,
				start_date,
				end_date,
				project_description,
				project_agent_name.agent_name,
				project_agent_name.agent_name_id,
				project_agent_role,
				project_remarks,
				agent_position,
				PROJECT_SPONSOR_ID,
				ACKNOWLEDGEMENT,
				project_sponsor.agent_name_id project_name_id,
				s_name.agent_name sponsor_name
			FROM 
				project,
				project_sponsor,
				agent_name project_agent_name,
				agent_name s_name,
				project_agent					
			WHERE 
				project.project_id = project_agent.project_id (+) AND 
				project.project_id = project_sponsor.project_id (+) AND 
				project_agent.agent_name_id = project_agent_name.agent_name_id (+) AND
				project_sponsor.agent_name_id = s_name.agent_name_id (+) AND
				project.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
			order by project_id
		</cfquery>
		<cfquery name="sponsors" dbtype="query">
			select
				PROJECT_SPONSOR_ID,
				ACKNOWLEDGEMENT,
				project_name_id,
				sponsor_name,
				project_name_id
			from
				getDetails
			WHERE
				PROJECT_SPONSOR_ID is not null
			group by
				PROJECT_SPONSOR_ID,
				ACKNOWLEDGEMENT,
				project_name_id,
				sponsor_name,
				project_name_id
		</cfquery>
		<cfquery name="agents" dbtype="query">
			select agent_name, agent_position, agent_name_id, project_agent_role from getDetails 
			where agent_name is not null
			group by agent_name, agent_position, agent_name_id, project_agent_role
			order by agent_position
		</cfquery>
		<cfquery name="getLoans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select 
				collection.collection,
				loan.loan_number,
				loan.transaction_id,
				nature_of_material,
				trans.trans_remarks,
				loan_description,
				project_trans.project_trans_remarks
			from 
				project_trans, 
				loan, 
				trans,
				collection
			where
				project_trans.transaction_id=loan.transaction_id and
				loan.transaction_id = trans.transaction_id and
				trans.collection_id=collection.collection_id and
				project_trans.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getDetails.project_id#">
			order by collection, loan_number
		</cfquery>
		<cfquery name="getAccns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select 
				accn_number,
				collection,
				accn.transaction_id,
				nature_of_material,
				trans_remarks
			from 
				project_trans, 
				accn, 
				trans,
				collection
			where
				project_trans.transaction_id=accn.transaction_id and
				accn.transaction_id = trans.transaction_id and
				trans.collection_id=collection.collection_id and
				project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getDetails.project_id#">
			order by collection, accn_number
		</cfquery>
		<cfquery name="taxonomy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select 
				taxonomy.taxon_name_id,
				scientific_name
			from 
				project_taxonomy, 
				taxonomy
			where
				taxonomy.taxon_name_id=project_taxonomy.taxon_name_id and
				project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getDetails.project_id#">
			order by 
				scientific_name
		</cfquery>
		<cfquery name="proj" dbtype="query">
			SELECT 
				project_id,
				project_name,
				start_date,
				end_date,
				project_description,
				project_remarks
			FROM 
				getDetails
			group by
				project_id,
				project_name,
				start_date,
				end_date,
				project_description,
				project_remarks
		</cfquery>
		<cfquery name="numAgents" dbtype="query">
			select max(agent_position) as  agent_position from agents
		</cfquery>
		<cfif len(numAgents.agent_position) gt 0>
			<cfset numberOfAgents = numAgents.agent_position + 1>
		<cfelse>
			<cfset numberOfAgents = 1>
		</cfif>
		<cfquery name="publications" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT 
				formatted_publication, formatted_publication.publication_id  
			FROM 
				project_publication,
				formatted_publication,
				publication
			WHERE 
				project_publication.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#"> AND  
				project_publication.publication_id = formatted_publication.publication_id AND 
				project_publication.publication_id = publication.publication_id AND 
				format_style = 'long'
			</cfquery>
			<form name="project" action="Project.cfm" method="post">
				<input type="hidden" name="action">
				<input type="hidden" name="project_id" id="project_id" value="#proj.project_id#">
				<table>
				<tr>
					<td>
						<label for="project_name">Project Title</label>
						<textarea name="project_name" id="project_name" cols="80" rows="3" class="reqdClr">#proj.project_name#</textarea>
					</td>
					<td>
						<span class="infoLink" onclick="italicize('project_name')">italicize selected text</span>
						<br><span class="infoLink" onclick="bold('project_name')">bold selected text</span>
						<br><span class="infoLink" onclick="superscript('project_name')">superscript selected text</span>
						<br><span class="infoLink" onclick="subscript('project_name')">subscript selected text</span>
					</td>
				</tr>
			</table>
				<label for="start_date">Start&nbsp;Date</label>
				<input type="text" name="start_date" id="start_date" value="#dateformat(proj.start_date,"yyyy-mm-dd")#" placeholder="yyyy-mm-dd">
				<label for="end_date">End&nbsp;Date</label>
				<input type="text" name="end_date" id="end_date" value="#dateformat(proj.end_date,"yyyy-mm-dd")#" placeholder="yyyy-mm-dd">
				<label for="end_date">Description</label>
				<textarea name="project_description" id="project_description" cols="80" rows="6">#proj.project_description#</textarea>
				<label for="project_remarks">Remarks</label>
				<textarea name="project_remarks" id="project_remarks" cols="80" rows="3">#proj.project_remarks#</textarea>
				<br>
				<input type="button" 
					value="Save Updates" 
					class="savBtn"
					onclick="document.project.action.value='saveEdits';submit();">
				<input type="button"
					value="Delete"
					class="delBtn"
					onclick="document.project.action.value='deleteProject';submit();">
				<input type="button"
					value="Quit"
					class="qutBtn"
					onClick="document.location='Project.cfm';">
			</form>
			<a name="agent"></a>
			<table style="margin: 1em 0;">
				<tr>
					<td colspan="2">
						<p>Project&nbsp;Agents</p>
					</td>
					<td colspan="2">
					Agent&nbsp;Role
					</td>
				</tr>
				<cfset i = 1>
				<cfloop query="agents">
					<form name="projAgents#i#" method="post" action="Project.cfm">
					    <input type="hidden" name="Action" value="saveAgentChange">
						<input type="hidden" name="project_id" value="#getDetails.project_id#">
						<input type="hidden" name="agent_name_id" value="#agents.agent_name_id#">
						<tr	#iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
							<td>
								##
								<select name="agent_position" size="1" class="reqdClr">
									<cfloop from="1" to="#numberOfAgents#" index="a">
										<option 
											<cfif #agent_position# is #a#> selected="selected" </cfif>
											value="#a#">#a#</option>
									</cfloop>
									<option value=""></option>
								</select>
							</td>
							<td>			
								<input type="text" name="agent_name" id="agent_name_#i#"
									value="#AGENTS.agent_name#" 
									class="reqdClr" 
									onchange="findAgentName('new_name_id_#i#',this.id,this.value); return false;"
									onKeyPress="return noenter(event);">
								<input type="hidden" name="new_name_id" id="new_name_id_#i#">
							</td>
							<td>
								<cfset thisRole = agents.project_agent_role>
								<select name="project_agent_role" size="1" class="reqdClr">
									<cfloop query="ctProjAgRole">
									<option 
										<cfif #ctProjAgRole.project_agent_role# is "#thisRole#"> 
											selected 
										</cfif> value="#ctProjAgRole.project_agent_role#">#ctProjAgRole.project_agent_role#
									</option>
									</cfloop>
								</select>
							</td>
							<td nowrap valign="center">			
								<input type="button" 
									value="Delete"
									class="delBtn"
									onclick="document.location='Project.cfm?Action=removeAgent&project_id=#project_id#&agent_name_id=#agent_name_id#';">
								<input type="submit" value="Save" class="savBtn">
							 </td>
						     <cfset i = i+1>
						</tr>
					</form>
				</cfloop>
				<tr class="newRec">
					<td colspan="5">
						Add Agent:
					</td>
				</tr>
				<tr class="newRec">
					<form name="newAgent" method="post" action="Project.cfm">
						<input type="hidden" name="Action" value="newAgent">
						<input type="hidden" name="project_id" value="#getDetails.project_id#">
						<td>	
							## <select name="agent_position" size="1" class="reqdClr">
								<cfloop from="1" to="#numberOfAgents#" index="i">
									<option 
										<cfif numberOfAgents is i> selected </cfif>	value="#i#">#i#</option>
								</cfloop>
								<option value=""></option>
							</select>
						</td>
						<td>
							<input type="text" name="newAgent_name" id="newAgent_name" 
								class="reqdClr" 
								onchange="findAgentName('newAgent_name_id','newAgent_name',this.value); return false;"
								onKeyPress="return noenter(event);">
							<input type="hidden" name="newAgent_name_id" id="newAgent_name_id">
						</td>
						<td>
							<select name="newRole" size="1" class="reqdClr">
								<cfloop query="ctProjAgRole">
									<option value="#ctProjAgRole.project_agent_role#">#ctProjAgRole.project_agent_role#
									</option>
								</cfloop>
							</select>
						</td>
						<td>
							<input type="submit" value="Save" class="savBtn">
						</td>
					</form>
				</tr>
			</table>
			<a name="sponsor"></a>
			<table border>
				<tr>
					<td>Project Sponsor</td>
					<td>Acknowledgement</td>
				</tr>
				<cfset i=1>
				<cfloop query="sponsors">
					<form name="sponsor#i#" method="post" action="Project.cfm">
						<input type="hidden" name="action" value="saveSponsorChange">
						<input type="hidden" name="project_id" value="#project_id#">
						<input type="hidden" name="PROJECT_SPONSOR_ID" value="#PROJECT_SPONSOR_ID#">
						<input type="hidden" name="agent_name_id" id="newAgent_name_id" value="#project_name_id#">
						<tr>
							<td>
								<input type="text" name="sponsor_name" 
								class="reqdClr" 
								onchange="findAgentName('agent_name_id','sponsor_name',this.value); return false;"
								onKeyPress="return noenter(event);"
								value="#sponsor_name#">
							</td>
							<td>
								<input type="text" size="60" name="ACKNOWLEDGEMENT" value="#ACKNOWLEDGEMENT#" class="reqdClr">
							</td>
							<td>
								<input type="submit" 
									value="Save Edits" 
									class="savBtn">
							</td>
							<td>
								<input type="button" 
									value="Delete Sponsor" 
									class="delBtn"
									onclick="sponsor#i#.action.value='deleteSponsor';submit();")>
							</td>
						</tr>
					</form>
					<cfset i=i+1>
				</cfloop>
				<form name="addSponsor" method="post" action="Project.cfm">
					<input type="hidden" name="new_sponsor_id" id="new_sponsor_id">
					<input type="hidden" name="project_id" value="#project_id#">
					<input type="hidden" name="action" value="addSponsor">
					<tr class="newRec">
						<td colspan="3">
							Add Sponsor
						</td>
					</tr>
					<tr>
						<td>
							<input type="text" name="new_sponsor_name" id="new_sponsor_name"
								class="reqdClr" 
								onchange="findAgentName('new_sponsor_id','new_sponsor_name',this.value); return false;"
								onKeyPress="return noenter(event);">
						</td>
						<td>
							<input type="text" size="70" name="newAcknowledgement" id="newAcknowledgement">
						</td>
						<td>
							<label for="add">&nbsp;</label>
							<input type="submit" 
									value="Add Sponsor" 
									class="savBtn">
						</td>
					</tr>
				</form>
			</table>
			<a name="trans"></a>
			<p>
				<strong>Project Accessions</strong>
				[ <a href="editAccn.cfm?project_id=#getDetails.project_id#">Add Accession</a> ] <!--- TODO: Replicate this API call another way --->
				<cfset i=1>
				<cfloop query="getAccns">
	 				<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>	
						<a href="/transactions/Accession.cfm?action=edit&transaction_id=#getAccns.transaction_id#">
							<strong>#collection#  #accn_number#</strong>
						</a>
						<a href="/Project.cfm?Action=delTrans&transaction_id=#transaction_id#&project_id=#getDetails.project_id#">
							[ Remove ]
						</a>
						<br>
							#nature_of_material# - #trans_remarks#
					</div>
					<cfset i=i+1>		
				</cfloop>
			</p>
			<p>
				<strong>Project Loans</strong>

				<form name="addLoan" method="post" action="Project.cfm">
					<div style="width: 100%; border: 1px gray; border-style: solid; padding: 3px;">
						<input type="hidden" name="action" id="addLoanAction" value="addLoan">
						<input type="hidden" name="project_id" value="#getDetails.project_id#">
						<input type="hidden" name="transaction_id" id="transaction_id" value="">
						<label for="loan_number">Pick loan by loan number</label>
						<input type="text" name="loan_number" id="loan_number" value="" placeholder="yyyy-n-Coll" size="40" style="width: 90%">
						<div style="width: 50em; positiuon: absolute;"></div>
						<label for="project_loan_remarks">Remarks</label>
						<input type="text" name="project_loan_remarks" id="project_loan_remarks" value="" size="30">
						<input type="submit" id="addLoanButton" value="Add Loan" class="savBtn" disabled>
						<script>
							function makeLoanPicker(nameControl,idControl,submitControl) {
								$('##'+nameControl).autocomplete({
									source: function (request, response) {
										$.ajax({
											url: "/transactions/component/functions.cfc",
											data: { term: request.term, method: 'getLoanAutocomplete' },
											dataType: 'json',
											success : function (data) { response(data); },
											error : function (jqXHR, textStatus, error) {
												var message = "";
												if (error == 'timeout') {
													message = ' Server took too long to respond.';
												} else if (error && error.toString().startsWith('Syntax Error: "JSON.parse:')) {
													message = ' Backing method did not return JSON.';
												} else {
													message = jqXHR.responseText;
												}
												console.log(error);
												messageDialog('Error:' + message ,'Error: ' + error);
											}
										})
									},
									focus: function (event, ui) {
										$('##'+nameControl).val(result.item.meta);
										return false;
									},
									select: function (event, result) {
										$('##'+nameControl).val(result.item.meta);
										if (idControl) {
											// if idControl is non null, non-empty, non-false
											$('##'+idControl).val(result.item.id);
										}
										if (submitControl) {
											// if submitControl is non null, non-empty, non-false
											$('##'+submitControl).prop('disabled',false);
										}
										return false;
									},
									minLength: 3
								});
								//.autocomplete("instance")._renderItem = function(ul,item) {
								//	// override to display meta "collection name * (description)" instead of value in picklist.
								//	return $("<li>").append("<div style='width: 30em;'>" + item.value + " (" + item.meta + ")</div>").appendTo(ul);
								//};
							};

							$(document).ready(function () {
								makeLoanPicker("loan_number","transaction_id","addLoanButton");
							});
						</script>
					</div>				
				</form>

				<cfset i=1>
				<cfloop query="getLoans">
		 			<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
						<a href="/transactions/Loan.cfm?action=editLoan&transaction_id=#transaction_id#">
							<strong>#collection# #loan_number#</strong>
						</a>
						<a href="Project.cfm?Action=delTrans&transaction_id=#transaction_id#&project_id=#getDetails.project_id#">
							[ Remove ]
						</a>
						<cfif len(project_trans_remarks) GT 0><cfset pr_t_remarks = "[#project_trans_remarks#]"><cfelse><cfset pr_t_remarks = ""></cfif>
						<div>
							#nature_of_material# - #LOAN_DESCRIPTION# #pr_t_remarks#
						</div>
					</div>
					<cfset i=i+1>
				</cfloop>
			</p>
			<a name="pub"></a>
			<p>
				<strong>Project Publications</strong>
				<a href="/SpecimenUsage.cfm?toproject_id=#getDetails.project_id#">[ add Publication ]</a>
				<cfset i=1>
				<cfloop query="publications">
		 			<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
						<div>
							#formatted_publication#
						</div>
						<br>
						<a href="/publications/Publication.cfm?publication_id=#publication_id#">[ Edit Publication ]</a>
						<a href="/Project.cfm?Action=delePub&publication_id=#publication_id#&project_id=#getDetails.project_id#">
							[ Remove Publication ]
						</a>
					</div>
					<cfset i=i+1>
				</cfloop>
			</p>
			<p><a name="taxonomy"></a>
				<strong>Project Taxonomy</strong>
				<form name="tpick" method="post" action="Project.cfm">
					<input type='hidden' name='project_id' value='#proj.project_id#'>
					<input type='hidden' name='action' value='addtaxon'>
					<label for="newtax">Add taxon name</label>
					<input type="text" name="newtax" id="newtax" onchange="taxaPick('newTaxId',this.id,'tpick',this.value)"
						onKeyPress="return noenter(event);">
					<input type="hidden" name="newTaxId" id="newTaxId">
					<input type="button" onclick="addProjTaxon()" value="Add Taxon">
				</form>
				<cfset i=1>
				<cfloop query="taxonomy">
		 			<div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
						<div>
							<a href="/name/#scientific_name#">#scientific_name#</a>
							<a href="/Project.cfm?action=removeTaxonomy&taxon_name_id=#taxon_name_id#&project_id=#project_id#">
								[ Remove Name ]
							</a>
						</div>
					</div>
					<cfset i=i+1>
				</cfloop>
			</p>	
		</cfoutput>

</cfif>
<!------------------------------------------------------------------------------------------->
<cfif action is "removeTaxonomy">
	<cfoutput>
		<cfquery name="addtaxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from project_taxonomy where
			project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#"> and
			taxon_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#taxon_name_id#">
		</cfquery>
	<cflocation url="Project.cfm?Action=editProject&project_id=#project_id###taxonomy" addtoken="false">
	</cfoutput>
</cfif>				
<!------------------------------------------------------------------------------------------->
<cfif action is "addtaxon">
	<cfoutput>
		<cfquery name="addtaxon" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into project_taxonomy (
				 project_id,
				 taxon_name_id
			) values (
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newTaxId#">
			)
		</cfquery>
	<cflocation url="Project.cfm?Action=editProject&project_id=#project_id###taxonomy" addtoken="false">
	</cfoutput>
</cfif>				
<!------------------------------------------------------------------------------------------->
<cfif action is "addLoan">
	<cfoutput>
		<cfquery name="addloan" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			insert into project_trans (
				 project_id,
				 transaction_id
				 <cfif isDefined("project_loan_remarks") AND len(project_loan_remarks) GT 0>
					, project_trans_remarks
				</cfif>
			) values (
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
				<cfif isDefined("project_loan_remarks") AND len(project_loan_remarks) GT 0>
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#project_loan_remarks#">
				</cfif>
			)
		</cfquery>
	<cflocation url="Project.cfm?Action=editProject&project_id=#project_id###trans" addtoken="false">
	</cfoutput>
</cfif>				
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "deleteSponsor">
	<cfoutput>
		<cfquery name="deleteSponsor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from project_sponsor
			where PROJECT_SPONSOR_ID=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#PROJECT_SPONSOR_ID#">
		</cfquery>
	<cflocation url="Project.cfm?Action=editProject&project_id=#project_id###sponsor" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "saveSponsorChange">
	<cfoutput>
		<cfquery name="updateSponsor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			update project_sponsor
			set 
			agent_name_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_name_id#">,
			ACKNOWLEDGEMENT=<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ACKNOWLEDGEMENT#">
			where PROJECT_SPONSOR_ID=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#PROJECT_SPONSOR_ID#">
		</cfquery>
	<cflocation url="Project.cfm?action=editProject&project_id=#project_id###sponsor" addtoken="no">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "deleteProject">
 <cfoutput>
	<cftransaction>
	 	<cfquery name="isAgent"	 datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select agent_name_id FROM project_agent WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
		</cfquery>
		<cfif #isAgent.recordcount# gt 0>
			There are agents for this project! Delete denied!
			<cfabort>
		</cfif>
		<cfquery name="isTrans"	 datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select project_id FROM project_trans WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
		</cfquery>
		<cfif #isTrans.recordcount# gt 0>
			There are transactions for this project! Delete denied!
			<cfabort>
		</cfif>
		<cfquery name="isPub"	 datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select project_id FROM project_publication WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
		</cfquery>
		<cfif #isPub.recordcount# gt 0>
			There are publications for this project! Delete denied!
			<cfabort>
		</cfif>
		<cfquery name="killProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from project where project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
		</cfquery>
		<cftransaction action="commit">
	</cftransaction>
	
	You've deleted the project.
	<br>
	<a href="Project.cfm">continue</a>
 </cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "addSponsor">
	 <cfoutput>
	<cfquery name="addSponsor" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		insert into project_sponsor
			(PROJECT_ID,
			AGENT_NAME_ID,
			ACKNOWLEDGEMENT
		) values (
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">,
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_sponsor_id#">,
			<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newAcknowledgement#">
		)
	</cfquery>
 <cflocation url="Project.cfm?Action=editProject&project_id=#project_id###sponsor" addtoken="false">
 </cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "removeAgent">
 <cfoutput>
 	<cfquery name="deleAgnt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
 		DELETE FROM project_agent 
		where project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
			and agent_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_name_id#">
	</cfquery>
	 <cflocation url="Project.cfm?Action=editProject&project_id=#project_id###agent" addtoken="false">
 </cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "saveAgentChange">
 <cfoutput>
	<cfquery name="upProj" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		UPDATE project_agent 
		SET
			project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
		 	<cfif len(#new_name_id#) gt 0>
				,agent_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#new_name_id#">
			</cfif>
			<cfif len(#project_agent_role#) gt 0>
				,project_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#project_agent_role#">
			</cfif>
			<cfif len(#agent_position#) gt 0>
				,agent_position = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_position#">
			</cfif>
		WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
			AND agent_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_name_id#">
	</cfquery>
	<cflocation url="Project.cfm?Action=editProject&project_id=#project_id###agent" addtoken="false">
 </cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "newAgent">
	<cfoutput>
		<cfquery name="newProjAgnt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO project_agent (
		 		PROJECT_ID,
				AGENT_NAME_ID,
				PROJECT_AGENT_ROLE,
				AGENT_POSITION)
			VALUES (
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#PROJECT_ID#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newAgent_name_id#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newRole#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_position#">                 
			)                 
		</cfquery>
 		<cflocation url="Project.cfm?Action=editProject&project_id=#project_id###agent" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "saveEdits">
	<cfoutput>
		<cfquery name="upProject" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE project 
			SET 
				project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
				,project_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#project_name#">
			<cfif len(#start_date#) gt 0>
			 	,start_date = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(start_date,"yyyy-mm-dd")#">
			<cfelse>
				,start_date = null
			</cfif>
			<cfif len(#end_date#) gt 0>
			 	,end_date = <cfqueryparam cfsqltype="CF_SQL_TIMESTAMP" value="#dateformat(end_date,"yyyy-mm-dd")#">
			<cfelse>
			 	,end_date = null
			</cfif>
			<cfif len(#project_description#) gt 0>
			 	,project_description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#project_description#">
			<cfelse>
			 	,project_description = null
			</cfif>
			<cfif len(#project_remarks#) gt 0>
			 	,project_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#project_remarks#">
			<cfelse>
			 	,project_remarks = null
			</cfif>
			where project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
		</cfquery>
		<cflocation url="Project.cfm?Action=editProject&project_id=#project_id#" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "addTrans">
 <cfoutput>
	<cfquery name="newTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
 		INSERT INTO project_trans 
			(project_id, transaction_id) 
		values (
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">, 
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		)
  	</cfquery>
   <cflocation url="Project.cfm?Action=editProject&project_id=#project_id###trans" addtoken="false">
 </cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "addPub">
	<cfoutput>
		<cfquery name="newPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO project_publication 
				(project_id, 
				publication_id) 
			values (
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">, 
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
			)
		</cfquery>
  		<cflocation url="Project.cfm?Action=editProject&project_id=#project_id###pub" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "delePub">
 <cfoutput>
	<cfquery name="newPub" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM project_publication 
		WHERE project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#"> 
			and publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#">
	</cfquery>
	<cflocation url="Project.cfm?Action=editProject&project_id=#project_id###pub" addtoken="false">
 </cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
<cfif #Action# is "delTrans">
	<cfoutput>
		<cfquery name="delTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			DELETE FROM  project_trans 
			where project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
				and transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
		</cfquery>
		<cflocation url="Project.cfm?Action=editProject&project_id=#project_id###trans" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------->
	</div>
<cfinclude template="/includes/_footer.cfm">
