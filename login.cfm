<cfset pageTitle = "Login">
<cfinclude template = "includes/_header.cfm">
<cfif isdefined("session.username") and len(#session.username#) gt 0 and #action# neq "signOut">
	<cflocation url="/UserProfile.cfm?action=nothing" addtoken="false">
		</cfif>
<!------------------------------------------------------------>
<cfif action is "signOut">
	<cfset initSession()>
	<cflocation url="/Specimens.cfm" addtoken="false">
</cfif>
<!------------------------------------------------------------>
<cfif  action is "newUser">
	<cfquery name="uUser" datasource="cf_dbuser">
		select * from cf_users where username = '#username#'
	</cfquery>
	<cfset err="">
	<cfif len(password) is 0>
		<cfset err="Your password must be at least one character long.">
	</cfif>
	<cfquery name="dbausr" datasource="uam_god">
		select username from dba_users where upper(username) = '#ucase(username)#'
	</cfquery>
	<cfif len(dbausr.username) gt 0>
		<cfset err="That username is not available.">
	</cfif>
	<cfif len(username) is 0>
		<cfset err="Your user name must be at least one character long.">
	</cfif>
	<cfif uUser.recordcount gt 0>
		<cfset err="That username is already in use.">
	</cfif>
	<!--- create their account --->
	<cfif len(err) gt 0>
		<cflocation url="/login.cfm?username=#username#&badPW=true&err=#err#" addtoken="false">
			
			<div class="container">
				<div class="row">
					<div class="col">
						<p> You used a bad password or user name</p>
						<p>This is what you entered for your username: #username#</p>
						<p>Try entering your credentials again.</p>
					</div>
				</div>
			</div>
		
	</cfif>
	<cfquery name="nextUserID" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select max(user_id) + 1 as nextid from cf_users
	</cfquery>
	<cfoutput>
		<cfquery name="newUser" datasource="cf_dbuser">
			INSERT INTO cf_users (
				user_id,
				username,
				password,
				PW_CHANGE_DATE,
				last_login
			) VALUES (
				#nextUserID.nextid#,
				'#username#',
				'#hash(password)#',
				sysdate,
				sysdate
			)
		</cfquery>
		<cflocation url="/login.cfm?action=signIn&username=#username#&password=#password#" addtoken="false">
	</cfoutput>
</cfif>
<!------------------------------------------------------------>
<CFIF  action is "signIn">

	<cfoutput>
		<cfset initSession('#username#','#password#')>
		<cfif len(session.username) is 0>
			<cfset u="/login.cfm?action=nothing&username=#username#">
			
			<cfif isdefined("gotopage")>
				<cfset u=u & '&gotopage=#gotopage#'>
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
					username = '#session.username#'
			</cfquery>
			<cfset pwtime =  round(now() - getUserData.pw_change_date)>
			<cfset pwage = Application.max_pw_age - pwtime>
			<cfif pwage lte 7>
				<div style="text-align:center;color:red;font-weight:bold;">
					Your password expires in #pwage# days
					<br>You may <a href="/ChangePassword.cfm">change it now</a>
				</div>
				<a href="#gotopage#">Continue to #gotopage#</a>
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

</cfif>
<!------------------------------------------------------------>
<cfif action is "nothing">

<cfoutput>

<cfif isdefined("badPW")>
	<div class="container-fluid form-div">
  <div class="container my-2 pt-2">
	  <div class="row justify-content-center">
		 <div class="col-md-10 col-lg-10 col-sm-12">
				<p class="h3">
					Hello #username#!</p>
			 <p class="h3">You have entered a bad password. Please try to enter your password again.</p>
			 </p>
			 	<p class="pb-3">
		<a href="/changePassword.cfm?action=lostPass"><strong>Lost your password?</strong></a> If you created a profile with an email address,
		we can send it to you. You can also just create a new account by entering a different username.  Once you are signed in, look for the "User Profile" link by clicking on the account icon to add your email address.
	</p>
			 
		  </div>
	  </div>
	</div>
	<cfelse>
<div class="container-fluid form-div">
  <div class="container my-2 pt-2">
	  <div class="row justify-content-center">
		 <div class="col-md-10 col-lg-10 col-sm-12">
		  <h2>MCZbase Accounts</h2>
		  </div>
		  <div class="col-md-0 col-lg-10 col-sm-12">
	<cfparam name="username" default="">
	<cfset title="Account">
		
	<p class="pb-3">
		Logging in enables you to turn on, turn off, or otherwise customize many features of
		this database. To create an account and log in, simply supply a username and
		password in the login form and click "Create Account."
	</p>	
	<p class="pb-3">
		<a href="/changePassword.cfm?action=lostPass"><strong>Lost your password?</strong></a> If you created a profile with an email address,
		we can send it to you. You can also just create a new account by entering a different username.  Once you are signed in, look for the "User Profile" link by clicking on the account icon.
	</p>
	<p class="pb-3">
		Explore MCZbase using basic options without signing in.  Contact the collection managers if you cannot find what you need. 
	</p>
		
		</cfif>
	</div>
		</div>
    </div>
		</div>
	</cfoutput>
</cfif>
<!-------------------------------------------------------------------------------------->
<cfif action is "lostPass">
	<cflocation url="/changePassword.cfm?action=nothing" addtoken="false">
</cfif>
<!-------------------------------------------------------------------------------------->
<cfinclude template = "/includes/_footer.cfm">
