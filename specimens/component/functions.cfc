<cfcomponent>
<cfinclude template = "../../includes/functionLib.cfm">

<cffunction name="getExternalStatus" access="remote">
	<cfargument name="uri" type="string" required="yes">
	<cfhttp url="#uri#" method="head"></cfhttp>
	<cfreturn left(cfhttp.statuscode,3)>
</cffunction>
<!------EXISTING----------------------------------------------------------------------------------------------------------->
<cffunction name="getIdentifications" returntype="query" access="remote">
	<cfargument name="identification_id" type="string" required="yes">
	<cftry>
		<cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		   select 1 as status, identification_id, collection_object_id, nature_of_id, accepted_id_fg,identification_remarks, taxa_formula, scientific_name, publication_id, sort_order, stored_as_fg
             from identification
             where identification_id  =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
		</cfquery>
		<cfif theResult.recordcount eq 0>
	  	  <cfset theResult=queryNew("status, message")>
		  <cfset t = queryaddrow(theResult,1)>
		  <cfset t = QuerySetCell(theResult, "status", "0", 1)>
		  <cfset t = QuerySetCell(theResult, "message", "No shipments found.", 1)>
		</cfif>
	  <cfcatch>
	   	<cfset theResult=queryNew("status, message")>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "status", "-1", 1)>
		<cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
	  </cfcatch>
	</cftry>
	<cfreturn theResult>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<cffunction name="getIdentificationTable" returntype="query" access="remote">
	<cfargument name="identification_id" type="string" required="yes">
	<cfset r=1>
	<cftry>
	    <cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
   			select 1 as status, identifications_id, collection_object_id, made_date, nature_of_id, accepted_id_fg,identification_remarks, taxa_formula, scientific_name, publication_id, sort_order, stored_as_fg
            from identification
            where identification_id  =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
		</cfquery>
		<cfif theResult.recordcount eq 0>
	  	  <cfset theResult=queryNew("status, message")>
		  <cfset t = queryaddrow(theResult,1)>
		  <cfset t = QuerySetCell(theResult, "status", "0", 1)>
		  <cfset t = QuerySetCell(theResult, "message", "No shipments found.", 1)>
		</cfif>
	<cfcatch>
	  <cfset theResult=queryNew("status, message")>
		<cfset t = queryaddrow(theResult,1)>
		<cfset t = QuerySetCell(theResult, "status", "-1", 1)>
		<cfset t = QuerySetCell(theResult, "message", "#cfcatch.type# #cfcatch.message# #cfcatch.detail#", 1)>
	  </cfcatch>
	</cftry>
    <cfif isDefined("asTable") AND asTable eq "true">
	    <cfreturn resulthtml>
    <cfelse>
   	    <cfreturn theResult>
    </cfif>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
<!--- TODO: Comment documents a shipment method, what follows is an identification method????  --->
<!--- NEW NEW NEW Obtain the list of shipments and their permits for a transaction formatted in html for display on a transaction page --->
<!---  @param transaction_id  the transaction for which to obtain a list of shipments and their permits.  --->
<!---  @return html list of shipments and permits, including editing controls for adding/editing/removing shipments and permits. --->
<cffunction name="getIdentificationHtml" returntype="string" access="remote" returnformat="plain">
   <cfargument name="identification_id" type="string" required="yes">
   <cfset r=1>
   <cfthread name="getSBTHtmlThread">
   <cftry>
       <cfquery name="theResult" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
         select 1 as status, identification.identification_id, identification.collection_object_id, identification.scientific_name, identification.made_date, identification.nature_of_id, identification.stored_as_fg,identification.identification_remarks, identification.accepted_id_fg, identification.taxa_formula, identification.sort_order, taxonomy.full_taxon_name, taxonomy.author_text, identification_agent.agent_id, concatidagent(identification.identification_id) agent_name
             	FROM 
						identification, identification_taxonomy,
						taxonomy, identification_agent
          		WHERE 	
		   				identification.identification_id=identification_taxonomy.identification_id and
		   				identification_agent.identification_id = identification.identification_id and
		   				identification_taxonomy.taxon_name_id = taxonomy.taxon_name_id and 
						identification.identification_id =<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#identification_id#">
           		ORDER BY 
		   				made_date
      </cfquery>
	
	
      <cfset resulthtml = "<div id='identification'> ">

      <cfloop query="theResult">

         <cfset resulthtml = resulthtml & "<div class='identifcationNewForm'>">
            <cfset resulthtml = resulthtml & "<form><div class='container pl-1'>">
			<cfset resulthtml = resulthtml & "<div class='col-md-6 col-sm-12 float-left'>">
			<cfset resulthtml = resulthtml & "<div class='form-group'><label for='scientific_name'>Scientific Name:</label><input type='text' class='form-control-sm' id='scientific_name' value='#scientific_name#'></div>">
			<cfset resulthtml = resulthtml & "<div class='form-group w-25 mb-3 float-left'><label for='taxa_formula'>Formula:</label><select class='border custom-select form-control input-sm id='select'><option value='' disabled='' selected=''>#taxa_formula#</option><option value='A'>A</option><option value='B'>B</option><option value='sp.'>sp.</option></select></div>">
					<cfset resulthtml = resulthtml & "<div class='form-group w-25 mb-3 ml-3 float-left'><label for='made_date'>Made Date:</label><input type='text' class='form-control ml-0 input-sm' id='made_date' value='#dateformat(made_date,'yyyy-mm-dd')#&nbsp;'></div></div>">
			<cfset resulthtml = resulthtml & "<div class='col-md-6 col-sm-12 float-left'>">
    <cfset resulthtml = resulthtml & "<div class='form-group'><label for='nature_of_id'>Determined By:</label><input type='text' class='form-control-sm' id='nature_of_id' placeholder='#agent_name#'></div>">
            <cfset resulthtml = resulthtml & "<div class='form-group'><label for='nature_of_id'>Nature of ID:</label><input type='text' class='form-control-sm' id='nature_of_id' placeholder='#nature_of_id#'></div>">
				

			<cfset resulthtml = resulthtml & "</div>">

			
        
				
			<cfset resulthtml = resulthtml & "<div class='col-md-12 col-sm-12 float-left'>">
         	<cfset resulthtml = resulthtml & "<div class='form-group'><label for='full_taxon_name'>Full Taxon Name:</label><input type='text' class='form-control-sm' id='full_taxon_name' placeholder='#full_taxon_name#'></div> ">
			<cfset resulthtml = resulthtml & "<div class='form-group'><label for='identification_remarks'>Identification Remarks:</label><textarea type='text' class='form-control' id='identification_remarks' value='#identification_remarks#'></textarea></div>">
				
			<cfset resulthtml = resulthtml & "<div class='form-check'><input type='checkbox' class='form-check-input' id='materialUnchecked'><label class='form-check-label' for='materialUnchecked'>Stored as #scientific_name#</label></div>">
			
		<cfset resulthtml = resulthtml & "<div class='form-group float-right'><button type='button' value='Create New Identification' class='btn btn-primary ml-2' onClick=""$('.dialog-ID').dialog('open'); loadNewIdentificationForm(addIdentification_#collection_object_id#,'newIdentificationForm');"">Create New Identification</button></div> ">
			<cfset resulthtml = resulthtml & "</div></div></form>">
       
            <cfset resulthtml = resulthtml & "</div>"> 
      </cfloop> <!--- theResult --->

   <cfcatch>
       <cfset resulthtml = resulthtml & "Error:" & "#cfcatch.type# #cfcatch.message# #cfcatch.detail#">
   </cfcatch>
   </cftry>
     <cfoutput>#resulthtml#</cfoutput>
   </cfthread>
    <cfthread action="join" name="getSBTHtmlThread" />
    <cfreturn getSBTHtmlThread.output>
</cffunction>
<!----------------------------------------------------------------------------------------------------------------->
</cfcomponent>
