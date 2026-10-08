<cfinclude template="/includes/_header.cfm">
<cfif NOT isDefined("captchaImageTag")>
	<cfinclude template="/shared/component/captcha.cfc" runOnce="true">
</cfif>
<cfparam name="form.action" default="">
<cfparam name="form.name" default="">
<cfparam name="form.email" default="">
<cfparam name="form.msg" default="">
<cfparam name="form.captcha" default="">
<!--- Logged in users aren't asked for the CAPTCHA. --->
<cfset variables.needsCaptcha = NOT (isDefined("session.username") AND len(session.username) GT 0)>

<cfif form.action NEQ "sendMail">
	<cfset title="Contact Us">
<cfoutput>
	<h2>Contact a system administrator</h2>
	<p>Data problems? Use a "report bad data" link if there's one available.</p>
	<cfform action="contact.cfm" method="post" name="contact">
		<input type="hidden" name="action" value="sendMail">
		<label for="name">Your Name or Arctos username (required)</label>
		<cfinput type="text" id="name" name="name" size="60" value="#session.username#" required="true" class="reqdClr">
		<label for="email">Your Email Address (required - we'll never share it)</label>
		<cfset eml=''>
		<cfif NOT variables.needsCaptcha>
			<cfquery name='temail' datasource="cf_dbuser">
				SELECT email
				FROM cf_users
					JOIN cf_user_data ON cf_users.user_id = cf_user_data.user_id
				WHERE
					username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfset eml=temail.email>
		</cfif>
		<cfinput type="text" id="email" name="email" size="60" value='#eml#' validate="email" required="true" class="reqdClr">
		<label for="msg">Your Message for us (20 characters minimum)</label>
		<cftextarea name="msg" id="msg" rows="10" cols="50" required="true" class="reqdClr"></cftextarea>
		<cfif variables.needsCaptcha>
			<p>Can't read the text? Just reload to get a new CAPTCHA.</p>
			#captchaImageTag("contact")#
			<br>
			<label for="captcha">Enter the text above. Case doesn't matter. (required)</label>
			<cfinput type="text" name="captcha" id="captcha" class="reqdClr" size="60">
		</cfif>
	    <br><cfinput name="s" type="submit" value="Send Message" class="savBtn">
	</cfform>
</cfoutput>
<cfelse>
	<cfoutput>
		<cfif variables.needsCaptcha AND NOT isCaptchaCorrect("contact", form.captcha)>
			You did not enter the right text. Please go back and reload the page for a new image.
			<cfabort>
		</cfif>
		<cfif len(form.msg) lt 20>
			A message of at least 20 characters is required to proceed. Please use your back button.
			<cfabort>
		</cfif>
		<cfif len(form.name) eq 0>
			A name is required to proceed. Please use your back button.
			<cfabort>
		</cfif>
		<cfif NOT isValid("email", form.email)>
			A valid email address is required to proceed. Please use your back button.
			<cfabort>
		</cfif>
		<cfmail subject="Arctos Contact"
			replyto="#form.email#" 
			to="#Application.technicalEmail#" 
			from="contact@#application.fromEmail#" type="html">
			Name: #encodeForHtml(form.name)#
			<br>Email: #encodeForHtml(form.email)#
			<br>Message: #encodeForHtml(form.msg)#
		</cfmail>
		Thanks for contacting us. Your message has been delivered.
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">
