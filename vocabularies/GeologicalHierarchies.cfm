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
<!--- Include the template that contains functions used to load portions of this page --->
<cfinclude template="/vocabularies/component/functions.cfc" runOnce="true">

<cfquery name="ctgeology_attribute"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	SELECT geology_attribute, type, description 
	FROM ctgeology_attribute
	ORDER BY ordinal
</cfquery>

<cfif NOT isDefined("action") OR len(action) EQ 0>
	<cfset action = "overview">
</cfif>

<cfswitch expression="#action#">
	<cfcase value="overview">
		<cfquery name="types"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="types_result">
			SELECT count(distinct geology_attribute_hierarchy_id) attrib_ct, 
				type 
			FROM ctgeology_attribute ct 
			left join geology_attribute_hierarchy ah on ct.geology_attribute = ah.attribute 
			GROUP BY type
		</cfquery>
		<cfoutput>
			<main class="container py-3" id="content" >
				<section class="row mt-2">
					<div class="col-12 pt-2">
						<h1 class="h2">Manage Geological Controlled Vocabularies</h1>
						<cfset navBlock = getGeologyNavigationHtml()>
						#navBlock#
					</div>
				</section>
				<section class="row border rounded">
					<div class="col-12 pt-3">
						<ul>
							<cfloop query="types">
								<li>#types.type# encompasses #types.attrib_ct# attribute values.</li>
							</cfloop>
						</ul>
					</div>
				</section>
			</main>
		</cfoutput>
	</cfcase>

	<cfcase value="edit">
		<main class="container py-3" id="content" >
			<cfoutput>
				<div class="row mx-0 pt-2">
					<cfset navBlock = getGeologyNavigationHtml()>
					#navBlock#
					<section class="col-12" title="Edit Geological Atribute">
	  					<!--- Lookup the current node --->
						<cfquery name="c"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT 
								GEOLOGY_ATTRIBUTE_HIERARCHY_ID ,
								PARENT_ID ,
								geology_attribute_hierarchy.ATTRIBUTE ,
								ATTRIBUTE_VALUE ,
								USABLE_VALUE_FG ,
								geology_attribute_hierarchy.DESCRIPTION,
								ctgeology_attribute.type,
								ctgeology_attribute.ordinal
							FROM geology_attribute_hierarchy 
								left join ctgeology_attribute on geology_attribute_hierarchy.attribute = ctgeology_attribute.geology_attribute
							WHERE
								geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
						</cfquery>
						<cfif c.recordcount EQ 0>
							<cfthrow message="No such geological attribute found.  The attribute may have been merged or deleted.">
						</cfif>
						<cfquery name="use"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="use_result">
							SELECT count(locality_id) ct
							FROM geology_attributes
								WHERE 
									geology_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#c.attribute#">
									AND
									geo_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#c.attribute_value#">
						</cfquery>

						<cfif c.usable_value_fg EQ 1><cfset uflag="*"><cfelse><cfset uflag=""></cfif>
						<h2 class="h2">Edit #c.type# term: <strong>#c.attribute_value# (#c.attribute#) #uflag#</strong></h2>
						<div class="h3">Attribute for #use.ct# Localities.</div>
						<cfset disabled = "">
						<cfif use.ct GT 0>
							<cfset disabled = "disabled">
						</cfif>

						<form name="ins" id="editAttrValForm" onsubmit="return noenter(event);">
							<input type="hidden" name="geology_attribute_hierarchy_id" value="#geology_attribute_hierarchy_id#">
							<cfif use.ct GT 0>
								<input type="hidden" name="attribute" value="#c.attribute#">
								<input type="hidden" name="attribute_value" value="#c.attribute_value#">
							</cfif>
							<div class="form-row mb-2">
								<div class="col-12 col-sm-12 col-xl-4">
									<label for="attribute#disabled#" class="data-entry-label">Attribute</label>
									<select name="attribute#disabled#" id="attribute#disabled#" class="data-entry-select reqdClr" #disabled#>
										<cfloop query="ctgeology_attribute">
											<cfif c.attribute EQ ctgeology_attribute.geology_attribute><cfset selected="selected='selected'"><cfelse><cfset selected=""></cfif>
											<option value="#ctgeology_attribute.geology_attribute#" #selected# >#ctgeology_attribute.geology_attribute# (#ctgeology_attribute.type#)</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-sm-6 col-xl-4">
									<label for="attribute_value#disabled#">Value</label>
									<input type="text" name="attribute_value#disabled#" id="attribute_value#disabled#" value="#c.attribute_value#" class="data-entry-input reqdClr" #disabled# required>
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
									<div id="updateFeedbackDiv"></div>
								</div>
								<div class="col-12 col-xl-6">
									<cfif use.ct EQ 0>
										<input type="button" value="Delete" id="deleteButton" class="btn btn-xs btn-danger"
											onclick="document.location='/vocabularies/GeologicalHierarchies.cfm?action=delete&geology_attribute_hierarchy_id=#geology_attribute_hierarchy_id#&type=#c.type#';">
									</cfif>
								</div>
							</div>
						</form>
						<script>
							function updateRecord(){ 
								updateGeologicalAttribute(#geology_attribute_hierarchy_id#, $("##attribute").val(), $("##attribute_value").val(), $("##usable_value_fg").val(), $("##description").val(), "updateFeedbackDiv", reloadHierarchy);
							}
							$(document).ready(function(){
								$("##editAttrValForm").submit(function(event) {
									event.preventDefault();
									if (checkFormValidity($('##editAttrValForm')[0])) { 
										updateRecord();  
									}
								});
							});
						</script>
					</section>
					<cfquery name="candidateParents"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT 
							GEOLOGY_ATTRIBUTE_HIERARCHY_ID,
							geology_attribute_hierarchy.ATTRIBUTE,
							ATTRIBUTE_VALUE,
							usable_value_fg
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
					<cfquery name="candidateChildren"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT 
							GEOLOGY_ATTRIBUTE_HIERARCHY_ID,
							geology_attribute_hierarchy.ATTRIBUTE,
							ATTRIBUTE_VALUE,
							usable_value_fg
						FROM geology_attribute_hierarchy 
							left join ctgeology_attribute on geology_attribute_hierarchy.attribute = ctgeology_attribute.geology_attribute
						WHERE
							ctgeology_attribute.type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#c.type#"> and
							ctgeology_attribute.ordinal > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#c.ordinal#"> and 
							geology_attribute_hierarchy_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#"> and
							(
								parent_id is NULL or
								parent_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
							)
						ORDER BY ordinal, attribute_value
					</cfquery>
					<section class="col-12">
						<div class="row border rounded my-2 mx-1 py-1">
							<div class="col-12">
								<h3 class="h4">Hierarchical Relationships of #c.attribute_value# (#c.attribute#)</h3>
							</div>
							<div class="col-12 col-md-8">
								<label for="changeParentage" class="data-entry-label">Change parent of #c.attribute_value# (#c.attribute#) to:</label>
								<select id="changeParentage" name="changeParentage" class="data-entry-select">
									<option value="NULL">Unlink from Parent</option>
									<cfloop query="candidateparents">
										<cfif candidateparents.usable_value_fg EQ 1><cfset uflag="*"><cfelse><cfset uflag=""></cfif>
										<option value="#candidateParents.geology_attribute_hierarchy_id#">#candidateParents.attribute_value# (#candidateParents.attribute#) #uflag#</option>
									</cfloop>
								</select>
							</div>
							<div class="col-12 col-md-4">
								<label for="changeParentageButton" class="data-entry-label">&nbsp;</label>
								<button id="changeParentageButton" value="Save" class="btn btn-secondary btn-xs data-entry-button" >Save</button>
								<div id="changeParentageFeedback"></div>
							</div>
							<div class="col-12" id="localTreeDiv">
								<cfset localTreeBlock = getNodeInGeologyTreeHtml('#geology_attribute_hierarchy_id#')>
								#localTreeBlock#
							</div>
							<cfif candidateChildren.recordcount GT 0> 
								<div class="col-12 col-md-8">
									<label for="addChild" class="data-entry-label">Add a child of #c.attribute_value# (#c.attribute#)</label>
									<select id="addChild" name="addChild" class="data-entry-select">
										<option value=""></option>
										<cfloop query="candidateChildren">
											<cfif candidateChildren.usable_value_fg EQ 1><cfset uflag="*"><cfelse><cfset uflag=""></cfif>
											<option value="#candidateChildren.geology_attribute_hierarchy_id#">#candidateChildren.attribute_value# (#candidateChildren.attribute#) #uflag#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-4">
									<label for="addChildButton" class="data-entry-label">&nbsp;</label>
									<button id="addChildButton" value="Add" class="btn btn-secondary btn-xs data-entry-button">Add</button>
									<div id="addChildFeedback"></div>
								</div>
							</cfif>
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
								function addChild() { 
									var newChild = $('select[name=addChild] option').filter(':selected').val();
									if (newChild) { 
										changeGeologicalAttributeLink(#geology_attribute_hierarchy_id#,newChild, "addChildFeedback", reloadHierarchy);
									} else { 
										messageDialog("Error: No value selected.");
									}
								};
								$(document).ready(function(){
									$("##changeParentageButton").on('click',changeParentage);
									$("##addChildButton").on('click',addChild);
								});
							</script>
						</div>
					</section>
					<section class="col-12">
						<cfquery name="mergeCandidates"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
							SELECT 
								GEOLOGY_ATTRIBUTE_HIERARCHY_ID,
								geology_attribute_hierarchy.ATTRIBUTE,
								ATTRIBUTE_VALUE,
								usable_value_fg,
								ordinal
							FROM geology_attribute_hierarchy 
								left join ctgeology_attribute on geology_attribute_hierarchy.attribute = ctgeology_attribute.geology_attribute
							WHERE
								ctgeology_attribute.type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#c.type#"> and
								<cfif c.usable_value_fg EQ 0>
									USABLE_VALUE_FG = 0 and
								</cfif>
								geology_attribute_hierarchy_id <> <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#"> 
								and (
									ctgeology_attribute.ordinal = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#c.ordinal#">
									OR
									usable_value_fg = 0
								)
							ORDER BY ordinal, attribute_value
						</cfquery>
						<div class="row border rounded my-2 mx-1 py-1">
							<div class="col-12">
								<h3 class="h4">Merge other nodes into #c.attribute#:#c.attribute_value# </h3>
								<p>Merging nodes will update the geological attributes of all localities that use the selected attribute and value to use #c.attribute#:#c.attribute_value# instead.</p>
							</div>
							<cfif mergeCandidates.recordcount GT 0> 
								<div class="col-12 col-md-8">
									<label for="nodeToMerge" class="data-entry-label">Merge selected value into: #c.attribute_value# (#c.attribute#)</label>
									<select id="nodeToMerge" name="nodeToMerge" class="data-entry-select">
										<option value=""></option>
										<cfloop query="mergeCandidates">
											<cfif mergeCandidates.usable_value_fg EQ 1><cfset uflag="*"><cfelse><cfset uflag=""></cfif>
											<option value="#mergeCandidates.geology_attribute_hierarchy_id#">#mergeCandidates.attribute_value# (#mergeCandidates.attribute#) #uflag#</option>
										</cfloop>
									</select>
								</div>
								<div class="col-12 col-md-4">
									<label for="mergeButton" class="data-entry-label">&nbsp;</label>
									<button id="mergeButton" value="Add" class="btn btn-danger btn-xs data-entry-button">Merge</button>
									<div id="mergeFeedback"></div>
								</div>
							<cfelse>
								<div class="col-12">
									<p>
										No Nodes are candidates to merge with this node.  
										<cfif c.usable_value_fg EQ 0>
											Note that nodes approved for data entry can't be merged with nodes which are not.  If there are nodes approved for data entry that you wish to merge with this node, change this node to valid for data entry and reload this page. 
										</cfif>
									</p>
								</div>
							</cfif>
							<cfif c.usable_value_fg EQ 1><cfset uflag="*"><cfelse><cfset uflag=""></cfif>
							<script>
								function mergeNode() { 
									var nodeToMerge = $('select[name=nodeToMerge] option').filter(':selected').val();
									if (nodeToMerge) { 
										mergeGeologicalAttributes(nodeToMerge, #geology_attribute_hierarchy_id#, "mergeFeedback", reloadHierarchy);
									} else { 
										messageDialog("Error: No value selected.");
									}
								};
								function confirmMerge() { 
									var toMerge = $('select[name=nodeToMerge] option').filter(':selected').text();
									confirmDialog('Update all localities replacing all instances of ' + toMerge +' with #c.attribute_value# (#c.attribute#) #uflag#?','Confirm Merge Nodes', mergeNode );
								};
								$(document).ready(function(){
									$("##mergeButton").on('click',confirmMerge);
								});
							</script>
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
					<cfset navBlock = getGeologyNavigationHtml()>
					#navBlock#
					<cfset formBlock = getAddGeologyAttributeHtml ()>
					#formBlock#
				</div>
				<script>
					function reload() {
						// no action 
					};
				</script>
			</cfoutput>
		</main>
	</cfcase>

	<!---------------------------------------->
	<cfcase value="organize">
		<main class="container py-3" id="content" >
			<cfoutput>
				<div class="row mx-0 border rounded my-2 pt-2">
					<cfset navBlock = getGeologyNavigationHtml()>
					#navBlock#
					<cfset organizeBlock = getGeologyMakeTreeHtml()>
					#organizeBlock#
					<script>
						function reload() {
							// no action, required callback for getGeologyMakeTreeHtml.
						};
					</script>
				</div>
			</cfoutput>
		</main>
	</cfcase>

	<!---------------------------------------->
	<cfcase value="list">
		<cfif NOT isDefined("type") OR len(type) EQ 0>
			<cfset type = "all">
		</cfif>
		<main class="container py-3" id="content" >
			<cfoutput>
				<div class="row mx-0 my-2 pt-2 px-2">
					<cfset navBlock = getGeologyNavigationHtml()>
					#navBlock#
					<section class="accordion col-12 px-0" id="editSection"> 
						<div class="card bg-light">
							<div class="card-header">
								<h2 class="h4 my-0">
									<button type="button" class="headerLnk text-left w-100 h-100" data-toggle="collapse" data-target="##editCardBodyWrap" aria-expanded="false" aria-controls="editCardBodyWrap">
											Add New/Edit Hierarchy
									</button>
								</h2>
							</div>
							<div id="editCardBodyWrap" class="collapse" aria-labelledby="publicationHeader" data-parent="##editSection">
								<div class="card-body py-1 mb-1 row">
									<cfset formBlock = getAddGeologyAttributeHtml(type="#type#")>
									#formBlock#
									<cfset organizeBlock = getGeologyMakeTreeHtml(type="#type#")>
									<div id="organizeDiv" class="w-100">
									#organizeBlock#
									</div>
								</div>
							</div>
						</div>
					</section>
					<script>
						function reload() {
							$.ajax({
								url: "/vocabularies/component/functions.cfc",
								data: { 
									type: '#type#',
									method: 'getGeologyAttributeTreeHtml'
								},
								dataType: 'html',
								success : function (result) { 
									$("##attributesSection").html(result)
								},
								error: function (jqXHR, textStatus, error) {
									handleFail(jqXHR,textStatus,error, "Error looking up tree of geological attributes: "); 
								}
							});
							$.ajax({
								url: "/vocabularies/component/functions.cfc",
								data: { 
									type: '#type#',
									method: 'getGeologyMakeTreeHtml'
								},
								dataType: 'html',
								success : function (result) { 
									$("##organizeDiv").html(result)
								},
								error: function (jqXHR, textStatus, error) {
									handleFail(jqXHR,textStatus,error, "Error looking up tree editor for geological attributes: "); 
								}
							});
						};
					</script>
					<cfset attributesBlock = getGeologyAttributeTreeHtml(type="#type#")>
					<section class="col-12 border rounded" title="Geological Atribute" id="attributesSection">
						#attributesBlock#
					</section>
				</div>
			</cfoutput>
		</main>
	</cfcase>

	<!---------------------------------------------------->
	<cfcase value="delete">
		<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
		<cfoutput>
			<cfif not isDefined("geology_attribute_hierarchy_id") OR len(geology_attribute_hierarchy_id) EQ 0>
				<cfthrow message = "Error: No record specified to delete.">
			</cfif>
			<cftransaction>
			<cftry>
				<cfquery name="findParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					SELECT parent_id 
					FROM geology_attribute_hierarchy 
					WHERE 
						geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#"> and
						parent_id IS NOT NULL
				</cfquery>
				<cfif findParent.recordcount EQ 1>
					<cfquery name="relinkChildren" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE geology_attribute_hierarchy
						SET parent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#findParent.parent_id#">
						where parent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
					</cfquery>
				<cfelse>
					<cfquery name="unlinkChildren" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						UPDATE geology_attribute_hierarchy
						SET parent_id = NULL
						where parent_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
					</cfquery>
				</cfif>
				<cfquery name="killGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
					DELETE FROM geology_attribute_hierarchy 
					WHERE 
						geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
				</cfquery>
				<cftransaction action="commit">
			<cfcatch>
				<cftransaction action="rollback">
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfthrow message = "Delete Failed. #error_message#">
			</cfcatch>
			</cftry>
			</cftransaction>
			<cfset typebit ="">
			<cfif isDefined("type") AND len(type) GT 0>
				<cfset typebit ="&type=#encodeForUrl(type)#">
			</cfif>
			<cflocation url="/vocabularies/GeologicalHierarchies.cfm?action=list#typebit#" addtoken="false">
		</cfoutput>
	</cfcase>

</cfswitch>

<cfinclude template="/shared/_footer.cfm">
