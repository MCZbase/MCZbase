<!---
shared/component/captcha.cfc
Google reCAPTCHA v2 ("I'm not a robot") for forms that anonymous visitors can submit.

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
<!--- The one CAPTCHA used in MCZbase.  The site key is Application.g_sitekey (from
	cf_global_settings.google_site_key).  Answers are checked on the server by the Java class
	edu.harvard.mcz.recaptchavalidate.RecaptchaValidate, which is installed on the ColdFusion server
	and is not in this repository; recaptchaStatus reports whether it can be loaded.  A check that
	fails for any reason refuses the submission.  No method is remote. --->
<cfcomponent>

<!---
	recaptchaWidget the reCAPTCHA checkbox, with Google's script, to place inside a form.

	@return the HTML for the widget; the form posts its answer as g-recaptcha-response.
--->
<cffunction name="recaptchaWidget" access="public" returntype="string" output="false">
	<cfreturn '<script src="https://www.google.com/recaptcha/api.js" async defer></script>'
		& '<div class="g-recaptcha" data-sitekey="#encodeForHtmlAttribute(Application.g_sitekey)#"></div>'>
</cffunction>

<!---
	isRecaptchaCorrect check the reCAPTCHA answer posted with the current form.

	@param caller names the page, for the log when the check can't be made.
	@return true only if Google confirms the answer; false if it is missing or wrong, or the
		check fails.
--->
<cffunction name="isRecaptchaCorrect" access="public" returntype="boolean" output="false">
	<cfargument name="caller" type="string" required="yes">
	<cfset var validator = "">
	<cfset var address = cgi.remote_addr>
	<cfif NOT structKeyExists(form, "g-recaptcha-response") OR len(form["g-recaptcha-response"]) EQ 0>
		<cfreturn false>
	</cfif>
	<cfif isDefined("clientAddress")>
		<cfset address = clientAddress()>
	</cfif>
	<cftry>
		<cfset validator = createObject("java", "edu.harvard.mcz.recaptchavalidate.RecaptchaValidate")>
		<cfreturn validator.validate(form["g-recaptcha-response"], address)>
	<cfcatch>
		<cflog file="MCZbase" text="#arguments.caller#: reCAPTCHA validation failed: #cfcatch.message#">
		<cfreturn false>
	</cfcatch>
	</cftry>
</cffunction>

<!---
	recaptchaStatus whether reCAPTCHA can work on this server, for administrators.

	@return a structure: siteKeySet (boolean), classLoaded (boolean), classLocation (the jar or
		directory the class was loaded from), validatorResponds (boolean: a check of a dummy answer
		returned without an error, which needs the class and access to Google), and message.
--->
<cffunction name="recaptchaStatus" access="public" returntype="struct" output="false">
	<cfset var status = { siteKeySet = false, classLoaded = false, classLocation = "", validatorResponds = false, message = "" }>
	<cfset var validator = "">
	<cfset var codeSource = "">
	<cfset status.siteKeySet = isDefined("Application.g_sitekey") AND len(Application.g_sitekey) GT 0>
	<cftry>
		<cfset validator = createObject("java", "edu.harvard.mcz.recaptchavalidate.RecaptchaValidate")>
		<cfset status.classLoaded = true>
		<cfset codeSource = validator.getClass().getProtectionDomain().getCodeSource()>
		<cfif NOT isNull(codeSource)>
			<cfset status.classLocation = codeSource.getLocation().toString()>
		</cfif>
	<cfcatch>
		<cfset status.message = "Class not loaded: #cfcatch.message# #cfcatch.detail#">
		<cfreturn status>
	</cfcatch>
	</cftry>
	<cftry>
		<!--- a dummy answer: Google rejects it, which shows the validator can reach Google --->
		<cfset validator.validate("mczbase-status-check", "127.0.0.1")>
		<cfset status.validatorResponds = true>
	<cfcatch>
		<cfset status.message = "Validator error: #cfcatch.message# #cfcatch.detail#">
	</cfcatch>
	</cftry>
	<cfreturn status>
</cffunction>

</cfcomponent>
