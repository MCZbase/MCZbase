<cfset pageTitle = "MCZbase Error: Access Forbidden">
<!---
errors/forbidden.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2019 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--->
<!--- 403 error handler invoked from Application.cfc  --->

<cfif isdefined("url.ref") and url.ref CONTAINS "/component/" >
	<!--- Attempt to access a backing component expected to be invoked in an ajax call.  --->
	<!--- Probably the result of an ajax call from an open page when the user's session has expired. --->
	<!--- Return a 403 status, and an error message without header/footer to display in an error dialog --->
	<cfheader statuscode="403" statustext="Forbidden">
	<div class="container">
		<div class="row">
	 		<div class="alert alert-danger" role="alert">
				<img src="/includes/images/Process-stop.png" alt="[ unauthorized access ]" style="float:left; width: 50px;margin-right: 1em;">
	  			<h2>Access denied.</h2>
				<p>You tried to visit a form for which you are not authorized, or your login has expired.</p>
				<p>If this message is in error, please <a class="underline" href="/contact.cfm">contact us</a>.</p>
			</div>
		</div>
	</div>
<cfelse>
	<!--- Other cases, typically a request for a user for a page after their session has expired --->
	<!--- Display the error in a page with header (and footer) --->
	<cfinclude template="/includes/_header.cfm">
	<div class="container">
		<div class="row">
	 		<div class="alert alert-danger" role="alert">
				<img src="/includes/images/Process-stop.png" alt="[ unauthorized access ]" style="float:left; width: 50px;margin-right: 1em;">
	  			<h2>Access denied.</h2>
				<p>You tried to visit a form for which you are not authorized, or your login has expired.</p>
				<p>If this message is in error, please <a class="underline" href="/contact.cfm">contact us</a>.</p>
			</div>
		</div>
	</div>

   <!--- this block kicks the handling back to onError in Application.cfc by throwing an exception --->
	<cfif not isdefined("url.ref")><cfset url.ref=""></cfif>
	<cfsavecontent variable="errortext">
		<cfoutput>
			 Referrer: #url.ref#
		</cfoutput>
	</cfsavecontent>
	<cfheader statuscode="403" statustext="Forbidden">
	<cfthrow 
	   type = "Access_Violation"
	   message = "Forbidden"
	   detail = "Someone found a locked form."
	   errorCode = "403 "
	   extendedInfo = "#errortext#">

	<!--- if we decide not to throw the exception, continue to this line and display the page footer --->
	<cfinclude template="/includes/_footer.cfm">
</cfif>
