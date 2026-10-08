<!---
shared/component/captcha.cfc
A CAPTCHA whose answer stays on the server.

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
<!--- The answer is kept in the session, not sent to the browser as a hash, which a client could
	replace with the hash of its own answer.  Each answer can be checked once, and expires.  The image
	is embedded in the page, so it shows even where every other request is answered with another page
	(errors/gtfo.cfm for blocked addresses).  No method is remote. --->
<cfcomponent>

<!---
	captchaImageTag create a new CAPTCHA for a form, replacing any earlier one in this session.

	@param formName names the form, so CAPTCHAs on different forms in one session don't interfere.
	@param altText the image's alternative text.
	@return an img tag with the CAPTCHA embedded as a data URI.
--->
<cffunction name="captchaImageTag" access="public" returntype="string" output="false">
	<cfargument name="formName" type="string" required="yes">
	<cfargument name="altText" type="string" required="no" default="Text to enter in the field below">
	<cfset var CAPTCHA_CHARACTERS = "23456789ABCDEFGHJKMNPQRS">
	<cfset var answer = "">
	<cfset var i = 0>
	<cfset var imageFile = getTempDirectory() & "captcha_" & createUUID() & ".png">
	<cfset var imageData = "">
	<cfloop from="1" to="#randRange(5, 7, 'SHA1PRNG')#" index="i">
		<cfset answer = answer & mid(CAPTCHA_CHARACTERS, randRange(1, len(CAPTCHA_CHARACTERS), "SHA1PRNG"), 1)>
	</cfloop>
	<cfset session["captcha_" & arguments.formName] = { answer = answer, issued = now() }>
	<cfimage action="captcha" width="300" height="50" text="#answer#" difficulty="low" destination="#imageFile#">
	<cfset imageData = toBase64(fileReadBinary(imageFile))>
	<cfset fileDelete(imageFile)>
	<cfreturn '<img src="data:image/png;base64,#imageData#" width="300" height="50" alt="#encodeForHtmlAttribute(arguments.altText)#">'>
</cffunction>

<!---
	isCaptchaCorrect check the answer to the CAPTCHA last shown for a form in this session.  The
	answer is removed whether or not it matches, so it can't be tried again or reused.

	@param formName the name given to captchaImageTag.
	@param response the text the user entered; case doesn't matter.
	@return true if the response matches an answer issued in the last 30 minutes.
--->
<cffunction name="isCaptchaCorrect" access="public" returntype="boolean" output="false">
	<cfargument name="formName" type="string" required="yes">
	<cfargument name="response" type="string" required="yes">
	<cfset var key = "captcha_" & arguments.formName>
	<cfset var issued = "">
	<cfif NOT structKeyExists(session, key)>
		<cfreturn false>
	</cfif>
	<cfset issued = session[key]>
	<cfset structDelete(session, key)>
	<cfreturn dateDiff("n", issued.issued, now()) LE 30 AND compare(ucase(trim(arguments.response)), issued.answer) EQ 0>
</cffunction>

</cfcomponent>
