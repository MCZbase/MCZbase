<!--- Shown for every request from a blocked address (Application.cfc onRequestStart), so the form is a
	plain form: requests to this server for cfform's scripts would be answered with this page too.
	The reCAPTCHA script comes from Google, so it still loads. --->
<cfif NOT isDefined("recaptchaWidget")>
	<cfinclude template="/shared/component/captcha.cfc" runOnce="true">
</cfif>
<cfparam name="form.action" default="">
<cfparam name="form.c" default="">
<cfparam name="form.email" default="">
<cfif form.action NEQ "p">
	It looks like your IP address is in our blocklist. This is the result of a request originating from your current IP address
	that appeared to be an attempt to hack this site. Occasionally this happens entirely by accident due to a malformed URL. Our apologies if this is in error.
	<p>Use the form below to request removal from the blocklist.</p>
	<form name="g" method="post" action="/errors/gtfo.cfm">
		<input type="hidden" name="action" value="p">
		<label for="c">Your request (min 20 characters)</label><br>
		<textarea name="c" id="c" rows="6" cols="50" class="reqdClr"></textarea>
		<br>
		<label for="email">Your email</label><br>
		<input type="text" name="email" id="email" class="reqdClr">
		<br>
		<cfoutput>#recaptchaWidget()#</cfoutput>
		<br><input type="submit" value="go">
	</form>
<cfelse>
	<cfoutput>
		<cfif NOT isDefined("clientAddress")>
			<cfinclude template="/shared/component/clientAddress.cfc" runOnce="true">
		</cfif>
		<cfif NOT isRecaptchaCorrect("errors/gtfo.cfm")>
			The "I'm not a robot" check was not completed. Please go back, reload the page, and try again.
			<cfabort>
		</cfif>
		<cfif len(form.c) lt 20>
			You need to explain how you got here.
			<cfabort>
		</cfif>
		<cfif len(form.email) is 0>
			Email is required.
			<cfabort>
		</cfif>
		<cftry>
		<cfif NOT isDefined("clientAddress")>
			<cfinclude template="/shared/component/clientAddress.cfc" runOnce="true">
		</cfif>
		<cfif NOT isDefined("allowAlertMail")>
			<cfinclude template="/shared/component/mailThrottle.cfc" runOnce="true">
		</cfif>
		<cfif NOT allowAlertMail("blocklistObjection", clientAddress())>
			A message from your address has already been sent in the past hour, or too many have been
			sent; please try again later, or use the contact information on the museum's web site.
			<cfabort>
		</cfif>
		<cfmail subject="BlackList Objection" to="#Application.PageProblemEmail#" from="blacklist@#application.fromEmail#" type="html">
			IP #encodeForHtml(clientAddress())# (#encodeForHtml(form.email)#) had this to say:
			<p>
				#encodeForHtml(form.c)#
			</p>
		</cfmail>
		Your message has been delivered.
			<cfcatch>
		<p>Error in sending mail to server administrator.</p>
	</cfcatch>
	</cftry>
	</cfoutput>
</cfif>
