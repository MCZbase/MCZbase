<!--
containers/browseContainer.cfm

Copyright 2021 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->
<cfset pageTitle="Browse Containers">
<cfinclude template="/shared/_header.cfm">
<cfif NOT isDefined("action")>
	<cfset action="">
</cfif>

<cfquery name="ctcontainer_type" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT container_type 
	FROM ctcontainer_type 
	ORDER BY container_type
</cfquery>

<cfoutput>
	<main class="container" id="content">
		<cfswitch expression="#action#">
			<cfcase value="qc">
				<h1 class="h3">Containers which should be placed in another container, but are not.</h2>
				<!---  parent_container_id = 0 are root containers, these should just be The Museum of Comparative Zoology and Deaccessioned.
				parent_container_id = 1 are containers within The Museum of Comparative Zoology (target is just the MCZ-campus and CFS-campus) --->
				<cfquery name="parentlessNodes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(*) ct, container_type 
					FROM container 
					WHERE parent_container_id < 2 and container_type <> 'campus' 
					GROUP BY container_type
				</cfquery>
				<div class="row">
					<div class="col-12">
						<ul>
							<cfloop query="parentlessNodes">
								<li>#parentlessNodes.container_type# (#parentlessNodes.ct#)</li>
								<cfif parentlessNodes.ct LT 100>
									<cfquery name="plNode" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
										SELECT label, container_type 
										FROM container 
										WHERE parent_container_id < 2 and container_type <> 'campus' 
											and container_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#parentlessNodes.container_type#">
									</cfquery>
									<ul>
										<cfloop query="plNode">
											<li><a href="findContainer.cfm?container_label=#plNode.label#">#plNode.label# (#plNode.container_type#)</a> in [nothing]</li>
										</cfloop>
									</ul>
								</cfif>
							</cfloop>
						</ul>
					</div>
				</div>
			</cfcase>
			<cfcase value="fixtures">
				<cfif not isdefined("labelStart")><cfset labelStart="IZ"></cfif>
				<!--- Get fixture name and parentage for a department --->
				<cfquery name="fixtures" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT container_type, label, sys_connect_by_path( label || ' (' || container_type ||')' ,' | ') parentage 
					FROM container
					WHERE (container_type = 'fixture' or container_type like '%freezer' or container_type = 'cryovat') 
						and label like <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#labelStart#%">
					START WITH container_type = 'campus'
					CONNECT BY PRIOR container_id = parent_container_id
					ORDER BY label
				</cfquery>
				<div class="row">
					<div class="col-12">
						<ul>
							<cfloop query="fixtures">
								<li><a href="findContainer.cfm?container_label=#fixtures.label#">#fixtures.label# (#fixtures.container_type#)</a> in #fixtures.parentage#</li>
							</cfloop>
						</ul>
					</div>
				</div>
			</cfcase>
			<cfdefaultcase>
				<!--- find list of departments (first few characters of fixture names) --->
				<cfquery name="fixturePrefixes" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT count(*) as ct, nvl(nvl(substr(label,0, instr(label,'_')-1),substr(label,0, instr(label,'-')-1)),substr(label,0, 4)) as prefix 
					FROM container 
					WHERE container_type = 'fixture' or container_type like '%freezer' or container_type = 'cryovat' 
					GROUP BY nvl(nvl(substr(label,0, instr(label,'_')-1),substr(label,0, instr(label,'-')-1)),substr(label,0, 4))
				</cfquery>
				<div class="row">
					<div class="col-12">
						<ul>
							<li><a href = "/containers/browseContainer.cfm?action=qc">Quality Control Containers</a></li>
							<li>List fixtures starting with:</li>
							<ul style="padding-left: 2em; line-height: 1.5em;">
								<cfloop query="fixturePrefixes">
									<li><a href = "/containers/browseContainer.cfm?action=fixtures&labelStart=#fixturePrefixes.prefix#">#fixturePrefixes.prefix# (#fixturePrefixes.ct#)</a></li>
								</cfloop>
							</ul>
						</ul>
					</div>
				</div>
			</cfdefaultcase>
		</cfswitch>
	</main>
</cfoutput>
<cfinclude template="shared/_footer.cfm">
