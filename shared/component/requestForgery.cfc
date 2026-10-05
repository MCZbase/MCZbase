<!---
shared/component/requestForgery.cfc
Functions to protect forms that change data from cross-site request forgery.

Copyright 2026 President and Fellows of Harvard College

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
<!--- Another site can make a logged-in user's browser submit a form to MCZbase, but cannot read
	the session's token to include in it.  No method is remote. --->
<cfcomponent>

<!---
	csrfTokenInput a hidden input carrying the session's token, for a form whose handler checks it
	with isPostWithCsrfToken.

	@return the html for the hidden input.
--->
<cffunction name="csrfTokenInput" access="public" returntype="string" output="false">
	<cfreturn '<input type="hidden" name="csrfToken" value="#encodeForHtmlAttribute(CSRFGenerateToken())#">'>
</cffunction>

<!---
	isPostWithCsrfToken test whether the current request is a post carrying the session's token.

	@return true if the request is a post with a form.csrfToken that matches the session's token.
--->
<cffunction name="isPostWithCsrfToken" access="public" returntype="boolean" output="false">
	<cfif cgi.request_method NEQ "POST" OR NOT structKeyExists(form, "csrfToken")>
		<cfreturn false>
	</cfif>
	<cfreturn CSRFVerifyToken(form.csrfToken)>
</cffunction>

</cfcomponent>
