<cfinclude template = "includes/_header.cfm">
<cfset title = "Project Results">
<cfif not isdefined("newQuery")>
	<cfset newQuery = 1>
</cfif>
<cfif #newQuery# is 1>
	<cfif url.src is "pubs"><!--- find using publication ID --->
		<cfquery name="ProjDB" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT project.project_id,project_name,start_date,end_date,agent_name,project_agent_role,
			agent_position 
			FROM project,project_agent,agent_name,project_publication 
			WHERE project_publication.publication_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#publication_id#"> AND 
			project_publication.project_id = project.project_id AND project.project_id = project_agent.project_id AND
			project_agent.agent_name_id = agent_name.agent_name_id ORDER BY project_id,agent_name
		</cfquery>
	</cfif>
	<cfif url.src is "proj"><!--- find using project criteria --->
		<cfquery name="ProjDB" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT 
				project.project_id,
				project.project_name,
				project.start_date,
				project.end_date,
				projAgentName.agent_name,
				project_agent.project_agent_role,
				project_agent.agent_position
			FROM
				project
				left join project_agent on project.project_id = project_agent.project_id 
				left join agent_name projAgentName on project_agent.agent_name_id = projAgentName.agent_name_id
				<cfif isdefined("collection_object_id") AND len(#collection_object_id#) gt 0>
					left join project_trans on project.project_id = project_trans.project_id 
					left join trans on project_trans.transaction_id=trans.transaction_id 
					left join cataloged_item on trans.transaction_id=cataloged_item.accn_id
				<cfif>
				<cfif isdefined("sponsor") AND len(#sponsor#) gt 0>
					left join project_sponsor on project.project_id = project_sponsor.project_id 
					left join agent_name projSponsorName on project_sponsor.agent_name_id = projSponsorName.agent_name_id
			WHERE 
				project.project_id is not null
				<cfif isdefined("projTitle") AND len(#projTitle#) gt 0>
					AND upper(project_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(projTitle)#%">
				</cfif>
				<cfif isdefined("projParticipant") AND len(#projParticipant#) gt 0>		
					AND upper(projAgentName.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(projParticipant)#%">
				</cfif>
				<cfif isdefined("begYear") AND len(#begYear#) gt 0>
					AND to_char(start_date,'YYYY') like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#begYear#%">
				</cfif>
				<cfif isdefined("endYear") AND len(#endYear#) gt 0>
					AND to_char(end_date,'YYYY') like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#endYear#%">
				</cfif>
				<cfif isdefined("project_id") AND len(#project_id#) gt 0>
					AND project.project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
				</cfif>
				<cfif isdefined("project_agent_name_id") AND len(#project_agent_name_id#) gt 0>
					AND project_agent.agent_name_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_agent_name_id#" list="yes">)
				</cfif>
				<cfif isdefined("collection_object_id") AND len(#collection_object_id#) gt 0>
					AND cataloged_item.collection_object_id IN (<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#" list="yes">)
				</cfif>
				<cfif isdefined("sponsor") AND len(#sponsor#) gt 0>
					AND upper(projSponsorName.agent_name) like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#ucase(sponsor)#%">
				</cfif>
		</cfquery>
	</cfif>
</cfif>
<cfset newQuery=0>
<cfquery name="Proj" dbtype="query" cachedwithin="#createtimespan(0,0,15,0)#">
	select 
		*
		 from ProjDB 
</cfquery>

<cfquery name="ProjDet" dbtype="query" cachedwithin="#createtimespan(0,0,15,0)#">
	select 
		project_id,
		project_name,
		start_date,
		end_date
	 from ProjDB
	 GROUP BY
		 project_id,
		project_name,
		start_date,
		end_date
	 ORDER BY project_id
</cfquery>
		
<cfquery name="cnt" dbtype="query" cachedwithin="#createtimespan(0,0,15,0)#"> 
	select distinct(project_id) from proj
</cfquery>

<cfparam name="StartRow" default="1">
<cfset ToRow = StartRow + (session.DisplayRows - 1)>
<cfif ToRow GT cnt.RecordCount>
	<cfset ToRow = cnt.RecordCount>
</cfif>
<cfoutput>
	<p>
		<h4>
			Displaying records #StartRow# - #ToRow# from the #cnt.RecordCount# 
			total records that matched your criteria.
		</h4>
<cfif cnt.recordcount is 0>
	<p><center><font size="+1" color="##FF0000">No projects matched your search criteria.</font></center>
</cfif>
</cfoutput>

<form name="form2">
	 <!--- update the values for the next and previous rows to be returned --->
	<CFSET Next = StartRow + session.DisplayRows>
	<CFSET Previous = StartRow - session.DisplayRows>
	 
	<!--- Create a previous records link if the records being displayed aren't the first set --->
	<cfoutput>
		<table>
	 		<tr>
				<td>
					<CFIF Previous GTE 1>
						<form name="form3" action="ProjectList.cfm">
							<input type="submit" 
								value="Previous #session.DisplayRows# Records" 
								class="lnkBtn"
								onmouseover="this.className='lnkBtn btnhov'" 
								onmouseout="this.className='lnkBtn'">
							<input name="StartRow" type="hidden" value="#Previous#">
							<input name="NewQuery" type="hidden" value="0">
							<input name="displayRows" type="hidden" value="#session.DisplayRows#">
						</form>
					</CFIF>
				</td>
				<td>
					<!--- Create a next records link if there are more records in the record set that haven't yet been displayed. --->
					<CFIF Next LTE cnt.RecordCount>
						<form name="form4" action="ProjectList.cfm">
							<input type="submit" 
								value="Next #session.DisplayRows# Records" 
								class="lnkBtn"
								onmouseover="this.className='lnkBtn btnhov'" 
								onmouseout="this.className='lnkBtn'">
							<input name="StartRow" type="hidden" value="#Next#">
							<input name="NewQuery" type="hidden" value="0">
							<input name="session.displayRows" type="hidden" value="#session.DisplayRows#">
						</form>
					</CFIF>
				</td>
			</tr>
		</table>
	</cfoutput>
</form>

<table border="1">
 <cfoutput query="ProjDet" StartRow="#StartRow#" MaxRows="#session.DisplayRows#">
  <tr>
	<td>
		<form action="ProjectDetail.cfm" method="post">
		<input type="submit" 
					value="View Project" 
					class="lnkBtn"
					onmouseover="this.className='lnkBtn btnhov'" 
					onmouseout="this.className='lnkBtn'">
		<input type="hidden" name="project_id" value="#project_id#">
			<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>					
			<br><input type="button" 
					value="Select for Edits" 
					class="lnkBtn"
					onmouseover="this.className='lnkBtn btnhov'" 
					onmouseout="this.className='lnkBtn'"
					onClick="window.open('Project.cfm?Action=editProject&project_id=#project_id#');">
							
		</cfif>
		</form>
	</td>
    <td>
		
		<b>#project_name#</b><br>
		
		<cfquery name="thisAgent"		 dbtype="query">
		SELECT 
			agent_name,
			project_agent_role,
			agent_position
		FROM
			proj
		WHERE 
			project_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#project_id#">
		ORDER BY
			agent_position
		</cfquery>
		<cfset agnt="">
		<cfloop query="thisAgent">
			<cfif len(#agnt#) is 0>
			
				<cfset agnt = "#thisAgent.agent_name# (#thisAgent.project_agent_role#)<br>">
			  <cfelse>
			
			  	<cfset agnt = "#agnt##thisAgent.agent_name# (#thisAgent.project_agent_role#)<br>">
			</cfif>		
		</cfloop>
		#agnt#
		
			#dateformat(start_date,"yyyy-mm-dd")# - #dateformat(end_date,"yyyy-mm-dd")#<br>
		
	</td>
  </tr>
  </cfoutput>
</table>

<form name="form2">
	 <!--- update the values for the next and previous rows to be returned --->
	<CFSET Next = StartRow + session.DisplayRows>
	<CFSET Previous = StartRow - session.DisplayRows>
	 
	<!--- Create a previous records link if the records being displayed aren't the
		  first set --->
	
	<table>
	<CFOUTPUT>
	  <tr>
		<td><CFIF Previous GTE 1>
				<form name="form3" action="ProjectList.cfm">
				<input name="previous" type="submit" value="Previous #session.DisplayRows# Records">
				<input name="StartRow" type="hidden" value="#Previous#">
				<input name="NewQuery" type="hidden" value="0">
				<input name="displayRows" type="hidden" value="#session.DisplayRows#">
				</form>
	</CFIF></td>
		<td><!--- Create a next records link if there are more records in the record set 
		  that haven't yet been displayed. --->
	<CFIF Next LTE cnt.RecordCount>
				<form name="form4" action="ProjectList.cfm">
				<input type="submit" 
					value="Next #session.DisplayRows# Records" 
					class="lnkBtn"
					onmouseover="this.className='lnkBtn btnhov'" 
					onmouseout="this.className='lnkBtn'">
				
				<input name="StartRow" type="hidden" value="#Next#">
				<input name="NewQuery" type="hidden" value="0">
				<input name="session.displayRows" type="hidden" value="#session.DisplayRows#">
				</form>
	</CFIF>
	</td>
	  </tr>
	  </CFOUTPUT>
	</table>
</form>
<cfinclude template = "includes/_footer.cfm">
