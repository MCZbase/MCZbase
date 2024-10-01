<!---
/users/UserProfile.cfm

Copyright 2020-2022 President and Fellows of Harvard College

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

<cfswitch expression="#action#">
<cfcase value="makeUser">
	<!------------------------------------------------------------------->
	<cfoutput>
		<cfquery name="exPw" datasource="uam_god">
			SELECT count(*) as passwordMatchCount
			FROM cf_users 
			WHERE
				username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
				AND PASSWORD = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#hash(pw)#"> 
		</cfquery>
		<cfif exPw.passwordMatchCount NEQ 1 >
			<div class="error">
				You did not enter the correct password.
			</div>
			<cfabort>
		</cfif>
		<cfquery name="checkDBUserExists" datasource="uam_god">
			SELECT count(*) ct
			FROM dba_users 
			WHERE upper(username) = <cfqueryparam value='#ucase(session.username)#' cfsqltype="CF_SQL_VARCHAR">
		</cfquery>
		<cfif checkDBUserExists.ct is not 0>
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
					MCZbase user #encodeForHtml(session.username)# has successfully created an Oracle account.
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
					<!--- no action, insert may have failed, so may be no user to drop --->
				</cfcatch>
				</cftry>
				<!--- create email message text --->
				<cfsavecontent variable="errortext">
					<h3>Error in creating user.</h3>
					<p>#cfcatch.Message#</p>
					<p>#cfcatch.Detail#</p>
					<hr>
					<cfif isdefined("CGI.HTTP_X_Forwarded_For") and #len(CGI.HTTP_X_Forwarded_For)# gt 0>
						<cfset ipaddress="#CGI.HTTP_X_Forwarded_For#">
					<cfelseif isdefined("CGI.Remote_Addr") and #len(CGI.Remote_Addr)# gt 0>
						<cfset ipaddress="#CGI.Remote_Addr#">
					<cfelse>
						<cfset ipaddress='unknown'>
					</cfif>
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
				<h2 class="h3 text-warning">Error in creating user.</h2>
				<p>#cfcatch.Message#</p>
				<cfabort>
			</cfcatch>
		</cftry>
		<cflocation url="/users/UserProfile.cfm" addtoken="false">
	</cfoutput>
</cfcase>
<cfcase value="nothing">
	<!------------------------------------------------------------------->
		<cfquery name="checkUserExists" datasource="cf_dbuser">
			SELECT count(*) ct
			FROM cf_users
			WHERE
				username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfquery>
		<cfif checkUserExists.ct NEQ 1>
			<cflocation url="/login.cfm" addtoken="false">
		</cfif>
		<cfquery name="getPrefs" datasource="cf_dbuser">
			SELECT * 
			FROM cf_users
				left join agent_name on cf_users.username = agent_name.agent_name and agent_name.agent_name_type = 'login'
				left join person on agent_name.agent_id = person.person_id
			WHERE 
				username = <cfqueryparam value='#session.username#' cfsqltype="CF_SQL_VARCHAR">
			ORDER BY cf_users.user_id
		</cfquery>
		<cfif getPrefs.recordcount is 0>
			<cflocation url="/login.cfm" addtoken="false">
		</cfif>
		<!--- check to see if user has been invited to becoem an operator --->
		<cfquery name="isInv" datasource="uam_god">
			SELECT allow 
			FROM temp_allow_cf_user 
			WHERE user_id = <cfqueryparam value="#getPrefs.user_id#" cfsqltype="CF_SQL_DECIMAL">
		</cfquery>
		<cfoutput query="getPrefs" group="user_id">
			<div class="container-fluid py-4" id="content">
				<div class="row mx-0 mb-5">
					<div class="col-12 col-md-8 mb-2">
						<h1 class="h2">
							<cfif len(getPrefs.first_name) GT 0 OR len(getPrefs.last_name) GT 0>
								Welcome back, <b>#encodeForHtml(getPrefs.first_name)# #encodeForHtml(getPrefs.last_name)#</b><br>
								<small>(login: #encodeForHtml(getPrefs.username)#)</small>
							<cfelse>
								<!--- not all users have agent and person records --->
								Welcome back, #encodeForHtml(getPrefs.username)#
							</cfif>
						</h1>
						<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"global_admin")>
							<!--- Provide users with global admin role sanity checking information on the current deployment environment --->
							<div class="form-row">
								<div class="col-12 col-md-6">
									<h2 class="h3">Server Settings</h2>
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
								<cfquery name="flatstatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
									SELECT count(*) ct, stale_flag 
									FROM flat
									GROUP BY stale_flag
								</cfquery>
								<div class="col-12 col-md-6">
									<h2 class="h3">FLAT Table</h2>
									<ul>
										<cfloop query="flatstatus">
											<cfset flattext = "">
											<cfif flatstatus.stale_flag GT 1><cfset flattext = " manually excluded"></cfif>
											<li>stale_flag: #flatstatus.stale_flag# Rows: #flatstatus.ct##flattext#</li>
										</cfloop>
									<ul>
								</div>
							</div>		
						</cfif>
						<h2 class="h3">Manage your profile</h2>
						<h3 class="h4">
							<a href="/users/changePassword.cfm">Change your password</a>
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
									<cflocation url="/users/changePassword.cfm" addtoken="false">
								</cfif>
								<cfelseif pwage lte 10>
								<span style="color:red;"> Your password expires in #pwage# days. </span>
							</cfif>
						</h3>
						<h3 class="h4"> 
							<a href="/users/Searches.cfm">Manage your Saved Searches</a>
							<span class="small pl-1"> (Click "Save Search" from Specimen Results to save a search.)</span>
						</h4>
						<cfif isInv.allow is 1>
							<div class="col-12 col-md-8 col-xl-6 py-3 my-3 border-right border-left border-top border-bottom border-danger">
								<p>You&apos;ve been invited to become an Operator. Password restrictions apply.</p>
								<p class="font-weight-lessbold">This form does not change your password (you may do so <a href="/users/changePassword.cfm">here</a>),
								but will provide information about the suitability of your password. You may need to change your password in order to successfully complete this form.</p>
								<form name="getUserData" method="post" action="/users/UserProfile.cfm" onSubmit="return noenter();">
									<input type="hidden" name="action" value="makeUser">
									<div class="form-row pl-0">
										<div class="col-12 col-md-6 mb-1 mt-2">
											<label for="pw" class="data-entry-label">Enter your password:</label>
											<input type="password" name="pw" id="pw" onkeyup="pwc(this.value,'#session.username#')" class="data-entry-input reqdClr" required>
											<span id="pwstatus" style="background-color:white;"></span>
										</div>
										<div class="col-12 col-md-6 mb-1 mt-2 mt-md-4">
											<span id="savBtn"><input type="submit" value="Verify Password &amp; Accept Invitation" class="btn btn-xs btn-secondary"></span>
										</div>
									</div>
								</form>
							</div>
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
								email,
								specimens_download_profile
							FROM
								cf_users left join cf_user_data on cf_users.user_id = cf_user_data.user_id
							WHERE
								username = <cfqueryparam value='#session.username#' cfsqltype="CF_SQL_VARCHAR" >
						</cfquery>
						<div class="border float-left p-3">
							<h3 class="my-0">Personal Profile</h3>
							<form method="post" action="/users/UserProfile.cfm" name="dlForm" class="border bg-verylightteal px-2 py-1">
								<input type="hidden" name="user_id" value="#getUserData.user_id#">
								<input type="hidden" name="action" value="saveProfile">
								<div class="form-row mx-0">
									<h4 class="h4 col-12 mt-2">
										A profile is required to download data.  See the <a href="https://mcz.harvard.edu/privacy-policy">privacy policy</a>
									</h4>
									<div class="col-12 col-md-4 mb-2">
										<label for="first_name" class="data-entry-label">First Name</label>
										<input type="text" name="first_name" id="first_name" value="#encodeForHtml(getUserData.first_name)#" class="data-entry-input reqdClr" required>
									</div>
									<div class="col-12 col-md-4 mb-2">
										<label class="data-entry-label" for="middle_name" >Middle Name</label>
										<input type="text" name="middle_name" id="middle_name" value="#encodeForHtml(getUserData.middle_name)#" class="data-entry-input">
									</div>
									<div class="col-12 col-md-4 mb-2">
										<label class="data-entry-label" for="last_name">Last Name</label>
										<input type="text" name="last_name" id="last_name" value="#encodeForHtml(getUserData.last_name)#" class="data-entry-input reqdClr" required>
									</div>
									<div class="col-12 col-md-6 mb-2">
										<label class="data-entry-label" for="affiliation">Affiliation</label>
										<input type="text" name="affiliation" id="affiliation" class="data-entry-input reqdClr" value="#encodeForHtml(getUserData.affiliation)#" required>
									</div>
									<div class="col-12 col-md-6 mb-2">
										<label class="data-entry-label" for="email">Email</label>
										<input type="text" name="email" id="email" class="data-entry-input" value="#encodeForHtml(getUserData.email)#"> 
									</div>
									<div class="col-12 mb-2">
										<h4 class="h4 px-1 mt-1">You cannot recover from a lost password unless you enter an email address.</h4>
										<input type="submit" value="Save Profile" class="btn btn-primary btn-xs ml-0 my-1 ">	
									</div>
								</div>
							</form>
				
							<cfquery name="OtherIdType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
								select distinct(other_id_type) FROM CTCOLL_OTHER_ID_TYPE ORDER BY other_Id_Type
							</cfquery>
							<cfquery name="collectionList" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
								select cf_collection_id,collection from cf_collection
								order by collection
							</cfquery>
							<cfquery name="getDownloadProfiles" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getProfiles_result">
								SELECT 
									username, name, download_profile_id, sharing, target_search, column_list, decode(agent_name.agent_id,NULL,username,MCZBASE.get_agentnameoftype(agent_name.agent_id)) as owner_name
								FROM 
									download_profile
									left join agent_name on upper(download_profile.username) = upper(agent_name.agent_name) and agent_name_type = 'login'
								WHERE
									upper(username) = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#ucase(session.username)#">
									or sharing = 'Everyone'
									<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
										or sharing = 'MCZ'
									</cfif>
								ORDER BY name
							</cfquery>
							<div class="form-row mx-0 my-2">
								<h3 class="h3 mt-3 mb-0 px-1 col-auto float-left px-1">
										MCZbase Settings <span class="font-weight-lessbold small">(settings related to how you see search results)</span>
								</h3>
								<!--- Most settings are session variables --->
								<!--- values are obtained from the session --->
								<!--- changing involves both changing the persistence store and the session variable.  --->
								<output id="changeFeedback" class="text-danger float-left pl-1 mt-0 mt-xl-3 pt-1 small90">&nbsp;</output>
							</div>
			
								<form method="post" action="/users/UserProfile.cfm" name="dlForm" class="userdataForm">
									<div class="form-row">
										<div class="col-12 col-md-6 float-left mb-2">
											<label for="specimens_default_action" class="data-entry-label">Default tab for Specimen Search</label>
											<cfif not isDefined("session.specimens_default_action")>
												<cfset session.specimens_default_action = "fixedSearch">
											</cfif>
											<select name="specimens_default_action" id="specimens_default_action" class="data-entry-input" onchange="changeSpecimensDefaultAction(this.value)">
												<option value="fixedSearch" <cfif session.specimens_default_action EQ "fixedSearch"> selected="selected" </cfif>>Basic Search</option>
												<option value="keywordSearch" <cfif session.specimens_default_action EQ "keywordSearch"> selected="selected" </cfif>>Keyword Search</option>
												<option value="builderSearch" <cfif session.specimens_default_action EQ "builderSearch"> selected="selected" </cfif>>Search Builder</option>
											</select>
										</div>
										<div class="col-12 col-md-6 float-left mb-2">
											<label for="specimens_pin_guid" class="data-entry-label">Pin GUID column</label>
											<cfif not isDefined("session.specimens_pin_guid")>
												<cfset session.specimens_pin_guid = "no">
											</cfif>
											<select name="specimens_pin_guid" id="specimens_pin_guid" class="data-entry-select" onchange="changeSpecimensPinGuid(this.value)">
												<option value="0" <cfif session.specimens_pin_guid EQ "0"> selected="selected" </cfif>>No</option>
												<option value="1" <cfif session.specimens_pin_guid EQ "1"> selected="selected" </cfif>>Yes, Pin Column</option>
											</select>
										</div>
									</div>
									<div class="form-row">
										<div class="col-12 col-md-6 float-left mb-2">
											<label for="specimens_pagesize" class="data-entry-label">Default Rows in Specimen Search Grid</label>
											<cfif not isDefined("session.specimens_pagesize")>
												<cfset session.specimens_pagesize = "25">
											</cfif>
											<!--- Must be one of the values on the pagesizeoptions array '5','10','25','50','100','1000' --->
											<select name="specimens_pagesize" id="specimens_pagesize" class="data-entry-select" onchange="changeSpecimensPageSize(this.value)">
												<option value="5" <cfif session.specimens_pagesize EQ "5"> selected="selected" </cfif>>5 (good for phone)</option>
												<option value="10" <cfif session.specimens_pagesize EQ "10"> selected="selected" </cfif>>10 (good for right/left scroll)</option>
												<option value="25" <cfif session.specimens_pagesize EQ "25"> selected="selected" </cfif>>25 (default)</option>
												<option value="50" <cfif session.specimens_pagesize EQ "50"> selected="selected" </cfif>>50</option>
												<option value="100" <cfif session.specimens_pagesize EQ "100"> selected="selected" </cfif>>100</option>
												<option value="500" <cfif session.specimens_pagesize EQ "1000" OR session.specimens_pagesize EQ "500"> selected="selected" </cfif>>500</option>
											</select>
										</div>
										<div class="col-12 float-left col-md-6 mb-2">
											<label for="customOtherIdentifier" class="data-entry-label" >My Other Identifier</label>
											<select name="customOtherIdentifier" id="customOtherIdentifier"
												size="1" class="data-entry-select" onchange="this.className='red';changecustomOtherIdentifier(this.value);">
												<option value="">None</option>
												<cfloop query="OtherIdType">
													<option
														<cfif session.CustomOtherIdentifier is other_id_type>selected="selected"</cfif>
														value="#other_id_type#">#other_id_type#</option>
												</cfloop>
											</select>
										</div>
									</div>
									<div class="form-row">
										<div class="col-12 col-md-6 float-left mb-2">
											<label for="gridenablemousewheel" class="data-entry-label">Enable Mouse Wheel Scrolling in Grids</label>
											<cfif not isDefined("session.gridenablemousewheel")>
												<cfset session.gridenablemousewheel = "false">
											</cfif>
											<select name="gridenablemousewheel" id="gridenablemousewheel" class="data-entry-select" onchange="changeGridEnableMousewheel(this.value)">
												<cfif session.gridenablemousewheel EQ "false"><cfset selected="selected='selected'"><cfelse><cfset selected=""></cfif>
												<option value="false" #selected#>Off (Mouse Wheel Scrolls Page)</option>
												<cfif session.gridenablemousewheel EQ "true"><cfset selected="selected='selected'"><cfelse><cfset selected=""></cfif>
												<option value="true" #selected#>On (Mouse Wheel Scrolls Grid Horizontally)</option>
											</select>
										</div>
										<div class="col-12 float-left col-md-6 mb-2">
											<label for="gridscrolltotop" class="data-entry-label">Searches Bounce to Results on Search</label>
											<cfif not isDefined("session.gridscrolltotop")>
												<cfset session.gridscrolltotop = "false">
											</cfif>
											<select name="gridscrolltotop" id="gridscrolltotop" class="data-entry-select" onchange="changeGridScrollToTop(this.value)">
												<cfif session.gridscrolltotop EQ "false"><cfset selected="selected='selected'"><cfelse><cfset selected=""></cfif>
												<option value="false" #selected#>Disabled</option>
												<cfif session.gridscrolltotop EQ "true"><cfset selected="selected='selected'"><cfelse><cfset selected=""></cfif>
												<option value="true" #selected#>Enabled</option>
											</select>
										</div>
									</div>
									<div class="form-row">
										<div class="col-12 col-md-6 float-left mb-2">
											<cfif not isDefined("session.killRow") OR len(session.killRow) EQ 0 ><cfset session.killRow EQ 0></cfif> 
											<label for="killRow" class="data-entry-label" >SpecimenResults Row-Removal Option</label>
											<select name="killRow" id="killRow" class="data-entry-select" onchange="changekillRows(this.value)">
												<option value="0" <cfif session.killRow is 0> selected="selected" </cfif>>No</option>
												<option value="1" <cfif session.killRow is 1> selected="selected" </cfif>>Yes, Single Row</option>
												<option value="2" <cfif session.killRow is 2> selected="selected" </cfif>>Yes, Checkboxes</option>
											</select>
										</div>
										<div class="col-12 col-md-6 float-left mb-2">
											<label for="showObservations" class="data-entry-label" >Include Observations? (currently old search only)</label>
											<select name="showObservations" id="showObservations" class="data-entry-select" onchange="changeshowObservations(this.value)">
												<option value="0" <cfif session.showObservations neq 1> selected="selected" </cfif>>No</option>
												<option value="1" <cfif session.showObservations is 1> selected="selected" </cfif>>Yes</option>
											</select>
										</div>
									</div>
									<div class="form-row">
										<div class="col-12 col-md-6 float-left mb-2">
											<label for="fancyCOID" class="data-entry-label" >Show 3-part ID on SpecimenSearch (deprecated, old search only)</label>
											<select name="fancyCOID" id="fancyCOID"
												size="1" class="data-entry-select" onchange="this.className='red';changefancyCOID(this.value);">
												<option <cfif #session.fancyCOID# is not 1>selected="selected"</cfif> value="">No</option>
												<option <cfif #session.fancyCOID# is 1>selected="selected"</cfif> value="1">Yes</option>
											</select>
										</div>
										<div class="col-12 col-md-6 float-left mb-2">
											<label for="block_suggest" class="data-entry-label" >Suggest Browse (unused)</label>
											<select name="block_suggest" id="block_suggest" class="data-entry-select" onchange="changeBlockSuggest(this.value)">
												<option value="0" <cfif session.block_suggest neq 1> selected="selected" </cfif>>Allow</option>
												<option value="1" <cfif session.block_suggest is 1> selected="selected" </cfif>>Block</option>
											</select>
										</div>
									</div>
									<div class="form-row">
										<div class="col-12 col-md-6 float-left mb-2">
											<label for="displayRows" class="data-entry-label" >Specimen Records Per Page (deprecated, old search only)</label>
											<select name="displayRows" id="displayRows" class="data-entry-select" onchange="changedisplayRows(this.value);" size="1">
												<option <cfif session.displayRows is "10"> selected </cfif> value="10">10</option>
												<option  <cfif session.displayRows is "20"> selected </cfif> value="20" >20</option>
												<option  <cfif session.displayRows is "50"> selected </cfif> value="50">50</option>
												<option  <cfif session.displayRows is "100"> selected </cfif> value="100">100</option>
											</select>
										</div>
										<cfif len(session.roles) gt 0 AND session.roles is "public">
											<div class="col-12 col-md-6 float-left mb-2">
											<cfif isdefined("session.portal_id")>
												<cfset pid=session.portal_id>
											<cfelse>
												<cfset pid="">
											</cfif>
											<label for="exclusive_collection_id" class="data-entry-label" >Filter Results By Collection (currently old search only)</label>
												<select name="exclusive_collection_id" id="exclusive_collection_id"
												class="data-entry-select" onchange="this.className='red';changeexclusive_collection_id(this.value);" size="1">
												<option  <cfif pid is "" or pid is 0>selected="selected" </cfif> value="">All</option>
												<cfloop query="collectionList">
													<option <cfif pid is cf_collection_id>selected="selected" </cfif> value="#cf_collection_id#">#collection#</option>
												</cfloop>
												</select>
											</div>
										</cfif>
									</div>
									<div class="form-row">
										<div class="col-12 col-xl-6 float-left mb-2">
											<!--- download profile is an exception, it isn&apos;t in the session but retrieved on demand--->
											<label for="specimens_default_profile" class="data-entry-label">Default Profile for Columns included when downloading Specimen results as CSV </label>
											<select name="specimen_default_profile" id="specimen_default_profile" class="data-entry-select" onchange="changeSpecimenDefaultProfile(this.value)">
												<option></option>
												<cfloop query="getDownloadProfiles">
													<cfif getDownloadProfiles.target_search EQ "Specimens">
														<cfset columnCount = ListLen(getDownloadProfiles.column_list)>
														<cfif getDownloadProfiles.download_profile_id EQ getUserData.specimens_download_profile><cfset selected="selected"><cfelse><cfset selected=""></cfif>
														<option value="#getDownloadProfiles.download_profile_id#" #selected#>#getDownloadProfiles.name# (#columnCount# cols. by #getDownloadProfiles.owner_name# visible to #getDownloadProfiles.sharing#)</option>
													</cfif>
												</cfloop>
											</select>
										</div>
										<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
											<div class="col-12 col-xl-12 float-left px-0 mb-2 pt-0 pt-xl-3">
												<span class="h4 ml-3"><a href="/users/manageDownloadProfiles.cfm">Manage Profiles for columns in CSV Downloads</a></span>
											</div>
										</cfif>
									</div>
								</form>
								<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"coldfusion_user")>
									<cfinclude template="/specimens/component/search.cfc" runOnce="true">
									<div class="form-row">
										<div class="col-12 col-xl-6 float-left mb-2">
											<div class="bg-light rounded border p-2">
												<h3 class="h3">Your recent specimen search CSV download requests</h3>
												<cfset downloadRequestsBlockContent = getDownloadRequestsHTML() >
												<span id="recentDownloadRequestsDiv"> #downloadRequestsBlockContent#</span>
												<p>The number of rows and columns determine how long it takes to process. <br>Once the download link appears, it remains available for a day.</p>
												<button class="btn btn-xs btn-secondary" 
													id="recheckDownloadRequestsBtn" onClick=" updateDownloadsBlock('recentDownloadRequestsDiv');" 
												>Recheck Status</button>
											</div>
										</div>
										<script>
											function updateDownloadsBlock(targetDiv) {
												jQuery.ajax(
												{
													dataType: "html",
													url: "/specimens/component/search.cfc",
													data: { 
														method : "getDownloadRequestsHTML"
													},
													error: function (jqXHR, textStatus, message) {
														handleFail(jqXHR,textStatus,message,"looking up download specimen search files metadata");
													},
													success: function (result) {
														if (targetDiv) { 
															$('##' + targetDiv).html(result);
														}
													}
												},
												)
											};
										</script>
									</div>
								</cfif>
						</div>
					</div>				
					<div class="col-12 col-md-4 float-left">
						<div id="divRss" class="h-75">
							<div class="shell h-100"><h2 class="h3 py-2 px-2 text-center">Checking the wiki for documentation updates...</h2></div>
						</div>
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
									var html ='<div class="shell h-100"><h2 class="h3 py-2 px-2 text-center">' + header + '<a href="https://code.mcz.harvard.edu/wiki/index.php?title=Special:RecentChanges&hideminor=1&days=60"><span class="d-block">Recent Wiki Changes</span> </a></h2>';
									for(var i = 0; i < feed.items.length && i < 5; i++) {
										var item = feed.items[i];
										item.updated = new Date(item.updated);
										html += '<div class="feedAtom">';
										html += '<div class="updatedAtom">' + item.updated.toDateString() + '</div>';
										html += '<div class="authorAtom pt-1" style="z-index:11;">by ' + item.author + '</div>';
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
		</cfoutput>
</cfcase>
<cfcase value="saveProfile">
	<!--- get the values they filled in --->
	<cfif not isDefined("first_name") OR len(first_name) is 0 OR
			not isDefined("last_name") OR len(last_name) is 0 OR
			not isDefined("affiliation") OR len(affiliation) is 0
	>
			<cfthrow message="You haven't filled in all required values! Please use your browser's back button to try again.">
	</cfif>
	<cfquery name="isUser" datasource="cf_dbuser">
		SELECT * from cf_user_data 
		WHERE 
			user_id = <cfqueryparam value='#user_id#' cfsqltype="CF_SQL_DECIMAL">
	</cfquery>
	<cfif isUser.recordcount is 1>
		<!---- already have a user_data entry --->
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
	<cfelseif #isUser.recordcount# EQ 0>
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
					, <cfqueryparam value='#middle_name#' cfsqltype="CF_SQL_VARCHAR">
				</cfif>
				<cfif len(#email#) gt 0>
					, <cfqueryparam value='#email#' cfsqltype="CF_SQL_VARCHAR">
				</cfif>
				)
		</cfquery>
	<cfelse>
		<cfthrow message="Error: more than one match on user_id when trying to update/create user">
	</cfif>
	<cflocation url="/users/UserProfile.cfm" addtoken="false">
</cfcase>
</cfswitch>
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
