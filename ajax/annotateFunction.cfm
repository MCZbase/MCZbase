<!--- hint="type=keyvalue, jsreturn=array , listdelimiter=| , delimiter='='" --->
<cfinclude template="/ajax/core/cfajax.cfm">


<cffunction name="addAnnotation" returntype="string" access="private">
	<cfargument name="collection_object_id" type="numeric" required="yes">
	<cfargument name="scientific_name" type="string" required="yes">
	<cfargument name="higher_geography" type="string" required="yes">
	<cfargument name="specific_locality" type="string" required="yes">
	<cfargument name="annotation_remarks" type="string" required="yes">
	
	<cfinclude template="/includes/functionLib.cfm">
	<cftry>
		<cfquery name="insAnn" datasource="uam_god">
			insert into specimen_annotations (
				collection_object_id,
				cf_username
				<cfif len(#higher_geography#) gt 0 and #higher_geography# is not "Annotate">
					,higher_geography
				</cfif>	
				<cfif len(#scientific_name#) gt 0 and #scientific_name# is not "Annotate">
					,scientific_name
				</cfif>	
				<cfif len(#specific_locality#) gt 0 and #specific_locality# is not "Annotate">
					,specific_locality
				</cfif>
				<cfif len(#annotation_remarks#) gt 0 and #annotation_remarks# is not "Annotate">
					,annotation_remarks
				</cfif>
				) values (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				<cfif len(#higher_geography#) gt 0 and #higher_geography# is not "Annotate">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#urldecode(higher_geography))#">
				</cfif>
				<cfif len(#scientific_name#) gt 0 and #scientific_name# is not "Annotate">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#urldecode(scientific_name))#">
				</cfif>
				<cfif len(#specific_locality#) gt 0 and #specific_locality# is not "Annotate">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#urldecode(specific_locality))#">
				</cfif>
				<cfif len(#annotation_remarks#) gt 0 and #annotation_remarks# is not "Annotate">
					,<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#urldecode(annotation_remarks))#">
				</cfif>	
				)
		</cfquery>
		<cfquery name="whoTo" datasource="uam_god">
			select
				address
			FROM
				cataloged_item,
				collection,
				collection_contacts,
				electronic_address
			WHERE
				cataloged_item.collection_id = collection.collection_id AND
				collection.collection_id = collection_contacts.collection_id AND
				collection_contacts.contact_agent_id = electronic_address.agent_id AND
				collection_contacts.CONTACT_ROLE = 'data quality' and
				electronic_address.ADDRESS_TYPE='e-mail' and
				cataloged_item.collection_object_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#collection_object_id#">
		</cfquery>
		<cfif len(#whoTo.address#) gt 0>
			<cfset mailTo = valuelist(whoTo.address)>
		<cfelse>	
			<cfset mailTo = #Application.bugReportEmail#>
		</cfif>
	
		
		<cfmail to="#mailTo#" from="annotation@#Application.fromEmail#" subject="Annotation Submitted" type="html">
			Arctos User #session.username# has submitted a specimen annotation. View details at
			<a href="#Application.ServerRootUrl#/info/annotate.cfm?action=show&collection_object_id=#collection_object_id#">
			#Application.ServerRootUrl#/info/annotate.cfm?action=show&collection_object_id=#collection_object_id#
			</a>
		</cfmail>
	
	<cfcatch>
		<cfset result = "A database error occured: #cfcatch.message# #cfcatch.detail# #sql#">
		<cfreturn result>
	</cfcatch>
	</cftry>

	<cfset result = "success">
	<cfreturn result>
	
</cffunction>
