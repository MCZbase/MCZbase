<!---
dataentry/component/functions.cfc

Copyright 2026 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Backing methods for the Data Entry pages, role data_entry.
--->
<cfcomponent>

<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">

<!--- the values a Data Entry field setting may take --->
<cfset DATA_ENTRY_SETTING_HIDE = 0>
<cfset DATA_ENTRY_SETTING_SHOW = 1>
<cfset DATA_ENTRY_SETTING_CARRY = 2>
<!--- setPagePrefs in includes/DEAjax.js hides a field by hiding the element with id d_{field} on
	/DataEntry.cfm, so only fields with such a wrapper can be hidden.  COLLECTOR_AGENT_1, COLLECTOR_ROLE_1
	and OTHER_ID_NUM_TYPE_5 have wrappers but are needed to save a record.  Keep in step with
	/form/customizeDataEntry.cfm until that page is retired. --->
<cfset DATA_ENTRY_HIDEABLE_FIELDS = "COLLECTOR_AGENT_2,COLLECTOR_AGENT_3,COLLECTOR_AGENT_4,COLLECTOR_AGENT_5,COLLECTOR_AGENT_6,COLLECTOR_AGENT_7,COLLECTOR_AGENT_8,COLLECTOR_ROLE_2,COLLECTOR_ROLE_3,COLLECTOR_ROLE_4,COLLECTOR_ROLE_5,COLLECTOR_ROLE_6,COLLECTOR_ROLE_7,COLLECTOR_ROLE_8,OTHER_ID_NUM_1,OTHER_ID_NUM_2,OTHER_ID_NUM_3,OTHER_ID_NUM_4,IDENTIFICATION_REMARKS,HABITAT_DESC,ASSOCIATED_SPECIES,COLL_OBJECT_HABITAT,ORIG_ELEV_UNITS,DEPTH_UNITS,COLL_EVENT_REMARKS,LOCALITY_REMARKS,LOCALITY_ID,COLLECTING_EVENT_ID,ORIG_LAT_LONG_UNITS,LAT_LONG_REMARKS,GEOLOGY_ATTRIBUTE_1,GEOLOGY_ATTRIBUTE_2,GEOLOGY_ATTRIBUTE_3,GEOLOGY_ATTRIBUTE_4,GEOLOGY_ATTRIBUTE_5,GEOLOGY_ATTRIBUTE_6,RELATIONSHIP,COLL_OBJECT_REMARKS,FLAGS,PART_NAME_1,PART_NAME_2,PART_NAME_3,PART_NAME_4,PART_NAME_5,PART_NAME_6,PART_NAME_7,PART_NAME_8,PART_NAME_9,PART_NAME_10,PART_NAME_11,PART_NAME_12">

<!--- requireDataEntry throws unless the session has the data_entry role; remote calls are not covered
	by cf_form_permissions, so every method here calls it first. --->
<cffunction name="requireDataEntry" access="private" returntype="void">
	<cfif NOT (isdefined("session.roles") AND listfindnocase(session.roles,"data_entry"))>
		<cfthrow message="Not Authorized: data_entry role is required.">
	</cfif>
</cffunction>

<!--- getDataEntrySettingFields lists the fields that have a Data Entry setting: the columns of
	cf_dataentry_settings that are also columns of bulkloader, so a setting for a field the bulkloader
	no longer has is left out, and a setting column added later is offered without a code change.
	Read from the data dictionary with uam_god, as the account behind user_login owns neither table.
	@return a list of column names, upper case, in the settings table's column order.
--->
<cffunction name="getDataEntrySettingFields" access="private" returntype="string">
	<cfset var getSettingFields = "">
	<cfset var fields = "">
	<cfquery name="getSettingFields" datasource="uam_god" result="getSettingFields_result" cachedwithin="#createtimespan(0,1,0,0)#">
		SELECT s.column_name
		FROM sys.user_tab_cols s
		WHERE
			s.table_name = 'CF_DATAENTRY_SETTINGS'
			AND s.column_name <> 'USERNAME'
			AND s.column_name IN (
				SELECT b.column_name
				FROM sys.user_tab_cols b
				WHERE b.table_name = 'BULKLOADER'
			)
		ORDER BY s.internal_column_id
	</cfquery>
	<cfloop query="getSettingFields">
		<!--- the names become column identifiers in saveDataEntrySettings, so only plain identifiers --->
		<cfif REFind("^[A-Z][A-Z0-9_]*$",getSettingFields.column_name) GT 0>
			<cfset fields = listAppend(fields,getSettingFields.column_name)>
		</cfif>
	</cfloop>
	<cfreturn fields>
</cffunction>

<!--- getDataEntrySettingSections groups the setting fields for display.  A field goes in the first
	section whose pattern matches its name; the last section matches anything, so no field is left out.
	@return an array of structs with id, title and pattern.
--->
<cffunction name="getDataEntrySettingSections" access="private" returntype="array">
	<cfset var sections = arrayNew(1)>
	<cfset arrayAppend(sections, { id="catalogSettings", title="Cataloged Item Identifiers", pattern="^(CAT_NUM|ACCN|OTHER_ID_NUM_5|OTHER_ID_NUM_TYPE_5)$" })>
	<cfset arrayAppend(sections, { id="identificationSettings", title="Identification", pattern="^(TAXON_NAME|NATURE_OF_ID|ID_MADE_BY_AGENT|MADE_DATE|IDENTIFICATION_REMARKS)$" })>
	<cfset arrayAppend(sections, { id="collectorSettings", title="Collectors", pattern="^COLLECTOR_(AGENT|ROLE)_[0-9]+$" })>
	<cfset arrayAppend(sections, { id="identifierSettings", title="Other Identifiers", pattern="^OTHER_ID_NUM(_TYPE)?_[0-9]+$" })>
	<cfset arrayAppend(sections, { id="coordinateSettings", title="Coordinates", pattern="^(ORIG_LAT_LONG_UNITS|DEC_LAT|DEC_LONG|LATDEG|DEC_LAT_MIN|LATMIN|LATSEC|LATDIR|LONGDEG|DEC_LONG_MIN|LONGMIN|LONGSEC|LONGDIR|DATUM|LAT_LONG_REF_SOURCE|MAX_ERROR_DISTANCE|MAX_ERROR_UNITS|GEOREFMETHOD|DETERMINED_BY_AGENT|DETERMINED_DATE|LAT_LONG_REMARKS|VERIFICATIONSTATUS|UTM_ZONE|UTM_EW|UTM_NS|EXTENT|GPSACCURACY|VERBATIM(LATITUDE|LONGITUDE|COORDINATES|COORDINATESYSTEM|SRS))$" })>
	<cfset arrayAppend(sections, { id="localitySettings", title="Locality and Collecting Event", pattern="^(VERBATIM_DATE|BEGAN_DATE|ENDED_DATE|COLLECTING_TIME|STARTDAYOFYEAR|ENDDAYOFYEAR|HIGHER_GEOG|SPEC_LOCALITY|VERBATIM_LOCALITY|ORIG_ELEV_UNITS|MAXIMUM_ELEVATION|MINIMUM_ELEVATION|VERBATIMELEVATION|DEPTH_UNITS|MIN_DEPTH|MAX_DEPTH|VERBATIMDEPTH|LOCALITY_REMARKS|HABITAT_DESC|COLL_EVENT_REMARKS|COLLECTING_METHOD|COLLECTING_SOURCE|COLL_OBJECT_HABITAT|ASSOCIATED_SPECIES|LOCALITY_ID|COLLECTING_EVENT_ID|STATION_NAME|STATION_NUMBER|VESSEL)$" })>
	<cfset arrayAppend(sections, { id="geologySettings", title="Geology", pattern="^(GEOLOGY_ATTRIBUTE|GEO_ATT_[A-Z_]+)_[0-9]+$" })>
	<cfset arrayAppend(sections, { id="attributeSettings", title="Attributes", pattern="^ATTRIBUTE(_[A-Z_]+)?_[0-9]+$" })>
	<cfset arrayAppend(sections, { id="catalogedItemSettings", title="Cataloged Item", pattern="^(FLAGS|COLL_OBJ_DISPOSITION|CONDITION|COLL_OBJECT_REMARKS|DISPOSITION_REMARKS|RELATIONSHIP|RELATED_TO_NUMBER|RELATED_TO_NUM_TYPE|BIOL_INDIV_RELATION_REMARKS)$" })>
	<cfset arrayAppend(sections, { id="partSettings", title="Parts", pattern="^(PART_[A-Z0-9_]+|PRESERV_METHOD_[0-9]+)$" })>
	<cfset arrayAppend(sections, { id="otherSettings", title="Other Fields", pattern="." })>
	<cfreturn sections>
</cffunction>

<!--- getUserDataEntrySettings returns the current user's settings row, creating it with the column
	defaults (carry) if the user has none, as /DataEntry.cfm does on a first visit.
	@return a query with the user's one row of cf_dataentry_settings.
--->
<cffunction name="getUserDataEntrySettings" access="private" returntype="query">
	<cfset var getSettings = "">
	<cfset var addSettings = "">
	<cfquery name="getSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getSettings_result">
		SELECT *
		FROM cf_dataentry_settings
		WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
	</cfquery>
	<cfif getSettings.recordcount EQ 0>
		<cfquery name="addSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="addSettings_result">
			INSERT INTO cf_dataentry_settings (
				username
			) VALUES (
				<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			)
		</cfquery>
		<cfquery name="getSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="getSettings_result">
			SELECT *
			FROM cf_dataentry_settings
			WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
		</cfquery>
	</cfif>
	<cfreturn getSettings>
</cffunction>

<!--- getDataEntrySettingsFormHtml renders the form for the current user's Data Entry settings, one
	select per field, grouped in sections with buttons to set a whole section.
	@param feedbackId the id of the output element for save feedback.
	@return the html of the form.
	@see saveDataEntrySettings
--->
<cffunction name="getDataEntrySettingsFormHtml" access="public" returntype="string">
	<cfargument name="feedbackId" type="string" required="yes">

	<cfset var formHtml = "">
	<cfset var settings = "">
	<cfset var fields = "">
	<cfset var sections = "">
	<cfset var sectionFields = structNew()>
	<cfset var section = "">
	<cfset var field = "">
	<cfset var fieldId = "">
	<cfset var settingValue = "">
	<cfset var hideSelected = "">
	<cfset var showSelected = "">
	<cfset var carrySelected = "">
	<cfset var feedbackIdJs = encodeForHtmlAttribute(encodeForJavaScript(arguments.feedbackId))>

	<cfset requireDataEntry()>
	<cfset settings = getUserDataEntrySettings()>
	<cfset fields = getDataEntrySettingFields()>
	<cfset sections = getDataEntrySettingSections()>
	<cfloop array="#sections#" index="section">
		<cfset sectionFields[section.id] = "">
	</cfloop>
	<cfloop list="#fields#" index="field">
		<cfloop array="#sections#" index="section">
			<cfif REFind(section.pattern, field) GT 0>
				<cfset sectionFields[section.id] = listAppend(sectionFields[section.id], field)>
				<cfbreak>
			</cfif>
		</cfloop>
	</cfloop>
	<cfsavecontent variable="formHtml">
		<cfoutput>
			<nav aria-label="Sections of the settings">
				<ul class="list-inline mb-2">
					<cfloop array="#sections#" index="section">
						<cfif listLen(sectionFields[section.id]) GT 0>
							<li class="list-inline-item"><a href="###section.id#">#encodeForHtml(section.title)#</a></li>
						</cfif>
					</cfloop>
				</ul>
			</nav>
			<div class="mb-2">
				<button type="button" class="btn btn-xs btn-secondary" onClick="setDataEntrySettings('dataEntrySettingsForm',#DATA_ENTRY_SETTING_HIDE#,'#feedbackIdJs#');">Hide all fields</button>
				<button type="button" class="btn btn-xs btn-secondary" onClick="setDataEntrySettings('dataEntrySettingsForm',#DATA_ENTRY_SETTING_SHOW#,'#feedbackIdJs#');">Show all fields</button>
				<button type="button" class="btn btn-xs btn-secondary" onClick="setDataEntrySettings('dataEntrySettingsForm',#DATA_ENTRY_SETTING_CARRY#,'#feedbackIdJs#');">Carry all fields</button>
			</div>
			<form id="dataEntrySettingsForm" onSubmit="return false;">
				<cfloop array="#sections#" index="section">
					<cfif listLen(sectionFields[section.id]) GT 0>
						<section id="#section.id#" class="border rounded px-2 pb-2 mb-2">
							<h2 class="h3 mt-2" id="#section.id#Heading">#encodeForHtml(section.title)#</h2>
							<div class="mb-1">
								<button type="button" class="btn btn-xs btn-secondary" onClick="setDataEntrySettings('#section.id#',#DATA_ENTRY_SETTING_HIDE#,'#feedbackIdJs#');">Hide all<span class="sr-only"> #encodeForHtml(section.title)# fields</span></button>
								<button type="button" class="btn btn-xs btn-secondary" onClick="setDataEntrySettings('#section.id#',#DATA_ENTRY_SETTING_SHOW#,'#feedbackIdJs#');">Show all<span class="sr-only"> #encodeForHtml(section.title)# fields</span></button>
								<button type="button" class="btn btn-xs btn-secondary" onClick="setDataEntrySettings('#section.id#',#DATA_ENTRY_SETTING_CARRY#,'#feedbackIdJs#');">Carry all<span class="sr-only"> #encodeForHtml(section.title)# fields</span></button>
							</div>
							<div class="form-row">
								<cfloop list="#sectionFields[section.id]#" index="field">
									<cfset fieldId = lcase(field)>
									<cfset settingValue = settings[field][1]>
									<cfset hideSelected = "">
									<cfset showSelected = "">
									<cfset carrySelected = "">
									<cfif settingValue EQ DATA_ENTRY_SETTING_HIDE AND listFindNoCase(DATA_ENTRY_HIDEABLE_FIELDS, field) GT 0>
										<cfset hideSelected = "selected">
									<cfelseif settingValue EQ DATA_ENTRY_SETTING_CARRY>
										<cfset carrySelected = "selected">
									<cfelse>
										<!--- show, and a stored hide for a field that cannot be hidden, which Data Entry treats as show --->
										<cfset showSelected = "selected">
									</cfif>
									<div class="col-12 col-sm-6 col-md-4 col-xl-3 mb-1">
										<label for="#fieldId#" class="data-entry-label">#encodeForHtml(replace(fieldId,"_"," ","all"))#</label>
										<select id="#fieldId#" name="#fieldId#" class="data-entry-select" onChange="setFeedbackControlState('#feedbackIdJs#','unsaved');">
											<cfif listFindNoCase(DATA_ENTRY_HIDEABLE_FIELDS, field) GT 0>
												<option value="#DATA_ENTRY_SETTING_HIDE#" #hideSelected#>hide</option>
											</cfif>
											<option value="#DATA_ENTRY_SETTING_SHOW#" #showSelected#>show</option>
											<option value="#DATA_ENTRY_SETTING_CARRY#" #carrySelected#>carry</option>
										</select>
									</div>
								</cfloop>
							</div>
						</section>
					</cfif>
				</cfloop>
			</form>
		</cfoutput>
	</cfsavecontent>
	<cfreturn formHtml>
</cffunction>

<!--- saveDataEntrySettings saves the current user's Data Entry field settings.  Fields not in the
	settings are left as they are; a hide for a field Data Entry cannot hide is saved as show.
	@param settings a JSON object of field name to setting value, 0 hide, 1 show, 2 carry.
	@return a struct with status saved and the count of fields saved, or an http 500 response.
--->
<cffunction name="saveDataEntrySettings" access="remote" returntype="any" returnformat="json">
	<cfargument name="settings" type="string" required="yes">

	<cfset var result = structNew()>
	<cfset var posted = "">
	<cfset var fields = "">
	<cfset var toSave = structNew()>
	<cfset var key = "">
	<cfset var field = "">
	<cfset var settingValue = "">
	<cfset var separator = "">
	<cfset var updateSettings = "">

	<cfset requireDataEntry()>
	<cftry>
		<cfif NOT isJSON(arguments.settings)>
			<cfthrow message="Settings must be a JSON object.">
		</cfif>
		<cfset posted = deserializeJSON(arguments.settings)>
		<cfif NOT isStruct(posted)>
			<cfthrow message="Settings must be a JSON object.">
		</cfif>
		<cfset fields = getDataEntrySettingFields()>
		<cfloop collection="#posted#" item="key">
			<cfset field = ucase(key)>
			<cfif listFind(fields, field) EQ 0>
				<cfthrow message="Not a Data Entry setting: #encodeForHtml(key)#">
			</cfif>
			<cfset settingValue = posted[key]>
			<cfif NOT listFind("#DATA_ENTRY_SETTING_HIDE#,#DATA_ENTRY_SETTING_SHOW#,#DATA_ENTRY_SETTING_CARRY#", settingValue)>
				<cfthrow message="Not a Data Entry setting value for #encodeForHtml(key)#.">
			</cfif>
			<cfif settingValue EQ DATA_ENTRY_SETTING_HIDE AND listFindNoCase(DATA_ENTRY_HIDEABLE_FIELDS, field) EQ 0>
				<cfset settingValue = DATA_ENTRY_SETTING_SHOW>
			</cfif>
			<cfset toSave[field] = settingValue>
		</cfloop>
		<cfif structCount(toSave) GT 0>
			<!--- ensure the row exists before updating it --->
			<cfset getUserDataEntrySettings()>
			<!--- a column name cannot be bound; each one was checked against the data dictionary above --->
			<cfquery name="updateSettings" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="updateSettings_result">
				UPDATE cf_dataentry_settings
				SET
					<cfloop collection="#toSave#" item="field">
						#separator##field# = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#toSave[field]#">
						<cfset separator = ",">
					</cfloop>
				WHERE username = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#session.username#">
			</cfquery>
			<cfif updateSettings_result.recordcount NEQ 1>
				<cfthrow message="Data Entry settings not saved.">
			</cfif>
		</cfif>
		<cfset result["status"] = "saved">
		<cfset result["count"] = structCount(toSave)>
	<cfcatch>
		<cfset error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset function_called = "#GetFunctionCalledName()#">
		<cfscript> reportError(function_called="#function_called#",error_message="#error_message#");</cfscript>
		<cfabort>
	</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>

</cfcomponent>
