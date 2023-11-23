<cfset pageTitle = "Access Denied">
<cfinclude template="/shared/_header.cfm">
<main class="container" id="content">
	<div class="row">
		<div class="col-8 mx-auto pt-5">
			<h1 class="h2 error">
				Access denied.
			</h1>
			<cfif not isdefined("url.ref")><cfset url.ref=""></cfif>
			<cfsavecontent variable="errortext">
				<cfoutput>
					<h2 class="h4">	
						Referrer: #url.ref#
					</h2>
				</cfoutput>
			</cfsavecontent>
			<cfheader statuscode="403" statustext="Forbidden">
			<cfthrow 
				type = "Access_Violation"
				message = "Forbidden"
				detail = "Someone found a locked form."
				errorCode = "403 "
				extendedInfo = "#errortext#">
		</div>
	</div>
</main>
