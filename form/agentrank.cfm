<cfset jquery11=true>
<cfinclude template="/includes/_pickHeader.cfm">
<script type='text/javascript' src='/includes/internalAjax.js'></script>
<cfif listcontainsnocase(session.roles,"manage_agent_ranking")>
<cfoutput>
	<cfquery name="agnt" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select agent_name from preferred_agent_name 
		where agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#"> 
	</cfquery>
	<cfquery name="pr" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select 
			agent_rank,
			transaction_type,
			rank_date,
			agent_name ranker, 
			remark
		from 
			agent_rank,
			preferred_agent_name 
		where 
			agent_rank.agent_id=<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#agent_id#"> 
			and ranked_by_agent_id=preferred_agent_name.agent_id
		order by 
			agent_rank,
			rank_date
	</cfquery>
	<cfif listcontainsnocase(session.roles,"admin_agent_ranking")>
		<cfquery name="ctagent_rank" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select agent_rank from ctagent_rank order by agent_rank
		</cfquery>
	<cfelse>
		<cfquery name="ctagent_rank" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			select agent_rank from ctagent_rank where agent_rank <> 'F' order by agent_rank
		</cfquery>
	</cfif>
	<cfquery name="cttransaction_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
		select transaction_type from cttransaction_type order by transaction_type
	</cfquery>
	<strong><a href='/agents/Agent.cfm?agent_id=#agent_id#' target='_blank'>#agnt.agent_name#</a></strong> has been ranked #pr.recordcount# times.&nbsp;&nbsp;&nbsp;
	<cfif pr.recordcount gt 0>
		<cfquery name="s" dbtype="query">
			select agent_rank, count(*) c from pr group by agent_rank
		</cfquery>
		<table border>
			<tr>
				<th>rank</th>
				<th>##</th>
				<th>%</th>
			</tr>
			<cfloop query="s">
				<tr>
					<td>#agent_rank#</td>
					<td>#c#</td>
					<cfset p=round((c/pr.recordcount) * 100)>
					<td>#p#</td>
				</tr>
			</cfloop>
		</table>
		<span class="infoLink" id="t_agentRankDetails" onclick="tog_AgentRankDetail(1)">Show Details</span>
		<div id="agentRankDetails" style="display:none">
			<table border>
				<tr>
					<th>Rank</th>
					<th>Trans</th>
					<th>Date</th>
					<th>Ranker</th>
					<th>Remark</th>
				</tr>
				<cfloop query="pr">
					<tr>
						<td>#agent_rank#</td>
						<td>#transaction_type#</td>
						<td nowrap="nowrap">#dateformat(rank_date,"yyyy-mm-dd")#</td>
						<td nowrap="nowrap">#replace(ranker," ", "&nbsp;","all")#</td>
						<td>#remark#</td>
					</tr>					 
				</cfloop>
			</table>
			
		</div>
	</cfif>
	<span class="infoLink" id="t_agentRankDetails" onclick=" $('##agentRankCreate').show(); ">Add Rank</span>
	<div id="agentRankCreate">
	<form name="a" method="post" action="agentrank.cfm">
		<input type="hidden" name="agent_id" id="agent_id" value="#agent_id#">
		<input type="hidden" name="action" id="action" value="saveRank">
		<label class="h" for="agent_rank">Add Rank of:</label>
		<select name="agent_rank" id="agent_rank">
			<cfloop query="ctagent_rank">
				<option value="#agent_rank#">#agent_rank#</option>
			</cfloop>
		</select>
		<label class="h"  for="transaction_type">for Transaction Type:</label>
		<select name="transaction_type" id="transaction_type">
			<cfloop query="cttransaction_type">
				<option value="#transaction_type#">#transaction_type#</option>
			</cfloop>
		</select>
		<br><label  class="h" for="remark">Remark: (required for unsatisfactory rankings; encouraged for all)</label>
		<br><textarea name="remark" id="remark" rows="4" cols="60"></textarea>
		<br><input type="button" class="savBtn" value="Save" onclick="saveAgentRank()">
		<input type="button" class="qutBtn" value="Cancel" onclick=" $('##agentRankCreate').hide(); ">
	</form>
	</div>
	<div id="saveAgentRankFeedback"></div>
    <script>
        $( document ).ready( function() { $('##agentRankCreate').hide(); } );
    </script>
</cfoutput>
</cfif><!--- has role manage agent ranking --->
<cfinclude template="/includes/_pickFooter.cfm">
