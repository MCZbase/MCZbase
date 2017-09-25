<cfset jquery11=true>
<cfinclude template="includes/_header.cfm">
<cfset MAGIC_MCZ_COLLECTION = 12><!--- the collection_id of the "MCZ Collection" (for non-specimen holdings) --->
<cfset MAGIC_MCZ_CRYO = 11><!--- the collection_id of the cryogenic collection --->
<cfset MAGIC_TTYPE_OTHER = 'other'><!--- Special Transaction type other, which can only be set by a sysadmin --->
<cfset MAGIC_DTYPE_TRANSFER = 'transfer'><!--- Deaccession type of Transfer --->
<cfif not isdefined("ImAGod") or len(#ImAGod#) is 0>
	<cfset ImAGod = "no">
</cfif>
<script type='text/javascript' src='/includes/internalAjax.js'></script>
<script type='text/javascript' src='/includes/transAjax.js'></script>
<cfif not isdefined("project_id")><cfset project_id = -1></cfif>
<cfquery name="queryNotApplicableAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct agent_id from agent_name where agent_name = 'not applicable' and rownum < 2
</cfquery>
<cfset NOTAPPLICABLEAGENTID = queryNotApplicableAgent.agent_id >
<cfquery name="ctDeaccType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select deacc_type from ctdeacc_type
</cfquery>
<cfquery name="ctDeaccStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select deacc_status from ctdeacc_status order by deacc_status desc
</cfquery>
<cfquery name="ctcoll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select collection_cde from ctcollection_cde order by collection_cde
</cfquery>
<!--- Obtain list of transaction agent roles, excluding those not relevant to deaccession editing --->
<cfquery name="cttrans_agent_role" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select distinct(trans_agent_role) from cttrans_agent_role  where trans_agent_role != 'entered by' and trans_agent_role != 'associated with agency' and trans_agent_role != 'received from' order by trans_agent_role
</cfquery>
<cfquery name="ctcollection" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select * from collection order by collection
</cfquery>

<cfoutput>
<script language="javascript" type="text/javascript">
	jQuery(document).ready(function() {
               $("##trans_date").datepicker({ dateFormat: 'yy-mm-dd'});
               $("##to_trans_date").datepicker({ dateFormat: 'yy-mm-dd'});
               $("##initiating_date").datepicker({ dateFormat: 'yy-mm-dd'});
               $("##shipped_date").datepicker({ dateFormat: 'yy-mm-dd'});
	});
	// Set the deaccession number and collection for a deaccession.
	function setDeaccNum(cid,deaccNum) {
           $("##deacc_number").val(deaccNum);
           $("##collection_id").val(cid);
           $("##collection_id").change();
	}
	function dCount() {
		var countThingees=new Array();
		countThingees.push('deacc_reason');
		countThingees.push('nature_of_material');
		for (i=0;i<countThingees.length;i++) {
			var els = countThingees[i];
			var el=document.getElementById(els);
			var elVal=el.value;
			var ds='lbl_'+els;
			var d=document.getElementById(ds);
			var lblVal=d.innerHTML;
			d.innerHTML=elVal.length + " characters";
		}
		var t=setTimeout("dCount()",500);
	}

    function addMediaHere (deaccessionLabel,transaction_id){
                var bgDiv = document.createElement('div');
                bgDiv.id = 'bgDiv';
                bgDiv.className = 'bgDiv';
                bgDiv.setAttribute('onclick','removeMediaDiv()');
                document.body.appendChild(bgDiv);
                var theDiv = document.createElement('div');
                theDiv.id = 'mediaDiv';
                theDiv.className = 'annotateBox';
                ctl='<span class="likeLink" style="position:absolute;right:0px;top:0px;padding:5px;color:red;" onclick="removeMediaDiv();">Close Frame</span>';
                theDiv.innerHTML=ctl;
                document.body.appendChild(theDiv);
                jQuery('##mediaDiv').append('<iframe id="mediaIframe" />');
                jQuery('##mediaIframe').attr('src', '/media.cfm?action=newMedia').attr('width','100%').attr('height','100%');
            jQuery('iframe##mediaIframe').load(function() {
                jQuery('##mediaIframe').contents().find('##relationship__1').val('shows deaccession');
                jQuery('##mediaIframe').contents().find('##related_value__1').val(deaccessionLabel);
                jQuery('##mediaIframe').contents().find('##related_id__1').val(transaction_id);
                viewport.init("##mediaDiv");
             });
     };
     function removeMediaDiv() {
		if(document.getElementById('bgDiv')){
			jQuery('##bgDiv').remove();
		}
		if (document.getElementById('mediaDiv')) {
			jQuery('##mediaDiv').remove();
		}
     };

</script>
</cfoutput>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "nothing">
	<cflocation url="Deaccession.cfm?action=search" addtoken="false">
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif  action is "newDeacc">
	<cfset title="New Deaccession">
	<cfoutput>
	<div class="newLoanWidth">
  
    	<h2 class="wikilink" style="margin-left: 0;">Initiate a Deaccession
	      <img src="/images/info_i_2.gif" onClick="getMCZDocs('Deaccession/Gift')" class="likeLink" alt="[ help ]">
        </h2>
  		<form name="newDeacc" id="newDeacc" action="Deaccession.cfm" method="post" onSubmit="return noenter();">
           		<input type="hidden" name="action" value="makeDeacc">
			<table border id="newDeaccTable">
				<tr>
					<td>
						<label for="collection_id">Collection
						</label>
						<select name="collection_id" size="1" id="collection_id">
							<cfloop query="ctcollection">
								<option value="#ctcollection.collection_id#">#ctcollection.collection#</option>
							</cfloop>
						</select>
					</td>
					<td id="upperRightCell"><!--- id for positioning nextnum div --->
						<label for="deacc_number">Deaccession Number</label>
						<input type="text" name="deacc_number" class="reqdClr" id="deacc_number">
					</td>
				</tr>
				<tr>
					<td>
						<label for="auth_agent_name">Authorized By</label>
						<input type="text" name="auth_agent_name" class="reqdClr" size="40"
						  onchange="getAgent('auth_agent_id','auth_agent_name','newDeacc',this.value); return false;"
						  onKeyPress="return noenter(event);">
						<input type="hidden" name="auth_agent_id" id="auth_agent_id" 
                            				onChange=" updateAgentLink($('##auth_agent_id').val(),'auth_agent_view');">
  				                <div id="auth_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</div>
					</td>
					<td>
						<label for="rec_agent_name">Received By:</label>
						<input type="text" name="rec_agent_name" id="rec_agent_name"
						  class="reqdClr" size="40" 
						  onchange="getAgent('rec_agent_id','rec_agent_name','newDeacc',this.value); return false;"
						  onKeyPress="return noenter(event);">
						<input type="hidden" name="rec_agent_id" id="rec_agent_id" 
                            				onChange=" updateAgentLink($('##rec_agent_id').val(),'rec_agent_view');">
  				                <div id="rec_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</div>
					</td>
				</tr>
				<tr>
					<td>
						<label for="in_house_contact_agent_name">In-House Contact:</label>
						<input type="text" name="in_house_contact_agent_name" class="reqdClr" size="40"
						  onchange="getAgent('in_house_contact_agent_id','in_house_contact_agent_name','newDeacc',this.value); return false;"
						  onKeyPress="return noenter(event);">
						<input type="hidden" name="in_house_contact_agent_id" id="in_house_contact_agent_id" 
                            				onChange=" updateAgentLink($('##in_house_contact_agent_id').val(),'in_house_contact_agent_view');">
  				                <div id="in_house_contact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</div>
					</td>
					<td>
						<label for="additional_contact_agent_name">Additional Outside Contact:</label>
						<input type="text" name="additional_contact_agent_name" size="40"
						  onchange="getAgent('additional_contact_agent_id','additional_contact_agent_name','newDeacc',this.value); return false;"
						  onKeyPress="return noenter(event);">
						<input type="hidden" name="additional_contact_agent_id" id="additional_contact_agent_id" 
                            				onChange=" updateAgentLink($('##additional_contact_agent_id').val(),'additional_contact_agent_view');">
  				                <div id="additional_contact_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</div>
					</td>
				</tr>
				<tr>
					<td>
						<label for="recipient_institution_agent_name">Recipient Institution:</label>
						<input type="text" name="recipient_institution_agent_name" id="recipient_institution_agent_name"
						  class="reqdClr" size="40" 
						  onchange="getAgent('recipient_institution_agent_id','recipient_institution_agent_name','newDeacc',this.value); return false;"
						  onKeyPress="return noenter(event);">
						<input type="hidden" name="recipient_institution_agent_id" id="recipient_institution_agent_id" 
                            				onChange=" updateAgentLink($('##recipient_institution_agent_id').val(),'recipient_institution_agent_view');">
  				                <div id="recipient_institution_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</div>
					</td>
					<td>
						<label for="foruseby_agent_name">For Use By:</label>
						<input type="text" name="foruseby_agent_name" size="40"
						  onchange="getAgent('foruseby_agent_id','foruseby_agent_name','newDeacc',this.value); return false;"
						  onKeyPress="return noenter(event);">
						<input type="hidden" name="foruseby_agent_id" id="foruseby_agent_id" 
                            				onChange=" updateAgentLink($('##foruseby_agent_id').val(),'foruseby_agent_view');">
  				                <div id="foruseby_agent_view">&nbsp;&nbsp;&nbsp;&nbsp;</div>
					</td>
				</tr>
				<tr>
					<td>
						<label for="deacc_type">Deaccession Type</label>
						
						<select name="deacc_type" id="deacc_type" class="reqdClr">
							<cfloop query="ctDeaccType">
								<option value="#ctDeaccType.deacc_type#">#ctDeaccType.deacc_type#</option>
							</cfloop>
						</select>

					</td>
					<td>
						<label for="deacc_status">Deaccession Status</label>
						<select name="deacc_status" id="deacc_status" class="reqdClr">
							<cfloop query="ctDeaccStatus">
								<option value="#ctDeaccStatus.deacc_status#">#ctDeaccStatus.deacc_status#</option>
							</cfloop>
						</select>
					</td>
				</tr>
				<tr>
					<td>
						<label for="initiating_date">Transaction Date</label>
						<input type="text" name="initiating_date" id="initiating_date" value="#dateformat(now(),"yyyy-mm-dd")#">
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="nature_of_material">Nature of Material</label>
					<textarea name="nature_of_material" id="nature_of_material" rows="3" cols="80" class="reqdClr"></textarea>
					</td>
				</tr>
                <tr>
					<td colspan="2">
						<label for="deacc_reason">Reason for Deaccession</label>
					<textarea name="deacc_reason" id="deacc_reason" rows="3" cols="80" class="reqdClr"></textarea>
					</td>
				</tr>
                	<tr>
					<td colspan="2">
						<label for="value">Value of Specimen(s)</label>
						<textarea name="value" id="value" rows="3" cols="80"></textarea>
					</td>
				</tr>
                 <tr>
					<td colspan="2">
						<label for="method">Method of Transfer</label>
						<textarea name="method" id="method" rows="3" cols="80"></textarea>
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="trans_remarks">Internal Remarks</label>
						<textarea name="trans_remarks" id="trans_remarks" rows="3" cols="80"></textarea>
					</td>
				</tr>
				
				<tr>
					<td colspan="2" align="center">
						<input type="submit" value="Create Deaccession" class="insBtn">
						&nbsp;
						<input type="button" value="Quit" class="qutBtn" onClick="document.location = 'Deaccession.cfm'">
			   		</td>
				</tr>
			</table>
		</form>
               
		<div class="nextnum" id="nextNumDiv">
			<p>Next Available Deaccession Number:</p>
			<cfquery name="all_coll" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select * from collection order by collection
			</cfquery>
			<cfloop query="all_coll">
				<cfif (institution_acronym is 'MCZ')>
					<!---- yyyy-n-CCDE format --->
					<cfset stg="'#dateformat(now(),"yyyy")#-' || max(to_number(substr(deacc_number,instr(deacc_number,'-')+1,instr(deacc_number,'-',1,2)-instr(deacc_number,'-')-1) + 1)) || '-#collection_cde#'">
					<cfset whr=" AND substr(deacc_number, 1,4) ='#dateformat(now(),"yyyy")#'">
				<cfelse>
					<!--- n format --->
					<cfset stg="'#dateformat(now(),"yyyy")#.' || max(to_number(substr(deacc_number,instr(deacc_number,'.')+1,instr(deacc_number,'.',1,2)-instr(deacc_number,'.')-1) + 1)) || '.#collection_cde#'">
					<cfset whr=" AND is_number(deacc_number)=1 and substr(deacc_number, 1,4) ='#dateformat(now(),"yyyy")#'">
				</cfif>
				<cftry>
					<cfquery name="thisq" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select
							 #preservesinglequotes(stg)# nn
						from
							deaccession,
							trans,
							collection
						where
							deaccession.transaction_id=trans.transaction_id and
							trans.collection_id=collection.collection_id
							<cfif institution_acronym is "MCZ">
								and	collection.collection_id=#collection_id#
							</cfif>
							#preservesinglequotes(whr)#
					</cfquery>
					<cfcatch>
						<hr>
						#cfcatch.detail#
						<br>
						#cfcatch.message#
						<cfquery name="thisq" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select
								 'check data' nn
							from
								dual
						</cfquery>
					</cfcatch>
				</cftry>
				<cfif len(thisQ.nn) gt 0>
					<span class="likeLink" onclick="setDeaccNum('#collection_id#','#thisQ.nn#')">#collection# #thisQ.nn#</span>
				<cfelse>
					<span style="font-size:x-small">
						No data available for #collection#.
					</span>
				</cfif>
				<br>
			</cfloop>
		</div>
                <script>
                        $(document).ready( function() { $('##nextNumDiv').position( { my: "left top", at: "right+3 top-3", of: $('##upperRightCell'), colision: "none" } ); } );
                </script>
                <script>
			$('##deacc_type').val('discarded').prop('selected', true);
                        $("##rec_agent_name").val('not applicable');
                        $("##rec_agent_id").val('#NOTAPPLICABLEAGENTID#');
                        $("##rec_agent_id").trigger('change');
                        $("##recipient_institution_agent_name").val('not applicable');
                        $("##recipient_institution_agent_id").val('#NOTAPPLICABLEAGENTID#');
                        $("##recipient_institution_agent_id").trigger('change');
			// transfer is not allowed as a type for a new accesison by default (but see below).
                        $("##deacc_type option[value='transfer']").each(function() { $(this).remove(); } );
			<cfif ImAGod is not "yes">
			  // other (MAGIC_TTYPE_OTHER) is not allowed as a type for a new deaccesison (must be set by sysadmin).
                          $("##deacc_type option[value='#MAGIC_TTYPE_OTHER#']").each(function() { $(this).remove(); } );
			</cfif>
                        // on page load, bind a function to collection_id to change the list of deaccession
                        // based on the selected collection
                        $("##collection_id").change( function () {
                              if ( $("##collection_id option:selected").text() == "MCZ Collections" ) {
                                     // only MCZ collections (the non-specimen collection) is allowed to make transfers.
                                     $("##deacc_type").append($("<option></option>").attr("value",'transfer').text('transfer'));
                              } else {
                                     $("##deacc_type option[value='transfer']").each(function() { $(this).remove(); } );
                              }
                        });
                        $("##deacc_type").change( function () {
                              if ( $("##deacc_type option:selected").text() == "discarded" ) {
                                     $("##rec_agent_name").val('not applicable');
                                     $("##rec_agent_id").val('#NOTAPPLICABLEAGENTID#');
                                     $("##rec_agent_id").trigger('change');

                                     $("##recipient_institution_agent_name").val('not applicable');
                                     $("##recipient_institution_agent_id").val('#NOTAPPLICABLEAGENTID#');
                                     $("##recipient_institution_agent_id").trigger('change');
			      } else { 
                                     if ($("##rec_agent_id").val()=='#NOTAPPLICABLEAGENTID#') { 
                                     	  $("##rec_agent_name").val('');
        	                          $("##rec_agent_id").val('');
 	                                  $("##rec_agent_id").trigger('change');
				     }
                                     if ($("##recipient_institution_agent_id").val()=='#NOTAPPLICABLEAGENTID#') { 
                                     	  $("##recipient_institution_agent_name").val('');
        	                          $("##recipient_institution_agent_id").val('');
 	                                  $("##recipient_institution_agent_id").trigger('change');
				     }
                              }
                        });
                </script>
       </div>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "editDeacc">
	<cfset title="Edit Deaccession">
	<cfoutput>
	<cfquery name="deaccDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select
            trans.transaction_id,
			trans.trans_date,
			deaccession.deacc_number,
			deaccession.deacc_type,
			deaccession.deacc_status,
            deaccession.value,
            deaccession.method,
			deaccession.deacc_reason,
			trans.nature_of_material,
			trans.trans_remarks,
			to_char(closed_date, 'YYYY-MM-DD') closed_date,
			trans.collection_id,
			collection.collection,
			concattransagent(trans.transaction_id,'entered by') enteredby 
		 from
			deaccession,
			trans,
			collection
		where
			deaccession.transaction_id = trans.transaction_id AND
			trans.collection_id=collection.collection_id and
			trans.transaction_id = <cfqueryparam value="#transaction_id#" CFSQLType="CF_SQL_DECIMAL">
	</cfquery>
	<cfquery name="deaccAgents" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select
			trans_agent_id,
			trans_agent.agent_id,
			agent_name,
			trans_agent_role,
                        MCZBASE.get_worstagentrank(trans_agent.agent_id) worstagentrank
		from
			trans_agent,
			preferred_agent_name
		where
			trans_agent.agent_id = preferred_agent_name.agent_id and
			trans_agent_role != 'entered by' and
			trans_agent.transaction_id=<cfqueryparam value="#transaction_id#" CFSQLType="CF_SQL_DECIMAL">
		order by
			trans_agent_role,
			agent_name
	</cfquery>
 	<!--- on page load, remove tranfer as an allowed deaccession type, except for the MCZ Collection --->
        <cfif deaccDetails.deacc_type neq 'transfer' and deaccDetails.collection_id NEQ MAGIC_MCZ_COLLECTION >
	<script>
		$(function() {
                      $("##deacc_type option[value='transfer']").each(function() { $(this).remove(); } );
                });
        </script>
        </cfif>
       <div class="editLoanbox">
       <h2 class="wikilink" style="margin-left: 0;">Edit Deaccession <img src="/images/info_i_2.gif" onClick="getMCZDocs('Deaccession/Gift')" class="likeLink" alt="[ help ]">
        <span class="loanNum">#deaccDetails.collection# #deaccDetails.deacc_number# </span>	</h2>
	<table class="editLoanTable">
    <tr>
    <td valign="top" class="leftCell"><!--- left cell ---->

  <form name="editDeacc" action="Deaccession.cfm" method="post">
		<input type="hidden" name="action" value="saveEdits">
		<input type="hidden" name="transaction_id" value="#deaccDetails.transaction_id#">
		<span style="font-size:14px;">Entered by #deaccDetails.enteredby#</span>
    <table class="IDloan">
    <tr>
    <td>
      <label>Department</label>
		<select name="collection_id" id="collection_id" size="1">
			<cfloop query="ctcollection">
				<option <cfif ctcollection.collection_id is deaccDetails.collection_id> selected </cfif>
					value="#ctcollection.collection_id#">#ctcollection.collection#</option>
			</cfloop>
		</select>
       </td>
        <script>
               // on page load, bind a function to collection_id to change the list of deaccession
               // based on the selected collection
               $("##collection_id").change( function () {
                    if ( $("##collection_id option:selected").text() == "MCZ Collections" ) {
                        // only MCZ collections (the non-specimen collection) is allowed to make transfers.
                        $("##deacc_type").append($("<option></option>").attr("value",'transfer').text('transfer'));
                    } else {
                        $("##deacc_type option[value='transfer']").each(function() { $(this).remove(); } );
                    }
               });
        </script>
       <td>
          <label for="deacc_number">Deaccession Number</label>
		<input type="text" name="deacc_number" id="deacc_number" value="#deaccDetails.deacc_number#" class="reqdClr">
        </td>
        </tr>
        </table>
		<cfquery name="inhouse" dbtype="query">
			select count(distinct(agent_id)) c from deaccAgents where trans_agent_role='in-house contact'
		</cfquery>
		<cfquery name="outside" dbtype="query">
			select count(distinct(agent_id)) c from deaccAgents where trans_agent_role='received by'
		</cfquery>
		<cfquery name="authorized" dbtype="query">
			select count(distinct(agent_id)) c from deaccAgents where trans_agent_role='authorized by'
		</cfquery>
		<cfquery name="recipientinstitution" dbtype="query">
			select count(distinct(agent_id)) c from deaccAgents where trans_agent_role='recipient institution'
		</cfquery>
		<table id="loanAgents"> <!--- id of loanAgents is used by addTransAgent() to find table to add rows to --->
			<tr style="height: 20px;">
				<th>Agent Name <span class="linkButton" onclick="addTransAgentToForm('','','','editDeacc')" style="cursor:pointer;">Add Row</span></th>
				<th></th>
				<th>Role</th>
				<th>Delete?</th>
				<th>CloneAs</th>
				<td rowspan="99">
					<cfif inhouse.c is 1 and authorized.c GT 0 >
						<span style="color:green;font-size:small">OK to print</span>
					<cfelse>
						<span style="color:red;font-size:small">
							One "authorized by" and one "in-house contact" are required to print Deaccessions. 
						</span>
					</cfif>
				</td>
			</tr>
        
			<cfset i=1>
			<cfloop query="deaccAgents">
				<tr>
					<td>
						<input type="hidden" name="trans_agent_id_#i#" id="trans_agent_id_#i#" value="#trans_agent_id#">
						<input type="text" name="trans_agent_#i#" id="trans_agent_#i#" class="reqdClr" size="30" value="#agent_name#"
		  					onchange="getAgent('agent_id_#i#','trans_agent_#i#','editDeacc',this.value); return false;"
		  					onKeyPress="return noenter(event);">
		  				<input type="hidden" name="agent_id_#i#" id="agent_id_#i#" value="#agent_id#" 
							onchange=" updateAgentLink($('##agent_id_#i#').val(),'agentViewLink_#i#'); " >
					</td>
					<td style=" min-width: 3.5em; ">
						<span id="agentViewLink_#i#"><a href="/agents.cfm?agent_id=#agent_id#" target="_blank">View</a><cfif deaccAgents.worstagentrank EQ 'A'> &nbsp;<cfelseif deaccAgents.worstagentrank EQ 'F'><img src='/images/flag-red.svg.png' width='16'><cfelse><img src='/images/flag-yellow.svg.png' width='16'></cfif>
                                            	</span>
					</td>
					<td>
						<select name="trans_agent_role_#i#" id="trans_agent_role_#i#">
							<cfloop query="cttrans_agent_role">
								<option
									<cfif cttrans_agent_role.trans_agent_role is deaccAgents.trans_agent_role>
										selected="selected"
									</cfif>
									value="#trans_agent_role#">#trans_agent_role#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<input type="checkbox" name="del_agnt_#i#" id="del_agnt_#i#" value="1">
					</td>
					<td>
						<select id="cloneTransAgent_#i#" onchange="cloneTransAgent(#i#)" style="width:8em">
							<option value=""></option>
							<cfloop query="cttrans_agent_role">
								<option value="#trans_agent_role#">#trans_agent_role#</option>
							</cfloop>
						</select>
					</td>
				</tr>
				<cfset i=i+1>
			</cfloop>
			<cfset na=i-1>
			<input type="hidden" id="numAgents" name="numAgents" value="#na#">
		</table><!-- end agents table --->
		<table width="100%">
			<tr>
				<td width="20%">
					<label for="deacc_type">Deaccession Type</label>
					<cfif deaccDetails.deacc_type EQ "#MAGIC_TTYPE_OTHER#">
					   <!--- deacc_type other (MAGIC_TTYPE_OTHER) is read only --->
					   <input type="hidden" name="deacc_type" id="deacc_type" value="#MAGIC_TTYPE_OTHER#">
					   <select name="deacc_type" id="deacc_type" class="reqdClr" disabled="true">
						<option selected="selected" value="#MAGIC_TTYPE_OTHER#">#MAGIC_TTYPE_OTHER#</option>
					   </select>
					<cfelse>
					   <select name="deacc_type" id="deacc_type" class="reqdClr">
                                                <cfloop query="ctDeaccType">
						      <!--- Other is not an allowed option (unless it is already set) ---> 
                                                      <cfif ctDeaccType.deacc_type NEQ MAGIC_TTYPE_OTHER >
						      <!--- Only the MCZ Collection is allowed to make transfers ---> 
                                                      <cfif ctDeaccType.deacc_type NEQ "transfer" OR deaccDetails.collection_id EQ MAGIC_MCZ_COLLECTION >
                                                          <option <cfif ctDeaccType.deacc_type is deaccDetails.deacc_type> selected="selected" </cfif>
                                                                  value="#ctDeaccType.deacc_type#">#ctDeaccType.deacc_type#</option>
                                                      <cfelseif deaccDetails.deacc_type EQ "transfer" AND deaccDetails.collection_id NEQ MAGIC_MCZ_COLLECTION >
                                                          <option <cfif ctDeaccType.deacc_type is deaccDetails.deacc_type> selected="selected" </cfif> value=""></option>
                                                      </cfif>
                                                      </cfif>
                                                </cfloop>
					   </select>
					</cfif>
				</td>
				<td>
					<label for="deacc_status">Deaccession Status</label>
					<select name="deacc_status" id="deacc_status" class="reqdClr">
						<cfloop query="ctDeaccStatus">                      
						<option <cfif ctDeaccStatus.deacc_status EQ deaccDetails.deacc_status>selected="selected"</cfif> value="#ctDeaccStatus.deacc_status#">#ctDeaccStatus.deacc_status#</option>
						</cfloop>
					</select>
				</td>
			</tr>
			<tr>
				<td>
					<label for="initiating_date">Transaction Date</label>
					<input type="text" name="initiating_date" id="initiating_date"
						value="#dateformat(deaccDetails.trans_date,"yyyy-mm-dd")#" class="reqdClr">
				</td>
			</tr>
		</table>
		<label for="nature_of_material">Nature of Material&nbsp;(<span id="lbl_nature_of_material"></span>)</label>
		<textarea name="nature_of_material" id="nature_of_material" rows="7" cols="120"
			class="reqdClr">#deaccDetails.nature_of_material#</textarea>
         <label for="deacc_reason">Reason for Deaccession (description)&nbsp;(<span id="lbl_deacc_reason"></span>)</label>
		<textarea name="deacc_reason" class="reqdClr" id="deacc_reason" rows="7"
			cols="120">#deaccDetails.deacc_reason#</textarea>
	    <label for="value">Value of Specimen(s)</label>
        <input name="value" id="value" value="#deaccDetails.value#" size="55">
		
        <label for="method">Method of Transfer</label>
		<textarea name="method" id="method" value="#deaccDetails.method#" rows="3" cols="120">#deaccDetails.method#</textarea>
    
		<label for="trans_remarks">Internal Remarks</label>
		<textarea name="trans_remarks" id="trans_remarks" rows="7" cols="120">#deaccDetails.trans_remarks#</textarea>
		<br>
		<input type="button" value="Save Edits" class="savBtn"
			onClick="editDeacc.action.value='saveEdits';submit();">

   		<input type="button" style="margin-left: 30px;" value="Quit" class="qutBtn" onClick="document.location = 'Deaccession.cfm?action=search'">
		<input type="button" value="Add Items" class="lnkBtn"
			onClick="window.open('SpecimenSearch.cfm?action=dispCollObjDeacc&transaction_id=#transaction_id#');">
		<input type="button" value="Add Items BY Barcode" class="lnkBtn"
			onClick="window.open('deaccByBarcode.cfm?transaction_id=#transaction_id#');">

			<input type="button" value="Review Items" class="lnkBtn"
			onClick="window.open('a_deaccItemReview.cfm?transaction_id=#transaction_id#');">
                            <input style="margin-left: 30px;" type="button" value="Delete Deaccession" class="delBtn"
			onClick="editDeacc.action.value='deleDeacc';confirmDelete('editDeacc');">
   		<br />
                <div id="deaccItemCountDiv"></div>
		<script>
			$(document).ready( updateDeaccItemCount('#transaction_id#','deaccItemCountDiv') );
 		</script>
   		<label for="redir">Print...</label>
		<select name="redir" id="redir" size="1" onchange="if(this.value.length>0){window.open(this.value,'_blank')};">
   			<option value=""></option>
			
   <cfif #cgi.HTTP_HOST# contains "harvard.edu">
          <!--- report_printer.cfm takes parameters transaction_id, report, and sort, where
                sort={a field name that is in the select portion of the query specified in the custom tag}, or
                sort={cat_num_pre_int}, which is interpreted as order by cat_num_prefix, cat_num_integer.
          --->
                
          <cfif inhouse.c is 1 and authorized.c GT 0 >
              <option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_deaccession_header">MCZ Deaccession Header</option>
          </cfif>
          <cfif inhouse.c is 1 and authorized.c GT 0 >
               <option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_deaccession_items">MCZ Deaccession Items</option>
          </cfif>
          <cfif inhouse.c is 1 and authorized.c GT 0 >
               <!--- only show Object header if deaccession is of type other or transfer --->
	       <cfif deaccDetails.deacc_type EQ "#MAGIC_TTYPE_OTHER#" OR deaccDetails.deacc_type EQ "#MAGIC_DTYPE_TRANSFER#" >
               <option value="/Reports/report_printer.cfm?transaction_id=#transaction_id#&report=mcz_loan_object_header_short">MCZ Object Deaccession Header</option>
               </cfif>
            </cfif>
            <option value="/edecView.cfm?transaction_id=#transaction_id#">USFWS eDec</option>
   <cfelse>
       <option value="">Host not recognized.</option>
   </cfif>

		</select>
        </form>
	</td><!---- end left cell --->
    </tr>
    </table>
    </div>
 
<div>
     <strong>Media (e.g. copies of correspondence) associated with this Deaccession:</strong>
      <div id="deaccessionMedia"></div>

</div>
<script>
    function loadDeaccessionMedia(transaction_id) {
        jQuery.get("/component/functions.cfc",
        {
            method : "getDeaccMediaHtml",
            transaction_id : transaction_id
        },
        function (result) {
           $("##deaccessionMedia").html(result);
        }
        );
    };

    // callback for ajax methods to reload from dialog
    function reloadDeaccessionMedia() { 
        loadDeaccessionMedia(#transaction_id#);
        $('##addDeaccDlg_#transaction_id#').html('').dialog('destroy');
    };

    jQuery(document).ready(loadDeaccessionMedia(#transaction_id#));

</script>

<div class="shippingBlock">
    <h3>Shipment Information:</h3>
<script>

function opendialog(page,id,title) {
  var content = '<iframe style="border: 0px; " src="' + page + '" width="100%" height="100%"></iframe>'
  var adialog = $(id)
  .html(content)
  .dialog({
    title: title,
    autoOpen: false,
    dialogClass: 'dialog_fixed,ui-widget-header',
    modal: true,
    height: 800,
    width: 950,
    minWidth: 400,
    minHeight: 450,
    draggable:true,
    resizable:true,
    buttons: { "Ok": function () { loadShipments(#transaction_id#); $(this).dialog("destroy"); $(id).html(''); } },
    close: function() { loadShipments(#transaction_id#);  $(this).dialog("destroy"); $(id).html('');  }
  });
  adialog.dialog('open');
};

</script>

	<cfquery name="ctShip" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select shipped_carrier_method from ctshipped_carrier_method order by shipped_carrier_method
	</cfquery>
	<cfquery name="ship" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
                 select sh.*, toaddr.country_cde tocountry, toaddr.institution toinst, fromaddr.country_cde fromcountry, fromaddr.institution frominst
                 from shipment sh
                    left join addr toaddr on sh.shipped_to_addr_id  = toaddr.addr_id
                    left join addr fromaddr on sh.shipped_from_addr_id = fromaddr.addr_id
		where transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#deaccDetails.transaction_id#">
	</cfquery>
    <div id="shipmentTable">Loading shipments...</div> <!--- shippmentTable for ajax replace --->

<script>

$( document ).ready(loadShipments(#transaction_id#));

    $(function() {
      $("##dialog-shipment").dialog({
        autoOpen: false,
        modal: true,
        width: 650,
        buttons: {
          "Save": function() {  saveShipment(#transaction_id#); } ,
          Cancel: function() {
            $(this).dialog( "close" );
          }
        },
        close: function() {
            $(this).dialog( "close" );
        }
      });
    });
</script>

    <div class="addstyle">
    <input type="button" class="lnkBtn" style="margin-left: 3em;" value="Add Shipment" onClick="$('##dialog-shipment').dialog('open'); setupNewShipment(#transaction_id#);"><div class="shipmentnote">Note: please check the <a href="https://code.mcz.harvard.edu/wiki/index.php/Country_Alerts">Country Alerts</a> page for special instructions or restrictions associated with specific countries</div>
    </div><!--- end addstyle --->

</div>  <!--- end Shipping block --->

<div id="dialog-shipment" title="Create new Shipment">
  <form name="shipmentForm" id="shipmentForm" >
    <fieldset>
	<input type="hidden" name="transaction_id" value="#transaction_id#" id="shipmentForm_transaction_id" >
	<input type="hidden" name="shipment_id" value="" id="shipment_id">
	<input type="hidden" name="returnFormat" value="json" id="returnFormat">
           <table>
             <tr>
              <td>
		<label for="shipped_carrier_method">Shipping Method</label>
		<select name="shipped_carrier_method" id="shipped_carrier_method" size="1" class="reqdClr">
			<option value=""></option>
			<cfloop query="ctShip">
				<option value="#ctShip.shipped_carrier_method#">#ctShip.shipped_carrier_method#</option>
			</cfloop>
		</select>
              </td>
              <td colspan="2">
		<label for="carriers_tracking_number">Tracking Number</label>
		<input type="text" value="" name="carriers_tracking_number" id="carriers_tracking_number" size="30" >
              </td>
            </tr><tr>
              <td>
		<label for="no_of_packages">Number of Packages</label>
		<input type="text" value="1" name="no_of_packages" id="no_of_packages">
              </td>
              <td>
		<label for="shipped_date">Ship Date</label>
		<input type="text" value="#dateformat(Now(),'yyyy-mm-dd')#" name="shipped_date" id="shipped_date">
              </td>
              <td>
		<label for="foreign_shipment_fg">Foreign shipment?</label>
		<select name="foreign_shipment_fg" id="foreign_shipment_fg" size="1">
			<option selected value="0">no</option>
			<option value="1">yes</option>
		</select>
              </td>
            </tr><tr>
              <td>
		<label for="package_weight">Package Weight (TEXT, include units)</label>
		<input type="text" value="" name="package_weight" id="package_weight">
              </td>
              <td>
		<label for="insured_for_insured_value">Insured Value (NUMBER, US$)</label>
		<input type="text" validate="float" label="Numeric value required."
			 value="" name="insured_for_insured_value" id="insured_for_insured_value">
              </td>
              <td>
		<label for="hazmat_fg">HAZMAT?</label>
		<select name="hazmat_fg" id="hazmat_fg" size="1">
			<option selected value="0">no</option>
			<option value="1">yes</option>
		</select>
              </td>
            </tr>
           </table>

		<label for="packed_by_agent">Packed By Agent</label>
		<input type="text" name="packed_by_agent" class="reqdClr" size="50" value="" id="packed_by_agent"
			  onchange="getAgent('packed_by_agent_id','packed_by_agent','shipmentForm',this.value); return false;"
			  onKeyPress="return noenter(event);">
		<input type="hidden" name="packed_by_agent_id" value="" id="packed_by_agent_id" >

		<label for="shipped_to_addr">Shipped To Address</label>
		<input type="button" value="Pick Address" class="picBtn"
			onClick="addrPick('shipped_to_addr_id','shipped_to_addr','shipmentForm'); return false;">
		<textarea name="shipped_to_addr" id="shipped_to_addr" cols="60" rows="5"
			readonly="yes" class="reqdClr"></textarea>
		<input type="hidden" name="shipped_to_addr_id" id="shipped_to_addr_id" value="">

		<label for="shipped_from_addr">Shipped From Address</label>
		<input type="button" value="Pick Address" class="picBtn"
			onClick="addrPick('shipped_from_addr_id','shipped_from_addr','shipmentForm'); return false;">
		<textarea name="shipped_from_addr" id="shipped_from_addr" cols="60" rows="5"
			readonly="yes" class="reqdClr"></textarea>
		<input type="hidden" name="shipped_from_addr_id" id="shipped_from_addr_id" value="">

		<label for="shipment_remarks">Remarks</label>
		<input type="text" value="" name="shipment_remarks" id="shipment_remarks" size="60">
		<label for="contents">Contents</label>
		<input type="text" value="" name="contents" id="contents" size="60">

    </fieldset>
  </form>
  <div id="shipmentFormPermits"></div>
  <div id="shipmentFormStatus"></div>
</div>
<div id="accsection">
	<h3>Accessions (and their permits) for material in this deaccession:</h3>
        <!--- List Accessions for collection objects included in the Deaccession --->
	<cfquery name="getAccessions" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct accn.accn_type, accn.received_date, accn.accn_number, accn.transaction_id from 
		   deaccession l 
		   left join deacc_item li on l.transaction_id = li.transaction_id
		   left join specimen_part sp on li.collection_object_id = sp.collection_object_id
		   left join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
		   left join accn on ci.accn_id = accn.transaction_id
		   where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#deaccDetails.transaction_id#">
        </cfquery>
        <ul class="accn">
	<cfloop query="getAccessions">
            <li class="accn2"><a  style="font-weight:bold;" href="editAccn.cfm?Action=edit&transaction_id=#transaction_id#"><span>Accession ##</span> #accn_number#</a>, <span>Type:</span> #accn_type#, <span>Received: </span>#dateformat(received_date,'yyyy-mm-dd')# 
	    <cfquery name="getAccnPermits" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select distinct permit_num, permit_type, issued_date, permit.permit_id,
                    issuedBy.agent_name as IssuedByAgent
		from permit_trans left join permit on permit_trans.permit_id = permit.permit_id
                     left join preferred_agent_name issuedBy on permit.issued_by_agent_id = issuedBy.agent_id
		where permit_trans.transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value=#transaction_id#>
                order by permit_type, issued_date
            </cfquery>
             <cfif getAccnPermits.recordcount gt 0>
	      <ul class="accnpermit">
              <cfloop query="getAccnPermits">
                 <li><span style="font-weight:bold;">Permit:</span> #permit_type# #permit_num#, <span>Issued:</span> #dateformat(issued_date,'yyyy-mm-dd')# <span>by</span> #IssuedByAgent# <a href="Permit.cfm?Action=editPermit&permit_id=#permit_id#" target="_blank">Edit</a></li>
                 
              </cfloop>
              </ul>
             
	    </cfif>
        </li>
	</cfloop>
        </ul>
</div>
    <!--- TODO: Print permits associated with these accessions --->
	  <div id="permitmedia">
      <h3>Permit Media (PDF copies of Permits)</h3>
	<cfquery name="getPermitMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="getPermitMediaRes">
        select distinct media_id, uri, permit_type, permit_num from (
		select media.media_id, media.media_uri as uri, p.permit_type, p.permit_num
           from deacc_item li
		   left join specimen_part sp on li.collection_object_id = sp.collection_object_id
		   left join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
		   left join accn on ci.accn_id = accn.transaction_id
           left join permit_trans on accn.transaction_id = permit_trans.transaction_id
           left join permit p on permit_trans.permit_id = p.permit_id
           left join media_relations on p.permit_id = media_relations.related_primary_key 
           left join media on media_relations.media_id = media.media_id
		where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#deaccDetails.transaction_id#">
                and (media_relations.related_primary_key is null 
                or (media_relations.media_relationship = 'shows permit'
                    and mime_type = 'application/pdf'))
        union
		select media.media_id, media.media_uri as uri, p.permit_type, p.permit_num
           from shipment s
           left join permit_shipment ps on s.shipment_id = ps.shipment_id
           left join permit p on ps.permit_id = p.permit_id
           left join media_relations on p.permit_id = media_relations.related_primary_key 
           left join media on media_relations.media_id = media.media_id
		where s.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#deaccDetails.transaction_id#"> 
                and (media_relations.related_primary_key is null 
                or (media_relations.media_relationship = 'shows permit'
                    and mime_type = 'application/pdf'))
        ) where permit_type is not null
    </cfquery>
  
    <ul>
  	<cfloop query="getPermitMedia">
        <cfif media_id is ''> 
           <li>#permit_type# #permit_num# (no pdf)</li>
        <cfelse>
           <li><a href="#uri#">#permit_type# #permit_num#</a></li>
        </cfif>
    </cfloop>
    <cfif getPermitMediaRes.recordcount EQ 0> 
         <p>No Permits Found</p>
    </cfif>
    </ul>
    </div>


</cfoutput>
<script>
	dCount();
</script>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "deleDeacc">
	<cftry>
	<cftransaction>
		<cfquery name="killDeacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from deaccession where transaction_id=#transaction_id#
		</cfquery>
	<cfquery name="killTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from trans_agent where transaction_id=#transaction_id#
		</cfquery>
		<cfquery name="killTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from trans where transaction_id=#transaction_id#
		</cfquery>
	</cftransaction>
	Deaccession deleted.....
	<cfcatch>
		DELETE FAILED
		<p>You cannot delete an active loan. This deaccession probably has specimens or
		other transactions attached. Use your back button.</p>
		<p>
			<cfdump var=#cfcatch#>
		</p>
	</cfcatch>
	</cftry>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "saveEdits">
	<cfoutput>
	<cftry>
		<cftransaction>
			<cfquery name="upTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE  trans  SET
					collection_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">,
					TRANS_DATE = '#dateformat(initiating_date,"yyyy-mm-dd")#',
					nature_of_material = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nature_of_material#">,
					trans_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_remarks#">
				where
					transaction_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">
			</cfquery>
			<cfquery name="upDeacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="upDeacRes">
				 UPDATE DEACCESSION SET
					DEACC_TYPE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deacc_type#">,
					DEACC_NUMBER = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deacc_number#">,
					DEACC_STATUS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deacc_status#">,
					DEACC_REASON = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deacc_reason#">,
					VALUE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#value#">,
					METHOD = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#method#">
					where TRANSACTION_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#TRANSACTION_ID#">
			</cfquery>
		        <cfloop from="1" to="#numAgents#" index="n">
				   <cfif IsDefined("trans_agent_id_" & n) >
					<cfset trans_agent_id_ = evaluate("trans_agent_id_" & n)>
					<cfset agent_id_ = evaluate("agent_id_" & n)>
					<cfset trans_agent_role_ = evaluate("trans_agent_role_" & n)>
					<cftry>
						<cfset del_agnt_=evaluate("del_agnt_" & n)>
					<cfcatch>
						<cfset del_agnt_=0>
					</cfcatch>
					</cftry>
					<cfif  del_agnt_ is "1" and isnumeric(trans_agent_id_) and trans_agent_id_ gt 0>
						<cfquery name="del" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							delete from trans_agent where trans_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trans_agent_id_#">
						</cfquery>
					<cfelse>
						<cfif trans_agent_id_ is "new" and del_agnt_ is 0>
							<cfquery name="newTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								insert into trans_agent (
									transaction_id,
									agent_id,
									trans_agent_role
								) values (
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#transaction_id#">,
									<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id_#">,
									<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_#">
								)
							</cfquery>
						<cfelseif del_agnt_ is 0>
							<cfquery name="upTransAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								update trans_agent set
									agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id_#">,
									trans_agent_role = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_agent_role_#">
								where
									trans_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trans_agent_id_#">
							</cfquery>
						</cfif>
					</cfif>
				   </cfif>
				</cfloop>
			</cftransaction>
			<cflocation url="Deaccession.cfm?action=editDeacc&transaction_id=#transaction_id#">
	<cfcatch>
		Update FAILED
		<p><cfdump var=#cfcatch#></p>
	</cfcatch>
        </cftry>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "makeDeacc">
	<cfoutput>
	<cftransaction>
			<cfquery name="newDeaccTrans" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans (
					TRANSACTION_ID,
					TRANS_DATE,
					CORRESP_FG,
					TRANSACTION_TYPE,
					NATURE_OF_MATERIAL,
					collection_id
					<cfif len(#trans_remarks#) gt 0>
						,trans_remarks
					</cfif>)
				VALUES (
					sq_transaction_id.nextval,
					'#initiating_date#',
					0,
					'deaccession',
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#nature_of_material#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_id#">
					<cfif len(#trans_remarks#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trans_remarks#'">
					</cfif>
					)
			</cfquery>
			<cfquery name="newDeacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO deaccession (
					TRANSACTION_ID,
					DEACC_TYPE,
					DEACC_NUMBER
					<cfif len(#deacc_status#) gt 0>
						,deacc_status
					</cfif>
					
					<cfif len(#DEACC_reason#) gt 0>
						,DEACC_REASON
					</cfif>
					  <cfif len(#value#) gt 0>
						,VALUE
					</cfif>
                    <cfif len(#method#) gt 0>
						,METHOD
					</cfif>
					 )
				values (
					sq_transaction_id.currval,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deacc_type#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deacc_number#">
					<cfif len(#deacc_status#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#deacc_status#">
					</cfif>
					<cfif len(#DEACC_REASON#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#DEACC_REASON#">
					</cfif>
                  <cfif len(#value#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#VALUE#">
					</cfif>
                    <cfif len(#method#) gt 0>
						,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#METHOD#">
                </cfif>
					)
			</cfquery>
			<cfquery name="authBy" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
				    transaction_id,
				    agent_id,
				    trans_agent_role
				) values (
					sq_transaction_id.currval,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#auth_agent_id#">,
					'authorized by')
			</cfquery>
			<cfquery name="in_house_contact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
				    transaction_id,
				    agent_id,
				    trans_agent_role
				) values (
					sq_transaction_id.currval,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#in_house_contact_agent_id#">,
					'in-house contact')
			</cfquery>
			<cfquery name="recipient_institution" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
				    transaction_id,
				    agent_id,
				    trans_agent_role
				) values (
					sq_transaction_id.currval,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#recipient_institution_agent_id#">,
					'recipient institution')
			</cfquery>
		<cfif isdefined("additional_contact_agent_id") and len(additional_contact_agent_id) gt 0>
			<cfquery name="additional_contact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
				    transaction_id,
				    agent_id,
				    trans_agent_role
				) values (
					sq_transaction_id.currval,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#additional_contact_agent_id#">,
					'additional outside contact')
			</cfquery>
		</cfif>
		<cfif isdefined("foruseby_agent_id") and len(foruseby_agent_id) gt 0>
			<cfquery name="foruseby_contact" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
				    transaction_id,
				    agent_id,
				    trans_agent_role
				) values (
					sq_transaction_id.currval,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#foruseby_agent_id#">,
					'for use by')
			</cfquery>
		</cfif>
			<cfquery name="newDeacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO trans_agent (
				    transaction_id,
				    agent_id,
				    trans_agent_role
				) values (
					sq_transaction_id.currval,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#REC_AGENT_ID#">,
					'received by')
			</cfquery>
			<cfquery name="nextTransId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_transaction_id.currval nextTransactionId from dual
			</cfquery>
		</cftransaction>
		<cflocation url="Deaccession.cfm?action=editDeacc&transaction_id=#nextTransId.nextTransactionId#" addtoken="false">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "search">
  <cfset title="Search for Deaccessions">
  <script src="/includes/jquery/jquery-autocomplete/jquery.autocomplete.pack.js" language="javascript" type="text/javascript"></script>
  <cfoutput>
  <script>
		jQuery(document).ready(function() {
	  		jQuery("##part_name").autocomplete("/ajax/part_name.cfm", {
				width: 320,
				max: 50,
				autofill: false,
				multiple: false,
				scroll: true,
				scrollHeight: 300,
				matchContains: true,
				minChars: 1,
				selectFirst:false
			});
		});
  </script>
   <div class="searchLoanWidth">
     <h2 class="wikilink">Find Deaccessions <img src="/images/info_i_2.gif" onClick="getMCZDocs('Loan/Gift_Transactions##Search_for_a_Loan_or_Gift')" class="likeLink" alt="[ help ]">
      </h2>
    <div id="loan">
      <cfquery name="ctType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select deacc_type from ctdeacc_type order by deacc_type
	</cfquery>
      <cfquery name="ctStatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select deacc_status from ctdeacc_status order by deacc_status
	</cfquery>

      <cfquery name="ctCollObjDisp" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select coll_obj_disposition from ctcoll_obj_disp
	</cfquery>
      <br>
      <form name="SpecData" action="Deaccession.cfm" method="post">
        <input type="hidden" name="action" value="listDeacc">
        <input type="hidden" name="project_id" <cfif project_id gt 0> value="#project_id#" </cfif>>
        <table>
          <tr>
            <td align="right">Collection Name: </td>
            <td><select name="collection_id" size="1">
                <option value=""></option>
                <cfloop query="ctcollection">
                  <option value="#collection_id#">#collection#</option>
                </cfloop>
              </select>
              <img src="images/nada.gif" width="2" height="1"> Number: <span class="lnum">
              <input type="text" name="deacc_number">
              </span></td>
          </tr>
          <tr>
            <td align="right"><select name="trans_agent_role_1">
                <option value="">Please choose an agent role...</option>
                <cfloop query="cttrans_agent_role">
                  <option value="#trans_agent_role#">-> #trans_agent_role#:</option>
                </cfloop>
              </select></td>
            <td><input type="text" name="agent_1"  size="50"></td>
          </tr>
          <tr>
            <td align="right"><select name="trans_agent_role_2">
                <option value="">Please choose an agent role...</option>
                <cfloop query="cttrans_agent_role">
                  <option value="#trans_agent_role#">-> #trans_agent_role#:</option>
                </cfloop>
              </select></td>
            <td><input type="text" name="agent_2"  size="50"></td>
          </tr>
          <tr>
            <td align="right"><select name="trans_agent_role_3">
                <option value="">Please choose an agent role...</option>
                <cfloop query="cttrans_agent_role">
                  <option value="#trans_agent_role#">-> #trans_agent_role#:</option>
                </cfloop>
              </select></td>
            <td><input type="text" name="agent_3"  size="50"></td>
          </tr>
        <tr>
            <td align="right">Type: </td>
            <td><select name="deacc_type">
                <option value=""></option>
                <cfloop query="ctType">
                  <option value="#ctType.deacc_type#">#ctType.deacc_type#</option>
                </cfloop>
              </select>
              <img src="images/nada.gif" width="25" height="1"> Status:&nbsp;
              <select name="deacc_status">
                <option value=""></option>
                <cfloop query="ctStatus">
                  <option value="#ctStatus.deacc_status#">#ctStatus.deacc_status#</option>
                </cfloop>
                <option value="not closed">closed</option>
              </select></td>
          </tr>
          <tr>
            <td align="right">Transaction Date:</td>
            <td><input name="trans_date" id="trans_date" type="text">
             &nbsp; To:
              <input type='text' name='to_trans_date' id="to_trans_date"></td>
          </tr>
         
          <tr>
            <td align="right">Permit Number:</td>
            <td><input type="text" name="permit_num" size="50">
              <span class="infoLink" onclick="getHelp('get_permit_number');">Pick</span></td>
          </tr>
             <tr>
            <td align="right">Nature of Material:</td>
            <td><textarea name="nature_of_material" rows="3" cols="50"></textarea></td>
          </tr>
          <tr>
            <td align="right">Reason for Deaccession:</td>
            <td><textarea name="deacc_reason" rows="3" cols="50"></textarea></td>
          </tr>
            <tr>
            <td align="right">Value: </td>
            <td><textarea name="value" rows="3" cols="50"></textarea></td>
          </tr>
          <tr>
            <tr>
            <td align="right">Method of Transfer: </td>
            <td><textarea name="method" rows="3" cols="50"></textarea></td>
          </tr>
          <tr>
            <td align="right">Internal Remarks: </td>
            <td><textarea name="deacc_remarks" rows="3" cols="50"></textarea></td>
          </tr>
          <tr>
            <td class="parts1"> Parts: </td>
            <td><table class="partloan">
                <tr>
                  <td valign="top"><label for="part_name_oper">Part<br/>
                      Match</label>
                    <select id="part_name_oper" name="part_name_oper">
                      <option value="is">is</option>
                      <option value="contains">contains</option>
                    </select></td>
                  <td valign="top"><label for="part_name">Part<br/>
                      Name</label>
                    <input type="text" id="part_name" name="part_name"></td>
                  <td valign="top"><label for="part_disp_oper">Disposition&nbsp;<br/>
                      Match</label>
                    <select id="part_disp_oper" name="part_disp_oper">
                      <option value="is">is</option>
                      <option value="isnot">is not</option>
                    </select></td>
                  <td valign="top"><label for="coll_obj_disposition">Part Disposition</label>
                    <select name="coll_obj_disposition" id="coll_obj_disposition" size="5" multiple="multiple">
                      <option value=""></option>
                      <cfloop query="ctCollObjDisp">
                        <option value="#ctCollObjDisp.coll_obj_disposition#">#ctCollObjDisp.coll_obj_disposition#</option>
                      </cfloop>
                    </select></td>
                </tr>
              </table></td>
          </tr>
          <tr>
            <td colspan="2" align="center">
            <input type="submit" value="Search" class="schBtn">
              &nbsp;
            <input type="reset" value="Clear" class="qutBtn">
            </td>
          </tr>
        </table>
      </form>
    </div>
    </div>
  </cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------------->
<cfif action is "listDeacc">
<cfoutput>
	<cfset title="Deaccession Item List">
	<cfset sel = "select
		trans.transaction_id,
		deacc_number,
		deaccession.deacc_type deacc_type,
		deacc_status,
        value,
		method,
		concattransagent(trans.transaction_id,'authorized by') auth_agent,
		concattransagent(trans.transaction_id,'entered by') ent_agent,
		concattransagent(trans.transaction_id,'received by') rec_agent,
		concattransagent(trans.transaction_id,'for use by') foruseby_agent,
		concattransagent(trans.transaction_id,'in-house contact') inHouse_agent,
		concattransagent(trans.transaction_id,'additional in-house contact') addInhouse_agent,
		concattransagent(trans.transaction_id,'additional outside contact') addOutside_agent,
		concattransagent(trans.transaction_id,'recipient institution') recip_inst,
		deacc_reason,
		trans_remarks,
		trans_date,
		to_char(closed_date, 'YYYY-MM-DD') closed_date,
		project_name,
		project.project_id pid,
		collection.collection">
	<cfset frm = " from
		deaccession,
		trans,
		project_trans,
		project,
		permit_trans,
		permit,
		collection,
                ctdeacc_type">
	<cfset sql = "where
		deaccession.transaction_id = trans.transaction_id AND
		trans.collection_id = collection.collection_id AND
		trans.transaction_id = project_trans.transaction_id (+) AND
		project_trans.project_id = project.project_id (+) AND
		deaccession.transaction_id = permit_trans.transaction_id (+) AND
		deaccession.deacc_type= ctdeacc_type.deacc_type (+) AND
		permit_trans.permit_id = permit.permit_id (+)">
	<cfif isdefined("trans_agent_role_1") AND len(trans_agent_role_1) gt 0>
		<cfset frm="#frm#,trans_agent trans_agent_1">
		<cfset sql="#sql# and trans.transaction_id = trans_agent_1.transaction_id">
		<cfset sql = "#sql# AND trans_agent_1.trans_agent_role = '#trans_agent_role_1#'">
	</cfif>


	<cfif isdefined("agent_1") AND len(agent_1) gt 0>
		<cfif #sql# does not contain "trans_agent_1">
			<cfset frm="#frm#,trans_agent trans_agent_1">
			<cfset sql="#sql# and trans.transaction_id = trans_agent_1.transaction_id">
		</cfif>
		<cfset frm="#frm#,preferred_agent_name trans_agent_name_1">
		<cfset sql="#sql# and trans_agent_1.agent_id = trans_agent_name_1.agent_id">
		<cfset sql = "#sql# AND upper(trans_agent_name_1.agent_name) like '%#ucase(agent_1)#%'">
	</cfif>
	<cfif isdefined("trans_agent_role_2") AND len(trans_agent_role_2) gt 0>
		<cfset frm="#frm#,trans_agent trans_agent_2">
		<cfset sql="#sql# and trans.transaction_id = trans_agent_2.transaction_id">
		<cfset sql = "#sql# AND trans_agent_2.trans_agent_role = '#trans_agent_role_2#'">
	</cfif>
	<cfif isdefined("agent_2") AND len(agent_2) gt 0>
		<cfif #sql# does not contain "trans_agent_2">
			<cfset frm="#frm#,trans_agent trans_agent_2">
			<cfset sql="#sql# and trans.transaction_id = trans_agent_2.transaction_id">
		</cfif>
		<cfset frm="#frm#,preferred_agent_name trans_agent_name_2">
		<cfset sql="#sql# and trans_agent_2.agent_id = trans_agent_name_2.agent_id">
		<cfset sql = "#sql# AND upper(trans_agent_name_2.agent_name) like '%#ucase(agent_2)#%'">
	</cfif>
	<cfif isdefined("trans_agent_role_3") AND len(#trans_agent_role_3#) gt 0>
		<cfset frm="#frm#,trans_agent trans_agent_3">
		<cfset sql="#sql# and trans.transaction_id = trans_agent_3.transaction_id">
		<cfset sql = "#sql# AND trans_agent_3.trans_agent_role = '#trans_agent_role_3#'">
	</cfif>
	<cfif isdefined("agent_3") AND len(#agent_3#) gt 0>
		<cfif #sql# does not contain "trans_agent_3">
			<cfset frm="#frm#,trans_agent trans_agent_3">
			<cfset sql="#sql# and trans.transaction_id = trans_agent_3.transaction_id">
		</cfif>
		<cfset frm="#frm#,preferred_agent_name trans_agent_name_3">
		<cfset sql="#sql# and trans_agent_3.agent_id = trans_agent_name_3.agent_id">
		<cfset sql = "#sql# AND upper(trans_agent_name_3.agent_name) like '%#ucase(agent_3)#%'">
	</cfif>
	<cfif isdefined("deacc_number") AND len(#deacc_number#) gt 0>
		<cfset sql = "#sql# AND upper(deacc_number) like '%#ucase(deacc_number)#%'">
	</cfif>
	<cfif isdefined("permit_num") AND len(#permit_num#) gt 0>
		<cfset sql = "#sql# AND PERMIT_NUM = '#PERMIT_NUM#'">
	</cfif>
	<cfif isdefined("collection_id") AND len(#collection_id#) gt 0>
		<cfset sql = "#sql# AND trans.collection_id = #collection_id#">
	</cfif>
	<cfif isdefined("deacc_type") AND len(#deacc_type#) gt 0>
		<cfset sql = "#sql# AND deaccession.deacc_type = '#deacc_type#'">
	</cfif>
	<cfif isdefined("deacc_status") AND len(#deacc_status#) gt 0>
    	<cfif deacc_status eq "not closed">
        	<cfset sql = "#sql# AND deacc_status <> 'closed'">
    	<cfelse>
		<cfset sql = "#sql# AND deacc_status = '#deacc_status#'">
        </cfif>
	</cfif>
	<cfif isdefined("rec_agent") AND len(#rec_agent#) gt 0>
		<cfset sql = "#sql# AND upper(recAgnt.agent_name) LIKE '%#ucase(escapeQuotes(rec_agent))#%'">
	</cfif>
	<cfif isdefined("auth_agent") AND len(#auth_agent#) gt 0>
		<cfset sql = "#sql# AND upper(authAgnt.agent_name) LIKE '%#ucase(escapeQuotes(auth_agent))#%'">
	</cfif>
	<cfif isdefined("ent_agent") AND len(#ent_agent#) gt 0>
		<cfset sql = "#sql# AND upper(entAgnt.agent_name) LIKE '%#ucase(escapeQuotes(ent_agent))#%'">
	</cfif>
	<cfif isdefined("nature_of_material") AND len(#nature_of_material#) gt 0>
		<cfset sql = "#sql# AND upper(nature_of_material) LIKE '%#ucase(escapeQuotes(nature_of_material))#%'">
	</cfif>
	<cfif isdefined("trans_date") and len(#trans_date#) gt 0>
		<cfif not isdefined("to_trans_date") or len(to_trans_date) is 0>
			<cfset to_trans_date=trans_date>
		</cfif>
		<cfset sql = "#sql# AND trans_date between to_date('#dateformat(trans_date, "yyyy-mm-dd")#')
			and to_date('#dateformat(to_trans_date, "yyyy-mm-dd")#')">
	</cfif>
	<cfif isdefined("trans_remarks") AND len(#trans_remarks#) gt 0>
		<cfset sql = "#sql# AND upper(trans_remarks) LIKE '%#ucase(trans_remarks)#%'">
	</cfif>
	<cfif isdefined("collection_object_id") AND len(#collection_object_id#) gt 0>
		<cfset frm="#frm#, deacc_item">
		<cfset sql = "#sql# AND deaccession.transaction_id=deacc_item.transaction_id AND deacc_item.collection_object_id IN (#collection_object_id#)">
	</cfif>
	<cfif (isdefined("part_name") AND len(part_name) gt 0) or (isdefined("coll_obj_disposition") AND len(coll_obj_disposition) gt 0)>
		<cfif frm does not contain "deacc_item">
			<cfset frm="#frm#, deacc_item">
			<cfset sql = "#sql# AND deaccession.transaction_id=deacc_item.transaction_id ">
		</cfif>
		<cfif frm does not contain "coll_object">
			<cfset frm="#frm#,coll_object">
			<cfset sql=sql & " and deacc_item.collection_object_id=coll_object.collection_object_id ">
		</cfif>
		<cfif frm does not contain "specimen_part">
			<cfset frm="#frm#,specimen_part">
			<cfset sql=sql & " and coll_object.collection_object_id = specimen_part.collection_object_id ">
		</cfif>

		<cfif isdefined("part_name") AND len(part_name) gt 0>
			<cfif not isdefined("part_name_oper")>
				<cfset part_name_oper='is'>
			</cfif>
			<cfif part_name_oper is "is">
				<cfset sql=sql & " and specimen_part.part_name = '#part_name#'">
			<cfelse>
				<cfset sql=sql & " and upper(specimen_part.part_name) like  '%#ucase(part_name)#%'">
			</cfif>
		</cfif>
		<cfif isdefined("coll_obj_disposition") AND len(coll_obj_disposition) gt 0>
			<cfif not isdefined("part_disp_oper")>
				<cfset part_disp_oper='is'>
			</cfif>
			<cfif part_disp_oper is "is">
				<cfset sql=sql & " and coll_object.coll_obj_disposition IN ( #listqualify(coll_obj_disposition,'''')# )">
			<cfelse>
				<cfset sql=sql & " and coll_object.coll_obj_disposition NOT IN ( #listqualify(coll_obj_disposition,'''')# )">
			</cfif>
		</cfif>
	</cfif>
	<cfset sql ="#sel# #frm# #sql#
		group by
		 	trans.transaction_id,
		   	deacc_number,
		    deaccession.deacc_type,
		    deacc_status,
		    value,
			method,
			concattransagent(trans.transaction_id,'authorized by'),
		 	concattransagent(trans.transaction_id,'entered by'),
		 	concattransagent(trans.transaction_id,'received by'),
			concattransagent(trans.transaction_id,'additional outside contact'),
			concattransagent(trans.transaction_id,'additional in-house contact'),
			concattransagent(trans.transaction_id,'in-house contact'),
			concattransagent(trans.transaction_id,'recipient institution'),
		 	deacc_reason,
		 	trans_remarks,
		  	trans_date,
		  	closed_date,
		   	project_name,
		 	project.project_id,
		 	collection.collection
		ORDER BY to_number(regexp_substr (deacc_number, '^[0-9]+', 1, 1)), to_number(regexp_substr (deacc_number, '[0-9]+', 1, 2)), deacc_number
    ">
	 <cfquery name="allDeacc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		#preservesinglequotes(sql)#
	</cfquery>
    <cfif allDeacc.recordcount is 0>
      Nothing matched your search criteria.
    </cfif>

    <cfset rURL="Deaccession.cfm?csv=true">
    <cfloop list="#StructKeyList(form)#" index="key">
    <cfset allDeacc.recordcount ++ />
      <cfif len(form[key]) gt 0>
        <cfset rURL='#rURL#&#key#=#form[key]#'>
      </cfif>
    </cfloop>
       <cfset deaccnum = ''>
    <cfif #allDeacc.recordcount# eq 1>
    <cfset deaccnum = 'item'>

    </cfif>
    <cfif #allDeacc.recordcount# gt 1>
    <cfset deaccnum = 'items'>
    </cfif>
    
 <header style="margin: 0 6em;">
 
     <div id="page_title">
      <h1  style="font-size: 1.5em;line-height: 1.6em;margin: 0;padding: 1em 0 0 0;">Deaccession Search Results<img src="/images/info_i_2.gif" border="0" onClick="getMCZDocs('Deaccession/Gift')" class="likeLink" alt="[ help ]" style="vertical-align:top;"></h1>
    </div>
   <p> #allDeacc.recordcount# #deaccnum# <a href="#rURL#" class="download">Download these results as a CSV file</a></p>
   </header>
    <hr/>
  </cfoutput>

    <cfset i=1>

    <cfif not isdefined("csv")>
      <cfset csv=false>
    </cfif>
    <cfif csv is true>
      <cfset dlFile = "ArctosLoanData.csv">
      <cfset variables.fileName="#Application.webDirectory#/download/#dlFile#">
      <cfset variables.encoding="UTF-8">
      <cfscript>
			variables.joFileWriter = createObject('Component', '/component.FileWriter').init(variables.fileName, variables.encoding, 32768);
			d='deacc_number,item_count,auth_agent,inHouse_agent,addInhouse_agent,Recipient,recip_inst,foruseby_agent,addOutside_agent,deacc_type,deacc_status,Transaction_Date,deacc_reason,trans_remarks,ent_agent,Project';
		 	variables.joFileWriter.writeLine(d);
	</cfscript>
    </cfif>
    <cfoutput query="allDeacc" group="transaction_id">

<div class="loan_results">
    <div id="listloans">

    <p>#i# of #allDeacc.recordcount# #deaccnum#</p>
       <dl>
         <dt>Collection &amp; Number:</dt>
         <dd><strong>#collection# / #deacc_number#</strong>
           
         </dd>
                <dt>Authorized By:</dt>
                 <cfif len(auth_agent) GT 0>
                  <dd class="mandcolr">#auth_agent#</dd>
                       <cfelse>
                   <dd class="emptystatus">N/A</dd>
                    </cfif>
                <dt title="primary in-house contact; 1 of 2 possible in-house contacts to receive email reminder">In-house Contact:</dt>

                  <cfif len(inHouse_agent) GT 0>
                     <dd class="mandcolr"> #inHouse_agent#</dd>
                    <cfelse>
                   <dd class="emptystatus">N/A</dd>
                  </cfif>


                <dt title="primary in-house contact; 1 of 2 possible in-house contacts to receive email reminder">Additional In-house Contact:</dt>
                  <cfif len(addInhouse_agent) GT 0>
                    <dd>#addInhouse_agent#</dd>
                    <cfelse>
                  <dd class="emptystatus">N/A</dd>
                  </cfif>

                <dt title="this is the primary borrower; listed on email reminder; 1 of 3 possible outside agents to receive email reminder; ship to address should be for this agent">Recipient:</dt>
                <dd class="mandcolr" title="1 of 3 possible outside agents to receive email reminder; listed on email reminder">#rec_agent#</dd>
                <dt title="1 of 3 possible outside agents to receive email reminder; listed on email reminder">For use by:</dt>

                  <cfif len(foruseby_agent) GT 0>
                    <dd>#foruseby_agent#</dd>
                    <cfelse>
                   <dd class="emptystatus">N/A</dd>
                  </cfif>
                 <dt>Recipient Institution:</dt>
                  <cfif len(recip_inst) GT 0>
                    <dd>#recip_inst#</dd>
                    <cfelse>
                   <dd class="emptystatus">N/A</dd>
                  </cfif>
                <dt title="1 of 3 possible outside agents to receive email reminder">Additional Outside Contact:</dt>
                <cfif len(addOutside_agent) GT 0>
                    <dd>#addOutside_agent#</dd>
                    <cfelse>
                   <dd class="emptystatus">N/A</dd>
                  </cfif>
                </dd>
                <dt title="included in email reminder">Type:</dt>
                <dd class="mandcolr">#deacc_type#</dd>
                <dt title="included in email reminder">Status:</dt>
                <dd class="mandcolr">#deacc_status# <cfif deacc_status EQ 'closed' and len(closed_date) GT 0>(#closed_date#)</cfif></dd>
                <dt title="included in email reminder">Transaction Date:</dt>
                 <cfif len(trans_date) GT 0>
                <dd  class="mandcolr">#dateformat(trans_date,"yyyy-mm-dd")#</dd>
                <cfelse>
                <dd class="mandcolrstatus">N/A</dd>
                </cfif>
				<dt title="included in email reminder">Reason for Deaccession:</dt>
                <cfif len(deacc_reason) GT 0>
                <dd class="mandcolr large">#deacc_reason#</dd>
                <cfelse>
                <dd class="mandcolrstatus large">N/A</dd>
                </cfif>
                <dt>Value:</dt>
				<cfif len(value) GT 0>
                    <dd class="large">#value#</dd>
                    <cfelse>
                    <dd class="large emptystatus">N/A</dd>
                  </cfif>
                     <dt>Method of Transfer:</dt>
				<cfif len(method) GT 0>
                    <dd class="large">#method#</dd>
                    <cfelse>
                    <dd class="large emptystatus">N/A</dd>
                  </cfif>
                <dt>Internal Remarks:</dt>
				<cfif len(trans_remarks) GT 0>
                    <dd class="large">#trans_remarks#</dd>
                    <cfelse>
                    <dd class="large emptystatus">N/A</dd>
                  </cfif>

                <dt>Entered By:</dt>
                 <cfif len(ent_agent) GT 0>
                 <dd>#ent_agent#</dd>
                 <cfelse>
                 <dd>N/A</dd>
                 </cfif>
         
   <ul class="loan_buttons">
      <li><a href="a_deaccItemReview.cfm?transaction_id=#transaction_id#">Review Items</a></li>
       <cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
       <li class="add"><a href="SpecimenSearch.cfm?action=dispCollObjDeacc&transaction_id=#transaction_id#">Add Items</a></li>
       <li class="barcode"><a href="deaccByBarcode.cfm?transaction_id=#transaction_id#">Add Items by Barcode</a></li>
       <li class="edit"><a href="Deaccession.cfm?transaction_id=#transaction_id#&action=editDeacc">Edit Deaccession</a></li>
     </cfif>
  </ul>
</dl>
 </div>
        </div>
      <cfif csv is true>
        <cfset d='"#escapeDoubleQuotes(collection)# #escapeDoubleQuotes(deacc_number)#"'>
        <cfset d=d &',"#c.c#"'>
        <cfset d=d &',"#escapeDoubleQuotes(auth_agent)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(inHouse_agent)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(addInhouse_agent)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(rec_agent)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(recip_inst)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(foruseby_agent)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(addOutside_agent)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(deacc_type)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(deacc_status)#"'>
        <cfset d=d &',"#dateformat(trans_date,"yyyy-mm-dd")#"'>
        <cfset d=d &',"#escapeDoubleQuotes(return_due_date)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(deacc_reason)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(trans_remarks)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(ent_agent)#"'>
        <cfset d=d &',"#escapeDoubleQuotes(valuelist(p.project_name))#"'>
        <cfscript>
				variables.joFileWriter.writeLine(d);
			</cfscript>
      </cfif>
      <cfset i=#i#+1>
    </cfoutput>

	<cfif csv is true>
		<cfscript>
			variables.joFileWriter.close();
		</cfscript>
		<cflocation url="/download.cfm?file=#dlFile#" addtoken="false">
	</cfif>
</table>
</cfif>

<cfinclude template="includes/_footer.cfm">
