<!---
shared/component/error_handler.cfc
 
Copyright 2021 President and Fellows of Harvard College

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
<!--- Repeatedly used error handling code for presenting error messages with an http 500 status code --->
<cfcomponent>

<!--- Report an error condition with an http 500 status header --->
<cffunction name="reportError" access="public" returntype="any" returnformat="plain">
	<cfargument name="function_called" type="string" required="yes">
	<cfargument name="error_message" type="string" required="yes">

	<cfset message = trim("Error processing #function_called#: #error_message#") >
	<cfheader statusCode="500" statusText="#message#">
	<cfoutput>
		<div class="container">
			<div class="row">
				<div class="alert alert-danger" role="alert">
					<img src="/shared/images/Process-stop.png" alt="[ error ]" style="float:left; width: 50px;margin-right: 1em;">
					<h2>Internal Server Error.</h2>
					<p>#message#</p>
					<p><a href="/info/bugs.cfm">“Feedback/Report Errors”</a></p>
				</div>
			</div>
		</div>
	</cfoutput>
</cffunction>

<cffunction name="cfcatchToErrorMessage" access="public" returntype="any" returnformat="plain">
	<cfargument name="cfcatchcopy" type="any" required="yes">

	<cfset error_message = "Error.  Undefined Error.">
	<cftry>
		<cfset errorLine ="">
		<cfset errorMessage ="">
		<cfset errorDetail ="">
		<cfif isDefined("cfcatchcopy.queryError") ><cfset queryError=cfcatchcopy.queryError><cfelse><cfset queryError = ''></cfif>
		<cfif structKeyExists(cfcatchcopy,"Cause") AND structKeyExists(cfcatchcopy.cause,"TagContext")>
			<cftry>
				<cfset errorLine = errorLine & "See #cfcatchcopy.cause.tagcontext[1].template#">
				<cfset errorLine = errorLine & "line #cfcatchcopy.cause.tagcontext[1].line#.">
			<cfcatch>
			</cfcatch>
			</cftry>
		</cfif>
		<cftry>
			<cfif structKeyExists(cfcatchcopy,"RootCause") AND structKeyExists(cfcatchcopy.rootcause,"TagContext")>
				<cfif cfcatchcopy.cause.tagcontext[1].line NEQ cfcatchcopy.rootcause.tagcontext[1].line >
					<cfset errorLine = errorLine & "line #cfcatchcopy.cause.tagcontext[1].line#.">
					<cfset errorLine = errorLine & "See #cfcatchcopy.cause.tagcontext[1].template#">
				</cfif>
			</cfif>
		<cfcatch>
		</cfcatch>
		</cftry>
		<cfif isDefined("cfcatchcopy.message") ><cfset errorMessage=cfcatchcopy.message></cfif>
		<cfif isDefined("cfcatchcopy.detail") ><cfset errorDetail=cfcatchcopy.detail></cfif>
		<cfset error_message = trim(errorMessage & " " & errorDetail & " " & queryError & " " & errorLine) >
	<cfcatch>
		<cfset error_message = "Error.  Unable to generate error message, no cfcatch object or error extracting data from cfcatch.">
	</cfcatch>
	</cftry>
	<cfreturn error_message>
</cffunction>

</cfcomponent>
