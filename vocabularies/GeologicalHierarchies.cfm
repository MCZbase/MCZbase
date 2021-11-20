<!---
GeologicalHierarchies.cfm

Management of geological attribute controlled vocabularies.

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
<cfset pageTitle = "Manage Geological Controlled Vocabularies">
<cfinclude template="/shared/_header.cfm">

<cfquery name="ctgeology_attribute"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT geology_attribute, type, description 
	FROM ctgeology_attribute
	ORDER BY ordinal
</cfquery>

<cfif NOT isDefined("action") OR len(action) EQ 0>
	<cfquery name="types"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="types_result">
		SELECT distinct type 
		FROM ctgeology_attribute
	</cfquery>
	<cfset action = "overview">
	<cfoutput>
		<main class=”container py-3” id=”content” >
			<section class=”row border rounded my-2”>
				<h1 class=”h2”>Manage Geological Controlled Vocabularies</h1>
				<ul>
					<li><a href="/CodeTableEditor.cfm?action=edit&tbl=CTGEOLOGY_ATTRIBUTES">Manage attribute types and categories</a></li>
					<cfloop query="types">
						<li><a href="/vocabularies/GeologicalHierarchies.cfm?action=list&type=#types.type#">List/Edit #types.type# Terms</a></li>
					</cfloop>
					<li><a href="/vocabularies/GeologicalHierarchies.cfm?action=list">List/Edit All Terms</a></li>
					<li><a href="/vocabularies/GeologicalHierarchies.cfm?action=addNew">Add New Term</a></li>
					<li><a href="/vocabularies/GeologicalHierarchies.cfm?action=organize">Organize Hiearchically</a></li>
				</ul>
			</section>
		</main>
	</cfoutput>
</cfif>

<cfswitch expression="#action#">
	<cfcase value="edit">
		<!--- Include the template that contains functions used to load portions of this page --->
		<cfinclude template="/vocabularies/component/functions.cfc" runOnce="true">
		<main class="container py-3" id="content" >
			<cfoutput>
				<div class="row mx-0 border rounded my-2 pt-2">
					<section class="col-12" title="Edit Geological Atribute">
	  
						<cfquery name="c"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT 
								GEOLOGY_ATTRIBUTE_HIERARCHY_ID ,
								PARENT_ID ,
								geology_attribute_hierarchy.ATTRIBUTE ,
								ATTRIBUTE_VALUE ,
								USABLE_VALUE_FG ,
								geology_attribute_hierarchy.DESCRIPTION,
								ctgeology_attribute.type
							FROM geology_attribute_hierarchy 
								left join ctgeology_attribute on geology_attribute_hierarchy.attribute = ctgeology_attribute.geology_attribute
							WHERE
								geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
						</cfquery>
						<cfquery name="use"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="use_result">
							SELECT count(locality_id) ct
							FROM geology_attributes
								WHERE 
									geology_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#c.attribute#">
									AND
									geo_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#c.attribute_value#">
						</cfquery>

						<h2 class="h2">Edit #c.attribute#:#c.attribute_value# (#c.type#)</h2>
						<div class="h3">Attribute for #use.ct# Localities.</div>
						<cfset disabled = "">
						<cfif use.ct GT 0>
							<cfset disabled = "disabled">
						</cfif>

						<form name="ins" method="post" action="/vocabularies/GeologicalHierarchies.cfm">
							<input type="hidden" name="action" value="saveEdit">
							<input type="hidden" name="geology_attribute_hierarchy_id" value="#geology_attribute_hierarchy_id#">
							<cfif use.ct GT 0>
								<input type="hidden" name="attribute" value="#c.attribute#">
								<input type="hidden" name="attribute_value" value="#c.attribute_value#">
							</cfif>
							<div class="form-row mb-2">
								<div class="col-12 col-sm-12 col-xl-4">
									<label for="attribute" class="data-entry-label">Attribute</label>
									<select name="attribute" id="attribute" class="data-entry-select reqdClr" #disabled#>
										<cfloop query="ctgeology_attribute">
											<cfif c.attribute EQ ctgeology_attribute.geology_attribute><cfset selected="selected='selected'"><cfelse><cfset selected=""></cfif>
											<option value="#ctgeology_attribute.geology_attribute#" #selected# >#ctgeology_attribute.geology_attribute# (#ctgeology_attribute.type#)</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-sm-6 col-xl-4">
									<label for="newTerm">Value</label>
									<input type="text" name="attribute_value" id="newTerm" value="#c.attribute_value#" class="data-entry-input reqdClr" #disabled# required>
								</div>
								<div class="col-12 col-sm-6 col-xl-4">
									<label for="usable_value_fg" class="data-entry-label">Allowed for Data Entry?</label>
									<cfset uvf=c.usable_value_fg>
									<select name="usable_value_fg" id="usable_value_fg" class="data-entry-select reqdClr">
										<option <cfif #uvf# is 0>selected="selected" </cfif>value="0">no</option>
										<option <cfif #uvf# is 1>selected="selected" </cfif>value="1">yes</option>
									</select>
								</div>
							</div>
							<div class="form-row mb-2">
								<div class="col-12">
									<label for="description" class="data-entry-label">Description</label>
									<input class="data-entry-input" type="text" name="description" id="description" value="#c.description#">
								</div>
							</div>
							<div class="form-row mb-2">
								<div class="col-12 col-xl-6">
									<input type="submit" id="saveUpdatesButton"  value="Save Edits" class="btn btn-primary btn-xs">
								</div>
								<div class="col-12 col-xl-6">
									<cfif use.ct EQ 0>
										<input type="button" value="Delete" id="deleteButton" class="btn btn-xs btn-danger"
	   									onclick="document.location='/vocabularies/GeologicalHierarchies.cfm?action=delete&geology_attribute_hierarchy_id=#geology_attribute_hierarchy_id#';">
									</cfif>
								</div>
							</div>
						</form>
					</section>
					<cfquery name="candidateParents"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT 
							GEOLOGY_ATTRIBUTE_HIERARCHY_ID,
							geology_attribute_hierarchy.ATTRIBUTE,
							ATTRIBUTE_VALUE
						FROM geology_attribute_hierarchy 
							left join ctgeology_attribute on geology_attribute_hierarchy.attribute = ctgeology_attribute.geology_attribute
						WHERE
							ctgeology_attribute.type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#c.type#"> and
							USABLE_VALUE_FG = 1 and
							geology_attribute_hierarchy_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#"> and
							(
								parent_id is NULL or
								parent_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
							)
						ORDER BY ordinal, attribute_value
					</cfquery>
					<section class="col-12">
						<div class="row border rounded my-2 mx-1">
							<div class="col-12">
								<h3 class="h4">Hierarchical Relationships of #c.attribute_value# (#c.attribute#)</h3>
							</div>
							<div class="col-12 col-md-8">
								<label for="changeParentage" class="data-entry-label">Change parent of #c.attribute_value# (#c.attribute#) to:</label>
								<select id="changeParentage" name="changeParentage" class="data-entry-select">
									<option value="NULL">Unlink from Parent</option>
									<cfloop query="candidateparents">
										<option value="#candidateParents.geology_attribute_hierarchy_id#">#candidateParents.attribute_value# (#candidateParents.attribute#)</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4">
								<label for="changeParentageButton" class="data-entry-label">&nbsp;</label>
								<button id="changeParentageButton" value="Save" class="btn btn-secondary btn-xs data-entry-button" >Save</button>
								<div id="changeParentageFeedback"></div>
							</div>
							<script>
								function reloadHierarchy() { 
									refreshGeologyTreeForNode(#geology_attribute_hierarchy_id#,"localTreeDiv")
								};
								function changeParentage() { 
									var newParent = $('select[name=changeParentage] option').filter(':selected').val();
									if (newParent) { 
										changeGeologicalAttributeLink(newParent, #geology_attribute_hierarchy_id#, "changeParentageFeedback", reloadHierarchy);
									} else { 
										messageDialog("Error: No value selected.");
									}
								};
								$(document).ready(function(){
									$("##changeParentageButton").on('click',changeParentage);
								});
							</script>
							<div class="col-12" id="localTreeDiv">
								<cfset localTreeBlock = getNodeInGeologyTreeHtml('#geology_attribute_hierarchy_id#')>
								#localTreeBlock#
							</div> 
						</div>
					</section>
				</div>
			</cfoutput>
		</main>
	</cfcase>

	<!---------------------------------------->
	<cfcase value="addNew">
		<main class="container py-3" id="content" >
			<cfoutput>
				<div class="row mx-0 border rounded my-2 pt-2">
					<section class="col-12" title="Add Geological Atribute">
						<h2 class="h3">Add New Geological Attribute Value:</h2>
						<form name="insertGeolAttrForm" id="insertGeolAttrForm" >
							<div class="form-row mb-2">
								<div class="col-12 col-sm-12 col-xl-4">
									<label for="attribute" class="data-entry-label">Attribute ("Formation")</label>
									<select name="attribute" id="attribute" class="data-entry-select reqdClr">
										<cfloop query="ctgeology_attribute">
											<option value="#ctgeology_attribute.geology_attribute#" >#ctgeology_attribute.geology_attribute# (#ctgeology_attribute.type#)</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-sm-12 col-xl-4">
									<label for="attribute_value" class="data-entry-label">Value ("Prince Creek")</label>
									<input type="text" name="attribute_value" id="attribute_value" class="data-entry-input reqdClr" required>
								</div>
								<div class="col-12 col-sm-12 col-xl-4">
									<label for="usable_value_fg" class="data-entry-label">Attribute valid for Data Entry?</label>
									<select name="usable_value_fg" id="usable_value_fg" class="data-entry-select reqdClr">
										<option value="0">no</option>
										<option value="1">yes</option>
									</select>
								</div>
								<div class="col-12">
									<label for="description" class="data-entry-label">Description</label>
									<input type="text" name="description" id="description" class="data-entry-input">
								</div>
								<div class="col-12">
									<input type="submit" value="Insert Term" class="btn btn-xs btn-primary">
									<div id="addFeedbackDiv"></div>
								</div>
							</div>
						</form>
						<script>
							function reload() { 
								// TODO: implement
							}
							function saveNew(){ 
								addGeologicalAttribute($("##attribute").val(), $("##attribute_value").val(), $("##usable_value_fg").val(), $("##description").val(), "addFeedbackDiv", reload);
							}
							$(document).ready(function(){
								$("##insertGeolAttrForm").submit(function(event) {
									event.preventDefault();
									if (checkFormValidity($('##insertGeolAttrForm')[0])) { 
										saveNew();  
									}
								});
							});
						</script>
					</section>
				</div>
			</cfoutput>
		</main>
	</cfcase>

	<!---------------------------------------->
	<cfcase value="organize">
		<cfquery name="terms"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select geology_attribute_hierarchy_id,
				attribute_value || ' (' || attribute || ')' attribute
			from geology_attribute_hierarchy
				order by attribute
		</cfquery>
		<main class="container py-3" id="content" >
			<cfoutput>
				<div class="row mx-0 border rounded my-2 pt-2">
					<section class="col-12" title="Edit Geological Atribute">
						<h2 class="h3">Link terms into Hierarchies</h2>
						<form name="rel" method="post" action="/vocabularies/GeologicalHierarchies.cfm">
							<input type="hidden" name="action" value="newReln">
							<div class="form-row mb-2">
								<div class="col-12 col-md-6 col-xl-6">
									<label for="parent" class="data-entry-label">Parent Term</label>
									<select name="parent" class="data-entry-select reqdClr" id="parent" required>
										<option value="">NULL</option>
										<cfloop query="terms">
											<option value="#geology_attribute_hierarchy_id#">#attribute#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-6 col-xl-6">
									<label for="child">Child Term</label>
									<select name="child" id="child" class="data-entry-select reqdClr">
										<cfloop query="terms">
											<option value="#geology_attribute_hierarchy_id#">#attribute#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12">
									<input type="submit" value="Create Relationship" class="btn btn-xs btn-primary">
								</div>
							</div>
						</form>
					</section>
				</div>
			</cfoutput>
		</main>
	</cfcase>

	<!---------------------------------------->
	<cfcase value="list">
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
				attribute
			FROM
				geology_attribute_hierarchy
				LEFT JOIN ctgeology_attributes on attribute = geology_attribute
			<cfif NOT type IS "all">
			WHERE
				ctgeology_attributes.type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#type#">
			</cfif>  
			START WITH parent_id is null
			CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id
			ORDER SIBLINGS BY ordinal, attribute_value
		</cfquery>
		<main class="container py-3" id="content" >
			<cfoutput>
				<div class="row mx-0 border rounded my-2 pt-2">
					<section class="col-12" title="Edit Geological Atribute">
						<h2 class="h3">Geological Attributes</h2> 
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
								</span>
								<a class="infoLink" href="/vocabularies/GeologicalHierarchies.cfm?action=edit&geology_attribute_hierarchy_id=#geology_attribute_hierarchy_id#">more</a>
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
	</cfcase>

	<!---------------------------------------------------->
	<cfcase value="delete">
		<cfoutput>
			<cfquery name="killGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				DELETE FROM geology_attribute_hierarchy 
				WHERE 
					geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
			</cfquery>
			<cflocation url="/vocabularies/GeologicalHierarchies.cfm?action=list" addtoken="false">
		</cfoutput>
	</cfcase>

	<!---------------------------------------------------->
	<cfcase value="saveEdit">
		<cfoutput>
			<cfquery name="changeGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE geology_attribute_hierarchy SET
					attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute#">,
					attribute_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_value#">,
					usable_value_fg = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#usable_value_fg#">,
					description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">
				WHERE
					geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
			</cfquery>
			<cflocation url="/vocabularies/GeologicalHierarchies.cfm?action=list" addtoken="false">
		</cfoutput>
	</cfcase>

	<!---------------------------------------------------->
	<cfcase value="newReln">
		<!--- TODO: Moved to component --->
		<cfoutput>
			<cfquery name="changeGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				UPDATE geology_attribute_hierarchy 
				SET parent_id=<cfif parent is "">NULL<cfelse><cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#parent#"></cfif> 
				WHERE 
					geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#child#">
			</cfquery>
			<cflocation url="/vocabularies/GeologicalHierarchies.cfm?action=list" addtoken="false">
		</cfoutput>
	</cfcase>

</cfswitch>

<cfinclude template="/shared/_footer.cfm">
