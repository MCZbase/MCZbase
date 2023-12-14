<cfset pageTitle = "Change Password">
<cfinclude template = "/shared/_header.cfm">
<!---------------------------------------------------------------------------------->
<script type="text/javascript" src="/shared/js/login_scripts.js"></script> 
<cfinclude template="/shared/loginFunctions.cfm" runOnce="true">
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
						<cfquery name="isGoodEmail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
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
						<!--- Passwords check out for public users, now see if they're a database user --->
						<cftransaction>
							<cfquery name="isDb" datasource="uam_god">
								SELECT *
								FROM all_users
								WHERE
								username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(session.username)#">
							</cfquery>
							<cfif isDb.recordcount is 0>
								<cfquery name="setPass" datasource="uam_god">
									UPDATE cf_users
									SET
										password = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#hash(newpassword)#">,
										PW_CHANGE_DATE=sysdate
									WHERE
										username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
								</cfquery>
								<cftransaction action="commit">
							<cfelse>
								<cftry>
									<cfquery name="dbUser" datasource="uam_god">
										alter user #session.username#
										identified by "#newpassword#"
									</cfquery>
									<cfquery name="setPass" datasource="uam_god">
										UPDATE cf_users
										SET
											password = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#hash(newpassword)#">,
											PW_CHANGE_DATE=sysdate
										WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
									</cfquery>
									<cftransaction action="commit">
								<cfcatch>
									<cftransaction action="rollback">
									<cfsavecontent variable="errortext">
										<h1 class="h3">Error in creating user.</h1>
										<p>#cfcatch.Message#</p>
										<p>#cfcatch.Detail#"</p>
										<CFIF isdefined("CGI.HTTP_X_Forwarded_For") and #len(CGI.HTTP_X_Forwarded_For)# gt 0>
											<CFSET ipaddress="#CGI.HTTP_X_Forwarded_For#">
										<CFELSEif  isdefined("CGI.Remote_Addr") and #len(CGI.Remote_Addr)# gt 0>
											<CFSET ipaddress="#CGI.Remote_Addr#">
										<cfelse>
											<cfset ipaddress='unknown'>
										</CFIF>
										<p>ipaddress: <cfoutput><a href="http://network-tools.com/default.asp?prog=network&host=#ipaddress#">#ipaddress#</a></cfoutput></p>
										<hr>
										<p>Client Dump:</p>
										<hr>
										<cfdump var="#client#" label="client">
										<hr>
										<p>URL Dump:</p>
										<hr>
										<cfdump var="#url#" label="url">
										<p>CGI Dump:</p>
										<hr>
										<cfdump var="#CGI#" label="CGI">
									</cfsavecontent>
									<cfmail subject="Error" to="#Application.PageProblemEmail#" from="SomethingBroke@#Application.fromEmail#" type="html">
										#errortext#
									</cfmail>
									<h3>Error in changing password user.</h3>
									<p>#cfcatch.Message#</p>
									<p>#cfcatch.Detail#</p>
									<cfabort>
								</cfcatch>
								</cftry>
							</cfif>
						</cftransaction>
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
							<cfset charList = "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,z,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,1,2,3,4,5,6,7,8,9,0">
							<cfset numList="1,2,3,4,5,6,7,8,9,0">
							<cfset specList="!,$,%,_,*,?,-,(,),=,/,:,;,.">
							<cfset newPass = "">
							<cfset cList="#charList#,#numList#,#specList#">
							<cfset c=0>
							<cfset i=1>
							<cfset thisChar = ListGetAt(charList,RandRange(1,listlen(charList)))>
							<cfset newPass=newPass & thisChar>
							<cfset thisChar = ListGetAt(numList,RandRange(1,listlen(numList)))>
							<cfset newPass=newPass & thisChar>
							<cfset thisChar = ListGetAt(specList,RandRange(1,listlen(specList)))>
							<cfset newPass=newPass & thisChar>
							<cfloop from="1" to="10" index="i">
								<cfset thisChar = ListGetAt(cList,RandRange(1,listlen(cList)))>
								<cfset newPass=newPass & thisChar>
							</cfloop>
							<cftransaction>
								<cfquery name="stopTrg" datasource="uam_god">
									alter trigger CF_PW_CHANGE disable
								</cfquery>
								<cfquery name="setNewPass" datasource="uam_god">
									UPDATE cf_users
									SET
										password = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#hash(newPass)#">,
										pw_change_date=sysdate-91
									where
										user_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#isGoodEmail.user_id#">
								</cfquery>
								<cftry>
									<cfquery name="unlock" datasource="uam_god">
                                                                                alter user #isGoodEmail.username# account unlock
                                                                        </cfquery>
									<cfquery name="db" datasource="uam_god">
										alter user #isGoodEmail.username# identified by <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#newPass#">
									</cfquery>
								<cfcatch>
									<!--- not a DB user - whatever --->
								</cfcatch>
								</cftry>
								<cfquery name="stopTrg" datasource="uam_god">
									alter trigger CF_PW_CHANGE enable
								</cfquery>
							</cftransaction>
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
