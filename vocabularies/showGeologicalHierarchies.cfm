<!---
showGeologicalHierarchies.cfm

View geological attribute controlled vocabularies.

Copyright 2008-2021 President and Fellows of Harvard College

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
<cfset pageTitle = "View Geological Controlled Vocabularies">
<cfinclude template="/shared/_header.cfm">

<cfquery name="ctgeology_attribute"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT geology_attribute, type, description 
	FROM ctgeology_attribute
	ORDER BY ordinal
</cfquery>

<cfif NOT isDefined("type") OR len(type) EQ 0>
	<cfset type = "all">
</cfif>
<cfquery name="cData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT  
		level,
		geology_attribute_hierarchy_id,
		parent_id,
		usable_value_fg,
		attribute_value,
		attribute,
		geology_attribute_hierarchy.description
	FROM
		geology_attribute_hierarchy
		LEFT JOIN ctgeology_attribute on attribute = geology_attribute
	<cfif NOT type IS "all">
	WHERE
		ctgeology_attribute.type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#type#">
	</cfif>  
	START WITH parent_id is null
	CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id
	ORDER SIBLINGS BY ordinal, attribute_value
</cfquery>
<main class="container py-3" id="content" >
	<cfoutput>
		<div class="row mx-0 border rounded my-2 pt-2 px-2">
			<cfquery name="types"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="types_result">
				SELECT distinct type 
				FROM ctgeology_attribute
			</cfquery>

				<ul class="nav nav-tabs">
					<cfloop query="types">
						<li class="nav-item border-top border-right border-left rounded">
							<a class="nav-link btn-link text-capitalize" href="/vocabularies/showGeologicalHierarchies.cfm?type=#types.type#">List #types.type# Terms</a>
						</li>
					</cfloop>
					<li class="nav-item border-top border-right border-left rounded">
						<a class="nav-link btn-link" href="/vocabularies/showGeologicalHierarchies.cfm">List All Terms</a>
					</li>
				</ul>
		
			<cfset typetext = "">
			<cfif type NEQ "all">
				<cfset typetext = ": #encodeForHtml(type)#">
			</cfif>
			<section class="col-12" title="Geological Atribute#typetext#">
				<h2 class="h3">Geological Attributes#typetext#</h2> 
				<div>Values in red are not available for data entry but may be used in searches</div>
				<cfset levelList = "">
				<cfloop query="cData">
					<cfquery name="locCount" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT count(locality_id) ct
						FROM geology_attributes
						WHERE
							geology_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cData.attribute#"> and
							geo_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#cData.attribute_value#">
					</cfquery>
					<cfset localityCount = locCount.ct>
					<cfif listLast(levelList,",") IS NOT level>
						<cfset levelListIndex = listFind(levelList,cData.level,",")>
						<cfif levelListIndex IS NOT 0>
							<cfset numberOfLevelsToRemove = listLen(levelList,",") - levelListIndex>
							<cfloop from="1" to="#numberOfLevelsToRemove#" index="i">
								<cfset levelList = listDeleteAt(levelList,listLen(levelList,","))>
							</cfloop>
							#repeatString("</ul>",numberOfLevelsToRemove)#
						<cfelse>
							<cfset levelList = listAppend(levelList,cData.level)>
							<ul>
						</cfif>
					</cfif>
					<cfset class="">
					<cfif usable_value_fg is 0><cfset class="text-danger"></cfif>
					<li>
						<span class="#class#">
							#attribute_value# (#attribute#)
							<cfif usable_value_fg IS 1>*</cfif>
						</span>
						#description#
						Used in #localityCount# Localities
					</li>
					<cfif cData.currentRow IS cData.recordCount>
						#repeatString("</ul>",listLen(levelList,","))#
					</cfif>
				</cfloop>
			</section>
		</div>
	</cfoutput>
</main>

<cfinclude template="/shared/_footer.cfm">
