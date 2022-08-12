<cfset pageTitle = "Change Password">
<cfinclude template = "/shared/_header.cfm">
<!---------------------------------------------------------------------------------->
<script type="text/javascript" src="/shared/js/login_scripts.js"></script> 
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
<cfif isDefined("action") AND action EQ "nothing">
	<cfset action="default">
</cfif>

<cfswitch expression="#action#">
<cfcase value="default">
	<cfif len(session.username) is 0>
		<cflocation url="/users/changePassword.cfm?action=lostPass" addtoken="false">
	</cfif>
	<cfoutput>
		<div class="changePW">
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
		<p>You are logged in as #session.username#.</p>
		<p>Your password is #pwtime# days old.</p>
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
			<h1 class="h2 px-2">Operators must change password every #Application.max_pw_age# days.</h1>
			<h2 class="h3 w-100 px-2">Password rules:</h2>
			<ul class="list-style-disc px-5">
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
		</cfif>
		<form action="/users/changePassword.cfm" method="post">
			<input type="hidden" name="action" value="update">
			<label for="oldpassword">Old password</label>
			<input name="oldpassword" id="oldpassword" type="password">
			<label for="newpassword">New password</label>
			<input name="newpassword" id="newpassword" type="password"
			<cfif isDb.cnt gt 0>
				onkeyup="pwc(this.value,'#session.username#')"
			</cfif>	>
			<span id="pwstatus"></span>
			<label for="newpassword2">Retype new password</label>
			<input name="newpassword2" id="newpassword2" type="password">
			<br><br>
			<input type="submit" value="Save Password Change" class="savBtn">
		</form>
		<cfquery name="isGoodEmail" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select email, username
			from cf_user_data, cf_users
			 where cf_user_data.user_id = cf_users.user_id and
			 username= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfquery>
		<cfif len(isGoodEmail.email) gt 0>
			<p>If you can't remember your old password, we can
				<a href="/users/changePassword?action=findPass&email=#isGoodEmail.email#&username=#isGoodEmail.username#">email a new temporary password</a>.
			</p>
		</cfif>
		</div>
	</cfoutput>
</cfcase>
<cfcase value="lostPass">
	<!----------------------------------------------------------->
	<div class="container py-3" style="width: 75%; margin: 0 auto 2rem auto;">
		<div class="row mx-0">
			<div class="col-12">
				<div class="changePW"></div>
				<p>Lost your password? Passwords are stored in an encrypted format and cannot be recovered.</p>
				<p>If you have saved your email address in your profile, enter it here to reset your password.</p>
				<p>If you have not saved your email address, please submit a bug report to that effect and we will reset your password for you.</p>
				<form name="pw" method="post" action="/users/changePassword.cfm">
					<input type="hidden" name="action" value="findPass">
					<label for="username">Username</label>
					<input type="text" name="username" id="username">
					<label for="email">Email Address</label>
					<input type="text" name="email" id="email">
					<br>
					<input type="submit" value="Request Password" class="lnkBtn" style="margin-top: 1rem;">
				</form>
			</div>
		</div>
	</div>
</cfcase>
<cfcase value="update">
	<!-------------------------------------------------------------------->
	<div class="changePW">
		<cfoutput>
			<cfquery name="getPass" datasource="cf_dbuser">
				select password
				from cf_users
				where username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfif hash(oldpassword) is not getpass.password>
				<span style="background-color:red;">
					Incorrect old password. <a href="/users/changePassword.cfm">Go Back</a>
				</span>
				<cfabort>
			<cfelseif getpass.password is hash(newpassword)>
				<span style="background-color:red;">
					You must pick a new password. <a href="/users/changePassword.cfm">Go Back</a>
				</span>
				<cfabort>
			<cfelseif newpassword neq newpassword2>
				<span style="background-color:red;">
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
					<cfquery name="setPass" datasource="cf_dbuser">
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
							<h3>Error in creating user.</h3>
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
			<p>Your password has successfully been changed.</p>
			<p>You will be redirected soon, or you may use the menu above now.</p>
			<script>
				setTimeout("go_now()",5000);
				function go_now () {
					document.location='#Application.ServerRootUrl#/users/UserProfile.cfm';
				}
			</script>
		</cfoutput>
	</div>
</cfcase>
<cfcase value="findPass">
	<!---------------------------------------------------------------------->
   <div class="changePW">
		<cfoutput>
			<cfquery name="isGoodEmail" datasource="cf_dbuser">
				SELECT cf_user_data.user_id, email, username
				FROM cf_user_data
					join cf_users on cf_user_data.user_id = cf_users.user_id
				WHERE
					email = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#email#">
				and username= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#username#">
			</cfquery>
			<cfif isGoodEmail.recordcount neq 1>
				<div>Sorry, that email was not associated with your username.</div>
				<cfabort>
			<cfelse>
				<cfset charList = "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,z,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,1,2,3,4,5,6,7,8,9,0">
				<cfset numList="1,2,3,4,5,6,7,8,9,0">
				<cfset specList="!,$,%,&,_,*,?,-,(,),=,/,:,;,.">
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
					<p></p>Your MCZbase username/password is
	
					#username# / #newPass#
	
					You will be required to change your password
					after logging in.
	
					#Application.ServerRootUrl#/login.cfm
	
					If you did not request this change, please reply to #Application.technicalEmail#.
				</cfmail>
				<div>An email containing your new password has been sent to the email address on file. It may take a few minutes to arrive.</div>
				<cfset initSession()>
			</cfif>
		</cfoutput>
	</div>
</cfcase>
<!---------------------------------------------------------------------->
<cfinclude template = "/shared/_footer.cfm">
