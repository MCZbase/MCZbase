<cfset usealternatehead="feedreader" />
<cfinclude template = "includes/_header.cfm">
<cfset title="My Arctos">
<cfif len(session.username) is 0>
	<cflocation url="/login.cfm" addtoken="false">
</cfif>
<script type="text/javascript" src="/shared/js/login_scripts.js"></script> 
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
		select PASSWORD from cf_users where username='#session.username#'
	</cfquery>
	<cfif hash(pw) is not exPw.password>
		<div class="error">
			You did not enter the correct password.
		</div>
		<cfabort>
	</cfif>
	<cfquery name="alreadyGotOne" datasource="uam_god">
		select count(*) c from dba_users where upper(username)='#ucase(session.username)#'
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
				create user #session.username# identified by "#pw#" profile "ARCTOS_USER" default TABLESPACE users QUOTA 1G on users
			</cfquery>
			<cfquery name="grantConn" datasource="uam_god">
				grant create session to #session.username#
			</cfquery>
			<cfquery name="grantTab" datasource="uam_god">
				grant create table to #session.username#
			</cfquery>
			<cfquery name="grantVPD" datasource="uam_god">
				grant execute on app_security_context to #session.username#
			</cfquery>
			<cfquery name="usrInfo" datasource="uam_god">
				select * from temp_allow_cf_user,cf_users where temp_allow_cf_user.user_id=cf_users.user_id and
				cf_users.username='#session.username#'
			</cfquery>
			<cfquery name="makeUser" datasource="uam_god">
				delete from temp_allow_cf_user where user_id=#usrInfo.user_id#
			</cfquery>
			<cfmail to="#usrInfo.invited_by_email#" from="account_created@#Application.fromEmail#" subject="User Authenticated" cc="#Application.PageProblemEmail#" type="html">
				Arctos user #session.username# has successfully created an Oracle account.
				<br>
				You now need to assign them roles and collection access.
				<br>Contact the Arctos DBA team immediately if you did not invite this user to become an operator.
			</cfmail>
		</cftransaction>
		<cfcatch>
			<cftry>
			<cfquery name="makeUser" datasource="uam_god">
				drop user #session.username#
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
	<cflocation url="myArctos.cfm" addtoken="false">
</cfoutput>
</cfif>
<!------------------------------------------------------------------->
<cfif action is "nothing">
	<cfquery name="getPrefs" datasource="cf_dbuser">
		select * 
		from cf_users
		where  
			username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		order by cf_users.user_id
	</cfquery>
	<cfif getPrefs.recordcount is 0>
		<cflocation url="login.cfm?action=signOut" addtoken="false">
	</cfif>
	<cfquery name="isInv" datasource="uam_god">
		select allow 
		from temp_allow_cf_user 
		where user_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#getPrefs.user_id#">
	</cfquery>
	<cfoutput query="getPrefs" group="user_id">
    <div style="width:70em; margin:0 auto;padding-bottom: 3em;overflow: hidden;">
        <div style="width: 33em; float: left; margin-right: 2.2em;padding-top: 2em;">
				<h2>Welcome back, <b>#encodeForHtml(getPrefs.username)#</b>!</h2>
				<cfif isdefined("session.roles") and listcontainsnocase(session.roles,"global_admin")>
					<!--- Provide users with global admin role sanity checking information on the current deployment environment --->
		    		<div style="width:70em; margin:0 auto; overflow: hidden;">
		        		<div style="width: 33em; float: left; margin-right: 2.2em;">
							<h2>Server Settings</h2>
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
							<cfquery name="flatstatus" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
								SELECT count(*) ct, stale_flag 
								FROM flat
								GROUP BY stale_flag
							</cfquery>
							<h2>FLAT Table</h2>
							<ul>
								<cfloop query="flatstatus">
									<cfset flattext = "">
									<cfif flatstatus.stale_flag GT 1><cfset flattext = " manually excluded"></cfif>
									<li>#flatstatus.stale_flag# #flatstatus.ct##flattext#</li>
								</cfloop>
							<ul>
						</div>		
						<h2>Manage your profile</h2>
					</div>		
				</cfif>

	<ul class="geol_hier" style="padding:0;width:430px;margin: 0;">
		<li>
			<a href="ChangePassword.cfm">Change your password</a>
			<cfset pwtime =  round(now() - getPrefs.pw_change_date)>
			<cfset pwage = Application.max_pw_age - pwtime>
			<cfif pwage lte 0>
				 <cfquery name="isDb" datasource="uam_god">
					select
					(select count(*) c from all_users where
					username='#ucase(session.username)#')
					+
					(select count(*) C from temp_allow_cf_user,
					cf_users where temp_allow_cf_user.user_id = cf_users.user_id and cf_users.username='#session.username#')
					cnt
					from dual
				</cfquery>
				<cfif isDb.cnt gt 0>
					<cfset session.force_password_change = "yes">
					<cflocation url="ChangePassword.cfm" addtoken="false">
				</cfif>
			<cfelseif pwage lte 10>
				<span style="color:red;font-weight:bold;">
					Your password expires in #pwage# days.
				</span>
			</cfif>
		</li>
		<cfif isdefined("session.roles") AND listfindnocase(session.roles,"coldfusion_user") >
      	<li>
				<a href="/users/Searches.cfm">Manage your Saved Searches</a> <br><span style="font-size:13px;"> (click Save Search from Specimen Results to save a search)</span>
			</li>
		</cfif>
	</ul>
	<cfif isInv.allow is 1>
		<div class="userData" style="background-color:##FF0000; border:2px solid black; width:75%;">
			You've been invited to become an Operator. Password restrictions apply.
			This form does not change your password (you may do so <a href="ChangePassword.cfm">here</a>),
			but will provide information about the suitability of your password. You may need to change your password
			in order to successfully complete this form.
			<form name="getUserData" method="post" action="myArctos.cfm" onSubmit="return noenter();">
				<input type="hidden" name="action" value="makeUser">
				<label for="pw">Enter your password:</label>
				<input type="password" name="pw" id="pw" onkeyup="pwc(this.value,'#session.username#')">
				<span id="pwstatus" style="background-color:white;"></span>
				<br>
				<br>
				<span id="savBtn"><input type="submit" value="Create Account" class="savBtn"></span>
			</form>
			<script>
				document.getElementById(pw).value='';
			</script>
		</div>
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
			cf_user_data,
			cf_users
		WHERE
			cf_users.user_id = cf_user_data.user_id (+) AND
			username = '#session.username#'
	</cfquery>
	<form class="userdataForm" method="post" action="myArctos.cfm" name="dlForm">
		<input type="hidden" name="action" value="saveProfile">
		<h3 style="margin-bottom: .5em;margin-top:1.5em; margin-bottom: 0;padding-bottom: 0;">Personal Profile</h3>
		<p style="margin-bottom: 1em;margin-top:.35em;">
			A profile is required to download data.<br>
			You cannot recover a lost password unless you enter an email address.<br>
			Personal information will never be shared with anyone, and we&apos;ll never send you spam.</p>

		<ul class="nobull">
            <li><label for="first_name">First Name</label>
                <input type="text" name="first_name" value="#encodeForHtml(getUserData.first_name)#" class="reqdClr" size="50"></li>
		<li><label for="middle_name">Middle Name</label>
            <input type="text" name="middle_name" value="#encodeForHtml(getUserData.middle_name)#" size="50"></li>
		<li><label for="last_name">Last Name</label>
            <input type="text" name="last_name" value="#encodeForHtml(getUserData.last_name)#" class="reqdClr" size="50"></li>
		<li><label for="affiliation">Affiliation</label>
            <input type="text" name="affiliation" value="#encodeForHtml(getUserData.affiliation)#" class="reqdClr" size="50"></li>
		<li><label for="email">Email</label>
            <input type="text" name="email" value="#encodeForHtml(getUserData.email)#" size="30"></li>
            <li>

            <input type="submit" value="Save Profile" class="savBtn" style="margin-top: .5em"></li></ul>
	</form>
	<!---
	<cfquery name="getUserPrefs" datasource="cf_dbuser">
		select * from cf_users where username='#session.username#'
	</cfquery>
	--->


	<cfquery name="OtherIdType" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" cachedwithin="#createtimespan(0,0,60,0)#">
		select distinct(other_id_type) FROM CTCOLL_OTHER_ID_TYPE ORDER BY other_Id_Type
	</cfquery>
	<cfquery name="collid" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select cf_collection_id,collection from cf_collection
		order by collection
	</cfquery>


   <h3 class="arctosSet">MCZbase Settings <span style="font-size: 13px;font-weight: 500">(settings related to how you see search results)</span></h3>
	<form method="post" action="myArctos.cfm" name="dlForm" class="userdataForm">
		<label for="specimens_default_action">Default tab for Specimen Search</label>
		<cfif not isDefined("session.specimens_default_action")>
			<cfset session.specimens_default_action = "fixedSearch">
		</cfif>
		<select name="specimens_default_action" id="specimens_default_action" onchange="changeSpecimensDefaultAction(this.value)">
			<option value="fixedSearch" <cfif session.specimens_default_action EQ "fixedSearch"> selected="selected" </cfif>>Basic Search</option>
			<option value="keywordSearch" <cfif session.specimens_default_action EQ "keywordSearch"> selected="selected" </cfif>>Keyword Search</option>
			<option value="builderSearch" <cfif session.specimens_default_action EQ "builderSearch"> selected="selected" </cfif>>Search Builder</option>
		</select>
		<label for="specimens_pin_guid">Pin GUID column</label>
		<cfif not isDefined("session.specimens_pin_guid")>
			<cfset session.specimens_pin_guid = "no">
		</cfif>
		<select name="specimens_pin_guid" id="specimens_pin_guid" onchange="changeSpecimensPinGuid(this.value)">
			<option value="0" <cfif session.specimens_pin_guid EQ "0"> selected="selected" </cfif>>No</option>
			<option value="1" <cfif session.specimens_pin_guid EQ "1"> selected="selected" </cfif>>Yes, Pin Column</option>
		</select>
		<label for="specimens_pagesize">Default Rows in Specimen Search Grid</label>
		<cfif not isDefined("session.specimens_pagesize")>
			<cfset session.specimens_pagesize = "25">
		</cfif>
		<!--- Must be one of the values on the pagesizeoptions array '5','10','25','50','100','1000'  --->
		<select name="specimens_pagesize" id="specimens_pagesize" onchange="changeSpecimensPageSize(this.value)">
			<option value="5" <cfif session.specimens_pagesize EQ "5"> selected="selected" </cfif>>5 (good for phone)</option>
			<option value="10" <cfif session.specimens_pagesize EQ "10"> selected="selected" </cfif>>10 (good for right/left scroll)</option>
			<option value="25" <cfif session.specimens_pagesize EQ "25"> selected="selected" </cfif>>25 (default)</option>
			<option value="50" <cfif session.specimens_pagesize EQ "50"> selected="selected" </cfif>>50</option>
			<option value="100" <cfif session.specimens_pagesize EQ "100"> selected="selected" </cfif>>100</option>
			<option value="1000" <cfif session.specimens_pagesize EQ "1000"> selected="selected" </cfif>>1000</option>
		</select>
		<label for="block_suggest">Suggest Browse</label>
		<select name="block_suggest" id="block_suggest" onchange="blockSuggest(this.value)">
			<option value="0" <cfif session.block_suggest neq 1> selected="selected" </cfif>>Allow</option>
			<option value="1" <cfif session.block_suggest is 1> selected="selected" </cfif>>Block</option>
		</select>
		<label for="showObservations">Include Observations?</label>
		<select name="showObservations" id="showObservations" onchange="changeshowObservations(this.value)">
			<option value="0" <cfif session.showObservations neq 1> selected="selected" </cfif>>No</option>
			<option value="1" <cfif session.showObservations is 1> selected="selected" </cfif>>Yes</option>
		</select>
		<label for="showObservations">Specimen & Taxonomy Records Per Page</label>
		<select name="displayRows" id="displayRows" onchange="changedisplayRows(this.value);" size="1">
			<option <cfif session.displayRows is "10"> selected </cfif> value="10">10</option>
			<option  <cfif session.displayRows is "20"> selected </cfif> value="20" >20</option>
			<option  <cfif session.displayRows is "50"> selected </cfif> value="50">50</option>
			<option  <cfif session.displayRows is "100"> selected </cfif> value="100">100</option>
		</select>
		<label for="killRows">SpecimenResults Row-Removal Option</label>
		<select name="killRow" id="killRow" onchange="changekillRows(this.value)">
			<option value="0" <cfif session.killRow neq 1> selected="selected" </cfif>>No</option>
			<option value="1" <cfif session.killRow is 1> selected="selected" </cfif>>Yes</option>
		</select>
		<label for="customOtherIdentifier">My Other Identifier</label>
		<select name="customOtherIdentifier" id="customOtherIdentifier"
			size="1" onchange="this.className='red';changecustomOtherIdentifier(this.value);">
			<option value="">None</option>
			<cfloop query="OtherIdType">
				<option
					<cfif session.CustomOtherIdentifier is other_id_type>selected="selected"</cfif>
					value="#other_id_type#">#other_id_type#</option>
			</cfloop>
		</select>
		<label for="fancyCOID">Show 3-part ID on SpecimenSearch</label>
		<select name="fancyCOID" id="fancyCOID"
			size="1" onchange="this.className='red';changefancyCOID(this.value);">
			<option <cfif #session.fancyCOID# is not 1>selected="selected"</cfif> value="">No</option>
			<option <cfif #session.fancyCOID# is 1>selected="selected"</cfif> value="1">Yes</option>
		</select>
		<cfif len(session.roles) gt 0 and session.roles is "public">
			<cfif isdefined("session.portal_id")>
				<cfset pid=session.portal_id>
			<cfelse>
				<cfset pid="">
			</cfif>
			<label for="exclusive_collection_id">Filter Results By Collection</label>
			<select name="exclusive_collection_id" id="exclusive_collection_id"
				onchange="this.className='red';changeexclusive_collection_id(this.value);" size="1">
			 	<option  <cfif pid is "" or pid is 0>selected="selected" </cfif> value="">All</option>
			  	<cfloop query="collid">
					<option <cfif pid is cf_collection_id>selected="selected" </cfif> value="#cf_collection_id#">#collection#</option>
			  	</cfloop>
			</select>
		</cfif>
	</form>

    </div>
	<div id="divRss"></div>

    </div>
	<script>
		$( document ).ready(function(){

            jQuery.getFeed({

               url: 'https://code.mcz.harvard.edu/feed/',
               success: function(feed) {
				var header = feed.title;
				header = header.replace("[en]", "");

                 jQuery('##divRss').empty();
                 var html ='<div class="shell"><h2><a href="https://code.mcz.harvard.edu/wiki/index.php?title=Special:RecentChanges&hideminor=1&days=30">' + header + '</a></h2>';

                  for(var i = 0; i < feed.items.length && i < 5; i++) {

                      var item = feed.items[i];
					  item.updated = new Date(item.updated);

                      html += '<div class="feedAtom">';
					  html += '<div class="updatedAtom" style="position: absolute; z-index: 10;"><p>' + item.updated.toDateString() + '</p></div>';
					  html += '<div class="authorAtom" style="z-index:11;">by ' + item.author + '</div>';
					  html += '<h3><a href="' + item.link + '">' + item.title + '</a></h3>';
                      html += '<div class="descriptionAtom">' + item.description +'</div>';
					  html += '</div>';
                  }
				  html += '</div>';
                  jQuery('##divRss').append(html);
               }

            });

	    });
    </script>

</cfoutput>
</cfif>


<!----------------------------------------------------------------------------------------------->
<cfif action is "saveSettings">
	<cfquery name="isUser" datasource="cf_dbuser">
		update cf_users set
			block_suggest=#block_suggest#
		where username='#session.username#'
	</cfquery>
	<cfset session.block_suggest=block_suggest>
	<cflocation url="/myArctos.cfm" addtoken="false">
</cfif>
<!----------------------------------------------------------------------------------------------->
<cfif action is "saveProfile">
	<!--- get the values they filled in --->
	<cfif len(first_name) is 0 OR
		len(last_name) is 0 OR
		len(affiliation) is 0>
		You haven't filled in all required values! Please use your browser's back button to try again.
		<cfabort>
	</cfif>
	<cfquery name="getUID" datasource="cf_dbuser">
		select user_id from cf_users where username='#session.username#'
	</cfquery>
	<cfquery name="isUser" datasource="cf_dbuser">
		select * from cf_user_data where user_id=#getUID.user_id#
	</cfquery>
		<!---- already have a user_data entry --->
	<cfif isUser.recordcount is 1>
		<cfquery name="upUser" datasource="cf_dbuser">
			UPDATE cf_user_data SET
				first_name = '#first_name#',
				last_name = '#last_name#',
				affiliation = '#affiliation#'
				<cfif len(#middle_name#) gt 0>
					,middle_name = '#middle_name#'
				<cfelse>
					,middle_name = NULL
				</cfif>
				<cfif len(#email#) gt 0>
					,email = '#email#'
				<cfelse>
					,email = NULL
				</cfif>
			WHERE
				user_id = #getUID.user_id#
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
				#getUID.user_id#,
				'#first_name#',
				'#last_name#',
				'#affiliation#'
				<cfif len(#middle_name#) gt 0>
					,'#middle_name#'
				</cfif>
				<cfif len(#email#) gt 0>
					,'#email#'
				</cfif>
				)
		</cfquery>
	</cfif>
	<cflocation url="/myArctos.cfm" addtoken="false">
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

<cfinclude template = "includes/_footer.cfm">
