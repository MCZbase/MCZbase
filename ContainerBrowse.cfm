<cfset jquery11=true>
<cfinclude template="includes/_header.cfm">
<script type='text/javascript' src='/includes/internalAjax.js'></script>

<cfquery name="ctcontainer_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select container_type from ctcontainer_type order by container_type
</cfquery>
<cfquery name="fixturePrefixes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
    -- find list of departments (first few characters of fixture names)
    select count(*) as ct, nvl(nvl(substr(label,0, instr(label,'_')-1),substr(label,0, instr(label,'-')-1)),substr(label,0, 4)) as prefix 
    from container 
    where container_type = 'fixture' or container_type like '%freezer' or container_type = 'cryovat' 
    group by  nvl(nvl(substr(label,0, instr(label,'_')-1),substr(label,0, instr(label,'-')-1)),substr(label,0, 4))
</cfquery>

<cfoutput>
<script language="javascript" type="text/javascript">
   jQuery(document).ready(function() { 
   }
</script>

<cfif action is "qc">
   <cfquery name="parentlessNodes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        select count(*) ct, container_type from container where parent_container_id = 0 group by container_type
   </cfquery>
   <ul>
   <cfloop query="qc">
      <li>#qc.container_type# (#qc.ct#)</li>
   </cfloop>
   </ul>
<cfelseif action is "fixtures">
   <cfif not isdefined("labelStart")><cfset labelStart="IZ"></cfif>
   <cfquery name="fixtures" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
      --  Get fixture name and parentage for a department
      select container_type, label, sys_connect_by_path( label || ' (' || container_type ||')' ,' | ') parentage 
      from container
      where (container_type = 'fixture'  or container_type like '%freezer' or container_type = 'cryovat') 
      and label like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#labelStart#%">
      start with label = 'MCZ-campus'
      connect by prior container_id = parent_container_id
      order by label
   </cfquery>
   <ul>
   <cfloop query="fixtures">
      <li>#fixtures.label# (#fixtures.container_type#) in #fixtures.parentage#</li>
   </cfloop>
   </ul>
<cfelse>
   <!--- Default action --->
   <ul>
     <li><a href = "ContainerBrowse.cfm?action=qc">Quality Control Containers</a></li>
     <li>List fixtures starting with:</li>
     <ul>
     <cfloop query="fixturePrefixes">
        <li><a href = "ContainerBrowse.cfm?action=fixtures&labelStart=#fixturePrefixes.label#">#fixturePrefixes.label# (#fixturePrefixes.ct#)</a></li>
     </cfloop>
     </ul>
   </ul>

</cfif> <!--- end of actions ---> 

</cfoutput>
<cfinclude template="includes/_footer.cfm">
