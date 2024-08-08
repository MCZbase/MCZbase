<cfset jquery11=true>
<cfinclude template="includes/_header.cfm">
<script type='text/javascript' src='/includes/internalAjax.js'></script>

<cfquery name="ctcontainer_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
	select container_type from ctcontainer_type order by container_type
</cfquery>
<cfquery name="fixturePrefixes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
    -- find list of departments (first few characters of fixture names)
    select count(*) as ct, nvl(nvl(substr(label,0, instr(label,'_')-1),substr(label,0, instr(label,'-')-1)),substr(label,0, 4)) as prefix 
    from container 
    where container_type = 'fixture'  or container_type like '%freezer' or container_type = 'cryovat' or container_type = 'tank'
    group by  nvl(nvl(substr(label,0, instr(label,'_')-1),substr(label,0, instr(label,'-')-1)),substr(label,0, 4))
</cfquery>

<cfoutput>
<script language="javascript" type="text/javascript">
   jQuery(document).ready(function() { 
   }
</script>

<cfif action is "qc">
   <h2 style="padding-left: 2em;">Containers which should be placed in another container, but are not.</h2>
   <!---  parent_container_id = 0 are root containers, these should just be The Museum of Comparative Zoology and Deaccessioned.
          parent_container_id = 1 are containers within The Museum of Comparative Zoology (target is just the MCZ-campus and CFS-campus) --->
   <cfquery name="parentlessNodes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
        select count(*) ct, container_type from container 
        where parent_container_id < 2 and container_type <> 'campus' 
        group by container_type
   </cfquery>
   <div class="container_qc_cascade">
   <ul>
   <cfloop query="parentlessNodes">
      <li>#parentlessNodes.container_type# (#parentlessNodes.ct#)</li>
      <cfif parentlessNodes.ct LT 100>
          <cfquery name="plNode" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
              select label, container_type from container 
              where parent_container_id < 2 and container_type <> 'campus' 
                 and container_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parentlessNodes.container_type#">
          </cfquery>
          <ul>
            <cfloop query="plNode">
               <li><a href="findContainer.cfm?container_label=#plNode.label#">#plNode.label# (#plNode.container_type#)</a> in [nothing]</li>
            </cfloop>
         </ul>
      </cfif>
   </cfloop>
   </ul>
   </div>
<cfelseif action is "fixtures">
   <cfif not isdefined("labelStart")><cfset labelStart="IZ"></cfif>
   <cfquery name="fixtures" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
      --  Get fixture name and parentage for a department
      select container_type, label, sys_connect_by_path( label || ' (' || container_type ||')' ,' | ') parentage 
      from container
      where (container_type = 'fixture'  or container_type like '%freezer' or container_type = 'cryovat' or container_type = 'tank') 
      and label like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#labelStart#%">
      start with container_type = 'campus'
      connect by prior container_id = parent_container_id
      order by label
   </cfquery>
   <ul>
   <cfloop query="fixtures">
      <li><a href="findContainer.cfm?container_label=#fixtures.label#">#fixtures.label# (#fixtures.container_type#)</a> in #fixtures.parentage#</li>
   </cfloop>
   </ul>
<cfelse>
   <!--- Default action --->
   <ul style="padding: 2em 4em; list-style: none; line-height: 2em;">
     <li><a href = "ContainerBrowse.cfm?action=qc">Quality Control Containers</a></li>
     <li>List fixtures starting with:</li>
     <ul style="padding-left: 2em; line-height: 1.5em;">
     <cfloop query="fixturePrefixes">
        <li><a href = "ContainerBrowse.cfm?action=fixtures&labelStart=#fixturePrefixes.prefix#">#fixturePrefixes.prefix# (#fixturePrefixes.ct#)</a></li>
     </cfloop>
     </ul>
   </ul>

</cfif> <!--- end of actions ---> 

</cfoutput>
<cfinclude template="includes/_footer.cfm">
