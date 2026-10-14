<cfset pageTitle = "Change Password">
<cfinclude template = "/shared/_header.cfm">
<!---------------------------------------------------------------------------------->
<script type="text/javascript" src="/shared/js/login_scripts.js"></script> 
<cfinclude template="/shared/loginFunctions.cfm" runOnce="true">
<cfinclude template="/shared/component/databaseAccounts.cfc" runOnce="true">
<script>
	function pwc(p,u){
		var r=orapwCheck(p,u);
		var elem=document.getElementById('pwstatus');
		if (r=='Password is acceptable'){
			var clas='goodPW';
		} else {
			var clas='badPW';
		}
		elem.innerHTML=r;
		elem.className=clas;
	}
</script>

<!--- A reset link works once, for this long. --->
<cfset RESET_TOKEN_MINUTES = 60>
<!--- At most this many reset links are sent for one user in an hour. --->
<cfset RESET_REQUESTS_PER_HOUR = 3>

<cfparam name="url.action" default="">
<cfparam name="form.action" default="">
<cfset variables.action = url.action>
<cfif len(form.action) GT 0>
	<cfset variables.action = form.action>
</cfif>
<cfif len(variables.action) EQ 0 OR variables.action EQ "nothing">
	<cfset variables.action = "default">
</cfif>

<!---
	resetTokenUser find the user a password reset token is for.

	@param token the token from the emailed link.
	@return a query of user_id and username, with one row if the token is current and unused, otherwise none.
--->
<cffunction name="resetTokenUser" returntype="query" output="false">
	<cfargument name="token" type="string" required="yes">

	<cfset var getResetUser = "">
	<cfset var getResetUser_result = "">
	<cfset var tokenHash = "">

	<cfif REFind("^[0-9a-f]{64}$", arguments.token) EQ 0>
		<cfset tokenHash = "">
	<cfelse>
		<cfset tokenHash = lcase(hash(arguments.token, "SHA-256"))>
	</cfif>
	<cfquery name="getResetUser" datasource="uam_god" result="getResetUser_result">
		SELECT cf_users.user_id, cf_users.username
		FROM cf_password_reset
			JOIN cf_users ON cf_password_reset.user_id = cf_users.user_id
		WHERE
			cf_password_reset.token_hash = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#tokenHash#">
			AND cf_password_reset.used_date IS NULL
			AND cf_password_reset.expires_date > sysdate
	</cfquery>
	<cfreturn getResetUser>
</cffunction>

<cfswitch expression="#variables.action#">
<cfcase value="default">
	<cfif len(session.username) is 0>
		<cflocation url="/users/changePassword.cfm?action=lostPass" addtoken="false">
	</cfif>
	<cfoutput>
		<div class="container">
			<div class="row">
				<div class="col-12 mt-3 changePW">
					<cfquery name="pwExp" datasource="uam_god">
						select pw_change_date
						from cf_users where
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
					</cfquery>
					<cfset pwtime =  round(now() - pwExp.pw_change_date)>
					<cfset pwage = Application.max_pw_age - pwtime>
					<cfif session.username is "guest">
						Guests are not allowed to change passwords.<cfabort>
					</cfif>
					<h1 class="h2 mt-3">Change Password</h1>
					<p class="font-weight-lessbold">You are logged in as #session.username#.</p>
					<cfif pwtime LT Application.max_pw_age>
						<cfset oldpwclass="">
					<cfelse>
						<cfset oldpwclass="text-danger">
					</cfif>
					<p>Your password is <span class="font-weight-lessbold #oldpwclass#">#pwtime#</span> days old.</p>
					<cfquery name="isDb" datasource="uam_god">
						select
						(
							select count(*) c
							from all_users
							where
							username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(session.username)#">
						)
						+
						(
							select count(*) C
							from temp_allow_cf_user, cf_users
							where temp_allow_cf_user.user_id = cf_users.user_id
							and cf_users.username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						)
						cnt
						from dual
					</cfquery>
					<cfif isDb.cnt gt 0>
						<p class="font-weight-lessbold">Operators must change password every #Application.max_pw_age# days.</p>
						<h2 class="h4 w-100">Password rules:</h2>
						<ul class="list-style-disc px-4">
							<li class="pb-1">At least eight characters</li>
							<li class="pb-1">May not contain some special characters</li>
							<li class="pb-1">May not contain your username</li>
							<li class="pb-1">Must contain at least
								<ul class="mt-1 list-style-circle px-5">
									<li class="pb-1">One letter</li>
									<li class="pb-1">One number</li>
									<li class="pb-1">One special character</li>
								</ul>
							</li>
						</ul>
						<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
							<p>Harvard information security recommends the use of <a href="https://security.harvard.edu/lastpass">LastPass</a> for password management.</p>
						</cfif>
					</cfif>
						<form class="row" action="/users/changePassword.cfm" method="post">
							<input type="hidden" name="action" value="update">
							
								<div class="col-12 col-sm-6 col-md-4 col-xl-3 mb-2">
									<label for="oldpassword" class="data-entry-label">Old password</label>
									<input name="oldpassword" class="data-entry-input border-danger" id="oldpassword" type="password">
								</div>
							</div>
						
								<div class="col-12 col-sm-6 col-md-4 col-xl-3 mb-2">
									<label for="newpassword" class="data-entry-label">New password</label>
									<input name="newpassword" class="data-entry-input" id="newpassword" type="password"
										<cfif isDb.cnt gt 0>
											onkeyup="pwc(this.value,'#session.username#')"
										</cfif>	
									>
								</div>
								<span id="pwstatus"></span>
								<div class="col-12 col-sm-6 col-md-4 col-xl-3 mb-2">
									<label for="newpassword2" class="data-entry-label">Retype new password</label>
									<input name="newpassword2" class="data-entry-input" id="newpassword2" type="password">
								</div>
							</div>
							<div class="row">
								<div class="col-12 col-md-3 my-3">
									<input type="submit" value="Save Password Change" class="btn btn-xs btn-primary">
								</div>
							</div>
						</form>
						<cfquery name="isGoodEmail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
							SELECT email, username
							FROM 
								cf_user_data
								join cf_users on cf_user_data.user_id = cf_users.user_id 
							WHERE 
								username= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
						<cfif len(isGoodEmail.email) gt 0>
							<p>If you can't remember your old password, we can
								<a href="/users/changePassword.cfm?action=lostPass">email you a link to reset it</a>.
							</p>
						</cfif>
					</div>
				</div>
			</div>
		</div>
	</cfoutput>
</cfcase>
<cfcase value="lostPass">
	<!----------------------------------------------------------->
	<cfoutput>
		<main class="container py-3" id="content">
			<section class="row my-3 mx-0">
				<div class="col-12 px-4 pt-4 pb-2 border rounded">
					<div class="changePW"></div>
					<h1 class="h2">Lost your password?</h1>
					<p>Passwords are stored in an encrypted format and cannot be recovered.</p>
					<p>If you have saved your email address in your profile, enter it with your username, and we will email you a link to set a new password.  The link works once, for #RESET_TOKEN_MINUTES# minutes.</p>
					<p>If you have not saved your email address, please submit a bug report to that effect and we will reset your password for you.</p>
					<form class="row" name="pw" method="post" action="/users/changePassword.cfm">
						<div class="col-12 col-sm-4 col-xl-3">
							<input type="hidden" name="action" value="findPass">
							<label for="username" class="data-entry-label">Username</label>
							<input type="text" name="username" id="username" class="data-entry-input">
						</div>
						<div class="col-12 col-sm-4 col-xl-3">
							<label for="email" class="data-entry-label">Email Address</label>
							<input type="text" name="email" id="email" class="data-entry-input">
						</div>
						<div class="col-12 my-3">
							<input type="submit" value="Email Me a Reset Link" class="btn btn-xs btn-primary">
						</div>
					</form>
				</div>
			</section>
		</main>
	</cfoutput>
</cfcase>
<cfcase value="update">
	<cfparam name="form.oldpassword" default="">
	<cfparam name="form.newpassword" default="">
	<cfparam name="form.newpassword2" default="">
	<!-------------------------------------------------------------------->
	<div class="changePW">
		<cfoutput>
			<main class="container py-3">
				<section class="row my-3 mx-0">
					<div class="col-12 px-4 pt-4 pb-2 border rounded">
						<cfquery name="getPass" datasource="cf_dbuser">
							select password
							from cf_users
							where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
						</cfquery>
						<cfif hash(form.oldpassword) is not getpass.password>
							<span class="font-weight-lessbold text-danger">
								Incorrect old password. <a href="/users/changePassword.cfm">Go Back</a>
							</span>
							<cfabort>
						<cfelseif getpass.password is hash(form.newpassword)>
							<span class="font-weight-lessbold text-danger">
								You must pick a new password. <a href="/users/changePassword.cfm">Go Back</a>
							</span>
							<cfabort>
						<cfelseif form.newpassword neq form.newpassword2>
							<span class="font-weight-lessbold text-danger">
								New passwords do not match. <a href="/users/changePassword.cfm">Go Back</a>
							</span>
							<cfabort>
						</cfif>
						<!--- For a database account the password is also set in Oracle, by DDL that cannot take bind
							variables: the account name comes from the data dictionary and the password is checked before both
							are quoted into the statement.  Public accounts have no database account. --->
						<cfset variables.databaseAccount = databaseAccountName(session.username)>
						<cfif len(variables.databaseAccount) GT 0>
							<cfset variables.passwordProblem = databasePasswordProblem(form.newpassword)>
							<cfif len(variables.passwordProblem) EQ 0>
								<cfset variables.passwordProblem = databasePasswordCheck(variables.databaseAccount, form.newpassword, form.oldpassword)>
							</cfif>
							<cfif len(variables.passwordProblem) GT 0>
								<span class="font-weight-lessbold text-danger">
									#encodeForHtml(variables.passwordProblem)# <a href="/users/changePassword.cfm">Go Back</a>
								</span>
								<cfabort>
							</cfif>
						</cfif>
						<cftry>
							<cfif len(variables.databaseAccount) GT 0>
								<!--- DDL commits implicitly, so it runs before the cf_users update: if it fails, nothing has changed. --->
								<cfquery name="dbUser" datasource="uam_god">
									ALTER USER "#variables.databaseAccount#" IDENTIFIED BY "#form.newpassword#"
								</cfquery>
							</cfif>
							<cfquery name="setPass" datasource="uam_god" result="setPass_result">
								UPDATE cf_users
								SET
									password = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#hash(form.newpassword)#">,
									PW_CHANGE_DATE=sysdate
								WHERE
									username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
							</cfquery>
						<cfcatch>
							<cfif isPasswordComplexityError(cfcatch)>
								<span class="font-weight-lessbold text-danger">
									Your new password does not meet the database's password requirements. <a href="/users/changePassword.cfm">Go Back</a>
								</span>
								<cfabort>
							</cfif>
							<cflog file="MCZbase" type="error" text="Password change failed for #session.username#: #cfcatch.message# #cfcatch.detail#">
							<cfmail subject="Password change failed" to="#Application.PageProblemEmail#" from="SomethingBroke@#Application.fromEmail#" type="text">
Changing the password for MCZbase user #session.username# failed: #cfcatch.message#
							</cfmail>
							<h1 class="h3">Your password could not be changed. Please <a href="/contact.cfm">contact us</a>.</h1>
							<cfabort>
						</cfcatch>
						</cftry>
						<cfset session.force_password_change = "">
						<cfset initSession('#session.username#','#form.newpassword#')>
						<h1 class="h3">Your password has successfully been changed.</h1>
						<p>You will be redirected soon, or you may use the menu above now.</p>
						<script>
							setTimeout("go_now()",5000);
							function go_now () {
								document.location='#Application.ServerRootUrl#/users/UserProfile.cfm';
							}
						</script>
					</div>
				</section>
			</main>
		</cfoutput>
	</div>
</cfcase>
<cfcase value="findPass">
	<!---------------------------------------------------------------------->
	<!--- Emails a single use, time limited link; nothing about the account changes until the link is
		used, so knowing a username and email address is no longer enough to change a password.  The
		response is the same whether or not they match an account. --->
	<cfparam name="form.username" default="">
	<cfparam name="form.email" default="">
	<cfif cgi.request_method NEQ "POST">
		<cflocation url="/users/changePassword.cfm?action=lostPass" addtoken="false">
	</cfif>
	<cfquery name="isGoodEmail" datasource="cf_dbuser">
		SELECT cf_user_data.user_id, email, username
		FROM cf_user_data
			join cf_users on cf_user_data.user_id = cf_users.user_id
		WHERE
			email = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.email)#">
			and username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(form.username)#">
	</cfquery>
	<cfif isGoodEmail.recordcount EQ 1>
		<cfquery name="recentRequests" datasource="uam_god" result="recentRequests_result">
			SELECT count(*) AS ct
			FROM cf_password_reset
			WHERE
				user_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#isGoodEmail.user_id#">
				AND created_date > sysdate - 1/24
		</cfquery>
		<cfif recentRequests.ct LT RESET_REQUESTS_PER_HOUR>
			<!--- generateSecretKey draws 256 bits from a secure random source; only the token's hash is stored. --->
			<cfset variables.resetToken = lcase(binaryEncode(binaryDecode(generateSecretKey("AES", 256), "base64"), "hex"))>
			<cftransaction>
				<!--- Only the newest link works. --->
				<cfquery name="supersedeTokens" datasource="uam_god" result="supersedeTokens_result">
					UPDATE cf_password_reset
					SET used_date = sysdate
					WHERE
						user_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#isGoodEmail.user_id#">
						AND used_date IS NULL
				</cfquery>
				<cfquery name="addToken" datasource="uam_god" result="addToken_result">
					INSERT INTO cf_password_reset (
						token_hash,
						user_id,
						expires_date,
						requested_from
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lcase(hash(variables.resetToken, "SHA-256"))#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#isGoodEmail.user_id#">,
						sysdate + <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#RESET_TOKEN_MINUTES#"> / 1440,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#left(cgi.remote_addr, 255)#">
					)
				</cfquery>
			</cftransaction>
			<cfmail to="#isGoodEmail.email#" subject="#Application.application_name# password reset" from="LostFound@#Application.fromEmail#" type="text">
Someone, probably you, asked to reset the password for your #Application.application_name# account, username #isGoodEmail.username#.

To set a new password, open this link within #RESET_TOKEN_MINUTES# minutes.  It works once.

#Application.ServerRootUrl#/users/changePassword.cfm?action=resetForm&token=#variables.resetToken#

If you did not ask for this, you can ignore this email: your password has not changed.
Questions: #Application.technicalEmail#
			</cfmail>
		<cfelse>
			<cflog file="MCZbase" type="warning" text="Password reset link not sent for user_id #isGoodEmail.user_id#: #recentRequests.ct# requests in the last hour.">
		</cfif>
	</cfif>
	<cfoutput>
		<main class="container py-3" id="content">
			<section class="row my-3 mx-0">
				<div class="col-12 px-4 pt-4 pb-2 border rounded">
					<h1 class="h3">Check your email</h1>
					<p>If that username and email address match an account, we have sent a link to set a new password to that address.
						It may take a few minutes to arrive, and works once, for #RESET_TOKEN_MINUTES# minutes.</p>
					<p>If no email arrives, check the username and the address saved in your profile, or <a href="/contact.cfm">contact us</a>.</p>
				</div>
			</section>
		</main>
	</cfoutput>
</cfcase>
<cfcase value="resetForm">
	<!---------------------------------------------------------------------->
	<!--- Opened from the emailed link.  Showing the form does not use the token, as mail scanners may
		open links; resetPass does. --->
	<cfparam name="url.token" default="">
	<!--- Keep the token out of the Referer header sent to any other site the page loads from. --->
	<cfheader name="Referrer-Policy" value="no-referrer">
	<cfset variables.resetUser = resetTokenUser(url.token)>
	<cfoutput>
		<main class="container py-3" id="content">
			<section class="row my-3 mx-0">
				<div class="col-12 px-4 pt-4 pb-2 border rounded">
					<cfif variables.resetUser.recordcount NEQ 1>
						<h1 class="h3">This link has expired or has already been used</h1>
						<p><a href="/users/changePassword.cfm?action=lostPass">Request a new link</a>.</p>
					<cfelse>
						<h1 class="h3">Set a new password for #encodeForHtml(variables.resetUser.username)#</h1>
						<h2 class="h4 w-100">Password rules:</h2>
						<ul class="list-style-disc px-4">
							<li class="pb-1">Eight to thirty characters</li>
							<li class="pb-1">May not contain your username</li>
							<li class="pb-1">Must contain at least one letter, one number, and one of ! ## $ % &amp; ( ) ` * + , - / : ; &lt; = &gt; ? _</li>
							<li class="pb-1">May contain letters, digits and punctuation, but not spaces, double quotes or accented characters</li>
						</ul>
						<form class="row" action="/users/changePassword.cfm" method="post">
							<input type="hidden" name="action" value="resetPass">
							<input type="hidden" name="token" value="#encodeForHtmlAttribute(url.token)#">
							<div class="col-12 col-sm-6 col-md-4 col-xl-3 mb-2">
								<label for="newpassword" class="data-entry-label">New password</label>
								<input name="newpassword" class="data-entry-input" id="newpassword" type="password" autocomplete="new-password"
									onkeyup="pwc(this.value,'#encodeForJavaScript(variables.resetUser.username)#')">
								<span id="pwstatus"></span>
							</div>
							<div class="col-12 col-sm-6 col-md-4 col-xl-3 mb-2">
								<label for="newpassword2" class="data-entry-label">Retype new password</label>
								<input name="newpassword2" class="data-entry-input" id="newpassword2" type="password" autocomplete="new-password">
							</div>
							<div class="col-12 my-3">
								<input type="submit" value="Set Password" class="btn btn-xs btn-primary">
							</div>
						</form>
					</cfif>
				</div>
			</section>
		</main>
	</cfoutput>
</cfcase>
<cfcase value="resetPass">
	<!---------------------------------------------------------------------->
	<cfparam name="form.token" default="">
	<cfparam name="form.newpassword" default="">
	<cfparam name="form.newpassword2" default="">
	<cfif cgi.request_method NEQ "POST">
		<cflocation url="/users/changePassword.cfm?action=lostPass" addtoken="false">
	</cfif>
	<cfset variables.resetUser = resetTokenUser(form.token)>
	<cfset variables.problem = "">
	<cfset variables.databaseAccount = "">
	<cfif variables.resetUser.recordcount NEQ 1>
		<cfset variables.problem = "This link has expired or has already been used.">
	<cfelseif compare(form.newpassword, form.newpassword2) NEQ 0>
		<cfset variables.problem = "The two passwords you typed do not match.">
	<cfelse>
		<cfset variables.problem = passwordRuleProblem(variables.resetUser.username, form.newpassword)>
		<cfif len(variables.problem) EQ 0>
			<cfset variables.databaseAccount = databaseAccountName(variables.resetUser.username)>
			<cfif len(variables.databaseAccount) GT 0>
				<cfset variables.problem = databasePasswordCheck(variables.databaseAccount, form.newpassword)>
				<!--- A reset may clear a lock from failed logins, LOCKED(TIMED), but not one an administrator set,
					which only global_admin may lift, from AdminUsers.cfm. --->
				<cfquery name="getAccountStatus" datasource="uam_god" result="getAccountStatus_result">
					SELECT account_status
					FROM dba_users
					WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#variables.databaseAccount#">
				</cfquery>
				<cfif len(variables.problem) EQ 0 AND findNoCase("LOCKED", replaceNoCase(getAccountStatus.account_status, "LOCKED(TIMED)", "", "all")) GT 0>
					<cfset variables.problem = "Your account has been locked by an administrator, so its password cannot be reset here.  Please contact us.">
				</cfif>
			</cfif>
		</cfif>
	</cfif>
	<cfif len(variables.problem) EQ 0>
		<!--- Claim the token before changing anything, so two posts of one link cannot both succeed. --->
		<cfquery name="claimToken" datasource="uam_god" result="claimToken_result">
			UPDATE cf_password_reset
			SET used_date = sysdate
			WHERE
				token_hash = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lcase(hash(form.token, "SHA-256"))#">
				AND used_date IS NULL
				AND expires_date > sysdate
		</cfquery>
		<cfif claimToken_result.recordcount NEQ 1>
			<cfset variables.problem = "This link has expired or has already been used.">
		<cfelse>
			<cftry>
				<cfif len(variables.databaseAccount) GT 0>
					<!--- DDL commits implicitly, so it runs before the cf_users update: if it fails, nothing has changed. --->
					<cfquery name="resetOracleUser" datasource="uam_god">
						ALTER USER "#variables.databaseAccount#" IDENTIFIED BY "#form.newpassword#" ACCOUNT UNLOCK
					</cfquery>
				</cfif>
				<cfquery name="setNewPass" datasource="uam_god" result="setNewPass_result">
					UPDATE cf_users
					SET
						password = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#hash(form.newpassword)#">
					WHERE
						user_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.resetUser.user_id#">
				</cfquery>
			<cfcatch>
				<!--- Nothing changed, so let the same link be used again. --->
				<cfquery name="releaseToken" datasource="uam_god" result="releaseToken_result">
					UPDATE cf_password_reset
					SET used_date = NULL
					WHERE token_hash = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#lcase(hash(form.token, "SHA-256"))#">
				</cfquery>
				<cfif isPasswordComplexityError(cfcatch)>
					<cfset variables.problem = "The database did not accept that password.  Please choose another.">
				<cfelse>
					<cflog file="MCZbase" type="error" text="Password reset failed for user_id #variables.resetUser.user_id#: #cfcatch.message#">
					<cfset variables.problem = "Your password could not be reset.">
				</cfif>
			</cfcatch>
			</cftry>
		</cfif>
	</cfif>
	<cfoutput>
		<main class="container py-3" id="content">
			<section class="row my-3 mx-0">
				<div class="col-12 px-4 pt-4 pb-2 border rounded">
					<cfif len(variables.problem) GT 0>
						<h1 class="h3">Your password was not changed</h1>
						<p class="text-danger">#encodeForHtml(variables.problem)#</p>
						<cfif variables.resetUser.recordcount EQ 1>
							<p><a href="/users/changePassword.cfm?action=resetForm&token=#encodeForUrl(form.token)#">Try again</a>.</p>
						<cfelse>
							<p><a href="/users/changePassword.cfm?action=lostPass">Request a new link</a>, or <a href="/contact.cfm">contact us</a>.</p>
						</cfif>
					<cfelse>
						<cfquery name="getResetEmail" datasource="cf_dbuser">
							SELECT email
							FROM cf_user_data
							WHERE user_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#variables.resetUser.user_id#">
						</cfquery>
						<cfif len(getResetEmail.email) GT 0>
							<cfmail to="#getResetEmail.email#" subject="#Application.application_name# password changed" from="LostFound@#Application.fromEmail#" type="text">
The password for your #Application.application_name# account, username #variables.resetUser.username#, was changed using a reset link.

If you did not do this, reply to #Application.technicalEmail# at once.
							</cfmail>
						</cfif>
						<!--- a reset proves control of the account's email, so it also ends a lock from failed logins --->
						<cfif NOT isDefined("clearLoginLock")>
							<cfinclude template="/shared/component/loginThrottle.cfc" runOnce="true">
						</cfif>
						<cfset clearLoginLock("username", variables.resetUser.username)>
						<cfset initSession()>
						<h1 class="h3">Your password has been changed</h1>
						<p><a href="/login.cfm?username=#encodeForUrl(variables.resetUser.username)#">Log in to #encodeForHtml(Application.application_name)#</a> with your new password.</p>
					</cfif>
				</div>
			</section>
		</main>
	</cfoutput>
</cfcase>
</cfswitch>
<!---------------------------------------------------------------------->
<cfinclude template = "/shared/_footer.cfm">
