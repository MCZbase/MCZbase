<cfoutput>
	<cfif isdefined("publication_id")>
		<cfset rurl='/publications/showPublication.cfm'>
		<cfset rurl=rurl & '?publication_id=' & publication_id>
	<cfelse>
		<cfset rurl='/Publications.cfm'>
	</cfif>
	<cfheader statuscode="301" statustext="Moved permanently">
	<cfheader name="Location" value="#rurl#"> 
</cfoutput>
