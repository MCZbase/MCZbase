<cfset pageTitle = "Login">
	<!--- I put greetings into the redriect strings so that I could tell what is happening. Let's remove them after development phase --->
<cfinclude template = "includes/_header.cfm">
	<cfoutput>
		<!--- I don't think I am using these parameters. Needs more testing--->
	<cfparam name="gtp" default="/login.cfm?greeting=Whatsup"> 
	<cfparam name="action" default="nothing">
	
</cfoutput>
<!------------------------------------------------------------>
<cfif action is "signOut">
	<cfset initSession()>
				<cfif isdefined("cgi.REDIRECT_URL") and len(cgi.REDIRECT_URL) gt 0>
             <cfset gtp=replace(cgi.REDIRECT_URL, "//", "/Specimens.cfm")>
        <cfelse>
             <cfset gtp=replace(cgi.SCRIPT_NAME, "//", "/Specimens.cfm")>
        </cfif>
		<input type="hidden" name="gotopage" value="#gtp#">
			<!--- This is the result after logging out from the green button on the header popup--->
	<cflocation url="/Specimens.cfm" addtoken="false">
</cfif>
<!------------------------------------------------------------>
<cfif action is "newUser">
	<cfquery name="uUser" datasource="cf_dbuser">
		SELECT * 
		FROM 
			cf_users 
		WHERE 
			username = <cfqueryparam value='#username#' cfsqltype="CF_SQL_VARCHAR">
	</cfquery>
	<cfset err="">
	<cfif len(password) is 0>
		<cfset err="You must provide a password.">
	</cfif>
	<cfquery name="dbausr" datasource="uam_god">
		SELECT 
			username 
		FROM
			dba_users 
		WHERE
			upper(username) = <cfqueryparam value='#ucase(username)#' cfsqltype="CF_SQL_VARCHAR">
	</cfquery>
	<cfif len(dbausr.username) gt 0>
		<cfset err="That username is not available.">
	</cfif>
	<cfif len(username) is 0>
		<cfset err="Enter a username and password.">
	</cfif>
	<cfif uUser.recordcount gt 0>
		<!---This error messages shows in the URL as well as on the login.cfm(below on ~line 215) page after an attempt to create an account with a username that is already in the database--->
		<cfset err="That username is already in use.">
	</cfif>
	<!--- create their account --->
	<cfif len(err) gt 0>
		<cflocation url="/login.cfm?action=nothing&username=#username#&badPW=true&err=#err#" addtoken="false">	
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
<CFIF action is "signIn">
	<cfoutput>
		<cfset initSession('#username#','#password#')>
			
		<cfif len(session.username) is 0>
			<cfset u="login.cfm?action=nothing&badPW=true&username=#username#">
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
							<cfset rurl=replace(gotopage,e,'','')>	
						</cfif>
					</cfloop>
				</cfloop>
				<cfset t=1>
				<cfset rurl=replace(gotopage,"?&","?","all")>
				<cfset rurl=replace(gotopage,"&&","&","all")>
				<cfset nogo="login.cfm?action=nothing&greeting=Hello">
				<cfloop list="#nogo#" index="n">
					<cfif gotopage contains n>
						<cfset gotopage = "/login.cfm?greeting=ByeBye">
					</cfif>
				</cfloop>
			<cfelse>
				<cfset gotopage = "/Specimens.cfm?greeting=Hiya">
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
				<!---This is a result when you put a good username and password into the login page "signIn" form--->
				<cflocation url="#gotopage#?greeting=Hola" addtoken="no">
			</cfif>
			<cfif len(getUserData.email) is 0>
				<cfset session.needEmailAddr=1>
			</cfif>
		<cfelse>
			<!--- This is the result when you put a new username into the header login form with a password and click create account--->
			<!--- This is also the result when you put a username into the login.cfm form with a good password and click sign in--->
			<cflocation url="/Specimens.cfm?greeting=hi" addtoken="no">
		</cfif>
	</cfoutput>
</cfif>
<!------------------------------------------------------------>
<cfif action is "nothing">
<script>
	function isInfo() {
		var uname = document.signIn.username.value;
		var pword = document.signIn.password.value;
		if (uname.length == 0 || pword.length == 0) {
			alert('Enter a username and a password in this form to create an account.');
			return false;
		} else {
			document.signIn.action.value='newUser';
			document.signIn.submit();
		}
	}
</script>
<cfoutput>
<cfparam name="username" default="">
<cfset title="Log In or Create Account">
<div class="container-fluid form-div">
  <div class="container my-2 pt-2">
	  <div class="row justify-content-center">
		 <div class="col-md-6 col-lg-6 col-sm-12">
	<h2>Log In or Create an Account</h2>
	<p>Logging in enables you to turn on, turn off, or otherwise customize many features of this database. To create an account and log in, simply supply a username and password here and click Create Account.
	</p>
	<cfif not isdefined("gotopage")>
		<cfset gotopage=''>
	</cfif>
	<form action="login.cfm" method="post" name="signIn">
		<input name="action" value="signIn" type="hidden">
		<input name="gotopage" value="#gotopage#" type="hidden">
		<div class="input-group col-md-12 mb-3 pl-0">
		  <div class="input-group-prepend">
			<span class="input-group-text" id="inputGroup-sizing-default">Username</span>
		  </div>
		 <input type="text" class="form-control" aria-label="username" aria-describedby="inputGroup-sizing-default" tabindex="1" id="username" name="username" onfocus="if(this.value==this.title){this.value=''};">
		</div>
		<div class="input-group col-md-12 mb-3 pl-0">
		  <div class="input-group-prepend">
			<span class="input-group-text" id="inputGroup-sizing-default">Password</span>
		  </div>
		  <input aria-label="Default" aria-describedby="inputGroup-sizing-default" name="password" type="password" class="form-control" tabindex="2" value="" id="password">
		</div>
		<button class="btn btn-secondary" onClick="signIn.action.value='signIn';submit();" tabindex="3">Sign In</button>
		&nbsp;or&nbsp; <button class="btn btn-secondary" onClick="isInfo();" tabindex="4">Create an Account</button>
	</form>
		<cfif isdefined("badPW") and badPW is true>
			<cfif not isdefined("err") or len(err) is 0>
				<cfset err="Your username or password was not recognized. Please try again.">
			</cfif>
			<span style="color:##a51c30;background-color: ##ffedeb;border-radius: .25em;border: 1px solid ##A51c30;font-style:italic;display:inline-block; margin:.75em .5em .5em 0;padding:.5em;">
				#err#
				<script>
					$('##username').css('backgroundColor','##ffffff');
					$('##password').val('').css('backgroundColor','##fffff').select().focus();
				</script>
			</span>
		</cfif>
	<p class="mt-3">
		<a href="/ChangePassword.cfm">Lost your password?</a> If you created a profile with an email address,
		we can send it to you. You can also just create a new account.
	</p>
	<p>
		You can explore MCZbase using basic options without signing in.
	</p>
        </div>
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
