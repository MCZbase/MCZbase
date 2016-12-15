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
	It looks like your IP address is our blacklist. This is the result of a request originating from your current IP address
	that appeared to be an attempt to hack this site. Occasionally this happens entirely by accident due to a malformed URL. Our apologies if this is in error.
	<p>Use the form below to request removal from the blacklist.</p>
	<p>Please reload if you cannot read the text.</p>
	<cfset captcha = makeRandomString()>
	<cfset captchaHash = hash(captcha)>
	<cfform name="g" method="post" action="/errors/gtfo.cfm">
		<input type="hidden" name="action" value="p">
		<label for="c">Your request (min 20 characters)</label><br>
		<textarea name="c" id="c" rows="6" cols="50" class="reqdClr"></textarea>
		<br>
		<label for="c">Your email</label><br>
		<input type="text" name="email" id="email" class="reqdClr">
		<br>
	    <cfimage action="captcha" width="300" height="50" text="#captcha#">
	   	<br>
	    <label for="captcha">Enter the text above</label>
	    <input type="text" name="captcha" id="captcha" class="reqdClr">
	    <cfoutput>
	    <input type="hidden" name="captchaHash" value="#captchaHash#">
	    </cfoutput>
		<br><input type="submit" value="go">
	</cfform>
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
		<cfmail subject="BlackList Objection" to="#Application.PageProblemEmail#" from="blacklist@#application.fromEmail#" type="html">
			IP #cgi.REMOTE_ADDR# (#email#) had this to say:
			<p>
				#c#
			</p>
		</cfmail>
		Your message has been delivered.
			<cfcatch>
		<p>Error in sending mail to server administrator.</p>
	</cfcatch>
	</cftry>
	</cfoutput>
</cfif>