<!---
UserProfile.cfm

Copyright 2020 President and Fellows of Harvard College

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
<cfset addheaderresource="feedreader" />
<cfset pageTitle="MCZbase User Profile">
<cfinclude template = "/shared/_header.cfm">
<cfparam name="action" default="nothing">
<cfif len(session.username) is 0>
	<cflocation url="/login.cfm" addtoken="false">
</cfif>
<script>
	function pwc(p,u){
		var r=orapwCheck(p,u);
		var elem=document.getElementById('pwstatus');
		var pwb=document.getElementById('savBtn');
		if (r=='Password is acceptable'){
			var clas='goodPW';
			pwb.className='doShow';
		} else {
			var clas='badPW';
			pwb.className='noShow';
		}
		elem.innerHTML=r;
		elem.className=clas;
	}
</script>
<!------------------------------------------------------------------->
<cfif action is "makeUser">
<cfoutput>
	<cfquery name="exPw" datasource="uam_god">
		select count(*) as passwordMatchCount
		from cf_users 
		where 
			username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			AND PASSWORD = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#hash(pw)#"> 
	</cfquery>
	<cfif exPw.passwordMatchCount NEQ 1 >
		<div class="error">
			You did not enter the correct password.
		</div>
		<cfabort>
	</cfif>
	<cfquery name="alreadyGotOne" datasource="uam_god">
		select count(*) c from dba_users 
		where upper(username) = <cfqueryparam value='#ucase(session.username)#' cfsqltype="CF_SQL_VARCHAR">
	</cfquery>
	<cfif alreadyGotOne.c is not 0>
		<cfthrow
		   type = "user_already_exists"
		   message = "user_already_exists"
		   detail = "Someone tried to create user #session.username#. That user already exists."
		   errorCode = "-123">
		<cfabort>
	</cfif>
	<cftry>
		<cftransaction>
			<cfquery name="makeUser" datasource="uam_god">
				create user <cfqueryparam value="#session.username#" cfsqltype="CF_SQL_VARCHAR"> 
					identified by <cfqueryparam value="#pw#" cfsqltype="CF_SQL_VARCHAR">
					profile "ARCTOS_USER" default TABLESPACE users QUOTA 1G on users
			</cfquery>
			<cfquery name="grantConn" datasource="uam_god">
				grant create session to <cfqueryparam value="#session.username#" cfsqltype="CF_SQL_VARCHAR"> 
			</cfquery>
			<cfquery name="grantTab" datasource="uam_god">
				grant create table to <cfqueryparam value="#session.username#" cfsqltype="CF_SQL_VARCHAR"> 
			</cfquery>
			<cfquery name="grantVPD" datasource="uam_god">
				grant execute on app_security_context to <cfqueryparam value="#session.username#" cfsqltype="CF_SQL_VARCHAR"> 
			</cfquery>
			<cfquery name="usrInfo" datasource="uam_god">
				select * from temp_allow_cf_user,cf_users where temp_allow_cf_user.user_id=cf_users.user_id and
				cf_users.username = <cfqueryparam value="#session.username#" cfsqltype="CF_SQL_VARCHAR"> 
			</cfquery>
			<cfquery name="makeUserCleanup" datasource="uam_god">
				delete from temp_allow_cf_user 
				where user_id = <cfqueryparam value="#usrInfo.user_id#" cfsqltype="CF_SQL_DECIMAL">
			</cfquery>
			<cfmail to="#usrInfo.invited_by_email#" from="account_created@#Application.fromEmail#" subject="User Authenticated" cc="#Application.PageProblemEmail#" type="html">
				Arctos user #encodeForHtml(session.username)# has successfully created an Oracle account.
				<br>
				You now need to assign them roles and collection access.
				<br>Contact the DBA immediately if you did not invite this user to become an operator.
			</cfmail>
		</cftransaction>
		<cfcatch>
			<cftry>
			<cfquery name="makeUserCleanup" datasource="uam_god">
				drop user <cfqueryparam value="#session.username#" cfsqltype="CF_SQL_VARCHAR"> 
			</cfquery>
			<cfcatch>
			</cfcatch>
			</cftry>
			<cfsavecontent variable="errortext">
				<h3>Error in creating user.</h3>
				<p>#cfcatch.Message#</p>
				<p>#cfcatch.Detail#</p>
				<hr>
				<CFIF isdefined("CGI.HTTP_X_Forwarded_For") and #len(CGI.HTTP_X_Forwarded_For)# gt 0>
					<CFSET ipaddress="#CGI.HTTP_X_Forwarded_For#">
				<CFELSEif  isdefined("CGI.Remote_Addr") and #len(CGI.Remote_Addr)# gt 0>
					<CFSET ipaddress="#CGI.Remote_Addr#">
				<cfelse>
					<cfset ipaddress='unknown'>
				</CFIF>
				<p>ipaddress: <cfoutput><a href="http://network-tools.com/default.asp?prog=network&host=#ipaddress#">#ipaddress#</a></cfoutput></p>
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
			<cfmail subject="Error" to="#Application.PageProblemEmail#" from="bad_authentication@#Application.fromEmail#" type="html">
				#errortext#
			</cfmail>
			<h3>Error in creating user.</h3>
			<p>#cfcatch.Message#</p>
			<cfabort>
		</cfcatch>
	</cftry>
	<cflocation url="/UserProfile.cfm" addtoken="false">
</cfoutput>
</cfif>
<!------------------------------------------------------------------->
<div class="container-fluid">
	<cfif action is "nothing">
	<cfquery name="getPrefs" datasource="cf_dbuser">
		SELECT * 
		FROM cf_users
			left join user_loan_request on cf_users.user_id = user_loan_request.user_id
			left join agent_name on cf_users.username = agent_name.agent_name
			left join person on agent_name.agent_id = person.person_id
		WHERE 
			agent_name.agent_name_type = 'login' and 
			username = <cfqueryparam value='#session.username#' cfsqltype="CF_SQL_VARCHAR">
		ORDER BY cf_users.user_id
	</cfquery>
	
	<cfif getPrefs.recordcount is 0>
		<cflocation url="/Specimens.cfm" addtoken="false">
	</cfif>
	<cfquery name="isInv" datasource="uam_god">
		SELECT allow 
		FROM temp_allow_cf_user 
		WHERE user_id = <cfqueryparam value="#getPrefs.user_id#" cfsqltype="CF_SQL_DECIMAL">
	</cfquery>
	<cfoutput query="getPrefs" group="user_id">
		<div class="container mt-4" id="content">
			<div class="row mb-5">
				<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"global_admin")>
					<div class="col-12">
						<h1 class="h2">Server Settings</h1>
						<ul>
							<li>Application.protocol: #Application.protocol#</li>
							<cfif Application.serverrole EQ "production" AND Application.protocol NEQ "https">
								<li><strong>Warning: expected protocol for production is https, restart coldfusion while apache is running.</li>
							</cfif>
							<li>Application.serverRootUrl: #Application.serverRootUrl# </li>
							<li>Application.serverrole: #Application.serverrole# </li>
							<cfif NOT isdefined("Session.gitBranch")>
								<cftry>
									<!--- assuming a git repository and readable by coldfusion, determine the checked out branch by reading HEAD --->
									<cfset gitBranch = FileReadLine(FileOpen("#Application.webDirectory#/.git/HEAD", "read"))>
								<cfcatch>
									<cfset gitBranch = "unknown">
								</cfcatch>
								</cftry>
								<cfset Session.gitBranch = gitBranch>
							</cfif>
							<li>Session.gitbranch: #Session.gitbranch# </li>
						</ul>
					</div>		
					</div>
					<div class="row mb-5">
				</cfif>
				<div class="col-12 col-md-6 mb-2">
					<h1 class="h2">
						<cfif len(getPrefs.first_name) GT 0 OR len(getPrefs.last_name) GT 0>
							Welcome back, <b>#encodeForHtml(getPrefs.first_name)# #encodeForHtml(getPrefs.last_name)#</b><br>
							<small>(login: #encodeForHtml(getPrefs.username)#)</small>
						<cfelse>
							<!--- not all users have agent and person records --->
							Welcome back, #encodeForHtml(getPrefs.username)#
						</cfif>
					</h1>
					<h4><a href="/changePassword.cfm?action=nothing">Change your password</a>
						<cfset pwtime = round(now() - getPrefs.pw_change_date)>
						<cfset pwage = Application.max_pw_age - pwtime>
						<cfif pwage lte 0>
							<cfquery name="isDb" datasource="uam_god">
								SELECT
								(
									select count(*) c from all_users where
									username= <cfqueryparam value='#ucase(session.username)#' cfsqltype="CF_SQL_VARCHAR" >
								)
								+
								(
									select count(*) C 
									from temp_allow_cf_user, cf_users 
									where temp_allow_cf_user.user_id = cf_users.user_id 
									AND cf_users.username = <cfqueryparam value='#session.username#' cfsqltype="CF_SQL_VARCHAR" >
								)
								cnt
								FROM dual
							</cfquery>
							<cfif isDb.cnt gt 0>
								<cfset session.force_password_change = "yes">
								<cflocation url="ChangePassword.cfm" addtoken="false">
							</cfif>
							<cfelseif pwage lte 10>
							<span style="color:red;"> Your password expires in #pwage# days. </span>
						</cfif>
					</h4>
					<h4> <a href="/saveSearch.cfm?action=manage">Manage your Saved Searches</a><br>
						<small>Click "Save Search" from Specimen Results to save a search.</small> </h4>
						<cfif isInv.allow is 1>
							You've been invited to become an Operator. Password restrictions apply.
							This form does not change your password (you may do so <a href="/ChangePassword.cfm">here</a>),
							but will provide information about the suitability of your password. You may need to change your password in order to successfully complete this form.
							<form name="getUserData" method="post" action="/UserProfile.cfm" onSubmit="return noenter();">
								<input type="hidden" name="action" value="makeUser">
								<label for="pw">Enter your password:</label>
								<input type="password" name="pw" id="pw" onkeyup="pwc(this.value,'#session.username#')">
								<span id="pwstatus" style="background-color:white;"></span>
								<br>
								<br>
								<span id="savBtn"><input type="submit" value="Create Account" class="btn btn-secondary"></span>
							</form>
							<script>
								document.getElementById(pw).value='';
							</script>
						</cfif>
						<cfquery name="getUserData" datasource="cf_dbuser">
							SELECT
								cf_users.user_id,
								first_name,
								middle_name,
								last_name,
								affiliation,
								email
							FROM
								cf_users left join cf_user_data on cf_users.user_id = cf_user_data.user_id
							WHERE
								username = <cfqueryparam value='#session.username#' cfsqltype="CF_SQL_VARCHAR" >
						</cfquery>
						<form method="post" action="/UserProfile.cfm" name="dlForm">
							<input type="hidden" name="user_id" value="#getUserData.user_id#">
							<input type="hidden" name="action" value="saveProfile">
							<h3 class="mb-0">Personal Profile</h3>
							<h4 class="h4">
								A profile is required to download data.  See the <a href="https://mcz.harvard.edu/privacy-policy">privacy policy</a>
							</h4>
							<div class="form-group col-md-12 col-sm-12 pl-0">
								<div class="input-group mb-3">
									<div class="input-group-prepend">
										<span class="input-group-text" name="first_name" id="basic-addon1">First Name</span>
									</div>
									<input type="text" name="first_name" value="#encodeForHtml(getUserData.first_name)#" class="form-control" placeholder="first_name" aria-label="first_name" aria-describedby="basic-addon1">
								</div>
								<div class="input-group mb-3">
									<div class="input-group-prepend">
										<span class="input-group-text" name="middle_name" id="basic-addon1">Middle Name</span>
									</div>
									<input type="text" name="middle_name" value="#encodeForHtml(getUserData.middle_name)#" class="form-control" placeholder="middle_name" aria-label="middle_name" aria-describedby="basic-addon1">
								</div>
								<div class="input-group mb-3">
									<div class="input-group-prepend">
										<span class="input-group-text" name="last_name" id="basic-addon1">Last Name</span>
									</div>
									<input type="text" name="last_name" value="#encodeForHtml(getUserData.last_name)#" class="form-control" placeholder="last_name" aria-label="last_name" aria-describedby="basic-addon1">
								</div>
							</div>
							<div class="form-group col-md-12 col-sm-12 pl-0">
								<div class="input-group mb-3">
									<div class="input-group-prepend">
										<span class="input-group-text" name="affiliation" id="basic-addon1">Affiliation</span>
									</div>
									<input type="text" name="affiliation" class="form-control" value="#encodeForHtml(getUserData.affiliation)#" placeholder="Affiliation" aria-label="affiliation" aria-describedby="basic-addon1">
								</div>
								<div class="input-group mb-3">
									<div class="input-group-prepend">
										<span class="input-group-text" name="email" id="basic-addon1">Email</span>
									</div>
									<input type="text" name="email" class="form-control" value="#encodeForHtml(getUserData.email)#" placeholder="email" aria-label="email" aria-describedby="basic-addon1">
								</div>
							</div>
							<div class="form-group col-md-12 col-sm-12 pl-0">
								<h4>You cannot recover from a lost password unless you enter an email address.</h4>
								<input type="submit" value="Save Profile" class="btn btn-primary ml-0 mt-1">	
							</div>
						</form>
					</div>				
				
					<div class="col-12 col-md-6 float-left">
						<cfquery name="getUserPrefs" datasource="cf_dbuser">
							SELECT 
								USERNAME, PASSWORD, TARGET, DISPLAYROWS, MAPSIZE, PARTS, ACCN_NUM, HIGHER_TAXA, AF_NUM,
								RIGHTS, USER_ID, ACTIVE_LOAN_ID, COLLECTION, IMAGES, PERMIT, CITATION, PROJECT, PRESMETH,
								ATTRIBUTES, COLLS, PHYLCLASS, SCINAMEOPERATOR, DATES, DETAIL_LEVEL, COLL_ROLE, CURATORIAL_STUFF,
								IDENTIFIER, BOUNDINGBOX, KILLROW, APPROVED_TO_REQUEST_LOANS, BIGSEARCHBOX, COLLECTING_SOURCE,
								SCIENTIFIC_NAME, CUSTOMOTHERIDENTIFIER, CHRONOLOGICAL_EXTENT, MAX_ERROR_IN_METERS, SHOWOBSERVATIONS,
								COLLECTION_IDS, EXCLUSIVE_COLLECTION_ID, LOAN_REQUEST_COLL_ID, MISCELLANEOUS, LOCALITY,
								RESULTCOLUMNLIST, PW_CHANGE_DATE, LAST_LOGIN, SPECSRCHPREFS, FANCYCOID, RESULT_SORT, 
								BLOCK_SUGGEST, LOCSRCHPREFS, REPORTPREFS
						 	FROM cf_users 
							WHERE 
								username = <cfqueryparam value='#session.username#' cfsqltype="CF_SQL_VARCHAR" >
						</cfquery>
	
						<div id="divRss"></div>
					 </div>
				<script>
					$( document ).ready(function(){
						jQuery.getFeed({
							url: 'https://code.mcz.harvard.edu/feed/',
							success: function(feed) {
								//var header = feed.title;
								var header = 'MCZ Biodiversity Informatics Project Support';
								header = header.replace("[en]", "");
				
								jQuery('##divRss').empty();
								var html ='<div class="shell"><h2 class="h3 py-2 px-2 text-center">' + header + '<a href="https://code.mcz.harvard.edu/wiki/index.php?title=Special:RecentChanges&hideminor=1&days=30"><span class="d-block"><small>- Link to Recent Wiki Changes - </small></span> </a></h2>';
								for(var i = 0; i < feed.items.length && i < 5; i++) {
									var item = feed.items[i];
									item.updated = new Date(item.updated);
									html += '<div class="feedAtom">';
									html += '<div class="updatedAtom">' + item.updated.toDateString() + '</div>';
									html += '<div class="authorAtom" style="z-index:11;">by ' + item.author + '</div>';
									html += '<h3 class="h4 my-1"><a class="pt-1" href="' + item.link + '">' + item.title + '</a></h3>';
									html += '<div class="descriptionAtom">' + item.description +'</div>';
									html += '</div>';
								} 
								html += '</div>';
								jQuery('##divRss').append(html);
							}
						});
					});
				</script>
			</div>
		</div>
	</div>
</cfoutput>
</cfif>

<!----------------------------------------------------------------------------------------------->

<!----------------------------------------------------------------------------------------------->
<cfif action is "saveProfile">
	<cfif isDefined("first_name")>
	<!--- get the values they filled in --->
	<cfif len(first_name) is 0 OR
		len(last_name) is 0 OR
		len(affiliation) is 0>
		You haven't filled in all required values! Please use your browser's back button to try again.
		<cfabort>
	</cfif>
	<cfquery name="isUser" datasource="cf_dbuser">
		select * from cf_user_data 
		where 
			user_id = <cfqueryparam value='#user_id#' cfsqltype="CF_SQL_DECIMAL">
	</cfquery>
		<!---- already have a user_data entry --->
	<cfif isUser.recordcount is 1>
		<cfquery name="upUser" datasource="cf_dbuser">
			UPDATE cf_user_data SET
				first_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#first_name#">,
				last_name = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#last_name#">,
				AFFILIATION= <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#affiliation#">
				<cfif len(#middle_name#) gt 0>
					,middle_name = <cfqueryparam value='#middle_name#' cfsqltype="CF_SQL_VARCHAR">
				<cfelse>
					,middle_name = NULL
				</cfif>
				<cfif len(#email#) gt 0>
					,email = <cfqueryparam value='#email#' cfsqltype="CF_SQL_VARCHAR">
				<cfelse>
					,email = NULL
				</cfif>
			WHERE
				user_id = <cfqueryparam value="#user_id#" cfsqltype="CF_SQL_DECIMAL">
		</cfquery>
	</cfif>
	<cfif #isUser.recordcount# is not 1>
		<cfquery name="newUser" datasource="cf_dbuser">
			INSERT INTO cf_user_data (
				user_id,
				first_name,
				last_name,
				affiliation
				<cfif len(#middle_name#) gt 0>
					,middle_name
				</cfif>
				<cfif len(#email#) gt 0>
					,email
				</cfif>
				)
			VALUES (
				<cfqueryparam value="#user_id#" cfsqltype="CF_SQL_DECIMAL">,
				<cfqueryparam value='#first_name#' cfsqltype="CF_SQL_VARCHAR">,
				<cfqueryparam value='#last_name#' cfsqltype="CF_SQL_VARCHAR">,
				<cfqueryparam value='#affiliation#' cfsqltype="CF_SQL_VARCHAR">
				<cfif len(#middle_name#) gt 0>
					,  <cfqueryparam value='#middle_name#' cfsqltype="CF_SQL_VARCHAR">
				</cfif>
				<cfif len(#email#) gt 0>
					,  <cfqueryparam value='#email#' cfsqltype="CF_SQL_VARCHAR">
				</cfif>
				)
		</cfquery>
	</cfif>
	<cflocation url="/UserProfile.cfm?action=nothing" addtoken="false">
		</cfif>
</cfif>
<!---------------------------------------------------------------------->
<cfif isdefined("redir") AND #redir# is "true">
	<cfoutput>
	<!----
		replace cflocation with JavaScript below so I'll always break
		out of frames (ie, agents) when using the nav button
	--->
	<script language="JavaScript">
		parent.location.href="#startApp#"
	</script>
	</cfoutput>
</cfif>

<cfinclude template = "/shared/_footer.cfm">
