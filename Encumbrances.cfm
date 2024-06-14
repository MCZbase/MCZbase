<cfinclude template="includes/_header.cfm">
    <div id="encumbranceBox1">
<script language="javascript" type="text/javascript">
	jQuery(document).ready(function() {
		jQuery("#made_date_after").datepicker();
		jQuery("#made_date_before").datepicker();
		jQuery("#expiration_date_after").datepicker();	
		jQuery("#made_date").datepicker();
		jQuery("#expiration_date_before").datepicker();
		jQuery("#expiration_date").datepicker();
	});
</script>
<cfif not isdefined("collection_object_id")>
	<cfset collection_object_id="">
</cfif>
<cfquery name="ctEncAct" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT encumbrance_action 
	FROM ctencumbrance_action 
	ORDER BY encumbrance_action
</cfquery>
<!--- TODO: This page incorporates both managing encumbrances, which needs redesign, and managing cataloged items in encumbrances, which has been moved to a manage page, 
  but not disentangled from this page yet, so not all functionality here needs to be moved into a redesigned find/create/edit encumbrances page.
--->
<!---------------------------------------------------------------------------->
<cfif action is "create">
	<strong><br>Create a new encumbrance.</strong>
	<cfset title="Create Encumbrance">
	<cfoutput>
		<form name="encumber" method="post" action="Encumbrances.cfm" onSubmit=" return validateForm(); ">
			<input type="hidden" name="action" value="createEncumbrance">
			<label for="encumberingAgent" class="likeLink" onclick="getDocs('encumbrance','encumbrancer')">
				Encumbering Agent
			</label>
			<input type="text" name="encumberingAgent" id="encumberingAgent" class="reqdClr" required
				onchange="getAgent('encumberingAgentId','encumberingAgent','encumber',this.value); return false;"
			  	onKeyPress="return noenter(event);">
			<input type="hidden" name="encumberingAgentId" id="encumberingAgentId"> 
			<label for="made_date">Made Date</label>
			<input type="text" name="made_date" id="made_date" class="reqdClr" required>
			<label for="expiration_date" class="likeLink" onclick="getDocs('encumbrance','expiration')">
				Expiration Date
			</label>
			<input type="text" name="expiration_date" id="expiration_date">
	        <label for="expiration_event" class="likeLink" onclick="getDocs('encumbrance','expiration')">
				Expiration Event
			</label>
			<input type="text" name="expiration_event" id="expiration_event">
			<label for="encumbrance" class="likeLink" onclick="getDocs('encumbrance','encumbrance_name')">
				Encumbrance
			</label>
			<input type="text" name="encumbrance" id="encumbrance" size="50" class="reqdClr" required>
			<label for="encumbrance_action">Encumbrance Action</label>
	        <select name="encumbrance_action" id="encumbrance_action" size="1" class="reqdClr" required>
	            <cfloop query="ctEncAct">
	              <option value="#ctEncAct.encumbrance_action#">#ctEncAct.encumbrance_action#</option>
	            </cfloop>
	         </select>
			<label for="remarks">Remarks</label>
			<textarea name="remarks" rows="3" cols="50"></textarea>
			<br>
			<input type="submit" 
				value="Create New Encumbrance"
				class="insBtn">
			<script>
				function validateForm() { 
					var status = true;
					if ($("##encumberingAgentId").val()=="") { 
						alert("Error: You must pick an Encumbering Agent");
						status = false;
					} 
					if ($("##expiration_date").val()!="" && $("##expiration_event").val()!="") { 
						alert("Error: You may specify an expiration event or an expiration date, but not both.");
						status = false;
					} 
					return status;
				};
			</script>
		</form>
	</cfoutput>
</cfif>
<!-------------------------------------------------->
<cfif action is "nothing">
	<cfoutput>
		<cfset title = "Search for specimens or encumbrances">
		<p>
			<cfif len(collection_object_id) gt 0>
				<!--- Note: We shouldn't reach this block now, manage encumbrances has been moved to manage by result_id --->
				Now find an encumbrance to apply to the specimens below. If you need a new encumbrance, create it
				first then come back here.
			<cfelse>
				Locate Encumbrances (or <a href="/Encumbrances.cfm?action=create">Create a new encumbrance</a>)
			</cfif>
		</p>
		<cfform name="encumber" method="post" action="Encumbrances.cfm">
			<input type="hidden" name="Action" value="listEncumbrances">
			<input type="hidden" name="collection_object_id" value="#collection_object_id#">
			<label for="">Encumbering Agent</label>
			<input name="encumberingAgent" id="encumberingAgent" type="text">
			<label for="made_date_after">Made Date After</label>
			<input type="text" name="made_date_after" id="made_date_after">
			<label for="made_date_before">Made Date Before</label>
			<input type="text" name="made_date_before" id="made_date_before">
			<label for="expiration_date_after">Expiration Date After</label>
			<input type="text" name="expiration_date_after" id="expiration_date_after">
			<label for="expiration_date_before">Expiration Date Before</label>
			<input type="text" name="expiration_date_before" id="expiration_date_before">
			<label for="expiration_event">Expiration Event</label>
			<input type="text" id="expiration_event" name="expiration_event">
			<label for="encumbrance">Encumbrance Event</label>
			<input type="text" name="encumbrance" id="encumbrance">
			<label for="encumbrance_action">Encumbrance Action</label>
			<select name="encumbrance_action" id="encumbrance_action" size="1">
				<option value=""></option>
				<cfloop query="ctEncAct">
					<option value="#ctEncAct.encumbrance_action#">#ctEncAct.encumbrance_action#</option>
				</cfloop>
			</select>
			<label for="remarks">Remarks</label>
			<textarea name="remarks" id="remarks" rows="3" cols="50"></textarea>
			<br><input type="submit" value="Find Encumbrance" class="schBtn">
		</cfform>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------->
<cfif action is "createEncumbrance">
	<cfoutput>
		<cfif not isDefined("encumberingAgentId") OR len(encumberingAgentId) EQ 0>
			<cfthrow message="No Encumbering Agent Provided.  You must select an agent.">
		</cfif>
		<cfif not isDefined("ENCUMBRANCE_ACTION") OR len(ENCUMBRANCE_ACTION) EQ 0>
			<cfthrow message="No Encubrance Action provided.  You must specify an Action.">
		</cfif>
		<cfif not isDefined("ENCUMBRANCE") OR len(ENCUMBRANCE) EQ 0>
			<cfthrow message="No Encubrance Name provided.  You must provide a descriptive name for the Encumbrance..">
		</cfif>
		<cfquery name="nextEncumbrance" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT sq_encumbrance_id.nextval nextEncumbrance FROM dual
		</cfquery>
		<cfquery name="newEncumbrance" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			INSERT INTO encumbrance (
				ENCUMBRANCE_ID,
				ENCUMBERING_AGENT_ID,
				ENCUMBRANCE,
				ENCUMBRANCE_ACTION
				<cfif len(#expiration_date#) gt 0>
					,EXPIRATION_DATE	
				</cfif>
				<cfif len(#EXPIRATION_EVENT#) gt 0>
					,EXPIRATION_EVENT	
				</cfif>
				<cfif len(#MADE_DATE#) gt 0>
					,MADE_DATE	
				</cfif>
				<cfif len(#REMARKS#) gt 0>
					,REMARKS	
				</cfif>
			) VALUES (
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextEncumbrance.nextEncumbrance#">,
				<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumberingAgentId#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ENCUMBRANCE#">,
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ENCUMBRANCE_ACTION#">
				<cfif len(#expiration_date#) gt 0>
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#dateformat(EXPIRATION_DATE,"yyyy-mm-dd")#">
				</cfif>
				<cfif len(#EXPIRATION_EVENT#) gt 0>
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#EXPIRATION_EVENT#">
				</cfif>
				<cfif len(#MADE_DATE#) gt 0>
					,<cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateformat(MADE_DATE,"yyyy-mm-dd")#">
				</cfif>
				<cfif len(#REMARKS#) gt 0>
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#REMARKS#">
				</cfif>
				)
		</cfquery>
		<cflocation url="Encumbrances.cfm?action=listEncumbrances&encumbrance_id=#nextEncumbrance.nextEncumbrance#" addtoken="false">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------->
<cfif action is "listEncumbrances">
    <style>
.oddRow{
    background-color: #fff;
    margin: .5em 0;
    border: 1px dotted #666;
    font-size: smaller;
    display: block;
    padding: .5em .8em;
}
.evenRow {
    background-color: #f8f8f8;
    margin: .5em 0;
    border: 1px dotted #666;
    font-size: smaller;
    padding: .5em .8em;
    display: block;
}
 span.lnkBtn, a.lnkBtn {
    color: #666666;
	font-size: 12px;
	font-weight: bold;
	padding: 2px 5px;
	background-color: #99CCFF;
	border: 1px solid #336666;
	border-radius: 5px;
  /*  margin-right: .5em;*/
}
span.delBtn {
    color: #666666;
	font-size:12px;
	font-weight: bold;
	padding: 2px 5px;
	background-color: #FF9966;
	border: 1px solid #336666;
	border-radius: 5px;
    margin-right: .5em;
        }
span.savBtn {
    color: #666666;
	font-size:12px;
	font-weight: bold;
	padding: 2px 5px;
	background-color: #FBD29B;
	border: 1px solid;
	border-color: #336666;
    border-radius: 5px;
    width: auto;
    margin-right: .5em;
}
a.qutBtn {
  border-radius: 5px;
	border: 1px solid #666;
	padding: 1px 5px;
	cursor: pointer;
    color: #666;
    font-weight: bold;
    background-color: #FF9966;
	border-color: #336666;
 }
#encumbranceBox1 li {list-style: none;}
  </style>
	<cfset title="Encumbrance Search Results">
	<a href="Encumbrances.cfm" style="margin-left: 3em;">Back to Search Encumbrances</a>
	<br>
	<cfoutput>
		<cfquery name="getEnc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT 
				count(coll_object_encumbrance.collection_object_id) as object_count,
				encumbrance.encumbrance_id,
				encumbrance.encumbrance,
				encumbrance.encumbrance_action,
				preferred_agent_name.agent_name,
				encumbrance.made_date,
				encumbrance.expiration_date,
				encumbrance.expiration_event,
				encumbrance.remarks
			FROM 
				encumbrance 
				left join preferred_agent_name on encumbrance.encumbering_agent_id = preferred_agent_name.agent_id
				<cfif isdefined("encumberingAgent") and len(encumberingAgent) gt 0>
					left join agent_name on encumbrance.encumbering_agent_id = agent_name.agent_id
				</cfif>
				left join coll_object_encumbrance on encumbrance.encumbrance_id = coll_object_encumbrance.encumbrance_id
			WHERE
				encumbrance.encumbrance_id is not null
		<cfif isdefined("encumberingAgent") and len(encumberingAgent) gt 0>
				AND upper(agent_name.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(encumberingAgent)#%">	
		</cfif>
		<cfif isdefined("made_date_after") and len(#made_date_after#) gt 0>
				AND made_date >= to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#made_date_after#">)
		</cfif>
		<cfif isdefined("made_date_before") and len(#made_date_before#) gt 0>
				AND made_date <= to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#made_date_before#">)
		</cfif>
		<cfif isdefined("expiration_date_after") and len(#expiration_date_after#) gt 0>
				AND expiration_date >= to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#expiration_date_after#">)
		</cfif>
		<cfif isdefined("expiration_date_before") and len(#expiration_date_before#) gt 0>
				AND expiration_date <= to_date(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#expiration_date_before#">)
		</cfif>
		<cfif isdefined("encumbrance_id") and len(encumbrance_id) gt 0>
				AND encumbrance.encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#">	
		</cfif>
		<cfif isdefined("encumbrance") and len(encumbrance) gt 0>
				AND upper(encumbrance) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(encumbrance)#%">	
		</cfif>
		<cfif isdefined("encumbrance_action") and len(encumbrance_action) gt 0>
				AND encumbrance_action = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#encumbrance_action#">	
		</cfif>
		<cfif isdefined("remarks") and len(remarks) gt 0>
				AND upper(remarks) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(remarks)#%">	
		</cfif>
			GROUP BY encumbrance.encumbrance_id,
				encumbrance.encumbrance,
				encumbrance.encumbrance_action,
				preferred_agent_name.agent_name,
				encumbrance.made_date,
				encumbrance.expiration_date,
				encumbrance.expiration_event,
				encumbrance.remarks
			ORDER BY encumbrance.encumbrance, preferred_agent_name.agent_name, encumbrance.made_date 
		</cfquery>
		<cfif getEnc.recordcount is 0>
			<div class="error">Nothing Found</div>
			<cfabort>
		</cfif>
		<cfset i = 1>
    <ul>
		<cfloop query="getEnc">
            <div #iif(i MOD 2,DE("class='evenRow'"),DE("class='oddRow'"))#>
			    <form name="listEnc#i#" method="post" action="Encumbrances.cfm">
				   <input type="hidden" name="Action">
				   <input type="hidden" name="encumbrance_id" value="#encumbrance_id#">
				   <input type="hidden" name="collection_object_id" value="#collection_object_id#">
           
                  <li>  
                      #i#. &nbsp; <span style="font-weight: bold;"> #encumbrance# (#encumbrance_action#) </span> <span style="color: ##666; font-style: italic;"> by #agent_name# made #dateformat(made_date,"yyyy-mm-dd")#,</span><span style="color: ##666"> expires:  #dateformat(expiration_date,"yyyy-mm-dd")# #expiration_event# #remarks# (#object_count# items)</span>
				<div style="margin-top: .25em;margin-left: 0em;text-align:right;margin-bottom:.2em;">
				<cfif len(collection_object_id) gt 0>
					<span class="likeLink picBtn" style="display:inline-block;margin-bottom: .45em;width:auto;" onclick="listEnc#i#.Action.value='saveEncumbrances';listEnc#i#.submit();">
						Add All Items To This Encumbrance
                    </span> 
					<span class="likeLink picBtn" onclick="listEnc#i#.Action.value='remListedItems';listEnc#i#.submit();">
						Remove Listed Items From This Encumbrance
					</span>
                    <br>
				</cfif>
				<span class="likeLink savBtn" onclick="listEnc#i#.Action.value='deleteEncumbrance';confirmDelete('listEnc#i#');">
					Delete This Encumbrance
				</span>
				<span class="likeLink lnkBtn" style="margin-right: .5em;background-color:##ffffcc;" onclick="listEnc#i#.Action.value='updateEncumbrance';listEnc#i#.submit();">
					Modify This Encumbrance
				</span>
				<a href="/SpecimenResults.cfm?encumbrance_id=#encumbrance_id#" class="lnkBtn">See Specimens</a>
				<a href="/Admin/deleteSpecByEncumbrance.cfm?encumbrance_id=#encumbrance_id#" class="qutBtn"> Delete Encumbered Specimens</a>
                    
                    </li>
                           
			</form>
			</div>
			<cfset i = #i#+1>
		</cfloop>
             </ul>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------->
<cfif #Action# is "remListedItems">
	<cfoutput>
	<cfif len(encumbrance_id) is 0>
		No encumbrance_id provided!<cfabort>
	</cfif>
	<cfif len(collection_object_id) is 0>
		No collection_object_id provided!<cfabort>
	</cfif>
	<cftry>
	
	<cfloop index="i" 
		list="#collection_object_id#" 
		delimiters=",">
	
	<cfquery name="encSpecs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		DELETE FROM coll_object_encumbrance
		WHERE
			encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#">
		 	AND collection_object_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#i#">
	</cfquery>
	
	</cfloop>
	<cfcatch type="database">
		<cfdump var="#cfcatch#">
	</cfcatch>

	</cftry>
	<p>
		All items listed below have been removed from this encumbrance.
		 <a href="Encumbrances.cfm?action=listEncumbrances&encumbrance_id=#encumbrance_id#&collection_object_id=#collection_object_id#">Return to Encumbrance.</a>
	</p>
</cfoutput>	
</cfif>


<!-------------------------------------------------------------------------------------------->
<cfif #Action# is "updateEncumbrance">
<cfset title = "Update Encumbrance">
<cfoutput>

<p><a href="Encumbrances.cfm?action=listEncumbrances&encumbrance_id=#encumbrance_id#">Back to Encumbrance</a></p>
Edit Encumbrance:  [encumbrance_id = #encumbrance_id#]
<cfquery name="encDetails" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	SELECT
		 * 
	FROM
		encumbrance, 
		preferred_agent_name 
	WHERE 
		encumbering_agent_id = agent_id 
		AND encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#">
</cfquery>
</cfoutput>
<cfoutput query="encDetails">
<form name="updateEncumbrance" method="post" action="Encumbrances.cfm">
	<input type="hidden" name="Action" value="updateEncumbrance2">
	<input name="encumbrance_id" value="#encumbrance_id#" type="hidden">
	
	<table border="1">
		<tr>
			<td align="right">
			<a href="javascript:void(0);" 
				class="novisit" 
				onClick="getDocs('encumbrance','encumbrancer')">Encumbering Agent:</a></td>
				</td>
			<td><input type="hidden" name="encumberingAgentId" id="encumberingAgentId" value="#encumbering_agent_id#">
			
		<input type="text" name="encumberingAgent" class="reqdClr" value="#agent_name#"
		 onchange="getAgent('encumberingAgentId','encumberingAgent','updateEncumbrance',this.value); return false;"
		  onKeyPress="return noenter(event);">
		  </td>
			<td align="right">
				Made Date:
			</td>
			<td><input type="text" name="made_date" id="made_date" value="#dateformat(made_date,'yyyy-mm-dd')#"></td>
		</tr>
		<tr>
			<td align="right">
			<a href="javascript:void(0);" 
				class="novisit" 
				onClick="getDocs('encumbrance','expiration')">Expiration Date:</a>
				</td>
			<td><input type="text" name="expiration_date" id="expiration_date"  value="#dateformat(expiration_date,'yyyy-mm-dd')#"></td>
			<td align="right">
			<a href="javascript:void(0);" 
				class="novisit" 
				onClick="getDocs('encumbrance','expiration')">Expiration Event:</a>
			</td>
			<td><input type="text" name="expiration_event" value="#expiration_event#"></td>
		</tr>
		<tr>
			<td align="right">
			<a href="javascript:void(0);" 
				class="novisit" 
				onClick="getDocs('encumbrance','encumbrance_name')">Encumbrance:</a>
				</td>
			<td><input type="text" name="encumbrance" value="#encumbrance#"></td>
			<td align="right">Encumbrance Action</td>
			<td>
			<select name="encumbrance_action" size="1">
				<cfloop query="ctEncAct">
					<option 
						<cfif #ctEncAct.encumbrance_action# is "#encDetails.encumbrance_action#"> selected </cfif> value="#ctEncAct.encumbrance_action#">#ctEncAct.encumbrance_action#</option>
				</cfloop>
			
			</select>
			</td>
		</tr>
		<tr>
			<td align="right">Remarks:</td>
			<td colspan="3"><textarea name="remarks" rows="3" cols="50">#remarks#</textarea></td>
		</tr>
		<tr>
			<td colspan="4" align="center">
			
			<input type="submit" 
		value="Save Edits" 
		class="savBtn"
		onmouseover="this.className='savBtn btnhov'"
		onmouseout="this.className='savBtn'">
		
		<input type="button" 
		value="Quit" 
		class="qutBtn"
		onmouseover="this.className='qutBtn btnhov'"
		onmouseout="this.className='qutBtn'"
		onClick="document.location='Encumbrances.cfm'">
		
		
		</td>
		</tr>
	</table>
</form>
</cfoutput>

</cfif>
<!-------------------------------------------------------------------------------------------->
<cfif #Action# is "updateEncumbrance2">
	<cfoutput>
		<cfquery name="newEncumbrance" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			UPDATE encumbrance 
			SET
				encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#">
				,ENCUMBERING_AGENT_ID = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumberingAgentId#">
				,ENCUMBRANCE = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ENCUMBRANCE#">
				,ENCUMBRANCE_ACTION = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ENCUMBRANCE_ACTION#">
				<cfif len(expiration_date) gt 0>
					,EXPIRATION_DATE = <cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateformat(EXPIRATION_DATE,"yyyy-mm-dd")#">	
				<cfelse>
					,expiration_date=null
				</cfif>
				,EXPIRATION_EVENT = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#EXPIRATION_EVENT#">
				<cfif len(#MADE_DATE#) gt 0>
					,MADE_DATE = <cfqueryparam cfsqltype="CF_SQL_DATE" value="#dateformat(MADE_DATE,'yyyy-mm-dd')#">	
				</cfif>
				,REMARKS = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#REMARKS#">
			WHERE encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#">
		</cfquery>

		<cflocation url="Encumbrances.cfm?Action=updateEncumbrance&encumbrance_id=#encumbrance_id#">
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------------->
<!-------------------------------------------------------------------------------------------->
<cfif #Action# is "deleteEncumbrance">
<cfoutput>
	<cfif len(#encumbrance_id#) is 0>
		Didn't get an encumbrance_id!!<cfabort>
	</cfif>
	<cfquery name="isUsed" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select count(*) as cnt from coll_object_encumbrance where encumbrance_id=#encumbrance_id#
	</cfquery>
	<cfif #isUsed.cnt# gt 0>
		You can't delete this encumbrance because specimens are using it!<cfabort>
	</cfif>
	<cfquery name="deleteEnc" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		DELETE FROM encumbrance 
		WHERE encumbrance_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#">
	</cfquery>
	
	Deleted. 
	
	<a href="Encumbrances.cfm">Return to Encumbrances</a>

</cfoutput>	
</cfif>
<!-------------------------------------------------------------------------------------------->


<!-------------------------------------------------------------------------------------------->
<cfif #Action# is "saveEncumbrances">
<cfoutput>
	<cfif len(#encumbrance_id#) is 0>
		Didn't get an encumbrance_id!!<cfabort>
	</cfif>
	<cfif len(collection_object_id) is 0>
		Didn't get a collection_object_id!!<cfabort>
	</cfif>

	
	<cfloop index="i" 
		list="#collection_object_id#" 
		delimiters=",">
	
	<cfquery name="encSpecs" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		INSERT INTO coll_object_encumbrance (
			encumbrance_id, 
			collection_object_id
		) VALUES (
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#encumbrance_id#">,
			<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#i#">
		)
	</cfquery>
	
	</cfloop>
	<p>
		All items listed below have been encumbered.
		 <a href="Encumbrances.cfm?action=listEncumbrances&encumbrance_id=#encumbrance_id#&collection_object_id=#collection_object_id#">Return to Encumbrance.</a>
	</p>
</cfoutput>	
</cfif>
<!-------------------------------------------------------------------------------------------->
<!-------------------------------------------------------------------------------------------->
<cfif len(collection_object_id) gt 0>
	<Cfset title = "Encumber these specimens">
		<cfoutput>
			<cfquery name="getData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
				 SELECT 
					cataloged_item.collection_object_id as collection_object_id, 
					cat_num, 
					concatSingleOtherId(cataloged_item.collection_object_id,'#session.CustomOtherIdentifier#') AS CustomID,
					identification.scientific_name, 
					country, 
					state_prov, 
					county, 
					cataloged_item.collection_object_id, 
					quad, 
					institution_acronym, 
					collection.collection_cde, 
					part_name, 
					specimen_part.collection_object_id AS partID, 
					encumbering_agent.agent_name AS encumbering_agent, 
					expiration_date, 
					expiration_event, 
					encumbrance, 
					encumbrance.made_date AS encumbered_date, 
					encumbrance.remarks AS remarks, 
					encumbrance_action, 
					encumbrance.encumbrance_id 
				FROM 
					identification, 
					collecting_event, 
					locality, 
					geog_auth_rec, 
					cataloged_item, 
					collection, 
					specimen_part, 
					coll_object_encumbrance, 
					encumbrance, 
					preferred_agent_name encumbering_agent
				WHERE 
					locality.geog_auth_rec_id = geog_auth_rec.geog_auth_rec_id AND 
					collecting_event.locality_id = locality.locality_id AND 
					cataloged_item.collecting_event_id = collecting_event.collecting_event_id AND
					cataloged_item.collection_object_id = identification.collection_object_id AND 
					identification.accepted_id_fg = 1 AND
					cataloged_item.collection_object_id = specimen_part.derived_from_cat_item (+) AND 
					cataloged_item.collection_id = collection.collection_id AND 
					cataloged_item.collection_object_id=coll_object_encumbrance.collection_object_id (+) AND 
					coll_object_encumbrance.encumbrance_id = encumbrance.encumbrance_id (+) AND 
					encumbrance.encumbering_agent_id = encumbering_agent.agent_id (+) AND 
					cataloged_item.collection_object_id 
				IN 
					( <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes" >) 
				ORDER BY 
					cataloged_item.collection_object_id

			</cfquery>

		<hr>
		<br><strong>Cataloged Items being encumbered:</strong>
			<table width="95%" border="1">
				<tr>
					<td><strong>Catalog Number</strong></td>
					<td><strong>#session.CustomOtherIdentifier#</strong></td>
					<td><strong>Scientific Name</strong></td>
					<td><strong>Country</strong></td>
					<td><strong>State</strong></td>
					<td><strong>County</strong></td>
					<td><strong>Quad</strong></td>
					<td><strong>Part</strong></td>
					<td><strong>Existing Encumbrances</strong></td>
				</tr>
						</cfoutput>
		<cfoutput query="getData" group="collection_object_id">
			<tr>
				<td>
					<a href="SpecimenDetail.cfm?collection_object_id=#collection_object_id#">
					#collection_cde#&nbsp;#cat_num#</a><br>
				</td>
				<td>#CustomID#&nbsp;</td>
				<td><i>#Scientific_Name#</i></td>
				<td>#Country#&nbsp;</td>
				<td>#State_Prov#&nbsp;</td>
				<td>#county#&nbsp;</td>
				<td>#quad#&nbsp;</td>
				<td>
					<cfquery name="getParts" dbtype="query">
						SELECT 
							part_name, 
							partID
						FROM 
							getData 
						WHERE 
							collection_object_id = #collection_object_id# 
						GROUP BY
							part_name, 
							partID
					</cfquery>
					
					<cfloop query="getParts">
						<cfif len (#getParts.partID#) gt 0>
							#getParts.part_name#<br>
						</cfif>
					</cfloop>
					
				</td>
				<td>
					<cfquery name="encs" dbtype="query">
						select 
							collection_object_id,
							encumbrance_id,
							encumbrance,
							encumbrance_action,
							encumbering_agent,
							encumbered_date,
							expiration_date,
							expiration_event,
							remarks
						FROM getData
						WHERE 
							collection_object_id = #collection_object_id# 
						GROUP BY
							collection_object_id,
							encumbrance_id,
							encumbrance,
							encumbrance_action,
							encumbering_agent,
							encumbered_date,
							expiration_date,
							expiration_event,
							remarks
					</cfquery>
					<cfset e=1>
					<cfloop query="encs">
					
					<cfif len(#encumbrance#) gt 0>
						#encumbrance# (#encumbrance_action#) 
						by #encumbering_agent# made 
						#dateformat(encumbered_date,"yyyy-mm-dd")#, 
						expires #dateformat(expiration_date,"yyyy-mm-dd")# 
						#expiration_event# #remarks#<br>
						<form name="nothing#e#">
							<input type="button" 
								value="Remove This Encumbrance" 
								class="delBtn"
								onmouseover="this.className='delBtn btnhov'"
								onmouseout="this.className='delBtn'"
								onClick="deleteEncumbrance(#encumbrance_id#,#encs.collection_object_id#);">
		
						</form>
					<cfelse>
						None
					</cfif> 
						<cfset e=#e#+1>
					</cfloop>
				</td>
			</tr>
		</cfoutput>
	</table>
</cfif>
            </div>
<!------------------------------------------------------------------------------------------------------->	
<cfinclude template = "includes/_footer.cfm">
<cf_customizeIFrame>
