<!----

drop table ds_temp_agent;

create table ds_temp_agent (
	key number not null,
	agent_type varchar2(255),
	preferred_name varchar2(255),
	first_name varchar2(255),
	middle_name varchar2(255),
	last_name varchar2(255),
	birth_date date,
	death_date date,
	prefix varchar2(255),
	suffix varchar2(255),
	other_name_1  varchar2(255),
	other_name_type_1   varchar2(255),
	other_name_2  varchar2(255),
	other_name_type_2   varchar2(255),
	other_name_3  varchar2(255),
	other_name_type_3   varchar2(255),
	agent_remark varchar2(4000),
	agentguid_guid_type varchar2(255),
	agentguid varchar2(900),
	creating_username varchar2(255)
	);
	
create public synonym ds_temp_agent for ds_temp_agent;
grant all on ds_temp_agent to coldfusion_user;
grant select on ds_temp_agent to public;

 CREATE OR REPLACE TRIGGER ds_temp_agent_key                                         
 before insert  ON ds_temp_agent
 for each row 
    begin     
    	if :NEW.key is null then                                                                                      
    		select somerandomsequence.nextval into :new.key from dual;
    	end if;                                
    end;                                                                                            
/
sho err

---->
<cfquery name="ctagent_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select agent_type from ctagent_type order by agent_type
</cfquery>
<cfquery name="ctagent_name_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select agent_name_type from ctagent_name_type order by agent_name_type
</cfquery>
<cfquery name="ctguid_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select guid_type, placeholder from ctguid_type where applies_to like '%agent%' order by guid_type
</cfquery>

<cfset tempTableColumns = "agent_type,preferred_name,first_name,middle_name,last_name,birth_date,death_date,prefix,suffix,other_name_1,other_name_type_1,other_name_2,other_name_type_2,other_name_3,other_name_type_3,agent_remark,agentguid_guid_type,agentguid">

<cfinclude template="/includes/_header.cfm">
    <div style="width: 56em;margin: 0 auto; padding: 1em 0 4em 0;">
<cfif action is "nothing">
	<h3 class="wikilink">Bulkload Agents</h3>
    <p>Upload a comma-delimited text file (csv). 
	Include column headings, spelled exactly as below. 
    </p>
    <p>
	NOTE: This application currently handles only agent_type='person'
    </p>
  
    <cfset agentNameTypes = "">
    <cfset separator = "">
    <cfloop query="ctagent_name_type">
       <cfset agentNameTypes = agentNameTypes & separator & ctagent_name_type.agent_name_type>
       <cfset separator = ", ">
    </cfloop>
    <cfset agentTypes = "">
    <cfset separator = "">
    <cfloop query="ctagent_type">
       <cfset agentTypes = agentTypes & separator & ctagent_type.agent_type>
       <cfset separator = ", ">
    </cfloop>
    <cfset agentguidTypes = "">
    <cfset separator = "">
    <cfloop query="ctguid_type">
       <cfset agentguidTypes = agentguidTypes & separator & ctguid_type.guid_type & " (" & ctguid_type.placeholder & ")" >
       <cfset separator = ", ">
    </cfloop>
	<cfoutput>
		<p><a href="/info/ctDocumentation.cfm?table=ctagent_name_type">Valid agent name types</a> (#agentNameTypes#)</p>
		<p><a href="/info/ctDocumentation.cfm?table=ctagent_type">Valid agent types</a> (#agentTypes#)</p>
		<p><a href="/info/ctDocumentation.cfm?table=ctguid_type">Valid agent_guid_guid_types</a> (#agentguidTypes#)</p>
		<div id="template" style="margin: 1em 0 1.5em 0;">
			<label for="t">Copy and save as a .csv file</label>
			<textarea rows="2" cols="80" id="t">#tempTableColumns#</textarea>
		</div> 
	</cfoutput>

	<p>
	Columns in <span style="color:red">red</span> are required; others are optional:</p>	
	<ul class="geol_hier" style="padding-bottom: 2em;">
		<li style="color:red">agent_type</li>
		<li style="color:red">preferred_name</li>
		<li>first_name (agent_type="person" only)</li>
		<li>middle_name (agent_type="person" only)</li>
		<li style="color:red">last_name (agent_type="person" only)</li>
		<li>birth_date (agent_type="person" only; format 1-Jan-2000)</li>
		<li>death_date (agent_type="person" only; format 1-Jan-2000)</li>
		<li>agent_remark</li>
		<li>prefix (agent_type="person" only)</li>
		<li>suffix (agent_type="person" only)</li>
		<li>other_name_1</li>
		<li>other_name_type_1</li>
		<li>other_name_2</li>
		<li>other_name_type_2</li>
		<li>other_name_3</li>
		<li>other_name_type_3</li>	 
		<li>agentguid_guid_type</li>
		<li>agentguid</li>
	</ul>
	
	
	<cfform name="atts" method="post" enctype="multipart/form-data">
		<input type="hidden" name="Action" value="getFile">
		<input type="file" name="FiletoUpload" size="45">
		<input type="submit" value="Upload this file" class="savBtn">
	</cfform>

</cfif>
<cfif action is "getFile">
<cfoutput>
	<!--- put this in a temp table --->
	<cfquery name="killOld" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		delete from ds_temp_agent 
		where creating_username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cffile action="READ" file="#FiletoUpload#" variable="fileContent">
	<cfset fileContent=replace(fileContent,"'","''","all")>
	<cfset arrResult = CSVToArray(CSV = fileContent.Trim()) />
	<cfset numberOfColumns = ArrayLen(arrResult[1])>
	<cfset header = arrResult[1] >
	<cfset fail = false>
   <cfif arrayFindNoCase(header,"agent_type") EQ 0>
		<h3>Error: agent_type is a required column in the csv file</h3>
		<cfset fail = true>
   </cfif>
   <cfif arrayFindNoCase(header,"preferred_name") EQ 0>
		<h3>Error: preferred_name is a required column in the csv file</h3>
		<cfset fail = true>
   </cfif>
	<cfloop from="1" to="#ArrayLen(header)#" index="headeritem">
		<cfif NOT arrayFindNoCase(listToArray(tempTableColumns),header[headeritem])>
			<h3>Error: #header[headeritem]# is not a recognized column name</h3>
			<cfset fail = true>
		</cfif>
	</cfloop>
	<cfif fail>
		<cfset separator = "">
		<p>Headers were: [<cfloop from="1" to="#ArrayLen(header)#" index="element">#separator##header[element]#<cfset separator=","></cfloop>]</p>
		<p>Back to <a href="/DataServices/agents.cfm">Bulkload Agents</a>.</p>
		<cfinclude template="/includes/_footer.cfm">
		<cfabort>
	</cfif>
   
	<cfset colNames="">
	<cfloop from="1" to ="#ArrayLen(arrResult)#" index="o">
		<cfset colVals="">
			<cfloop from="1"  to ="#ArrayLen(arrResult[o])#" index="i">
				 <cfset numColsRec = ArrayLen(arrResult[o])>
				<cfset thisBit=arrResult[o][i]>
				<cfif #o# is 1>
					<cfset colNames="#colNames#,#thisBit#">
				<cfelse>
					<cfset colVals="#colVals#,'#thisBit#'">
				</cfif>
			</cfloop>
		<cfif #o# is 1>
			<cfset colNames=replace(colNames,",","","first")>
		</cfif>	
		<cfif len(colVals) gt 1>
			<cfset colVals=replace(colVals,",","","first")>
			<cfif numColsRec lt numberOfColumns>
				<cfset missingNumber = numberOfColumns - numColsRec>
				<cfloop from="1" to="#missingNumber#" index="c">
					<cfset colVals = "#colVals#,''">
				</cfloop>
			</cfif>
			<cfquery name="ins" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into ds_temp_agent (#colNames#,creating_username) values (#preservesinglequotes(colVals)#,'#session.dbuser#')				
			</cfquery>
		</cfif>
	</cfloop>
</cfoutput>
<cflocation url="/DataServices/agents.cfm?action=validate" addtoken="false">

<!---
---->
</cfif>
<cfif action is "validate">
<script src="/lib/misc/sorttable.js"></script>
<style>
	.cfcatch{
		font-size:.9em;
		padding-left:1em;
	}
	.infobox{
		font-size:.7em;
		width:250px;
		overflow:auto;
	}
	.rBorder {
		border:2px solid red;
	}
	.gBorder {
		border:2px solid green;
	}
</style>
<cfoutput>
<script type='text/javascript' language='javascript'>
	function saveAll() {
		var keyList = document.getElementById('keyList').value;
	  	kAry=keyList.split(",");
	  	for (i=0; i<kAry.length; ++i) {
	  		jQuery.getJSON("/component/DSFunctions.cfc",
				{
					method : "loadAgent",
					key : kAry[i],
					agent_id : $('##agent_id_' + kAry[i]).val(),
					returnformat : "json",
					queryformat : 'column'
				},
				function (r) {
					var key=r.DATA.KEY[0];
					var msg=r.DATA.MSG[0];
					var status=r.DATA.STATUS[0];
					var agent_id=r.DATA.AGENT_ID[0];
					console.log(status);
					if (status=='FAIL'){
						console.log(r.DATA);
						$('##msgDiv_' + key).remove();						
						var ns='<div class="infobox rBorder" id="msgDiv_' + key + '">Error</div>';
						$('##suggested__' + key).append(ns);
						$('##msgDiv_' + key).html(msg);						
					} else if (status=='PASS') {
						$('##msgDiv_' + key).remove();
						var ns='<div class="infobox gBorder" id="msgDiv_' + key + '">Saved</div>';
						$('##suggested__' + key).html(ns);
						$('##msgDiv_' + key).html(msg);						
					}
				}
			);
		}
	}
	function useThis(key,name,id) {
		$('##name_' + key).val(name);
		$('##agent_id_' + key).val(id);
	}
	jQuery(document).ready(function() {
	  	var keyList = document.getElementById('keyList').value;
	  	kAry=keyList.split(",");
	  	for (i=0; i<kAry.length; ++i) {
	  		jQuery.getJSON("/component/DSFunctions.cfc",
				{
					method : "findAgentMatch",
					key : kAry[i],
					returnformat : "json",
					queryformat : 'column'
				},
				function (r) {
					var key=r.DATA.KEY[0];
					for (a=0; a<r.ROWCOUNT; ++a) {
						var ns='<br><span  id="clkUseAgent_' + key + '" class="infoLink" onclick="';
						ns+="useThis('" + key + "','" + r.DATA.PREFERRED_AGENT_NAME[a] + "',";
						ns+="'" + r.DATA.AGENT_ID[a] + "')";
						ns+='">' + r.DATA.PREFERRED_AGENT_NAME[a] + '</span>';
						ns+='&nbsp;<a class="infoLink" href="/agents/Agent.cfm?agent_id=' + r.DATA.AGENT_ID[a] + '" target="_blank">[info]</a>';
						$('##suggested__' + key).append(ns);
					}
				}
			);
	  	}
	});
</script>
	<cfquery name="d" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from ds_temp_agent 
		where creating_username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">
	</cfquery>
	<cfquery name="p" dbtype="query">
		select distinct(agent_type) agent_type from d
	</cfquery>
	<cfif valuelist(p.agent_type) is not "person">
		<div class="error">Sorry, we can only deal with agent type=person here.</div>
		<cfabort>
	</cfif>
	<cfquery name="rpn" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select count(*) c from ds_temp_agent where preferred_name is null
		and creating_username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfif rpn.c is not 0>
		<div class="error">Preferred name is required for every agent.</div>
		<cfabort>
	</cfif>
	<cfquery name="ont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select nt from (
			select
				other_name_type_1 nt
			from
				ds_temp_agent
				where creating_username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">
			union
			select
				other_name_type_2 nt
			from
				ds_temp_agent
				where creating_username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">
			union
			select
				other_name_type_3 nt
			from
				ds_temp_agent
				where creating_username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">
		)
		group by nt
	</cfquery>
	<cfif listfind(valuelist(ont.nt),"preferred")>
		<div class="error">Other name types may not be "preferred"</div>
		<cfabort>
	</cfif>
	<cfquery name="ctont" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select nt from  
		(
			select
				other_name_type_1 nt
			from
				ds_temp_agent
				where creating_username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">
			union
			select
				other_name_type_2 nt
			from
				ds_temp_agent
				where creating_username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">
			union
			select
				other_name_type_3 nt
			from
				ds_temp_agent
				where creating_username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">
		)
		where nt not in (select agent_name_type from ctagent_name_type)
	</cfquery>
	<cfif ctont.recordcount gt 0>
		<div class="error">Unaccepable name type(s): #valuelist(ctont.nt)#</div>
		<cfabort>
	</cfif>
	<hr>
	If you made it this far, your data are more-or-less acceptable. Congratulations!
	
	<br>There is a bunch of JavaScript off looking for likely agent matches. Give it some time to run - maybe while reading these
	instructions. It'll take a while, and your page will bounce around while it's doing it's thing.
	
	<br>You might need to split your load up into smaller batches, depending on your computer and how many
	suggestions we have. There is no fixed record limit, and at least several thousand agents are possible with lots of RAM.
	However, it's best to deal with a batch all at once, and the app gets smarter with every agent that's loaded. So, a duplicate that
	might be missed in one big batch is likely to be detected as part of several smaller runs.
	<p>
		Once everything is ready, do one of three things for each agent:
		<ol>
			<li>Create a new agent by clicking the preferred name you uploaded. It's the one in [ square brackets ], and says 
				"(new agent)" after it.
			</li>
			<li>Map your agent to an existing agent by clicking one of the suggest links. They're not in square brackets, and
				say [info] after them. Clicking [info] will take you to the agent detail page, where you can also access
				agent activity.
			</li>
			<li>Pick another existing agent by typing in the box and tabbing out, just like any other agent pick.</li>
		</ol>		
		Click Save to Arctos when you're done. You can actually click that anytime, and it will try to save what you've done.
		However, if you then reload it can be hard to tell what's what. Proceed with extreme caution
		if you must reload.
	</p>
	<p>
		If you picked an existing agent, we'll try to add all of your names to that agent.
		Your preferred name will be loaded as name type "aka". Attempting to load duplicate names to an agent will return
		"unique constraint (UAM.IU_AGENTNAME_AGENTNAME_AID) violated" - it's usually safe to ignore those, since they just mean the 
		name is already in Arctos.
	</p>
	<p>
		Just do nothing if you decide to not use an agent that you've loaded here - for example, if you notice that it's 
		mis-spelled. You can then either upload a revised file containing the corrected agent, or create the agent using other tools.
		Don't forget to update your specimen records to reflect the changes.
	</p>
	<p>
		If you chose to use your agent, we'll create an agent with all the names you supplied.
	</p>
	
	<p>
		Successfully saved records will contain nothing but a green message box in the MapToAgent column.
		You must deal with anything else.
	</p>
	<p>
		You can sort the table below by clicking on column headers.
	</p>
	<p>
		Leading and trailing spaces are TRIMmed, but get them out of your data anyway.
	</p>
	<p>
		Once everything has saved you can load specimen data using any of the names you loaded or, for pre-existing agents,
		any name that they already had.
	</p>
	
	<form name="f">
	<input type="button" onclick="saveAll()" value="save to Arctos">
	<input type="hidden" id="keyList" value="#valuelist(d.key)#">
	<table border id="theTable" class="sortable">
		<tr>
			<th>preferred_name</th>
			<th>MapToAgent</th>
			<th>first_name</th>
			<th>middle_name</th>
			<th>last_name</th>
			<th>prefix</th>
			<th>suffix</th>
			<th>aka_1</th>
			<th>aka_2</th>
			<th>aka_3</th>
			<th>agent_type</th>
			<th>birth_date</th>
			<th>death_date</th>
			<th>agentguid_guid_type</th>
			<th>agentguid</th>
			<th>Remark</th>
		</tr>
		<cfloop query="d">
			<tr id="row_#key#">
				<td>#preferred_name#</td>
				<td nowrap="nowrap" id="suggested__#key#">
					<label for="">Map To Agent</label>
					<input type="text" name="name_#key#" id="name_#key#" class="reqdClr" 
						onchange="getAgent('agent_id_#key#',this.id,'f',this.value); return false;"
		 				onKeyPress="return noenter(event);" size="30">
					<input type="hidden" name="agent_id_#key#" id="agent_id_#key#">
					<br><span id="clkUseAgent_#key#" class="infoLink" onclick="useThis('#key#','#preferred_name#','-1')">[ #preferred_name# ] (new agent)</span>
				</td>
				<td>#first_name#&nbsp;</td>
				<td>#middle_name#&nbsp;</td>
				<td>#last_name#&nbsp;</td>
				<td>#prefix#&nbsp;</td>
				<td>#suffix#&nbsp;</td>
				<td>
					<cfif len(other_name_1) gt 0>
						#other_name_1# (#other_name_type_1#)
					</cfif>
				</td>
				<td>
					<cfif len(other_name_2) gt 0>
						#other_name_2# (#other_name_type_2#)
					</cfif>
				</td>
				<td>
					<cfif len(other_name_3) gt 0>
						#other_name_3# (#other_name_type_3#)
					</cfif>
				</td>
				<td>#agent_type#</td>
				<td>#birth_date#&nbsp;</td>
				<td>#death_date#&nbsp;</td>
				<td>#agentguid_guid_type#&nbsp;</td>
				<td>#agentguid#&nbsp;</td>
				<td nowrap="nowrap">#agent_remark#</td>
			</tr>
		</cfloop>
	</table>
	</form>
</cfoutput>
</cfif>
<!----



var n='<input type="text" name="name' + key + '" class="reqdClr"';
					n+='onchange="getAgent(\'agentID_' + key + '\',\'name\',\'f\',this.value); return false;"';
					n+='onKeyPress="return noenter(event);">';
					n+='<input type="hidden" name="agentID_' + key + ' id="agentID_' + key + '">';
					
					---->
        </div>
<cfinclude template="/includes/_footer.cfm">
