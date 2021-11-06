<cfinclude template="/includes/_header.cfm">
<cfquery name="ctgeology_attribute"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
	select geology_attribute, type from ctgeology_attribute
</cfquery>

<cfif #action# is "edit">
   <div class="geol_hier">
	<cfoutput>
  
	<cfquery name="c"  datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select *
		from geology_attribute_hierarchy 
		where geology_attribute_hierarchy_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#geology_attribute_hierarchy_id#">
	</cfquery>
	<form name="ins" method="post" action="geol_hierarchy.cfm">
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
	<br>
	<input type="submit" 
		value="Save Edits" 
		class="savBtn"
	   	onmouseover="this.className='savBtn btnhov'" 
	   	onmouseout="this.className='savBtn'">
	<br>
	<input type="button" 
		value="Delete" 
		class="delBtn"
	   	onmouseover="this.className='delBtn btnhov'" 
	   	onmouseout="this.className='delBtn'"
   		onclick="document.location='geol_hierarchy.cfm?action=delete&geology_attribute_hierarchy_id=#geology_attribute_hierarchy_id#';">
	<br>
	<input type="button" 
		value="Nevermind..." 
		class="qutBtn"
	   	onmouseover="this.className='qutBtn btnhov'" 
	   	onmouseout="this.className='qutBtn'"
   		onclick="document.location='geol_hierarchy.cfm';">
	</form>
	</cfoutput>
	</div>
</cfif>
<!---------------------------------------->

<cfif #action# is "nothing">
	<cfset title="Geology Attribute Hierarchy">
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
			start with parent_id is null
			CONNECT BY PRIOR geology_attribute_hierarchy_id = parent_id
			ORDER SIBLINGS BY ordinal
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
</cfif>
<!---------------------------------------------------->
<cfif #action# is "delete">
	<cfoutput>
		<cfquery name="killGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			delete from  geology_attribute_hierarchy where geology_attribute_hierarchy_id=#geology_attribute_hierarchy_id#
		</cfquery>
		<cflocation url="geol_hierarchy.cfm" addtoken="false">
	</cfoutput>
</cfif>

<!---------------------------------------------------->
<cfif #action# is "saveEdit">
	<cfoutput>

	<cfquery name="changeGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update geology_attribute_hierarchy set
		attribute='#attribute#',
		attribute_value='#attribute_value#',
		usable_value_fg=#usable_value_fg#,
		description='#description#'
		where
		geology_attribute_hierarchy_id=#geology_attribute_hierarchy_id#
	</cfquery>
	<cflocation url="geol_hierarchy.cfm" addtoken="false">
	</cfoutput>
</cfif>
<!---------------------------------------------------->
<cfif #action# is "newTerm">
	<cfoutput>

	<cfquery name="changeGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		insert into geology_attribute_hierarchy (attribute,attribute_value,usable_value_fg,description) 
		values
		 ('#attribute#','#attribute_value#',#usable_value_fg#,'#description#')
	</cfquery>
	<cflocation url="geol_hierarchy.cfm" addtoken="false">
	</cfoutput>
</cfif>
<!---------------------------------------------------->
<cfif #action# is "newReln">
	<cfoutput>
	<cfquery name="changeGeog" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		update geology_attribute_hierarchy set parent_id=<cfif parent is "">NULL<cfelse>#parent#</cfif> where geology_attribute_hierarchy_id=#child#
	</cfquery>
	<cflocation url="geol_hierarchy.cfm" addtoken="false">
	</cfoutput>
</cfif>
<cfinclude template="/includes/_footer.cfm">
