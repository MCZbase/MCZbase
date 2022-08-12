<!--- login.cfm login dialog and account creation

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2022 President and Fellows of Harvard College

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
<cfset pageTitle = "Login">
<cfinclude template = "/shared/_header.cfm">
<cfif isdefined("session.username") and len(#session.username#) gt 0 and (NOT isDefined("action") OR #action# neq "signOut")>
	<!--- user is logged in already, redirect to user profile page --->
	<cflocation url="/users/UserProfile.cfm" addtoken="false">
</cfif>
<cfif NOT isDefined("action") or len(action) EQ 0>
	<cfset action="loginForm">
</cfif>
<cfswitch expression="#action#">
	<!------------------------------------------------------------>
	<cfcase value="signOut">
		<cfinclude template="/shared/loginFunctions.cfm" runOnce="true">
		<cfset initSession()>
		<cflocation url="/Specimens.cfm" addtoken="false">
	</cfcase>
	<!------------------------------------------------------------>
	<cfcase value="loginForm">
		<cfif NOT isDefined("mode") or len(mode) EQ 0>
			<cfset mode="">
		</cfif>
		<script type="text/javascript" src="/shared/js/login_scripts.js"></script> 
		<script>
			function validateAndRegister() {
				var uname = $("#formUsername").val();
				var pword = $("#formPassword").val();
				if (uname.length == 0 || pword.length == 0) {
					messageDialog("Enter a username and a password in this form to create an account.","Username and password are required.");
				} else {
					var checkResult = orapwCheck(pword,uname);
					if (checkResult =='Password is acceptable'){
						$("#formAction").val("newUser");
						$("#loginform").submit();
					} else {
						messageDialog(checkResult,"Password does not meet complexity requirements.");
					}
				}
			}
		</script>
		<cfoutput>
			<cfif NOT isDefined("username") or len(username) EQ 0 ><cfset username=""></cfif>
			<cfif not isdefined("gotopage")>
				<cfset gotopage=''>
			</cfif>
			<main class="container py-3" id="content" >
				<section class="row mx-0 my-3">
					<div class="col-12 py-3 border rounded">
						<cfif mode EQ "register"> 
							<cfset headingText = "Create an Account">
						<cfelseif mode EQ "authenticate"> 
							<cfset headingText = "Log In">
						<cfelse>
							<cfset headingText = "Log In (or Create an Account)">
						</cfif>

						<form name="loginform" id="loginform" method="post" action="/login.cfm">
							<input name="action" id="formAction" value="signIn" type="hidden">
							<input name="gotopage" value="#gotopage#" type="hidden">
							<input name="mode" value="#mode#" type="hidden">
							<div class="form-row mx-0">
								<h1 class="h2 px-2">#headingText#</h1>
								<p class="px-2">Logging in enables you to download data, turn on, turn off, or otherwise customize many features of
									this database. To create an account and log in, simply supply a username and
									password here and click Create Account.
								</p>
								<div class="col-12 col-md-6 col-xl-4">
									<label for="formUsername" class="data-entry-label">Username</label>
									<input name="username" class="data-entry-input reqdClr" type="text" tabindex="1" value="#encodeForHtml(username)#" id="formUsername" required>
								</div>
								<div class="col-12 col-md-6 col-xl-4">
									<label for="formPassword" class="data-entry-label">Password</label>
									<input name="password" class="data-entry-input reqdClr" type="password" tabindex="2" value="" id="formPassword" required>
								</div>
								<div class="col-12 col-xl-8">
									<cfif isdefined("badPW") and badPW is true>
										<cfif not isdefined("err") or len(err) is 0>
											<cfset err="Your username or password was not recognized. Please try again.">
										</cfif>
										<h2 class="data-entry-label sr-only mb-0">Error</h2>
										<div class="data-entry-input bg-danger text-white mt-3">#err#</div>
										<script>
											$(document).ready(function() { 
												$('##username').css('backgroundColor','red');
												$('##password').val('').css('backgroundColor','red').select().focus();
												$('##formUsername').css('backgroundColor','red');
												$('##formPassword').val('').css('backgroundColor','red').select().focus();
											});
										</script>
									</cfif>
								</div>
							</div>
							<div class="form-row mx-0 my-2">
								<cfif mode NEQ "register"> 
									<div class="col-12 col-sm-4 col-md-2 col-xl-1 py-2">
										<input type="submit" class="btn btn-xs btn-primary px-3" value="Sign In" onClick="$('##formAction').value='signIn';submit();" tabindex="3">
									</div>
								</cfif>
			<!---					<cfif mode EQ "">
									<div class="col-1 col-md-1 text-center">
										or
									</div>
								</cfif>--->
								<cfif mode NEQ "authenticate"> 
									<div class="col-12 col-sm-4 col-md-3 py-2">
										<input type="button" class="btn btn-xs btn-secondary" value="Create an Account" class="insBtn" onClick="validateAndRegister();" tabindex="4">
									</div>
								</cfif>
							</div>
							<cfif mode EQ "register"> 
								<div class="form-row mx-0 my-2">
									<div class="col-12">
										<h2 class="h3 w-100 px-2">Password rules:</h2>
										<ul class="list-style-disc px-5">
											<li class="pb-1">At least eight characters</li>
											<li class="pb-1">May not contain your username</li>
											<li class="pb-1">Must contain at least:
												<ul class="mt-1 list-style-circle px-5">
													<li class="pb-1">One letter</li>
													<li class="pb-1">One number</li>
													<li class="pb-1">One special character .&nbsp;!&nbsp;$&nbsp;%&nbsp;&amp;&nbsp;*&nbsp;?&nbsp;_&nbsp;-&nbsp;(&nbsp;)&nbsp;<&nbsp;>&nbsp;=&nbsp;/&nbsp;:&nbsp;;</li>
												</ul>
											</li>
											<li class="pb-1">May only contain characters A-Z, a-z, 0-9, and .&nbsp;!&nbsp;$&nbsp;%&nbsp;&amp;&nbsp;_&nbsp;?&nbsp;\&nbsp;-&nbsp;)&nbsp;&lt;&nbsp;(&nbsp;&gt;&nbsp;=&nbsp;/&nbsp;:&nbsp;;&nbsp;*</li>
										</ul>
									</div>
								</div>
							</cfif>
						</form>
							<div class="form-row mx-0">
								<div class="col-12">
									<p><a href="/users/changePassword.cfm">Lost your password?</a> If you created a profile with an email address,
									we can send it to you. You can also just create a new account.</p>
									<p class="mb-1">You can explore MCZbase using basic options without signing in.</p>
								</div>
							</div>
					</section>
			</main>
		</cfoutput>
	</cfcase>
	<!------------------------------------------------------------>
	<cfcase value="newUser">
		<!--- Check that conditions for new account are met --->
		<cfset err="">
		<cfquery name="uUser" datasource="cf_dbuser">
			select * from cf_users where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#username#">
		</cfquery>
		<cfif len(password) is 0>
			<cfset err="Your password must be at least one character long.">
		</cfif>
		<cfquery name="dbausr" datasource="uam_god">
			select username from dba_users where upper(username) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(username)#">
		</cfquery>
		<cfif len(dbausr.username) gt 0>
			<cfset err="That username is already in use.">
		</cfif>
		<cfif len(username) is 0>
			<cfset err="Your user name must be at least one character long.">
		</cfif>
		<cfif uUser.recordcount gt 0>
			<cfset err="That username is already in use.">
		</cfif>
		<cfif len(err) gt 0>
			<!--- Don't create the new account --->
			<cflocation url="/login.cfm?username=#username#&badPW=true&err=#err#" addtoken="false">
		</cfif>
		<!--- Create the new account --->
		<cfoutput>
			<cftransaction>
				<cftry>
					<cfquery name="nextUserID" datasource="cf_dbuser">
						select max(user_id) + 1 as nextid from cf_users
					</cfquery>
					<cfquery name="newUser" datasource="cf_dbuser">
						INSERT INTO cf_users (
							user_id,
							username,
							password,
							PW_CHANGE_DATE,
							last_login
						) VALUES (
							<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#nextUserID.nextid#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#username#">,
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#hash(password)#">,
							sysdate,
							sysdate
						)
					</cfquery>
					<cftransaction action="commit">
				<cfcatch>
					<cftransaction action="rollback">
					<cfset err="User Creation Failed. #cfcatch.message#">
					<cflocation url="/login.cfm?username=#encodeForURL(username)#&badPW=true&err=#encodeForURL(err)#&mode=#encodeForURL(mode)#" addtoken="false">
				</cfcatch>
				</cftry>
				<main class="container py-3" id="content" >
					<section class="row my-3 p-2">
						<div class="col-12 py-2 border rounded rounded">
							<h1 class="h2 w-100">Successfully created user #encodeForHtml(username)#.</h1>
							<div class="mt-2">
								<a href="/login.cfm?username=#encodeForURL(username)#&gotopage=/users/UserProfile.cfm&mode=authenticate" addtoken="false">Login to MCZbase</a>
							</div>
						</div>
					</section>
				</main>
			</cftransaction>
		</cfoutput>
	</cfcase>
	<!------------------------------------------------------------>
	<cfcase value="signIn">
		<cfinclude template="/shared/loginFunctions.cfm" runOnce="true">
		<cfoutput>
			<cfset initSession('#username#','#password#')>
			<cfif len(session.username) is 0>
				<cfset u="/login.cfm?badPW=true&username=#encodeForUrl(username)#">
				<cfif isdefined("gotopage")>
					<cfset u=u & '&gotopage=#encodeForUrl(gotopage)#'>
				</cfif>
				<cflocation url="#u#" addtoken="false">
			</cfif>
	
			<cfif not isdefined("gotopage") or len(gotopage) is 0>
				<cfif isdefined("cgi.HTTP_REFERER") and left(cgi.HTTP_REFERER,(len(application.serverRootUrl))) is application.serverRootUrl>
					<cfset gotopage=replace(cgi.HTTP_REFERER,application.serverRootUrl,'')>
					<cfset junk="CFID,CFTOKEN">
					<cfloop list="#gotopage#" index="e" delimiters="?&">
						<cfloop list="#junk#" index="j">
							<cfif left(e,len(j)) is j>
								<cfset rurl=replace(gotopage,e,'','all')>
							</cfif>
						</cfloop>
					</cfloop>
					<cfset t=1>
					<cfset rurl=replace(gotopage,"?&","?","all")>
					<cfset rurl=replace(gotopage,"&&","&","all")>
					<cfset nogo="login.cfm,errors/">
					<cfloop list="#nogo#" index="n">
						<cfif gotopage contains n>
							<cfset gotopage = "/Specimens.cfm">
						</cfif>
					</cfloop>
				<cfelse>
					<cfset gotopage = "/Specimens.cfm">
				</cfif>
			</cfif>
			<cfif session.roles contains "coldfusion_user">
				<cfquery name="getUserData" datasource="cf_dbuser">
					SELECT
						cf_users.user_id,
						first_name,
						middle_name,
						last_name,
						affiliation,
						email,
						PW_CHANGE_DATE
					FROM
						cf_user_data,
						cf_users
					WHERE
						cf_users.user_id = cf_user_data.user_id (+) AND
						username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				</cfquery>
				<cfset pwtime = round(now() - getUserData.pw_change_date)>
				<cfset pwage = Application.max_pw_age - pwtime>
				<cfif pwage lte 7>
					<div style="text-align:center;color:red;font-weight:bold;">
						Your password expires in #pwage# days
						<br>You may <a href="/users/changePassword.cfm">change it now</a>
					</div>
					<a href="#gotopage#">Continue to #encodeForHtml(gotopage)#</a>
				<cfelse>
					<cflocation url="#gotopage#" addtoken="no">
				</cfif>
				<cfif len(getUserData.email) is 0>
					<cfset session.needEmailAddr=1>
				</cfif>
			<cfelse>
				<cflocation url="#gotopage#" addtoken="no">
			</cfif>
		</cfoutput>
	</cfcase>
</cfswitch>

<cfinclude template = "/shared/_footer.cfm">
