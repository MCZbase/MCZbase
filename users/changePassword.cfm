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

<cfif not isDefined("action") OR len(action) EQ 0>
	<cfset action="default">
<cfelseif isDefined("action") AND action EQ "nothing">
	<cfset action="default">
</cfif>

<cfswitch expression="#action#">
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
								<a href="/users/changePassword.cfm?action=lostPass">email a new temporary password</a>.
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
	<main class="container py-3">
		<section class="row my-3 mx-0">
			<div class="col-12 px-4 pt-4 pb-2 border rounded">
				<div class="changePW"></div>
				<h1 class="h2">Lost your password?</h1>
				<p>Passwords are stored in an encrypted format and cannot be recovered.</p>
				<p>If you have saved your email address in your profile, enter it here to reset your password.</p>
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
						<input type="submit" value="Request Password" class="btn btn-xs btn-primary">
					</div>
				</form>
			</div>
		</section>
	</main>
</cfcase>
<cfcase value="update">
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
						<cfif hash(oldpassword) is not getpass.password>
							<span class="font-weight-lessbold text-danger">
								Incorrect old password. <a href="/users/changePassword.cfm">Go Back</a>
							</span>
							<cfabort>
						<cfelseif getpass.password is hash(newpassword)>
							<span class="font-weight-lessbold text-danger">
								You must pick a new password. <a href="/users/changePassword.cfm">Go Back</a>
							</span>
							<cfabort>
						<cfelseif newpassword neq newpassword2>
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
							<cfset variables.passwordProblem = databasePasswordProblem(newpassword)>
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
									ALTER USER "#variables.databaseAccount#" IDENTIFIED BY "#newpassword#"
								</cfquery>
							</cfif>
							<cfquery name="setPass" datasource="uam_god" result="setPass_result">
								UPDATE cf_users
								SET
									password = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#hash(newpassword)#">,
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
						<cfset initSession('#session.username#','#newpassword#')>
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
   <div class="changePW">
		<cfoutput>
			<main class="container py-3">
				<section class="row my-3 mx-0">
					<div class="col-12 px-4 pt-4 pb-2 border rounded">
						<cfquery name="isGoodEmail" datasource="cf_dbuser">
							SELECT cf_user_data.user_id, email, username
							FROM cf_user_data
								join cf_users on cf_user_data.user_id = cf_users.user_id
							WHERE
								email = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#email#">
							and username= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#username#">
						</cfquery>
						<cfif isGoodEmail.recordcount neq 1>
							<h1 class="h3 mt-3">Sorry, that email was not associated with your username.</h1>
							<cfabort>
						<cfelse>
							<!--- SHA1PRNG is cryptographically secure, unlike RandRange's default.  One letter, one digit and one
								symbol are guaranteed, then shuffled out of fixed positions.  The symbols are ones the database's
								verify function counts as punctuation, and include no quotes, as the password is placed in quoted DDL. --->
							<cfset variables.LETTERS = "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z">
							<cfset variables.DIGITS = "0,1,2,3,4,5,6,7,8,9">
							<cfset variables.SYMBOLS = "!,$,%,_,*,?,-,(,),=,/,:,;">
							<cfset variables.allCharacters = "#variables.LETTERS#,#variables.DIGITS#,#variables.SYMBOLS#">
							<cfset variables.passwordCharacters = arrayNew(1)>
							<cfset arrayAppend(variables.passwordCharacters, listGetAt(variables.LETTERS, randRange(1, listLen(variables.LETTERS), "SHA1PRNG")))>
							<cfset arrayAppend(variables.passwordCharacters, listGetAt(variables.DIGITS, randRange(1, listLen(variables.DIGITS), "SHA1PRNG")))>
							<cfset arrayAppend(variables.passwordCharacters, listGetAt(variables.SYMBOLS, randRange(1, listLen(variables.SYMBOLS), "SHA1PRNG")))>
							<cfloop from="1" to="10" index="variables.i">
								<cfset arrayAppend(variables.passwordCharacters, listGetAt(variables.allCharacters, randRange(1, listLen(variables.allCharacters), "SHA1PRNG")))>
							</cfloop>
							<cfloop from="#arrayLen(variables.passwordCharacters)#" to="2" step="-1" index="variables.i">
								<cfset arraySwap(variables.passwordCharacters, variables.i, randRange(1, variables.i, "SHA1PRNG"))>
							</cfloop>
							<cfset newPass = arrayToList(variables.passwordCharacters, "")>
							<!--- Oracle DDL cannot take bind variables, so it uses only the account name the data dictionary
								returns, checked and quoted, never the username from the request or cf_users; accounts with
								no Oracle user get no DDL.  newPass is generated above and contains no quotes. --->
							<cftry>
								<cfset variables.databaseAccount = databaseAccountName(isGoodEmail.username)>
								<cfif len(variables.databaseAccount) GT 0>
									<cfif REFind("^[A-Za-z0-9!$%_*?=/:;()-]+$", newPass) EQ 0 OR len(databasePasswordProblem(newPass)) GT 0>
										<cfthrow message="Unexpected characters in the generated password.">
									</cfif>
									<!--- DDL commits implicitly, so it runs before the cf_users updates: if it fails, nothing has changed. --->
									<cfquery name="resetOracleUser" datasource="uam_god">
										ALTER USER "#variables.databaseAccount#" IDENTIFIED BY "#newPass#" ACCOUNT UNLOCK
									</cfquery>
								</cfif>
								<cftransaction>
									<cfquery name="setNewPass" datasource="uam_god" result="setNewPass_result">
										UPDATE cf_users
										SET
											password = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#hash(newPass)#">
										WHERE
											user_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#isGoodEmail.user_id#">
									</cfquery>
									<!--- CF_PW_CHANGE stamps pw_change_date only when the password changes, so a second update
										can backdate it without disabling the trigger for every session. --->
									<cfquery name="backdatePass" datasource="uam_god" result="backdatePass_result">
										UPDATE cf_users
										SET
											pw_change_date = sysdate - 91
										WHERE
											user_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#isGoodEmail.user_id#">
									</cfquery>
								</cftransaction>
							<cfcatch>
								<cflog file="MCZbase" type="error" text="Password reset failed for user_id #isGoodEmail.user_id#: #cfcatch.message#">
								<h1 class="h3 mt-3">Your password could not be reset. Please <a href="/contact.cfm">contact us</a>.</h1>
								<cfabort>
							</cfcatch>
							</cftry>
							<cfmail to="#email#" subject="Arctos password" from="LostFound@#Application.fromEmail#" type="text">
								Your MCZbase username and password is

								username: #username# 
								temporary password: #newPass#

								You will be required to change your password
								after logging in.

								#Application.ServerRootUrl#/login.cfm

								If you did not request this change, please reply to #Application.technicalEmail#.
							</cfmail>
							<div>An email containing your new password has been sent to the email address on file. It may take a few minutes to arrive.</div>
							<cfset initSession()>
						</cfif>
					</div>
				</section>
			</main>
		</cfoutput>
	</div>
</cfcase>
</cfswitch>
<!---------------------------------------------------------------------->
<cfinclude template = "/shared/_footer.cfm">
