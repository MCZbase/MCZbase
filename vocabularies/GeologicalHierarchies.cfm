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

<cfif NOT isDefined("action") OR length(action) EQ 0>
	<cfset action = "overview">
	<main class=”container py-3” id=”content” >
		<section class=”row border rounded my-2”>
			<h1 class=”h2”>Manage Geological Controlled Vocabularies</h1>

			<a href="/vocabularies/GeologicalHierarchies.cfm?action=list">List/Edit All</a>
		</section>
	</main>
</cfif>

<cfswitch expression="#action#">
	<cfcase value="edit">
		<main class=”container py-3” id=”content” >
			<cfoutput>
				<section class=”row border rounded my-2”>
	  
					<cfquery name="c"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
						SELECT 
							GEOLOGY_ATTRIBUTE_HIERARCHY_ID ,
							PARENT_ID ,
							geology_attribute_heirarchy.ATTRIBUTE ,
							ATTRIBUTE_VALUE ,
							USABLE_VALUE_FG ,
							DESCRIPTION,
							ctgeology_attribute.type
						FROM geology_attribute_hierarchy 
							left join ctgeology_attribute on geology_attribute_heirarchy.attribute = ctgeology_attribute.geology_attribute
						WHERE
							geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
					</cfquery>

					<h1 class=”h2”>Edit #c.attribute#:#c.attribute_value# (#c.type#)</h1>

					<cfquery name="use"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="use_result">
						SELECT count(*) ct
						FROM geology_attributes
							WHERE 
								geology_attribute = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#c.attribute#">
								AND
								geo_att_value = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#c.attribute_value#">
					</cfquery>

					<form name="ins" method="post" action="/vocabularies/GeologicalHierarchies.cfm">
						<input type="hidden" name="action" value="saveEdit">
						<input type="hidden" name="geology_attribute_hierarchy_id" value="#geology_attribute_hierarchy_id#">

						<label for="attribute">Attribute ("Formation")</label>
						<select name="attribute" id="attribute">
							<cfloop query="ctgeology_attribute">
								<cfif c.attribute EQ ctgeology_attribute.geology_attribute><cfset selected="selected='selected'"><cfelse><cfset selected=""></cfif>
								<option value="#ctgeology_attribute.geology_attribute#" #selected# >#ctgeology_attribute.geology_attribute# (#ctgeology_attribute.type#)</option>
							</cfloop>
						</select>

						<label for="newTerm">Value ("Prince Creek")</label>
						<input type="text" name="attribute_value" id="newTerm" value="#c.attribute_value#">

						<label for="usable_value_fg">Attribute valid for Data Entry?</label>
						<cfset uvf=c.usable_value_fg>
						<select name="usable_value_fg" id="usable_value_fg">
							<option <cfif #uvf# is 0>selected="selected" </cfif>value="0">no</option>
							<option <cfif #uvf# is 1>selected="selected" </cfif>value="1">yes</option>
						</select>

						<label for="description">Description</label>
						<input type="text" name="description" id="description" value="#c.description#" size="60">

						<div class="h3">Attribute for #use.ct# Localities</div>

						<br>
						<input type="submit" 
							value="Save Edits" 
							class="savBtn"
		   				onmouseover="this.className='savBtn btnhov'" 
					   	onmouseout="this.className='savBtn'">

						<cfif use.ct EQ 0>
							<br>
							<input type="button" 
								value="Delete" 
								class="delBtn"
		   					onmouseover="this.className='delBtn btnhov'" 
						   	onmouseout="this.className='delBtn'"
	   						onclick="document.location='geol_hierarchy.cfm?action=delete&geology_attribute_hierarchy_id=#geology_attribute_hierarchy_id#';">
						</cfif>

						<br>
						<input type="button" 
							value="Nevermind..." 
							class="qutBtn"
		   				onmouseover="this.className='qutBtn btnhov'" 
					   	onmouseout="this.className='qutBtn'"
	   					onclick="document.location='/vocabularies/GeologicalHierarchies.cfm?action=list';">

					</form>
				</section>
				<section class=”row border rounded my-2”>
					<cfquery name="parents"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="parents_result">
				      SELECT
				         level,
				         geology_attribute_hierarchy_id,
				         parent_id,
				         usable_value_fg,
				         attribute_value || ' (' || attribute || ')' attribute,
							SYS_CONNECT_BY_PATH(attribute_value, '|') as path
				      FROM
				         geology_attribute_hierarchy
				         LEFT JOIN ctgeology_attributes on attribute = geology_attribute
						WHERE
							geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
				      START WITH parent_id IS NULL
       				CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id
					</cfquery>
					<cfloop query="parents">
						<div>#parents.path#</div>
					</cfloop>
					<cfquery name="children"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#" result="children_result">
				      SELECT
				         level,
				         geology_attribute_hierarchy_id,
				         parent_id,
				         usable_value_fg,
				         attribute_value || ' (' || attribute || ')' attribute
				      FROM
				         geology_attribute_hierarchy
				         LEFT JOIN ctgeology_attributes on attribute = geology_attribute
				         START WITH geology_attribute_hierarchy.geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="c.geology_attribute_hierarchy_id">
       					CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id
    						ORDER SIBLINGS BY ordinal, attribute_value
					</cfquery>
					<cfset levelList = "">
					<cfloop query="children">
						<cfif listLast(levelList,",") IS NOT children.level>
					    	<cfset levelListIndex = listFind(levelList,children.level,",")>
				      	<cfif levelListIndex IS NOT 0>
					        	<cfset numberOfLevelsToRemove = listLen(levelList,",") - levelListIndex>
				         	<cfloop from="1" to="#numberOfLevelsToRemove#" index="i">
				            	<cfset levelList = listDeleteAt(levelList,listLen(levelList,","))>
         					</cfloop>
					        	#repeatString("</ul>",numberOfLevelsToRemove)#
			      		<cfelse>
      			  			<cfset levelList = listAppend(levelList,children.level)>
         					<ul>
      					</cfif>
  						</cfif>
						<li>
							<span <cfif children.usable_value_fg is 0>style="color:red"</cfif>>#children.attribute#</span>
							<a class="infoLink" href="/vocabularies/GeologicalHierarchies.cfm?action=edit&geology_attribute_hierarchy_id=#children.geology_attribute_hierarchy_id#">more</a>
						</li>
						<cfif cData.currentRow IS cData.recordCount>
							#repeatString("</ul>",listLen(levelList,","))#
				   	</cfif>
					</cfloop>
				</section>

			</cfoutput>
		</mail>
	</cfcase>

	<!---------------------------------------->
	<cfcase value="list">

		<cfquery name="cData" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			SELECT  
				level,
				geology_attribute_hierarchy_id,
				parent_id,
				usable_value_fg,
				attribute_value || ' (' || attribute || ')' attribute
			FROM
				geology_attribute_hierarchy
				LEFT JOIN ctgeology_attributes on attribute = geology_attribute
				START WITH parent_id is null
				CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id
				ORDER SIBLINGS BY ordinal, attribute_value
		</cfquery>
		<cfquery name="terms"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select geology_attribute_hierarchy_id,
				attribute_value || ' (' || attribute || ')' attribute
			from geology_attribute_hierarchy
				order by attribute
		</cfquery>

	<div class="geol_hier">
		<h2 class="wikilink">Geology Attributes (code table)</h2>
		<div style="border:1px dotted gray;font-size:smaller;padding: 20px;">
			<p>This form serves dual purpose as the code table editor for geology attributes and a way to store hierarchical relationships among attributes.</p>
			<ul>
				<li>Create any attributes that you need.</li>
				<li>Select "no" for "Attribute valid for Data Entry" for those that should only be used for searching legacy data values, but not allowed for new values.</li>
				<li>Note that Attribute and Value are required. Value is used in building hierarchies for searching.</li>
				<li>Create hierarchies by selecting a child and parent term. </li>
				<li> Click "More" to edit or delete an attribute. You cannot delete attributes with children.</li>
			</ul>
		</div>
		<cfoutput>
			<table class="newRec">
				<tr><td>
				New Term:
				<form name="ins" method="post" action="geol_hierarchy.cfm">
					<input type="hidden" name="action" value="newTerm">
					<label for="attribute">Attribute ("Formation")</label>
					<select name="attribute" id="attribute">
						<cfloop query="ctgeology_attribute">
							<option value="#ctgeology_attribute.geology_attribute#" >#ctgeology_attribute.geology_attribute# (#ctgeology_attribute.type#)</option>
						</cfloop>
					</select>
					<label for="attribute_value">Value ("Prince Creek")</label>
					<input type="text" name="attribute_value" id="attribute_value">
					<label for="usable_value_fg">Attribute valid for Data Entry?</label>
					<select name="usable_value_fg" id="usable_value_fg">
						<option value="0">no</option>
						<option value="1">yes</option>
					</select>
					<label for="description">Description</label>
					<input type="text" name="description" id="description" size="60">
					<br>
					<input type="submit" value="Insert Term" class="insBtn"
						onmouseover="this.className='insBtn btnhov'" 
						onmouseout="this.className='insBtn'">	
			</form>
			</td></tr>
		</table>

Create Hierarchies:
<form name="rel" method="post" action="geol_hierarchy.cfm">
	<input type="hidden" name="action" value="newReln">
	<label for="newTerm">Parent Term</label>
	<select name="parent">
		<option value="">NULL</option>
		<cfloop query="terms">
			<option value="#geology_attribute_hierarchy_id#">#attribute#</option>
		</cfloop>
	</select>
	<label for="newTerm">Child Term</label>
	<select name="child">
		<cfloop query="terms">
			<option value="#geology_attribute_hierarchy_id#">#attribute#</option>
		</cfloop>
	</select>
	<br>
	<input type="submit" 
		value="Create Relationship" 
		class="savBtn"
           style="margin-top:.5em;"
	   	onmouseover="this.className='savBtn btnhov'"
	   	onmouseout="this.className='savBtn'">
</form>


<br>Current Data (values in red are NOT code table values but may still be used in searches):
<cfset levelList = "">
<cfloop query="cData">
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
	<li><span <cfif usable_value_fg is 0>style="color:red"</cfif>
	>#attribute#</span>
	<a class="infoLink" href="geol_hierarchy.cfm?action=edit&geology_attribute_hierarchy_id=#geology_attribute_hierarchy_id#">more</a>
	</li>
	<cfif cData.currentRow IS cData.recordCount>
		#repeatString("</ul>",listLen(levelList,","))#
   	</cfif>
</cfloop>
</cfoutput>
    </div>

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
	<cfcase value="newTerm">
		<cfoutput>
			<cfquery name="changeGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
				insert into geology_attribute_hierarchy 
					(attribute,
					attribute_value,
					usable_value_fg,
					description) 
				values
					(<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#attribute_value#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#usable_value_fg#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#description#">)
			</cfquery>
			<cflocation url="/vocabularies/GeologicalHierarchies.cfm?action=list" addtoken="false">
		</cfoutput>
	</cfcase>

	<!---------------------------------------------------->
	<cfcase value="newReln">
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
