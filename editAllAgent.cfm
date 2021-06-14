<cfset jquery11=true>
<cfinclude template="/includes/_frameHeader.cfm">
    <style>
        .content_box {width:100%;}</style>
<cfquery name="ctNameType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select agent_name_type as agent_name_type from ctagent_name_type where agent_name_type != 'preferred' order by agent_name_type
</cfquery>
<cfquery name="ctAgentType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select agent_type from ctagent_type order by agent_type
</cfquery>
<cfquery name="ctAddrType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select addr_type from ctaddr_type
	where addr_type <> 'temporary'
</cfquery>
<cfquery name="ctElecAddrType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select address_type from ctelectronic_addr_type
</cfquery>
<cfquery name="ctprefix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select prefix from ctprefix order by prefix
</cfquery>
<cfquery name="ctsuffix" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select suffix from ctsuffix order by suffix
</cfquery>
<cfquery name="ctRelns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select AGENT_RELATIONSHIP from CTAGENT_RELATIONSHIP
</cfquery>
<cfquery name="ctguid_type_agent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select guid_type, placeholder, pattern_regex, resolver_regex, resolver_replacement, search_uri
   from ctguid_type
   where applies_to like '%agent.agentguid%'
</cfquery>
<!--- Make sure that agentguid and agentguid_guid_type are defined and empty if not provided --->
<cfif NOT isDefined("agentguid_guid_type")>
	<cfset agentguid_guid_type = "">
</cfif>
<cfif NOT isDefined("agentguid")>
	<cfset agentguid = "">
</cfif>
<script type='text/javascript' src='/includes/internalAjax.js'></script>
<script type='text/javascript' src='/includes/transAjax.js'></script>
<link rel="stylesheet" type="text/css" href="/includes/css/mcz_style.css" title="mcz_style">
<script> var CKEDITOR_BASEPATH = '/includes/js/ckeditor/'; </script>
<script src="/includes/js/ckeditor/ckeditor.js"></script>
<cfoutput>
<script>
	function getAssembledName() {
		var result = "";
		if ($('##last_name').val()!="") {
			result = $('##last_name').val();
		}
		if ($('##middle_name').val()!="") {
			result = $('##middle_name').val() + " " + result;
		}
		if ($('##first_name').val()!="") {
			result = $('##first_name').val() + " " + result;
		}
		return result;
	}
</script>
</cfoutput>
<cfif not isdefined("agent_id")>
	<cfset agent_id = -1>
</cfif>
<script language="javascript" type="text/javascript">

	jQuery(document).ready(function() {
		jQuery("#birth_date").datepicker( { dateFormat: 'yy-mm-dd'} );
		jQuery("#death_date").datepicker( { dateFormat: 'yy-mm-dd'}  );
	});
	function suggestName(ntype){
		try {
			var fName=document.getElementById('first_name').value;
			var mName=document.getElementById('middle_name').value;
			var lName=document.getElementById('last_name').value;
			var name='';
			if (ntype=='initials plus last'){
				if (fName.length>0){
					name=fName.substring(0,1) + '. ';
				}
				if (mName.length>0){
					name+=mName.substring(0,1) + '. ';
				}
				if (lName.length>0){
					name+=lName;
				} else {
					name='';
				}
			}
			if (ntype=='last plus initials'){
				if (lName.length>0){
					name=lName + ', ';
					if (fName.length>0){
						name+=fName.substring(0,1) + '. ';
					}
					if (mName.length>0){
						name+=mName.substring(0,1) + '. ';
					}
				} else {
					name='';
				}
			}
			if (name.length>0){
				var rf=document.getElementById('agent_name');
				var tName=name.replace(/^\s+|\s+$/g,""); // trim spaces
				if (rf.value.length==0){
					rf.value=tName;
				}
			}
		}
		catch(e){
		}
	}

function opendialogrank(page,id,title,agentId) {
  var content = '<iframe style="border: 0px; " src="' + page + '" width="100%" height="100%"></iframe>'
  var adialog = $(id)
  .html(content)
  .dialog({
    title: title,
    autoOpen: false,
    dialogClass: 'dialog_fixed,ui-widget-header',
    modal: true,
    position: { my: "top", at: "center", of: id },
    height: 450,
    width: 550,
    minWidth: 300,
    minHeight: 250,
    draggable:true,
    resizable:true,
    buttons: { "Ok": function () { $(this).dialog("destroy"); $(id).html(''); loadAgentRankSummary('agentRankSummary',agentId);  } },
    close: function() {  $(this).dialog("destroy"); $(id).html(''); loadAgentRankSummary('agentRankSummary',agentId); }
  });
  adialog.dialog('open');
};


</script>
<!------------------------------------------------------------------------------------------------------------->
<cfif action is "newOtherAgent">
    <div style="padding: 0 0 0 1em;width:95%;">
<h3 class="wikilink">Add a New Other Agent <img src="/images/info_i_2.gif" border="0" onClick="getMCZDocs('Other Agent')" class="likeLink" alt="[ help ]"></h3>
	<cfoutput>
		<form name="prefdName" action="editAllAgent.cfm" method="post" target="_person">
			<input type="hidden" name="action" value="makeNewAgent">
			<input type="hidden" name="agent_name_type" value="preferred">
			<label for="agent_name">Preferred Name</label>
			<input type="text" name="agent_name" id="agent_name" size="50" class="reqdClr">
			<label for="agent_type">Agent Type</label>
			<select name="agent_type" id="agent_type" size="1">
				<cfloop query="ctAgentType">
					<cfif #ctAgentType.agent_type# neq 'person'>
						<option value="#ctAgentType.agent_type#">#ctAgentType.agent_type#</option>
					</cfif>
				</cfloop>
			</select>
			<label for="agent_remarks">Remarks</label>
                        <textarea name="agent_remarks" id="agent_remarks" style="height: 20em;"></textarea>
                       	<script>CKEDITOR.replace( 'agent_remarks' );</script>
		<input type="submit" value="Create Agent" class="savBtn">
			</form>
	</cfoutput>
    </div>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif #Action# is "newPerson">
        <div style="padding: 0 0 0 1em;width:95%;">
<h3 class="wikilink">Add a New Person <img src="/images/info_i_2.gif" onClick="getMCZDocs('Agent')" class="likeLink" alt="[ help ]"></h3>
	<form name="newPerson" action="editAllAgent.cfm" method="post" target="_person">
		<input type="hidden" name="Action" value="insertPerson">
		<label for="prefix">Prefix</label>
		<select name="prefix" id="prefix" size="1">
			<option value=""></option>
			<cfoutput query="ctprefix">
				<option value="#prefix#">#prefix#</option>
			</cfoutput>
		</select>
		<label for="first_name">First Name</label>
		<input type="text" name="first_name" id="first_name">
		<label for="middle_name">Middle Name</label>
		<input type="text" name="middle_name" id="middle_name">
		<label for="last_name">Last Name</label>
		<input type="text" name="last_name" id="last_name" class="reqdClr">
		<label for="suffix">Suffix</label>
		<select name="suffix" size="1" id="suffix">
			<option value=""></option>
			<cfoutput query="ctsuffix">
				<option value="#suffix#">#suffix#</option>
			</cfoutput>
    	</select>
		<label for="pref_name">Preferred Name</label>
		<input type="text" name="pref_name" id="pref_name">
		<cfoutput>
		<div class="detailCell">
			<label for="agentguid">GUID for Agent</label>
			<cfset pattern = "">
			<cfset placeholder = "">
			<cfset regex = "">
			<cfset replacement = "">
			<cfset searchlink = "" >
			<cfset searchtext = "" >
			<select name="agentguid_guid_type" id="agentguid_guid_type" size="1">
				<cfif searchtext EQ "">
					<option value=""></option>
				</cfif>
				<cfloop query="ctguid_type_agent">
					<cfset sel="">
						<cfif ctguid_type_agent.recordcount EQ 1 >
							<cfset sel="selected='selected'">
							<cfset placeholder = "#ctguid_type_agent.placeholder#">
							<cfset pattern = "#ctguid_type_agent.pattern_regex#">
							<cfset regex = "#ctguid_type_agent.resolver_regex#">
							<cfset replacement = "#ctguid_type_agent.resolver_replacement#">
						</cfif>
					<option #sel# value="#ctguid_type_agent.guid_type#">#ctguid_type_agent.guid_type#</option>
				</cfloop>
			</select>
			<a href="#searchlink#" id="agentguid_search" target="_blank">#searchtext#</a>
			<input size="55" name="agentguid" id="agentguid" value="" placeholder="#placeholder#" pattern="#pattern#" title="Enter a guid in the form #placeholder#">
			<a id="agentguid_link" href="" target="_blank" class="hints"></a>
			<script>
				$(document).ready(function () {
					if ($('##agentguid').val().length > 0) {
						$('##agentguid').hide();
					}
					$('##agentguid_search').click(function (evt) {
						switchGuidEditToFind('agentguid','agentguid_search','agentguid_link',evt);
					});
					$('##agentguid_guid_type').change(function () {
						// On selecting a guid_type, remove an existing guid value.
						$('##agentguid').val("");
						// On selecting a guid_type, change the pattern.
						getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
					});
					$('##agentguid').blur( function () {
						// On loss of focus for input, validate against the regex, update link
						getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
					});
					$('##first_name').change(function () {
						// On changing prefered name, update search.
						getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
					});
					$('##middle_name').change(function () {
						// On changing prefered name, update search.
						getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
					});
					$('##last_name').change(function () {
						// On changing prefered name, update search.
						getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
					});
				});
			</script>
		</div>
		</cfoutput>
		<input type="submit" value="Add Person" class="savBtn">
	</form>
    </div>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif action is "nothing">
	<cfif not isdefined("agent_id") OR agent_id lt 0 >
		<cfabort>
	</cfif>
	<cfquery name="person" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select
			agent_id,
			person_id,
			prefix,
			suffix,
			first_name,
			last_name,
			middle_name,
			birth_date,
			death_date,
			biography,
			agent_remarks,
			agent_type,
			agent.edited edited,
			agentguid_guid_type,
			agentguid
		from
			agent
			left outer join person on (agent_id = person_id)
			where agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
	</cfquery>
	<cfoutput query="person">
		<cfif #agent_type# is "person">
			<cfset nameStr="">
			<cfset nameStr= listappend(nameStr,prefix,' ')>

			<cfset nameStr= listappend(nameStr,first_name,' ')>
			<cfset nameStr= listappend(nameStr,middle_name,' ')>
			<cfset nameStr= listappend(nameStr,last_name,' ')>
			<cfset nameStr= listappend(nameStr,suffix,' ')>
			<cfif len(birth_date) gt 0>
				<cfset nameStr="#nameStr# (#birth_date#">
			<cfelse>
				<cfset nameStr="#nameStr# (unknown">
			</cfif>
			<cfif len(death_date) gt 0>
				<cfset nameStr="#nameStr# - #death_date#)">
			<cfelse>
				<cfset nameStr="#nameStr# - unknown)">
			</cfif>
		<cfelse>
			<cfquery name="getName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select agent_name from agent_name where agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				and agent_name_type='preferred'
			</cfquery>
			<cfset nameStr=#getName.agent_name#>
		</cfif>
        <div style="padding: 1em;">
		<h3 class="wikilink" style="margin-bottom:.5em;"> Edit Agent Profile <img src="/images/info_i_2.gif" border="0" onClick="getMCZDocs('Agent_Standards')" class="likeLink" style="margin-top: -10px;" alt="[ help ]"></h3>

		<strong>#nameStr#</strong> (#agent_type#) {ID: <a href="/agents/Agent.cfm?agent_id=#agent_id#" target="_blank">#agent_id#</a>}
		<cfif len(#person.biography#) gt 0>
			#person.biography#
		</cfif>
		<cfif len(#person.agent_remarks#) gt 0>
			<h4>Internal Remarks</h4>
			#person.agent_remarks#
		</cfif>
        <div style="margin-bottom: 1em;">
          <cfif listcontainsnocase(session.roles, "manage_transactions")>
             <p><a href="/agents/Agent.cfm?agent_id=#agent_id#" target="_self">Agent Activity</a>
          </cfif>
          <cfif listcontainsnocase(session.roles,"manage_transactions")>
			<cfquery name="rank" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select count(*) || ' ' || agent_rank agent_rank
				from agent_rank
				where agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				group by agent_rank
			</cfquery>
         &nbsp; &nbsp;

			<span id="agentRankSummary" style="font-size: 13px;margin: 1em 0;">
			<cfif rank.recordcount gt 0>
				Previous Ranking: #valuelist(rank.agent_rank,"; ")#
                                <cfif  #valuelist(rank.agent_rank,"; ")# contains 'F'>
                                    <img src='/images/flag-red.svg.png' width='16'>
                                </cfif>
			</cfif></span>
          		<cfif listcontainsnocase(session.roles,"manage_agent_ranking")>
 				<input type="button" class="lnkBtn" value="Rank" onclick="opendialogrank('/form/agentrank.cfm?agent_id=#agent_id#','##agentRankDlg_#agent_id#','Rank Agent #nameStr#',#agent_id#);">

			&nbsp;&nbsp;<img src="/images/icon_info.gif" border="0" onClick="getMCZDocs('Agent_Ranking')" class="likeLink" style="margin-top: -15px;" alt="[ help ]"></cfif>
                         <div id="agentRankDlg_#agent_id#"></div>

	   </cfif>
           <cfif listcontainsnocase(session.roles, "manage_transactions")>
              </p>
	   </cfif>
        </div>
	</cfoutput>
	<cfquery name="agentAddrs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from addr
		where agent_id = <cfqueryparam value="#person.agent_id#" cfsqltype="CF_SQL_DECIMAL">
			and addr.addr_type <> 'temporary'
		order by valid_addr_fg DESC
	</cfquery>
	<cfquery name="elecagentAddrs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from electronic_address
		where
		agent_id = <cfqueryparam value="#person.agent_id#" cfsqltype="CF_SQL_DECIMAL">
	</cfquery>
	<cfoutput>
		<cfset i=1>
		<cfloop query="agentAddrs">
			<cfif valid_addr_fg is 1>
				<div class="grayishbox">
			<cfelse>
				<div class="grayishbox">
			</cfif>
				<form name="addr#i#" method="post" action="editAllAgent.cfm">
					<input type="hidden" name="agent_id" value="#person.agent_id#">
					<input type="hidden" name="addr_id" value="#agentAddrs.addr_id#">
					<input type="hidden" name="action" value="editAddr">
					<input type="hidden" name="addrtype" value="#agentAddrs.addr_type#">
					<input type="hidden" name="job_title" value="#agentAddrs.job_title#">
					<input type="hidden" name="street_addr1" value="#agentAddrs.street_addr1#">
					<input type="hidden" name="department" value="#agentAddrs.department#">
					<input type="hidden" name="institution" value="#agentAddrs.institution#">
					<input type="hidden" name="street_addr2" value="#agentAddrs.street_addr2#">
					<input type="hidden" name="city" value="#agentAddrs.city#">
					<input type="hidden" name="state" value="#agentAddrs.state#">
					<input type="hidden" name="zip" value="#agentAddrs.zip#">
					<input type="hidden" name="country_cde" value="#agentAddrs.country_cde#">
					<input type="hidden" name="mail_stop" value="#agentAddrs.mail_stop#">
					<input type="hidden" name="validfg" value="#agentAddrs.valid_addr_fg#">
					<input type="hidden" name="addr_remarks" value="#agentAddrs.addr_remarks#">
					<input type="hidden" name="formatted_addr" value="#agentAddrs.formatted_addr#">
				</form>
				#addr_type# Address (<cfif #valid_addr_fg# is 1>valid<cfelse>invalid</cfif>)
				&nbsp;
				<input type="button" class="lnkBtn" value="Edit" onclick="addr#i#.action.value='editAddr';addr#i#.submit();">
				&nbsp;
				<input type="button" class="delBtn" value="Delete" onclick="addr#i#.action.value='deleteAddr';confirmDelete('addr#i#');">
				<div style="margin-left:1em;">
					#replace(formatted_addr,chr(10),"<br>","all")#
				</div>
				<cfset i=#i#+1>
			</div>
		</cfloop>

		<cfset i=1>
		<cfloop query="elecagentAddrs">
			<form name="elad#i#" method="post" action="editAllAgent.cfm">
				<input type="hidden" name="action" >
				<input type="hidden" name="agent_id" value="#person.agent_id#">
				<input type="hidden" name="address_type" value="#address_type#">
				<input type="hidden" name="address" value="#address#">
			</form>
			<div class="grayishbox">
				#address_type#: #address#
				<input type="button" value="Edit" class="lnkBtn" onclick="elad#i#.action.value='editElecAddr';elad#i#.submit();">
				<input type="button" value="Delete" class="delBtn" onclick="elad#i#.action.value='deleElecAddr';confirmDelete('elad#i#');">
			</div>
			<cfset i=#i#+1>
		</cfloop>
	</cfoutput>
	<br />
	<cfif #person.agent_type# is "person">
		<cfoutput query="person">
			<form name="editPerson" action="editAllAgent.cfm" method="post" target="_person">
				<input type="hidden" name="agent_id" value="#agent_id#">
				<input type="hidden" name="action" value="editPerson">
				<div class="grayishbox">
					<table>
						<tr>
							<td>
								<label for="prefix">Prefix</label>
								<select name="prefix" id="prefix" size="1">
									<option value=""></option>
									<cfloop query="ctprefix">
										<option value="#ctprefix.prefix#"
										<cfif #ctprefix.prefix# is "#person.prefix#">selected</cfif>>#ctprefix.prefix#
										</option>
									</cfloop>
								</select>
							</td>
							<td>
								<label for="first_name">First Name</label>
								<input type="text" name="first_name" id="first_name" value="#first_name#">
							</td>
							<td>
								<label for="middle_name">Middle Name</label>
								<input type="text" name="middle_name" id="middle_name" value="#middle_name#">
							</td>
							<td>
								<label for="last_name">Last Name</label>
								<input type="text" name="last_name" id="last_name" value="#last_name#">
							</td>
							<td>
								<label for="suffix">Suffix</label>
								<select name="suffix" id="suffix" size="1">
									<option value=""></option>
									   <cfloop query="ctsuffix">
											<option value="#ctsuffix.suffix#"
												<cfif #ctsuffix.suffix# is "#person.suffix#">selected</cfif>>#ctsuffix.suffix#</option>
										</cfloop>
								</select>
							</td>
						</tr>
 						<tr>
							<td>
 								<label for="birth_date">Birth Date</label>
 								<input type="text" name="birth_date" id="birth_date" value="#birth_date#" size="10">
 							</td>
							<td>
 								<label for="death_date">Death Date</label>
 								<input type="text" name="death_date" id="death_date" value="#death_date#" size="10">
 							</td>
						        <td colspan="2">
                                                            <label for="editedPerson">Vetted</label>
				                            <select name="editedPerson" size="1">
					                       <option value=1 <cfif #edited# EQ 1>selected</cfif>>yes *</option>
					                       <option value=0 <cfif #edited# EQ 0 or #edited# EQ "">selected</cfif>>no</option>
				                            </select>
				                        </td>
 						</tr>
 						<tr>
							<td colspan="5" class="detailCell">
								<label for="agentguid">GUID for Agent</label>
								<cfset pattern = "">
								<cfset placeholder = "">
								<cfset regex = "">
								<cfset replacement = "">
								<cfset searchlink = "" >
								<cfset searchtext = "" >
								<cfset searchclass = "" >
								<cfloop query="ctguid_type_agent">
				 					<cfif person.agentguid_guid_type is ctguid_type_agent.guid_type OR ctguid_type_agent.recordcount EQ 1 >
										<cfset searchlink = ctguid_type_agent.search_uri & replace(EncodeForURL(trim(person.first_name & ' ' & trim(person.middle_name & ' ' & person.last_name))),'+','%20') >
										<cfif len(person.agentguid) GT 0>
											<cfset searchtext = "Edit" >
											<cfset searchclass = 'class="smallBtn editGuidButton"' >
										<cfelse>
											<cfset searchtext = "Find GUID" >
											<cfset searchclass = 'class="smallBtn findGuidButton external"' >
										</cfif>
									</cfif>
								</cfloop>
								<select name="agentguid_guid_type" id="agentguid_guid_type" size="1">
									<cfif searchtext EQ "">
										<option value=""></option>
									</cfif>
									<cfloop query="ctguid_type_agent">
										<cfset sel="">
				 							<cfif person.agentguid_guid_type is ctguid_type_agent.guid_type OR ctguid_type_agent.recordcount EQ 1 >
												<cfset sel="selected='selected'">
												<cfset placeholder = "#ctguid_type_agent.placeholder#">
												<cfset pattern = "#ctguid_type_agent.pattern_regex#">
												<cfset regex = "#ctguid_type_agent.resolver_regex#">
												<cfset replacement = "#ctguid_type_agent.resolver_replacement#">
											</cfif>
										<option #sel# value="#ctguid_type_agent.guid_type#">#ctguid_type_agent.guid_type#</option>
									</cfloop>
								</select>
								<a href="#searchlink#" id="agentguid_search" target="_blank" #searchclass#>#searchtext#</a>
								<input size="55" name="agentguid" id="agentguid" value="#person.agentguid#"
									placeholder="#placeholder#"
									pattern="#pattern#" title="Enter a guid in the form #placeholder#">
								<cfif len(regex) GT 0 >
									<cfset link = REReplace(person.agentguid,regex,replacement)>
								<cfelse>
									<cfset link = person.agentguid>
								</cfif>
								<a id="agentguid_link" href="#link#" target="_blank" class="hints">#agentguid#</a>
								<script>
									$(document).ready(function () {
										if ($('##agentguid').val().length > 0) {
											$('##agentguid').hide();
										}
										$('##agentguid_search').click(function (evt) {
											switchGuidEditToFind('agentguid','agentguid_search','agentguid_link',evt);
										});
										$('##agentguid_guid_type').change(function () {
											// On selecting a guid_type, remove an existing guid value.
											$('##agentguid').val("");
											// On selecting a guid_type, change the pattern.
											getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
										});
										$('##agentguid').blur( function () {
											// On loss of focus for input, validate against the regex, update link
											getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
										});
										$('##first_name').change(function () {
											// On changing name, update search.
											getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
										});
										$('##middle_name').change(function () {
											// On changing name, update search.
											getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
										});
										$('##last_name').change(function () {
											// On changing name, update search.
											getGuidTypeInfo($('##agentguid_guid_type').val(), 'agentguid', 'agentguid_link','agentguid_search',getAssembledName());
										});
									});
								</script>
							</td>
 						</tr>
 						<tr>
							<td colspan="5">
 								<label for="biography">Biography (public) &nbsp;&nbsp;<img src="/images/icon_info.gif" border="0" onClick="getMCZDocs('Agent_Remarks')" class="likeLink" style="margin-top: -15px;" alt="[ help ]"></label>
                     		<textarea name="biography" id="biography" style="height: 20em;">#biography#</textarea>
                       		<script>CKEDITOR.replace( 'biography' );</script>
 							</td>
 						</tr>
 						<tr>
							<td colspan="5">
 								<label for="agent_remarks">Internal Remarks &nbsp;&nbsp;<img src="/images/icon_info.gif" border="0" onClick="getMCZDocs('Agent_Remarks')" class="likeLink" style="margin-top: -15px;" alt="[ help ]"></label>
                       						<textarea name="agent_remarks" id="agent_remarks" style="height: 20em;">#agent_remarks#</textarea>
                       						<script>CKEDITOR.replace( 'agent_remarks' );</script>

 								<input type="submit" class="savBtn" value="Update Person">
 							</td>
 						</tr>

					</table>
				</div>
			</form>
		</cfoutput>
	<cfelse>
		<cfoutput query="person">
		<form name="editNonPerson" action="editAllAgent.cfm" method="post" target="_person">
			<input type="hidden" name="agent_id" value="#agent_id#">
			<input type="hidden" name="action" value="editNonPerson">

					<table>
						<tr>
 						<tr>
							<td colspan="4">
 								<label for="biography">Biography (public) &nbsp;&nbsp;<img src="/images/icon_info.gif" border="0" onClick="getMCZDocs('Agent_Remarks')" class="likeLink" style="margin-top: -15px;" alt="[ help ]"></label>
                     		<textarea name="biography" id="biography" style="height: 20em;">#biography#</textarea>
                       		<script>CKEDITOR.replace( 'biography' );</script>
 							</td>
 						</tr>
							<td colspan="4">
								<label for="agent_remarks">Agent Remarks</label>
                       						<textarea name="agent_remarks" id="agent_remarks" style="height: 20em;">#agent_remarks#</textarea>
                       						<script>CKEDITOR.replace( 'agent_remarks' );</script>
								<br>
								<input type="submit" class="savBtn" value="Update Agent">
							</td>
							<td>Edited:
								<select name="editedPerson" size="1">
									<option value=1 <cfif #edited# EQ 1>selected</cfif>>yes</option>
									<option value=0 <cfif #edited# EQ 0 or #edited# EQ "">selected</cfif>>no</option>
								</select>
							</td>
						</tr>
					</table>

		</form>
		</cfoutput>
	</cfif>
	<cfoutput>
		<!----- group handling ---->
		<cfif #person.agent_type# IS "group" OR #person.agent_type# IS "expedition" OR #person.agent_type# IS "vessel">
			<cfquery name="grpMem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select
					MEMBER_AGENT_ID,
					MEMBER_ORDER,
					agent_name
				from
					group_member,
					preferred_agent_name
				where
					group_member.MEMBER_AGENT_ID = preferred_agent_name.agent_id AND
					GROUP_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				order by MEMBER_ORDER
			</cfquery>
			<label for="gmemdv">Group Members</label>
			<cfset i=1>
			<br />
			<div id="gmemdv" class="grayishbox">
				<cfloop query="grpMem">
					<form name="groupMember#i#" method="post" action="editAllAgent.cfm">
						<input type="hidden" name="action" value="deleteGroupMember" />
						<input type="hidden" name="member_agent_id" value="#member_agent_id#" />
						<input type="hidden" name="agent_id" value="#agent_id#" />
						#agent_name#&nbsp;<input type="button" value="Remove Member" class="delBtn" onClick="confirmDelete('groupMember#i#');"><br>
					</form>
					<cfset i=#i# + 1>
				</cfloop>
			</div>
			<cfquery name="memOrd" dbtype="query">
				select max(member_order) + 1 as nextMemOrd from grpMem
			</cfquery>
			<cfif len(memOrd.nextMemOrd) gt 0>
				<cfset nOrd = memOrd.nextMemOrd>
			<cfelse>
				<cfset nOrd = 1>
			</cfif>
			<form name="newGroupMember" method="post" action="editAllAgent.cfm">
				<input type="hidden" name="agent_id" value="#agent_id#" />
				<input type="hidden" name="action" value="makeNewGroupMemeber" />
				<input type="hidden" name="member_order" value="#nOrd#" />
				<input type="hidden" name="member_id">
				<div class="newRec" style="margin-top: 1em;">
					<label for="">Add Member to Group</label>
					<input type="text" name="group_member" class="reqdClr" readonly autocomplete="off" onfocus="this.removeAttribute('readonly');"
						onchange="getAgent('member_id','group_member','newGroupMember',this.value); return false;"
				 		onKeyPress="return noenter(event);">
					<input type="submit" class="insBtn" value="Add Group Member">
				</div>
			</form>
		</cfif>
		<!--- agent names --->
		<cfquery name="anames" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select * from agent_name where agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
		</cfquery>
		<cfquery name="pname" dbtype="query">
			select * from anames where agent_name_type='preferred'
		</cfquery>
		<cfquery name="npname" dbtype="query">
			select * from anames where agent_name_type!='preferred'
		</cfquery>
		<cfset i=1>
		<br />
		<h4 class="groupAgent">Agent Names </h4>
		<div id="anamdv" class="grayishbox">
			<form name="a#i#" action="editAllAgent.cfm" method="post" target="_person">
				<input type="hidden" name="action">
				<input type="hidden" name="agent_name_id" value="#pname.agent_name_id#">
				<input type="hidden" name="agent_id" value="#pname.agent_id#">
				<input type="hidden" name="agent_name_type" value="#pname.agent_name_type#">
				<label for="agent_name">Preferred Name</label>
				<input type="text" value="#pname.agent_name#" name="agent_name" id="agent_name" readonly autocomplete="off" onfocus="this.removeAttribute('readonly');">
				<input type="button" value="Update" class="savBtn" onClick="a#i#.action.value='updateName';a#i#.submit();">
                <input type="button" value="Copy" class="lnkBtn" onClick="newName.agent_name.value='#pname.agent_name#';">
                <span class="hints" style="color: green;">(add a space between initials for all forms with two initials)</span>
			</form>

			<cfset i=i+1>
			<label>Other Names</label>
			<cfloop query="npname">
				<form name="a#i#" action="editAllAgent.cfm" method="post" target="_person">
					<input type="hidden" name="action">
					<input type="hidden" name="agent_name_id" value="#npname.agent_name_id#">
					<input type="hidden" name="agent_id" value="#npname.agent_id#">
					<select name="agent_name_type">
						<cfloop query="ctNameType">
							<option  <cfif ctNameType.agent_name_type is npname.agent_name_type> selected="selected" </cfif>
								value="#ctNameType.agent_name_type#">#ctNameType.agent_name_type#</option>
						</cfloop>
					</select>
					<input type="text" value="#npname.agent_name#" name="agent_name" readonly autocomplete="off" onfocus="this.removeAttribute('readonly');">
					<input type="button" value="Update" class="savBtn" onClick="a#i#.action.value='updateName';a#i#.submit();">
					<input type="button" value="Delete" class="delBtn" onClick="a#i#.action.value='deleteName';confirmDelete('a#i#');">
					<input type="button" class="lnkBtn" value="Copy" onClick="newName.agent_name.value='#pname.agent_name#';">
				</form>
				<cfset i = i + 1>
			</cfloop>

		<div id="nagnndv" class="newRec" style="padding-top: 0em;">
			<label for="nagnndv">Add agent name</label>
			<form name="newName" action="editAllAgent.cfm" method="post" target="_person">
				<input type="hidden" name="Action" value="newName">
				<input type="hidden" name="agent_id" value="#person.agent_id#">
				<select name="agent_name_type" onchange="suggestName(this.value);">
					<cfloop query="ctNameType">
						<option value="#ctNameType.agent_name_type#">#ctNameType.agent_name_type#</option>
					</cfloop>
				</select>
				<input type="text" name="agent_name" id="agent_name" readonly autocomplete="off" onfocus="this.removeAttribute('readonly');">
				<input type="submit" class="insBtn" value="Create Name">
			</form>
		</div>
		<cfquery name="relns" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select
				agent_relationship, agent_name, related_agent_id
			from agent_relations, agent_name
			where
			  agent_relations.related_agent_id = agent_name.agent_id
			  and agent_name_type = 'preferred' and
			  agent_relations.agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#person.agent_id#">
		</cfquery>
		</div>
            <h4 class="groupAgent">Relationships</h4>
		<div id="areldv" class="grayishbox">
			<cfset i=1>
			<cfloop query="relns">
				<form name="agentRelations#i#" method="post" action="editAllAgent.cfm">
					<input type="hidden" name="action">
					<input type="hidden" name="agent_id" value="#person.agent_id#">
					<input type="hidden" name="related_agent_id" value="#related_agent_id#">
					<input type="hidden" name="oldRelationship" value="#agent_relationship#">
					<input type="hidden" name="newRelatedAgentId">
					<cfset thisReln = agent_relationship>
					<select name="relationship" size="1">
						<cfloop query="ctRelns">
							<option value="#ctRelns.AGENT_RELATIONSHIP#"
								<cfif #ctRelns.AGENT_RELATIONSHIP# is "#thisReln#">
									selected="selected"
								</cfif>
								>#ctRelns.AGENT_RELATIONSHIP#</option>
						</cfloop>
					</select>
					<input type="text" name="related_agent" class="reqdClr" value="#agent_name#" readonly autocomplete="off" onfocus="this.removeAttribute('readonly');"
						onchange="getAgent('newRelatedAgentId','related_agent','agentRelations#i#',this.value); return false;"
						onKeyPress="return noenter(event);">
					<input type="button" class="savBtn" value="Save" onClick="agentRelations#i#.action.value='changeRelated';agentRelations#i#.submit();">
					<input type="button" class="delBtn" value="Delete" onClick="agentRelations#i#.action.value='deleteRelated';confirmDelete('agentRelations#i#');">
				</form>
				<cfset i=#i#+1>
			</cfloop>

		<div class="newRec" style="margin-top: 1em;">
			<label>Add Relationship</label>
			<form name="newRelationship" method="post" action="editAllAgent.cfm">
				<input type="hidden" name="action" value="addRelationship">
				<input type="hidden" name="newRelatedAgentId">
				<input type="hidden" name="agent_id" value="#person.agent_id#">
				<select name="relationship" size="1">
					<cfloop query="ctRelns">
						<option value="#ctRelns.AGENT_RELATIONSHIP#">#ctRelns.AGENT_RELATIONSHIP#</option>
					</cfloop>
				</select>
				<input type="text" name="related_agent" class="reqdClr" readonly autocomplete="off" onfocus="this.removeAttribute('readonly');"
					onchange="getAgent('newRelatedAgentId','related_agent','newRelationship',this.value); return false;"
					onKeyPress="return noenter(event);">
				<input type="submit" class="insBtn" value="Create Relationship">
			</form>
		</div></div>
        	<h4 class="groupAgent">Address</h4>
            <div class="grayishbox">
		<div class="newRec">

			<form name="newAddress" method="post" action="editAllAgent.cfm">
				<input type="hidden" name="agent_id" value="#person.agent_id#">
				<input type="hidden" name="Action" value="newAddress">
				<table>
					<tr>
						<td>
							<label for="addr_type">Address Type</label>
							<select name="addr_type" id="addr_type" size="1">
								<cfloop query="ctAddrType">
								<option value="#ctAddrType.addr_type#">#ctAddrType.addr_type#</option>
								</cfloop>
							</select>
						</td>
						<td>
							<label for="job_title">Job Title</label>
							<input type="text" name="job_title" id="job_title">
						</td>
					</tr>
					<tr>
						<td colspan="2">
							<label for="institution">Institution</label>
							<input type="text" name="institution" id="institution"size="50" >
						</td>
					</tr>
					<tr>
						<td colspan="2">
							<label for="department">Department</label>
							<input type="text" name="department" id="department" size="50" >
						</td>
					</tr>
					<tr>
						<td colspan="2">
							<label for="street_addr1">Street Address 1</label>
							<input type="text" name="street_addr1" id="street_addr1" size="50" class="reqdClr">
						</td>
					</tr>
					<tr>
						<td colspan="2">
							<label for="street_addr2">Street Address 2</label>
							<input type="text" name="street_addr2" id="street_addr2" size="50">
						</td>
					</tr>
					<tr>
						<td>
							<label for="city">City</label>
							<input type="text" name="city" id="city" class="reqdClr">
						</td>
						<td>
							<label for="state">State</label>
							<input type="text" name="state" id="state" class="reqdClr">
						</td>
					</tr>
					<tr>
						<td>
							<label for="zip">Zip</label>
							<input type="text" name="zip" id="zip" class="reqdClr">
						</td>
                  				<td>
						<script>
						function handleCountrySelect(){
						   var countrySelection =  $('input:radio[name=country]:checked').val();
						   if (countrySelection == 'USA') {
						      $("##textUS").css({"color": "black", "font-weight":"bold" });
						      $("##other_country_cde").toggle("false");
						      $("##country_cde").val("USA");
						      $("##other_country_cde").removeClass("reqdClr");
						   } else {
						      $("##textUS").css({"color": "##999999", "font-weight": "normal" });
						      $("##other_country_cde").toggle("true");
						      $("##country_cde").val($("##other_country_cde").val());
						      $("##other_country_cde").addClass("reqdClr");
						   }
						}
						</script>
				                     <label for="country_cde">Country <img src="/images/icon_info.gif" border="0" onclick="getMCZDocs('Country_Name_List')" class="likeLink" style="margin-top: -10px;" alt="[ help ]"></label>
				                     <span>
				                     <input type="hidden" name="country_cde" id="country_cde" class="reqdClr" value="USA">
				                     <input type="radio" name="country" value="USA" onclick="handleCountrySelect();" checked="checked" ><span id="textUS" style="color: black; font-weight: bold">USA</span>
				                     <input type="radio" name="country" value="other" onclick="handleCountrySelect();" ><span id="textOther">Other</span>
				                     <input type="text" name="other_country_cde" id="other_country_cde" onblur=" $('##country_cde').val($('##other_country_cde').val());" style="display: none;" >
				                     <span>
				                  </td>
					</tr>
					<tr>
						<td>
							<label for="mail_stop">Mail Stop</label>
							<input type="text" name="mail_stop" id="mail_stop">
						</td>
						<td>
							<label for="valid_addr_fg">Valid?</label>
							<select name="valid_addr_fg" id="valid_addr_fg" size="1">
								<option value="1">yes</option>
								<option value="0">no</option>
							</select>
						</td>
					</tr>
					<tr>
						<td colspan="2">
							<label for="addr_remarks">Address Remark</label>
							<input type="text" name="addr_remarks" id="addr_remarks" size="50">
						</td>
					</tr>
					<tr>
						<td colspan="2">
							<input type="submit" class="insBtn" value="Create Address">
						</td>
					</tr>
				</table>
			</form>

		<div class="newRec" style="margin-top:.5em;">
			<label>Add Electronic Address</label>
			<form name="newElecAddr" method="post" action="editAllAgent.cfm">
				<input name="Action" type="hidden" value="newElecAddr">
				<input type="hidden" name="agent_id" value="#person.agent_id#">
				<select name="address_type" size="1">
					<cfloop query="ctElecAddrType">
						<option value="#ctElecAddrType.address_type#">#ctElecAddrType.address_type#</option>
					</cfloop>
				</select>
				<input type="text" name="address" id="address" size="50">
				<input type="submit" class="insBtn" value="Create Address">
			</form>
		</div></div></div>
		<cfquery name="media" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		    select distinct
		        media.media_id,
		        media.media_uri,
		        media.mime_type,
		        media.media_type,
		        media.preview_uri,
			    mczbase.get_media_descriptor(media.media_id) as media_descriptor
		     from
		         media,
		         media_relations,
		         media_labels
		     where
		         media.media_id=media_relations.media_id and
		         media.media_id=media_labels.media_id (+) and
		         media_relations.media_relationship = 'shows agent' and
		         media_relations.related_primary_key = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
		</cfquery>
		<cfif media.recordcount gt 0>
	<h4 class="groupAgent">Media</h4>
    <div class="grayishbox">
		<!---div class="detailLabel">Media--->
		<cfquery name="wrlCount" dbtype="query">
			select * from media where mime_type = 'model/vrml'
		</cfquery>
		<cfif wrlCount.recordcount gt 0>
			<br><span class="innerDetailLabel">Note: CT scans with mime type "model/vrml" require an external plugin such as <a href="http://cic.nist.gov/vrml/cosmoplayer.html">Cosmo3d</a> or <a href="http://mediamachines.wordpress.com/flux-player-and-flux-studio/">Flux Player</a>. For Mac users, a standalone player such as <a href="http://meshlab.sourceforge.net/">MeshLab</a> will be required.</span>
		</cfif>
		 		<!---cfif oneOfUs is 1>
				 <cfquery name="hasConfirmedImageAttr"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(*) c
					FROM
						ctattribute_type
					where attribute_type='image confirmed' and
					collection_cde='#one.collection_cde#'
				</cfquery>
				<span class="detailEditCell" onclick="window.parent.loadEditApp('MediaSearch');">Edit</span>
				<cfquery name="isConf"  dbtype="query">
					SELECT count(*) c
					FROM
						attribute
					where attribute_type='image confirmed'
				</cfquery>
				<CFIF isConf.c is "" and hasConfirmedImageAttr.c gt 0>
					<span class="infoLink"
						id="ala_image_confirm" onclick='windowOpener("/ALA_Imaging/confirmImage.cfm?collection_object_id=#collection_object_id#","alaWin","width=700,height=400, resizable,scrollbars,location,toolbar");'>
						Confirm Image IDs
					</span>
				</CFIF>
			</cfif--->
		<div class="detailBlock">
            <span class="detailData">
				<!---div class="thumbs"--->
					<div class="thumb_spcr">&nbsp;</div>
					<cfloop query="media">
						<cfset altText = media.media_descriptor>
						<cfset puri=getMediaPreview(preview_uri,media_type)>
		            	<cfquery name="labels"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							select
								media_label,
								label_value
							from
								media_labels
							where
								media_id=<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#media_id#'>
						</cfquery>
						<cfquery name="desc" dbtype="query">
							select label_value from labels where media_label='description'
						</cfquery>
						<cfset alt="Media Preview Image">
						<cfif desc.recordcount is 1>
							<cfset alt=desc.label_value>
						</cfif>
		               <div class="one_thumb">
			               <a href="#media_uri#" target="_blank"><img src="#getMediaPreview(preview_uri,media_type)#" alt="#altText#" class="theThumb"></a>
		                   	<p>
								#media_type# (#mime_type#)
			                   	<br><a href="/media/#media_id#" target="_blank">Media Details</a>
								<br>#alt#
							</p>
						</div>
					</cfloop>
					<div class="thumb_spcr">&nbsp;</div>

	        </span>
		</div>
	</div>
</cfif>
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif #Action# is "editElecAddr">
	<cfoutput>
		<form name="edElecAddr" method="post" action="editAllAgent.cfm">
			<input name="Action" type="hidden" value="saveEditElecAddr">
			<input type="hidden" name="agent_id" value="#agent_id#">
			<input type="hidden" name="origAddress" value="#address#">
			<input type="hidden" name="origAddressType" value="#address_type#">
			<select name="address_type" size="1" id="address_type">
				<cfloop query="ctElecAddrType">
					<option <cfif #form.address_type# is "#ctElecAddrType.address_type#"> selected </cfif>value="#ctElecAddrType.address_type#">#ctElecAddrType.address_type#</option>
				</cfloop>
			</select>
			<input type="text" name="address" id="address" value="#address#" size="50">
			<input type="submit"
				value="Save Updates"
				class="savBtn">
		</form>
</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif #Action# is "saveEditElecAddr">
	<cfoutput>
		<cfquery name="upElecAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE electronic_address SET
				address_type = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#address_type#'>,
				address = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#address#'>
			where
				agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				and address_type = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#origAddressType#'>
				and address = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#origAddress#'>
		</cfquery>
		<cflocation url="editAllAgent.cfm?agent_id=#agent_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif #Action# is "deleElecAddr">
	<cfoutput>
		<cfquery name="deleElecAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from electronic_address where
				agent_id=<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#agent_id#'>
				and address_type=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#address_type#'>
				and address=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#address#'>
		</cfquery>
		<cflocation url="editAllAgent.cfm?agent_id=#agent_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif action is "editAddr">
	<cfset title = "Edit Address">
	Edit Address:
	<cfoutput>
	<form name="editAddr" method="post" action="editAllAgent.cfm">
		<input type="hidden" name="agent_id" value="#agent_id#">
		<input type="hidden" name="action" value="saveEditsAddr">
		<input type="hidden" name="addr_id" value="#addr_id#">
			<table>
				<tr>
					<td>
						<label for="addr_type">Address Type</label>
						<select name="addr_type" id="addr_type" size="1">
							<cfloop query="ctAddrType">
							<option
								<cfif addrtype is ctAddrType.addr_type> selected="selected" </cfif>
								value="#ctAddrType.addr_type#">#ctAddrType.addr_type#</option>
							</cfloop>
						</select>
					</td>
					<td>
						<label for="job_title">Job Title</label>
						<input type="text" name="job_title" id="job_title" value="#job_title#">
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="institution">Institution</label>
						<input type="text" name="institution" id="institution" size="50"  value="#institution#">
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="department">Department</label>
						<input type="text" name="department" id="department" size="50"  value="#department#">
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="street_addr1">Street Address 1</label>
						<input type="text" name="street_addr1" id="street_addr1" size="50" class="reqdClr" value="#street_addr1#">
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="street_addr2">Street Address 2</label>
						<input type="text" name="street_addr2" id="street_addr2" size="50" value="#street_addr2#">
					</td>
				</tr>
				<tr>
					<td>
						<label for="city">City</label>
						<input type="text" name="city" id="city" class="reqdClr" value="#city#">
					</td>
					<td>
						<label for="state">State</label>
						<input type="text" name="state" id="state" class="reqdClr" value="#state#">
					</td>
				</tr>
				<tr>
					<td>
						<label for="zip">Zip</label>
						<input type="text" name="zip" id="zip" class="reqdClr" value="#zip#">
					</td>
					<td>
						<script>
						function handleCountrySelect(){
						   var countrySelection =  $('input:radio[name=country]:checked').val();
						   if (countrySelection == 'USA') {
						      $("##textUS").css({"color": "black", "font-weight":"bold" });
						      $("##other_country_cde").toggle("false");
						      $("##country_cde").val("USA");
						      $("##other_country_cde").removeClass("reqdClr");
						   } else {
						      $("##textUS").css({"color": "##999999", "font-weight": "normal" });
						      $("##other_country_cde").toggle("true");
						      $("##country_cde").val($("##other_country_cde").val());
						      $("##other_country_cde").addClass("reqdClr");
						   }
						}
						</script>
							<cfif country_cde EQ 'USA'>
								<cfset usaChecked = "checked='checked'">
								<cfset otherChecked = "">
								<cfset otherStyle = "style='display: none;'">
							<cfelse>
								<cfset otherChecked = "checked='checked'">
								<cfset usaChecked = "">
								<cfset otherStyle = "">
							</cfif>
				                     <label for="country_cde">Country <img src="/images/icon_info.gif" border="0" onclick="getMCZDocs('Country_Name_List')" class="likeLink" style="margin-top: -10px;" alt="[ help ]"></label>
				                     <span>
				                     <input type="hidden" name="country_cde" id="country_cde" class="reqdClr" value="#country_cde#">
				                     <input type="radio" name="country" value="USA" onclick="handleCountrySelect();" #usaChecked# ><span id="textUS" style="color: black; font-weight: bold">USA</span>
				                     <input type="radio" name="country" value="other" onclick="handleCountrySelect();" #otherChecked# ><span id="textOther">Other</span>
				                     <input type="text" name="other_country_cde" id="other_country_cde" onblur=" $('##country_cde').val($('##other_country_cde').val());" #otherStyle# value="#country_cde#" >
				                     <span>
					</td>
				</tr>
				<tr>
					<td>
						<label for="mail_stop">Mail Stop</label>
						<input type="text" name="mail_stop" id="mail_stop" value="#mail_stop#">
					</td>
					<td>
						<label for="valid_addr_fg">Valid?</label>
						<select name="valid_addr_fg" id="valid_addr_fg" size="1">
							<option <cfif validfg IS "1"> selected="selected" </cfif>value="1">yes</option>
							<option <cfif validfg IS "0"> selected="selected" </cfif>value="0">no</option>
						</select>
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<label for="addr_remarks">Address Remark</label>
						<input type="text" name="addr_remarks" id="addr_remarks" size="50" value="#addr_remarks#">
					</td>
				</tr>
				<tr>
					<td colspan="2">
						<input type="submit" class="savBtn" value="Save Edits">
					</td>
				</tr>
			</table>
		</form>
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif #Action# is "saveEditsAddr">
	<cfoutput>
		<cfquery name="editAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE addr SET
				STREET_ADDR1 = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#STREET_ADDR1#'>
				,STREET_ADDR2 = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#STREET_ADDR2#'>
				,department = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#department#'>
				,institution = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#institution#'>
				,CITY = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#CITY#'>
				,STATE = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#STATE#'>
				,ZIP = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#ZIP#'>
				,COUNTRY_CDE = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#COUNTRY_CDE#'>
				,MAIL_STOP = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#MAIL_STOP#'>
				,AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#AGENT_ID#">
				,ADDR_TYPE = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#ADDR_TYPE#'>
				,JOB_TITLE = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#JOB_TITLE#'>
				,VALID_ADDR_FG = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#VALID_ADDR_FG#'>
				,ADDR_REMARKS = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#ADDR_REMARKS#'>
			where addr_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#addr_id#">
</cfquery>
<cflocation url="editAllAgent.cfm?agent_id=#agent_id#">
</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif #Action# is "deleteAddr">
	<cfoutput>
		<cfquery name="killAddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from addr where addr_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#addr_id#">
		</cfquery>
		<cflocation url="editAllAgent.cfm?agent_id=#agent_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif #Action# is "saveCurrentAddress">
	<cfoutput>
		<cftransaction>
			<cfquery name="addr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE addr SET
					addr_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#addr_id#">
				 	,STREET_ADDR1 = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#STREET_ADDR1#'>
				 	,institution = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#institution#'>
					,department = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#department#'>
				 	,STREET_ADDR2 = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#STREET_ADDR2#'>
				 	,CITY = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#CITY#'>
				 	,state = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#state#'>
					,ZIP = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#ZIP#'>
				 	,COUNTRY_CDE = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#COUNTRY_CDE#'>
				 	,MAIL_STOP = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#MAIL_STOP#'>
				 where addr_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#addr_id#">
			</cfquery>
			<cfquery name="elecaddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE electronic_address
				SET
					AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
					,ELECTRONIC_ADDR = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#ELECTRONIC_ADDR#'>
					,address_type=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#address_type#'>
				where
					AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
			</cfquery>
		</cftransaction>
		<cflocation url="editAllAgent.cfm?agent_id=#agent_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------>
<cfif #Action# is "newElecAddr">
	<cfoutput>
	<cfquery name="elecaddr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		INSERT INTO electronic_address (
			AGENT_ID
			,address_type
		 	,address
		 ) VALUES (
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
			,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#address_type#'>
		 	,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#address#'>
		)
	</cfquery>
	<cflocation url="editAllAgent.cfm?agent_id=#agent_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------>
<cfif #Action# is "newAddress">
	<cfoutput>
		<cfquery name="prefName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select agent_name from preferred_agent_name where agent_id=#agent_id#
		</cfquery>
		<cfquery name="addr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO addr (
                                ADDR_ID
                                ,STREET_ADDR1
                                ,STREET_ADDR2
                                ,institution
                                ,department
                                ,CITY
                                ,state
                                ,ZIP
                                ,COUNTRY_CDE
                                ,MAIL_STOP
                                ,agent_id
                                ,addr_type
                                ,job_title
                                ,valid_addr_fg
                                ,addr_remarks
                        ) VALUES (
                                 sq_addr_id.nextval
                                ,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#STREET_ADDR1#'>
                                ,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#STREET_ADDR2#'>
                                ,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#institution#'>
                                ,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#department#'>
                                ,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#CITY#'>
                                ,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#state#'>
                                ,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#ZIP#'>
                                ,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#COUNTRY_CDE#'>
                                ,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#MAIL_STOP#'>
                                ,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
                                ,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#addr_type#'>
                                ,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#job_title#'>
                                ,<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#valid_addr_fg#">
                                ,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#addr_remarks#'>
                        )
		</cfquery>
		<cflocation url="editAllAgent.cfm?agent_id=#agent_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif #Action# is "addRelationship">
	<cfoutput>
		<cfif len(#newRelatedAgentId#) is 0>
			Pick an agent, then click the button.
			<cfabort>
		</cfif>
		<cfquery name="newReln" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO agent_relations (
				AGENT_ID,
				RELATED_AGENT_ID,
				AGENT_RELATIONSHIP)
			VALUES (
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newRelatedAgentId#">,
				<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#relationship#'>)
		</cfquery>
		<cflocation url="editAllAgent.cfm?agent_id=#agent_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif #Action# is "deleteRelated">
	<cfoutput>
	<cfquery name="killRel" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		delete from agent_relations where
			agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
			and related_agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_agent_id#">
			and agent_relationship = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#relationship#'>
	</cfquery>
<cflocation url="editAllAgent.cfm?agent_id=#agent_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif #Action# is "deleteGroupMember">
	<cfoutput>
	<cfquery name="killGrpMem" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		DELETE FROM group_member
		WHERE
			GROUP_AGENT_ID =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
		AND
			MEMBER_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#MEMBER_AGENT_ID#">
	</cfquery>
	<cflocation url="editAllAgent.cfm?agent_id=#agent_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif #Action# is "changeRelated">
	<cfoutput>
		<cfquery name="changeRelated" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE agent_relations SET
				related_agent_id =
					<cfif len(#newRelatedAgentId#) gt 0>
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#newRelatedAgentId#">
					  <cfelse>
					  	<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_agent_id#">
					</cfif>
				, agent_relationship=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#relationship#'>
			WHERE agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
				AND related_agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#related_agent_id#">
				AND agent_relationship=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#oldRelationship#'>
		</cfquery>
		<cflocation url="editAllAgent.cfm?agent_id=#agent_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif #Action# is "newName">
	<cfoutput>
		<cfquery name="updateName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			INSERT INTO agent_name (
				agent_name_id,
				agent_id,
				agent_name_type,
				agent_name)
			VALUES (
				sq_agent_name_id.nextval,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">,
				<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agent_name_type#'>,
				<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agent_name#'>)
		</cfquery>
		<cflocation url="editAllAgent.cfm?agent_id=#agent_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif #Action# is "updateName">
	<cfoutput>
		<cfquery name="updateName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			UPDATE agent_name
			SET
				agent_name = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agent_name#'>,
				agent_name_type=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agent_name_type#'>
			where
				agent_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_name_id#">
		</cfquery>
		<cflocation url="editAllAgent.cfm?agent_id=#agent_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif #Action# is "deleteName">
	<cfoutput>
		<cfquery name="delId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT
				PROJECT_AGENT.AGENT_NAME_ID,
				PUBLICATION_AUTHOR_NAME.AGENT_NAME_ID,
				project_sponsor.AGENT_NAME_ID
			FROM
				PROJECT_AGENT,
				PUBLICATION_AUTHOR_NAME,
				project_sponsor,
				agent_name
			WHERE
				agent_name.agent_name_id = PROJECT_AGENT.AGENT_NAME_ID (+) and
				agent_name.agent_name_id = PUBLICATION_AUTHOR_NAME.AGENT_NAME_ID  (+) and
				agent_name.agent_name_id = project_sponsor.AGENT_NAME_ID  (+) and
				agent_name.agent_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_name_id#">
		</cfquery>
		<cfif #delId.recordcount# gt 1>
			The agent name you are trying to delete is active.<cfabort>
		</cfif>
		<cfquery name="deleteAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			DELETE FROM agent_name
			WHERE agent_name_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_name_id#">
		</cfquery>
		<cflocation url="editAllAgent.cfm?agent_id=#agent_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif #Action# is "editPerson">
	<cfoutput>
		<cftransaction>
			<cfquery name="editPerson" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE person SET
					person_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
			<cfif len(#first_name#) gt 0>
				,first_name=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#first_name#'>
			<cfelse>
				,first_name=null
			</cfif>
			<cfif len(#prefix#) gt 0>
				,prefix=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#prefix#'>
			<cfelse>
				,prefix=null
			</cfif>
			<cfif len(#middle_name#) gt 0>
				,middle_name=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#middle_name#'>
			<cfelse>
				,middle_name=null
			</cfif>
			<cfif len(#last_name#) gt 0>
				,last_name=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#last_name#'>
			<cfelse>
				,last_name=null
			</cfif>
			<cfif len(#suffix#) gt 0>
				,suffix=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#suffix#'>
			<cfelse>
				,suffix=null
			</cfif>
			<cfif len(#birth_date#) gt 0>
				,birth_date=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#birth_date#'>
			  <cfelse>
			  	,birth_date=null
			</cfif>
			<cfif len(#death_date#) gt 0>
				,death_date=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#death_date#'>
			  <cfelse>
			  	,death_date=null
			</cfif>
				WHERE
					person_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
			</cfquery>
			<cfquery name="updateAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE agent SET
					edited=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#editedPerson#'>
					<cfif len(#biography#) gt 0>
						, biography = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#biography#'>
					<cfelse>
					  	, biography = null
					</cfif>
					<cfif len(#agent_remarks#) gt 0>
						, agent_remarks = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agent_remarks#'>
					<cfelse>
					  	, agent_remarks = null
					</cfif>
					<cfif len(#agentguid_guid_type#) gt 0>
						, agentguid_guid_type = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agentguid_guid_type#'>
					<cfelse>
					  	, agentguid_guid_type = null
					</cfif>
					<cfif len(#agentguid#) gt 0>
						, agentguid = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agentguid#'>
					<cfelse>
					  	, agentguid = null
					</cfif>
				WHERE
					agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
			</cfquery>
		</cftransaction>
	<cflocation url="editAllAgent.cfm?agent_id=#agent_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif #Action# is "editNonPerson">
	<cfif not isdefined("agentguid")><cfset agentguid=""></cfif>
	<cfif not isdefined("agentguid_guid_type")><cfset agentguid_guid_type=""></cfif>
	<cfoutput>
		<cftransaction>
			<cfquery name="updateAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE agent SET
					edited=<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#editedPerson#'>
					<cfif len(#biography#) gt 0>
						, biography = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#biography#'>
					<cfelse>
					  	, biography = null
					</cfif>
					<cfif len(#agent_remarks#) gt 0>
						, agent_remarks = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agent_remarks#'>
					<cfelse>
					  	, agent_remarks = null
					</cfif>
					<cfif len(#agentguid_guid_type#) gt 0>
						, agentguid_guid_type = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agentguid_guid_type#'>
					<cfelse>
					  	, agentguid_guid_type = null
					</cfif>
					<cfif len(#agentguid#) gt 0>
						, agentguid = <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agentguid#'>
					<cfelse>
					  	, agentguid = null
					</cfif>
				WHERE
					agent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#">
			</cfquery>
		</cftransaction>
	<cflocation url="editAllAgent.cfm?agent_id=#agent_id#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif #action# is "makeNewGroupMemeber">
	<cfquery name="newGroupMember" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		INSERT INTO group_member
			(GROUP_AGENT_ID,
			MEMBER_AGENT_ID,
			MEMBER_ORDER)
		values
			(<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#agent_id#'>,
			<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#member_id#'>,
			<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#MEMBER_ORDER#'>
		)
	</cfquery>
	<cflocation url="editAllAgent.cfm?agent_id=#agent_id#">
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif action is "insertPerson">
	<!--- Deprecated, replaced by /agents/editAgent.cfm --->
	<cfoutput>
		<cftransaction>
			<cfquery name="agentID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_agent_id.nextval nextAgentId from dual
			</cfquery>
			<cfquery name="agentNameID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_agent_name_id.nextval nextAgentNameId from dual
			</cfquery>
			<cfquery name="insPerson" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO agent (
					agent_id,
					agent_type,
					preferred_agent_name_id
					<cfif len(#agentguid_guid_type#) gt 0>
						,agentguid_guid_type
					</cfif>
					<cfif len(#agentguid#) gt 0>
						,agentguid
					</cfif>
					)
				VALUES (
					<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#agentID.nextAgentId#'>,
					'person',
					<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value='#agentNameID.nextAgentNameId#'>
					<cfif len(#agentguid_guid_type#) gt 0>
						,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#agentguid_guid_type#">
					</cfif>
					<cfif len(#agentguid#) gt 0>
						,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#agentguid#">
					</cfif>
				)
			</cfquery>
			<cfquery name="insPerson" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO person (
					PERSON_ID
					<cfif len(#prefix#) gt 0>
						,prefix
					</cfif>
					<cfif len(#LAST_NAME#) gt 0>
						,LAST_NAME
					</cfif>
					<cfif len(#FIRST_NAME#) gt 0>
						,FIRST_NAME
					</cfif>
					<cfif len(#MIDDLE_NAME#) gt 0>
						,MIDDLE_NAME
					</cfif>
					<cfif len(#SUFFIX#) gt 0>
						,SUFFIX
					</cfif>
					)
				VALUES
					(<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value="#agentID.nextAgentId#">
					<cfif len(#prefix#) gt 0>
						,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#prefix#'>
					</cfif>
					<cfif len(#LAST_NAME#) gt 0>
						,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#LAST_NAME#'>
					</cfif>
					<cfif len(#FIRST_NAME#) gt 0>
						,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#FIRST_NAME#'>
					</cfif>
					<cfif len(#MIDDLE_NAME#) gt 0>
						,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#MIDDLE_NAME#'>
					</cfif>
					<cfif len(#SUFFIX#) gt 0>
						,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#SUFFIX#'>
					</cfif>
					)
			</cfquery>
			<cfif len(pref_name) is 0>
				<cfset name = "">
				<cfif len(#prefix#) gt 0>
					<cfset name = "#name# #prefix#">
				</cfif>
				<cfif len(#FIRST_NAME#) gt 0>
					<cfset name = "#name# #FIRST_NAME#">
				</cfif>
				<cfif len(#MIDDLE_NAME#) gt 0>
					<cfset name = "#name# #MIDDLE_NAME#">
				</cfif>
				<cfif len(#LAST_NAME#) gt 0>
					<cfset name = "#name# #LAST_NAME#">
				</cfif>
				<cfif len(#SUFFIX#) gt 0>
					<cfset name = "#name# #SUFFIX#">
				</cfif>
				<cfset pref_name = #trim(name)#>
			</cfif>
			<cfif not isdefined("ignoreDupChek") or ignoreDupChek is false>
				<cfquery name="dupPref" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select agent.agent_type,agent_name.agent_id,agent_name.agent_name
						from agent_name, agent
						where agent_name.agent_id = agent.agent_id
							and upper(agent_name.agent_name) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(pref_name)#%'>
				</cfquery>
				<cfif dupPref.recordcount gt 0>
                    <div style="padding: 1em;width: 75%;">
                        <h3>That agent may already exist!</h3>
                        <p>The name you entered is either a preferred name or other name for an existing agent.</p>
                        <p>A duplicated preferred name will prevent MCZbase from functioning normally.
                        </p>
                        <p>Click duplicated names below to see details. Add the fullest version of the name if it can be differentiated from another. If the need for a duplicate agent should arise, please merge the pre-existing matches (bad duplicates) so they will not create problems.</p>
					<cfloop query="dupPref">
						<br><a href="/agents/Agent.cfm?agent_id=#agent_id#">#agent_name# (agent ID ## #agent_id# - #agent_type#)</a>
					</cfloop>
					<p>Are you sure you want to continue?</p>
					<form name="ac" method="post" action="editAllAgent.cfm">
						<input type="hidden" name="action" value="insertPerson">
						<input type="hidden" name="prefix" value="#prefix#">
						<input type="hidden" name="LAST_NAME" value="#LAST_NAME#">
						<input type="hidden" name="FIRST_NAME" value="#FIRST_NAME#">
						<input type="hidden" name="MIDDLE_NAME" value="#MIDDLE_NAME#">
						<input type="hidden" name="SUFFIX" value="#SUFFIX#">
						<input type="hidden" name="pref_name" value="#pref_name#">
						<input type="hidden" name="ignoreDupChek" value="true">
						<input type="submit" class="insBtn" value="Create Agent">

					</form>
                      <br><br>
                         <input type="cancel" value="Cancel" class="insBtn" style="background-color: ##ffcc00;border: 1px solid ##336666; width: 42px;" onclick="javascript:window.location='';return false;">
					<cfabort>


                        </div>
				</cfif>
			</cfif>
			<cfquery name="insName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO agent_name (
					agent_name_id,
					agent_id,
					agent_name_type,
					agent_name,
					donor_card_present_fg)
				VALUES (
					<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value="#agentNameID.nextAgentNameId#">,
					<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value="#agentID.nextAgentId#">,
					'preferred',
					<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#pref_name#'>,
					0
					)
			</cfquery>
		</cftransaction>
		<cflocation url="editAllAgent.cfm?agent_id=#agentID.nextAgentId#">
	</cfoutput>
</cfif>
<!------------------------------------------------------------------------------------------------------------->
<cfif #Action# is "makeNewAgent">
	<!--- Deprecated, replaced by /agents/editAgent.cfm --->
	<cfif not isdefined("agentguid")><cfset agentguid=""></cfif>
	<cfif not isdefined("agentguid_guid_type")><cfset agentguid_guid_type=""></cfif>
	<cfoutput>
		<cftransaction>
			<cfquery name="agentID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_agent_id.nextval nextAgentId from dual
			</cfquery>
			<cfquery name="agentNameID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				select sq_agent_name_id.nextval nextAgentNameId from dual
			</cfquery>
			<cfquery name="insAgent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO agent (
					agent_id,
					agent_type,
					preferred_agent_name_id
					<cfif len(#agent_remarks#) gt 0>
						,agent_remarks
					</cfif>
					<cfif len(#agentguid_guid_type#) gt 0>
						,agentguid_guid_type
					</cfif>
					<cfif len(#agentguid#) gt 0>
						,agentguid
					</cfif>
					)
				VALUES (
					<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value="#agentID.nextAgentId#">,
					<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agent_type#'>,
					<cfqueryparam cfsqltype='CF_SQL_DECIMAL' value="#agentNameID.nextAgentNameId#">
					<cfif len(#agent_remarks#) gt 0>
						,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agent_remarks#'>
					</cfif>
					<cfif len(#agentguid_guid_type#) gt 0>
						,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#agentguid_guid_type#">
					</cfif>
					<cfif len(#agentguid#) gt 0>
						,<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value="#agentguid#">
					</cfif>
					)
			</cfquery>
			<cfif not isdefined("ignoreDupChek") or ignoreDupChek is false>
				<cfquery name="dupPref" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					select agent_id,agent_name
					from agent_name
					where upper(agent_name) like <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='%#ucase(agent_name)#%'>
				</cfquery>
				<cfif dupPref.recordcount gt 0>
					<p>That agent may already exist! Click to see details.</p>
					<cfloop query="dupPref">
						<br><a href="/agents/Agent.cfm?agent_id=#agent_id#">#agent_name#</a>
					</cfloop>
					<p>Are you sure you want to continue?</p>
					<form name="ac" method="post" action="editAllAgent.cfm">
						<input type="hidden" name="action" value="makeNewAgent">
						<input type="hidden" name="agent_remarks" value="#agent_remarks#">
						<input type="hidden" name="agent_type" value="#agent_type#">
						<input type="hidden" name="agent_name" value="#agent_name#">
						<input type="hidden" name="ignoreDupChek" value="true">
						<input type="submit" class="insBtn" value="Of course. I carefully checked for duplicates before creating this agent.">
						<br><input type="button" class="qutBtn" onclick="back()" value="Oh - back one step, please.">
					</form>
					<cfabort>
				</cfif>
			</cfif>
			<cfquery name="insName" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				INSERT INTO agent_name (
					agent_name_id,
					agent_id,
					agent_name_type,
					agent_name,
					donor_card_present_fg)
				VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agentNameID.nextAgentNameId#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agentID.nextAgentId#">,
					'preferred',
					<cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#agent_name#'>,
					0
					)
			</cfquery>
		</cftransaction>
		<cflocation url="editAllAgent.cfm?agent_id=#agentID.nextAgentId#">
	</cfoutput>
</cfif>
<script>
	parent.resizeCaller();
</script>
<cfoutput>
<cfif action is "nothing">
<script type="text/javascript" language="javascript">
	if (top.location==document.location) {
    	top.location='/agents/editAgent.cfm?agent_id=#agent_id#';
	}
</script>
</cfif>
</cfoutput>
<!------------------------------------------------------------------------------------------------------------->
<cfinclude template="includes/_pickFooter.cfm">
