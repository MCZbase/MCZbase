<cfinclude template="/includes/_header.cfm">
<script src="/lib/misc/sorttable.js"></script>
<script>
	function flagDupAgent(bad,good){
		$.getJSON("/component/functions.cfc",
			{
				method : "flagDupAgent",
				bad : bad,
				good : good,
				returnformat : "json",
				queryformat : 'column'
			},
			function(r) {
				var status=r.DATA.STATUS[0];
				var good=r.DATA.GOOD[0];
				var bad=r.DATA.BAD[0];
				var msg=r.DATA.MSG[0];
				
				if (status == 'success') {
					$("#fg_" + good).html('saved');
					$("#fg_" + bad).html('saved');
				} else {
					$("#fg_" + good).addClass('red');
					$("#fg_" + bad).addClass('red');
					alert(msg);
				}	
			}
		);
	}
</script>
<cfoutput>
    <div style="width: 100%;">
        <div style="width: 54em; margin: 0 auto;padding-bottom: 3em;">
<cfset title="Agent Duplicates">
<cfif action is "nothing">
    <h2>Cleaning up agents</h2>
	<p>
		The following links perform queries that attempt to locate duplicate agents. Not all results will be duplicates
		(in the sense of one individual with multiple agent_ids). There really are two people named Robert Rausch, for example. 
		Please note this in agent remarks or elsewhere should you
		discover it. 
	</p>
	<p>
		"Whodunit" links, when provided, simply search the SQL logs 
		(Reports/Audit SQL) for the relevant term. Log data is incomplete, and the suggested search
		may not make sense.	It may also be possible to determine who created duplicates by examining Agent Activity. Please do so; they need remedial training.
	</p>
	<p>Each agent will appear only one time in the resulting table, so given agents:</p>
	<ul style="margin-left: 2.5em;">
		<li>Bob Jones (1)</li>
		<li>Bob Jones (2)</li>
		<li>Bob Jones (3)</li>
	</ul>
    <p style="margin-top: 1em;">you will see only:</p>
	<table border style="margin-left: 2.5em;">
		<tr>
			<td>Bob Jones (1)</td>
			<td>Bob Jones (2)</td>
		</tr>
	</table>
	<p>rather than all possibilities, e.g.,</p>
	<table border style="margin-left: 2.5em;">
		<tr>
			<td>Bob Jones (1)</td>
			<td>Bob Jones (2)</td>
		</tr>
		<tr>
			<td>Bob Jones (2)</td>
			<td>Bob Jones (1)</td>
		</tr>
		
		<tr>
			<td>Bob Jones (1)</td>
			<td>Bob Jones (3)</td>
		</tr>
		<tr>
			<td colspan="2" align="center">.....</td>
		</tr>
	</table>
	<p>
		Merge agents and return to this form to see agents excluded by the "appears only once" rule.
	</p>
	<p style="font-weight: bold;">The format on the duplicate agent pages is:</p>
	<blockquote style="font-weight:bold;">
		<div>
			preferred_name
			<span style="font-size:small"> (agent_id)</span>
		</div>
		<div style="color:red;">
			shared_name (shared_name may be the same as preferred_name for zero, one, or both agents)
		</div>
		<div>
			[ other names ]
		</div>
		<div style="color:red;">
			[ activities which might preclude automated merger ]
		</div>
	</blockquote>
	<p>
		agent_relations flag excludes relationships of "bad duplicate of"
	</p>
	<p>
		Some guidelines, which are only guidelines and may be mutually exclusive or self-defeating:
		<ul style="margin-left: 2.5em;">
			<li>Flag "badDupOf" for the agent with the least activity. Agents who have addresses, produce publications,
				have relationships, etc. are difficult to deal with. Keep them if you can.
            </li>
			<li>
				Don't keep superflous junk. Given two agents representing the same person, both with no activity:
				<ul style="margin-left: 4em;">
					<li>Bob Jones (preferred)</li>
				</ul>
				<p style="margin-left:1.5em;">and</p>
				<ul style="margin-left: 4em;">
					<li>Bob Jones (preferred)</li>
					<li>Bob Jones (full)</li>
					<li>Jones, B. (author)</li>
					<li>Bobby Jones (a.k.a.)</li>
				</ul>
				keep the more complex variant. Someone may have filled it out because they are going to use it.
			</li>
		</ul>
	</p>
	
	
	<div style="margin:2em 0;font-weight:bold;">
    <p><a href="dupAgent.cfm?action=fullDup">Find Agents that share a name</a></p>
    <p><a href="dupAgent.cfm?action=shareFL">Find Person agents that share first and last name</a></p>
    </div>
</cfif>
<cfif not isdefined("start")>
	<cfset start=1>
</cfif>
<cfif not isdefined("stop")>
	<cfset stop=100>
</cfif>
<cfif isdefined("int")>
	<cfif int is "next">
		<cfset start=start+100>
		<cfset stop=stop+100>
	<cfelseif int is "prev">
		<cfset start=start-100>
		<cfset stop=stop-100>
	</cfif>
</cfif>
<cfif action is "shareFL">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		Select * from (
			Select a.*, rownum rnum From (
				select
					per1.first_name || ' ' || per1.last_name name1,
					per2.first_name || ' ' || per2.last_name name2,
					per1.person_id id1,
					per2.person_id id2,
					rownum r
				from
					person per1,
					person per2
				where 
					per1.first_name=per2.first_name and
					per1.last_name=per2.last_name and
					per1.person_id != per2.person_id  
				order by
					per1.first_name,per1.last_name
			) a where rownum <= #stop#
		) where rnum >= #start#
	</cfquery>
	#start# to #stop# Persons that share first and last name.
</cfif>

<cfif action is "fullDup">
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">		
		Select * from (
			Select a.*, rownum rnum From (
				select
					a.agent_id id1,
					b.agent_id id2,
					a.agent_name name1,
					b.agent_name name2
				from
					agent_name a,
					agent_name b
				where 
					a.agent_name=b.agent_name and
					a.agent_id != b.agent_id
				group by
					a.agent_id,
					b.agent_id,
					a.agent_name,
					b.agent_name
				order by
					a.agent_name
			) a where rownum <= #stop#
		) where rnum >= #start#
	</cfquery>
        <h2>Duplicate Agents?</h2>
	#start# to #stop# Agents that fully share a namestring (in orange).
</cfif>
<cfif isdefined("d")>
	<cfif start gt 1>
		<a href="dupAgent.cfm?action=#action#&start=#start#&stop=#stop#&int=prev">[ previous 100 ]</a>
	</cfif>
	<a href="dupAgent.cfm?action=#action#&start=#start#&stop=#stop#&int=next">[ next 100 ]</a>
	<a href="dupAgent.cfm">[ start over ]</a>
	<table border id="t" class="sortable">
		<tr>
			<th>Agent1</th>
			<th>Agent2</th>
		</tr>
		<cfset usedAgentIdList="">
	<cfloop query="d">
		<cfif not listcontains(usedAgentIdList,id1) and not listcontains(usedAgentIdList,id2)>
			<cfset usedAgentIdList=listappend(usedAgentIdList,id1)>
			<cfset usedAgentIdList=listappend(usedAgentIdList,id2)>
			<tr>
				<td valign="bottom" style="width: 415px;height: 100px;padding-top:.4em;">
					<cfquery name="one" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select
							agent_name,
							agent_name_type,
							agent_type,
							agent_name_id
						from
							agent,
							agent_name
						where
							agent.agent_id=agent_name.agent_id and				
							agent.agent_id=#id1#
						group by
							agent_name,
							agent_name_type,
							agent_type,
							agent_name_id
					</cfquery>
					<cfquery name="p1" dbtype="query">
						select * from one where agent_name_type='preferred'
					</cfquery>
					<cfquery name="np1" dbtype="query">
						select * from one where agent_name_type!='preferred' and
						agent_name != '#name1#'
						order by agent_name
					</cfquery>
					<div style="padding-left: 1.5em;font-weight: 562;">
						#p1.agent_name# <span style="font-size: small;">(agent id: #d.id1#)</span>
					</div>
					<div style="color:orange;padding-left: 1.5em;">
						= #d.name1# 
					</div>
					<cfloop query="np1">
						<div style="padding-left: 1.5em;">
							#agent_name# (#agent_name_type#)
						</div>
					</cfloop>
					<cfquery name="project_agent" datasource="uam_god">
						select 
							count(*) c
						from 
							project_agent
						where
							project_agent.agent_name_id IN (#valuelist(one.agent_name_id)#)
					</cfquery>
					<cfif project_agent.c gt 0>
						<div style="color:red;padding-left: 1.5em;">Attn! project agent</div>
					</cfif>
					<cfquery name="publication_author_name" datasource="uam_god">
						select 
							count(*) c
						from
							publication_author_name
						where
							publication_author_name.agent_name_id IN (#valuelist(one.agent_name_id)#)
					</cfquery>
					<cfif publication_author_name.c gt 0>
						<div style="color:red;padding-left: 1.5em;">Attn! publication agent</div>
					</cfif>
					<cfquery name="project_sponsor" datasource="uam_god">
						select 
							count(*) c
						from 
							project_sponsor
						where
							 project_sponsor.agent_name_id IN (#valuelist(one.agent_name_id)#)
					</cfquery>
					<cfif project_sponsor.c gt 0>
						<div style="color:red;padding-left: 1.5em;">proj sponsor agent</div>
					</cfif>
					<cfquery name="electronic_address" datasource="uam_god">
						select count(*) c from electronic_address where agent_id=#id1#
					</cfquery>
					<cfif electronic_address.c gt 0>
						<div style="color:red;padding-left: 1.5em;">Attn! electronic address</div>
					</cfif>
					<cfquery name="addr" datasource="uam_god">
						select count(*) c from addr where agent_id=#id1#
					</cfquery>
					<cfif addr.c gt 0>
						<div style="color:red;padding-left: 1.5em;">Attn! address</div>
					</cfif>
					<cfquery name="shipment" datasource="uam_god">
						select 
							count(*) c 
						from
							shipment
						where
							PACKED_BY_AGENT_ID=#id1#		
					</cfquery>
					<cfif shipment.c gt 0>
						<div style="color:red;padding-left: 1.5em;">Attn! shipment</div>
					</cfif>
					<cfquery name="ship_to" datasource="uam_god">
						select 
							count(*) c 
						from
							shipment,
							addr
						where
							shipment.SHIPPED_TO_ADDR_ID=addr.addr_id and
							addr.agent_id=#id1#
					</cfquery>
					<cfif ship_to.c gt 0>
						<div style="color:red;padding-left: 1.5em;">Attn! ship to</div>
					</cfif>
					<cfquery name="ship_from" datasource="uam_god">
						select 
							count(*) c 
						from
							shipment,
							addr
						where
							shipment.SHIPPED_FROM_ADDR_ID=addr.addr_id and
							addr.agent_id=#id1#
					</cfquery>
					<cfif ship_from.c gt 0>
						<div style="color:red;padding-left: 1.5em;">Attn! ship_from</div>
					</cfif>				
					<cfquery name="agent_relations" datasource="uam_god">
						select count(*) c 
						from agent_relations
						where 	
						( 
							agent_relations.agent_id=#id1# or 
							RELATED_AGENT_ID=#id1#
						) and
						agent_relationship != 'bad duplicate of'
					</cfquery>
					<cfif agent_relations.c gt 0>
						<div style="color:red;padding-left: 1.5em;">Attn! agent relationship</div>
					</cfif>
					<cfquery name="coll" datasource="uam_god">
						select 
							collection 
						from
							collection,
							cataloged_item,
							collector
						where
							collection.collection_id=cataloged_item.collection_id and
							cataloged_item.collection_object_id=collector.collection_object_id and
							collector.agent_id=#id1#
						group by collection
					</cfquery>
					<cfif coll.recordcount gt 0>
						<cfquery name="dates" datasource="uam_god">
							select
								min(substr(began_date,1,4)) edate,
								max(substr(ended_date,1,4)) ldate
							from
								collecting_event,
								cataloged_item,
								collector
							where	
								collecting_event.collecting_event_id=cataloged_item.collecting_event_id and
								cataloged_item.collection_object_id=collector.collection_object_id and
								collector.agent_id=#id1#
						</cfquery>
						<div style="font-size:smaller;">
                            <p style="padding-left:1.5em;padding-bottom: .12em;margin-bottom:0;"><span style="font-style:italic;">Collection(s):</span> #valuelist(coll.collection)#</p>
                            <p style="padding-left:1.5em;padding-bottom: .25em;padding-top:0;"><span style="font-style:italic;">Specimen date(s):</span> #dates.edate#<cfif dates.edate is not dates.ldate>-#dates.ldate#</cfif> </p>
						<div>
					</cfif>
                           
					<div style="margin-top: .5em;">
						<ul id="navbar"><li>
                            <a class="likeLink" href="/agents/editAgent.cfm?agent_id=#id1#" target="_blank">Edit</a></li>
                           <!--- <li><a class="likeLink" href="/Admin/ActivityLog.cfm?action=search&object=agent_name&sql=#name1#">Whodunit</a></li>--->
                            <li><a class="likeLink" href="/agents/Agent.cfm?agent_id=#id1#" target="_blank">Activity</a></li>
                            <li>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</li>
                            <li><span id="fg_#id1#" class="likeLink" onclick="flagDupAgent(#id1#,#id2#)">IsBadDupOf &rarr;</span></li>
                        </ul>
					</div>
				</td>
				<td valign="bottom" style="width: 415px;height: 100px;padding-top:.4em;">
					<cfquery name="two" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						select
							agent_name,
							agent_name_type,
							agent_type,
							agent_name_id
						from
							agent,
							agent_name
						where
							agent.agent_id=agent_name.agent_id and				
							agent.agent_id=#id2#
						group by
							agent_name,
							agent_name_type,
							agent_type,
							agent_name_id
						order by agent_name
					</cfquery>
					<cfquery name="p2" dbtype="query">
						select * from two where agent_name_type='preferred'
					</cfquery>
					<cfquery name="np2" dbtype="query">
						select * from two where agent_name_type!='preferred' and
						agent_name != '#name2#'
						order by agent_name
					</cfquery>
					<div style="padding-left: 1.5em;">
						#p2.agent_name#
						<span style="font-size:small"> (agent id: #d.id2#)</span>
					</div>
					<div style="color:orange;padding-left: 1.5em;">
						= #d.name2# 
					</div>
					<cfloop query="np2">
						<div style="padding-left: 1.5em;">
							#agent_name# (#agent_name_type#)
						</div>
					</cfloop>
					<cfquery name="project_agent" datasource="uam_god">
						select 
							count(*) c
						from 
							project_agent
						where
							project_agent.agent_name_id IN (#valuelist(two.agent_name_id)#)
					</cfquery>
					<cfif project_agent.c gt 0>
						<div style="color:red;padding-left: 1.5em;">Attn! project agent</div>
					</cfif>
					<cfquery name="publication_author_name" datasource="uam_god">
						select 
							count(*) c
						from
							publication_author_name
						where
							publication_author_name.agent_name_id IN (#valuelist(two.agent_name_id)#)
					</cfquery>
					<cfif publication_author_name.c gt 0>
						<div style="color:red;padding-left: 1.5em;">Attn! publication agent</div>
					</cfif>
					<cfquery name="project_sponsor" datasource="uam_god">
						select 
							count(*) c
						from 
							project_sponsor
						where
							 project_sponsor.agent_name_id IN (#valuelist(two.agent_name_id)#)
					</cfquery>
					<cfif project_sponsor.c gt 0>
						<div style="color:red;padding-left:1.5em;">Attn! proj sponsor agent</div>
					</cfif>
					<cfquery name="electronic_address" datasource="uam_god">
						select count(*) c from electronic_address where agent_id=#id2#
					</cfquery>
					<cfif electronic_address.c gt 0>
						<div style="color:red;padding-left: 1.5em;">Attn! electronic address</div>
					</cfif>
					<cfquery name="addr" datasource="uam_god">
						select count(*) c from addr where agent_id=#id2#
					</cfquery>
					<cfif addr.c gt 0>
                        <div style="color:red;padding-left: 1.5em;">Attn! address</div>
					</cfif>
					<cfquery name="shipment" datasource="uam_god">
						select 
							count(*) c 
						from
							shipment
						where
							PACKED_BY_AGENT_ID=#id2#		
					</cfquery>
					<cfif shipment.c gt 0>
						<div style="color:red;padding-left: 1.5em;">Attn! shipment</div>
					</cfif>
					<cfquery name="ship_to" datasource="uam_god">
						select 
							count(*) c 
						from
							shipment,
							addr
						where
							shipment.SHIPPED_TO_ADDR_ID=addr.addr_id and
							addr.agent_id=#id2#
					</cfquery>
					<cfif ship_to.c gt 0>
						<div style="color:red;padding-left: 1.5em;">Attn! ship to</div>
					</cfif>
					<cfquery name="ship_from" datasource="uam_god">
						select 
							count(*) c 
						from
							shipment,
							addr
						where
							shipment.SHIPPED_FROM_ADDR_ID=addr.addr_id and
							addr.agent_id=#id2#
					</cfquery>
					<cfif ship_from.c gt 0>
						<div style="color:red;">! ship from</div>
					</cfif>
					<cfquery name="agent_relations" datasource="uam_god">
						select count(*) c 
						from agent_relations
						where 	
						( 
							agent_relations.agent_id=#id2# or 
							RELATED_AGENT_ID=#id2#
						) and
						agent_relationship != 'bad duplicate of'
                        
					</cfquery>
					<cfif agent_relations.c gt 0>
						<div style="color:red;padding-left: 1.5em;">Attn! agent relationship</div>
					</cfif>
					<cfquery name="coll" datasource="uam_god">
						select 
							collection 
						from
							collection,
							cataloged_item,
							collector
						where
							collection.collection_id=cataloged_item.collection_id and
							cataloged_item.collection_object_id=collector.collection_object_id and
							collector.agent_id=#id2#
						group by collection
					</cfquery>
					<cfif coll.recordcount gt 0>
						<cfquery name="dates" datasource="uam_god">
							select
								min(substr(began_date,1,4)) edate,
								max(substr(ended_date,1,4)) ldate
							from
								collecting_event,
								cataloged_item,
								collector
							where	
								collecting_event.collecting_event_id=cataloged_item.collecting_event_id and
								cataloged_item.collection_object_id=collector.collection_object_id and
								collector.agent_id=#id2#
						</cfquery>
						<div style="font-size:smaller;">
                            <p style="padding-left:1.5em;padding-bottom: .12em;margin-bottom:0;"><span style="font-style:italic;">Collection(s):</span> #valuelist(coll.collection)# </p>
                            <p style="padding-left:1.5em;padding-bottom: .25em;padding-top:0;"><span style="font-style:italic;">Specimen date(s):</span> #dates.edate#<cfif dates.edate is not dates.ldate>-#dates.ldate#</cfif> </p>
						<div>
					</cfif>
					
					<div style="margin-top: .5em;">
                        <ul id="navbar">
                        <li><span id="fg_#id2#" class="likeLink" onclick="flagDupAgent(#id2#,#id1#)"> &larr; IsBadDupOf</span></li>
                            <li>&nbsp;&nbsp;&nbsp;&nbsp;</li>
                        <li><a class="likeLink" href="/agents/editAgent.cfm?agent_id=#id2#" target="_blank">Edit</a></li>
                       <!--- <li><a class="likeLink" href="/Admin/ActivityLog.cfm?action=search&object=agent_name&sql=#name2#">Whodunit</a></li>--->
                        <li><a class="likeLink" href="/agents/Agent.cfm?agent_id=#id2#" target="_blank">Activity</a></li>
                       
                        </ul>
						
						
						
						
					</div>
				</td>
			</tr>
		</cfif>
	</cfloop>
	</table>
</cfif>
                </div></div>
</cfoutput>
<cfinclude template="/includes/_footer.cfm">
