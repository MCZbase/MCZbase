<cffunction name="makeRandomString" returnType="string" output="false">
    <cfscript>
		var chars = "23456789ABCDEFGHJKMNPQRS";
		var length = randRange(4,7);
		var result = "";
	    for(i=1; i <= length; i++) {
	        char = mid(chars, randRange(1, len(chars)),1);
	        result&=char;
	    }
	    return result;
    </cfscript>
</cffunction>
<cfif not isdefined("action") or action is not "p">
	It looks like your IP address is in our blocklist. This is the result of a request originating from your current IP address
	that appeared to be an attempt to hack this site. Occasionally this happens entirely by accident due to a malformed URL. Our apologies if this is in error.
	<p>Use the form below to request removal from the blocklist.</p>
	<p>Please reload if you cannot read the text.</p>
	<cfset captcha = makeRandomString()>
	<cfset captchaHash = hash(captcha)>
	<!--- The blocklist check in Application.cfc answers every request from a blocked address with this
		page, including the request for a CAPTCHA image file and cfform's scripts, so the image is
		embedded in the page and the form is a plain form. --->
	<cfset captchaFile = getTempDirectory() & "gtfo_" & createUUID() & ".png">
	<cfimage action="captcha" width="300" height="50" text="#captcha#" destination="#captchaFile#">
	<cfset captchaImage = toBase64(fileReadBinary(captchaFile))>
	<cfset fileDelete(captchaFile)>
	<form name="g" method="post" action="/errors/gtfo.cfm">
		<input type="hidden" name="action" value="p">
		<label for="c">Your request (min 20 characters)</label><br>
		<textarea name="c" id="c" rows="6" cols="50" class="reqdClr"></textarea>
		<br>
		<label for="email">Your email</label><br>
		<input type="text" name="email" id="email" class="reqdClr">
		<br>
		<cfoutput><img src="data:image/png;base64,#captchaImage#" width="300" height="50" alt="Text to enter in the field below"></cfoutput>
	   	<br>
	    <label for="captcha">Enter the text above</label>
	    <input type="text" name="captcha" id="captcha" class="reqdClr">
	    <cfoutput>
	    <input type="hidden" name="captchaHash" value="#captchaHash#">
	    </cfoutput>
		<br><input type="submit" value="go">
	</form>
</cfif>

<cfif isdefined("action") and action is "p">
	<cfoutput>
		<cfif hash(ucase(form.captcha)) neq form.captchaHash>
			You did not enter the right text.
			<cfabort>
		</cfif>
		<cfif len(c) lt 20>
			You need to explain how you got here.
			<cfabort>
		</cfif>
		<cfif len(email) is 0>
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
			IP #encodeForHtml(clientAddress())# (#encodeForHtml(email)#) had this to say:
			<p>
				#encodeForHtml(c)#
			</p>
		</cfmail>
		Your message has been delivered.
			<cfcatch>
		<p>Error in sending mail to server administrator.</p>
	</cfcatch>
	</cftry>
	</cfoutput>
</cfif>
