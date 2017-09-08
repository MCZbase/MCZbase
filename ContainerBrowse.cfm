<cfset jquery11=true>
<cfinclude template="includes/_header.cfm">
<script type='text/javascript' src='/includes/internalAjax.js'></script>

<cfquery name="ctcontainer_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select container_type from ctcontainer_type order by container_type
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
   <cfquery name="fixtures" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
      --  Get fixture name and parentage for a department
      select container_type, label, sys_connect_by_path( label || '(' || container_type ||')' ,'|') parentage 
      from container
      where (container_type = 'fixture'  or container_type like '%freezer' or container_type = 'cryovat') and label like 'Ent%'
      start with label = 'MCZ-campus'
      connect by prior container_id = parent_container_id
      order by label;
   </cfquery>
   <ul>
   <cfloop query="fixtures">
      <li>#fixtures.label# (#fixtures.container_type#) in #fixtures.parentage#</li>
   </cfloop>
   </ul>
<cfelse>
   <!--- Default action --->
   <ul>
     <li><a href = "ContainerSearch.cfm?action=qc">Quality Control Containers</a></li>
     <li><a href = "ContainerSearch.cfm?action=fixtures">List fixtures</a></li>
   </ul>

</cfif> <!--- end of actions ---> 

</cfoutput>
<cfinclude template="includes/_footer.cfm">
