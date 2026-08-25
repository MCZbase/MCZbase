<!---
containers/component/functions.cfc
Functions supporting the use of containers.

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

--->
<cfcomponent>
<cf_rolecheck>
<cfinclude template="/shared/component/error_handler.cfc" runOnce="true">
<cfinclude template="/containers/component/public.cfc" runOnce="true"><!--- for validateContainerPlacement, validateContainerRetype, moveContainerById --->

<!---
Function getContainerForEdit.  Returns all editable fields for a single container record,
plus the parent container's label and barcode for pre-populating the parent picker.
Used to populate the Container.cfm edit form via AJAX or direct CFC call.

@param container_id the container_id to load.
@return a JSON object with all container fields plus parent_label and parent_barcode.
--->
<cffunction name="getContainerForEdit" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_id" type="numeric" required="yes">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfquery name="queryGetContainer" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT
				c.container_id,
				c.parent_container_id,
				c.container_type,
				c.label,
				c.description,
				c.parent_install_date,
				c.container_remarks,
				c.barcode,
				c.print_fg,
				c.width,
				c.height,
				c.length,
				c.number_positions,
				c.locked_position,
				c.institution_acronym,
				p.label AS parent_label,
				p.barcode AS parent_barcode
			FROM
				container c
				LEFT JOIN container p ON c.parent_container_id = p.container_id
			WHERE
				c.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
		</cfquery>
		<cfif queryGetContainer.recordcount EQ 0>
			<cfset local.retval["container_id"] = "">
			<cfset local.retval["error"] = "Container not found.">
		<cfelse>
			<cfset local.retval["container_id"] = queryGetContainer.container_id>
			<cfset local.retval["parent_container_id"] = queryGetContainer.parent_container_id>
			<cfset local.retval["container_type"] = queryGetContainer.container_type>
			<cfset local.retval["label"] = queryGetContainer.label>
			<cfset local.retval["description"] = queryGetContainer.description>
			<cfif isDate(queryGetContainer.parent_install_date)>
				<cfset local.retval["parent_install_date"] = dateFormat(queryGetContainer.parent_install_date, "yyyy-mm-dd")>
			<cfelse>
				<cfset local.retval["parent_install_date"] = "">
			</cfif>
			<cfset local.retval["container_remarks"] = queryGetContainer.container_remarks>
			<cfset local.retval["barcode"] = queryGetContainer.barcode>
			<cfset local.retval["print_fg"] = queryGetContainer.print_fg>
			<cfset local.retval["width"] = queryGetContainer.width>
			<cfset local.retval["height"] = queryGetContainer.height>
			<cfset local.retval["length"] = queryGetContainer.length>
			<cfset local.retval["number_positions"] = queryGetContainer.number_positions>
			<cfset local.retval["locked_position"] = queryGetContainer.locked_position>
			<cfset local.retval["institution_acronym"] = queryGetContainer.institution_acronym>
			<cfset local.retval["parent_label"] = queryGetContainer.parent_label>
			<cfset local.retval["parent_barcode"] = queryGetContainer.parent_barcode>
		</cfif>
	<cfcatch>
		<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
		<cfset local.function_called = "#GetFunctionCalledName()#">
		<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
		<cfset local.retval = StructNew()>
		<cfset local.retval["container_id"] = "">
		<cfset local.retval["error"] = cfcatch.message>
	</cfcatch>
	</cftry>
	<cfreturn serializeJSON(local.retval)>
</cffunction>

<!---
Function createContainer.  Creates a new container record.

@return JSON object with status and container_id on success.
--->
<cffunction name="createContainer" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_type" type="string" required="yes">
	<cfargument name="label" type="string" required="yes">
	<cfargument name="parent_container_id" type="string" required="yes">
	<cfargument name="barcode" type="string" required="no" default="">
	<cfargument name="description" type="string" required="no" default="">
	<cfargument name="parent_install_date" type="string" required="no" default="">
	<cfargument name="container_remarks" type="string" required="no" default="">
	<cfargument name="width" type="string" required="no" default="">
	<cfargument name="height" type="string" required="no" default="">
	<cfargument name="length" type="string" required="no" default="">
	<cfargument name="number_positions" type="string" required="no" default="">
	<cfargument name="institution_acronym" type="string" required="no" default="MCZ">

	<cfset local.retval = StructNew()>
	<cfif len(trim(arguments.container_type)) EQ 0 OR len(trim(arguments.label)) EQ 0 OR len(trim(arguments.parent_container_id)) EQ 0>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Container type, label, and parent container are required.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif NOT isNumeric(arguments.parent_container_id)>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Parent container must be numeric.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif len(trim(arguments.parent_install_date)) GT 0 AND NOT isDate(arguments.parent_install_date)>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Placement date must be a valid date in yyyy-mm-dd format.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif (len(trim(arguments.width)) GT 0 AND NOT isNumeric(arguments.width))
			OR (len(trim(arguments.height)) GT 0 AND NOT isNumeric(arguments.height))
			OR (len(trim(arguments.length)) GT 0 AND NOT isNumeric(arguments.length))
			OR (len(trim(arguments.number_positions)) GT 0 AND NOT isNumeric(arguments.number_positions))>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Width, height, length, and number of positions must be numeric when provided.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif len(trim(arguments.institution_acronym)) EQ 0>
		<cfset arguments.institution_acronym = "MCZ">
	</cfif>

	<cftransaction>
		<cftry>
			<cfquery name="queryNextId" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT
					sq_container_id.nextval AS next_container_id
				FROM
					dual
			</cfquery>
			<cfquery name="queryInsertContainer" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				INSERT INTO container (
					container_id,
					parent_container_id,
					container_type,
					label,
					description,
					parent_install_date,
					container_remarks,
					barcode,
					width,
					height,
					length,
					number_positions,
					locked_position,
					institution_acronym
				) VALUES (
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#queryNextId.next_container_id#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.parent_container_id#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.container_type)#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.label)#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.description)#" null="#len(trim(arguments.description)) EQ 0#">,
					<cfif len(trim(arguments.parent_install_date)) GT 0>
						<cfqueryparam cfsqltype="CF_SQL_DATE" value="#createODBCDate(parseDateTime(arguments.parent_install_date))#">
					<cfelse>
						<cfqueryparam cfsqltype="CF_SQL_DATE" value="" null="yes">
					</cfif>,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.container_remarks)#" null="#len(trim(arguments.container_remarks)) EQ 0#">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.barcode)#" null="#len(trim(arguments.barcode)) EQ 0#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="4" value="#trim(arguments.width)#" null="#len(trim(arguments.width)) EQ 0#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="4" value="#trim(arguments.height)#" null="#len(trim(arguments.height)) EQ 0#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="4" value="#trim(arguments.length)#" null="#len(trim(arguments.length)) EQ 0#">,
					<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.number_positions)#" null="#len(trim(arguments.number_positions)) EQ 0#">,
					<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="0">,
					<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.institution_acronym)#">
				)
			</cfquery>
			<cfset local.retval["status"] = "created">
			<cfset local.retval["container_id"] = queryNextId.next_container_id>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset local.function_called = "#GetFunctionCalledName()#">
			<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
			<cfset local.retval = StructNew()>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = cfcatch.message>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJSON(local.retval)>
</cffunction>

<!---
Function saveContainer.  Updates an existing container record.
--->
<cffunction name="saveContainer" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_id" type="string" required="yes">
	<cfargument name="container_type" type="string" required="yes">
	<cfargument name="label" type="string" required="yes">
	<cfargument name="parent_container_id" type="string" required="yes">
	<cfargument name="barcode" type="string" required="no" default="">
	<cfargument name="description" type="string" required="no" default="">
	<cfargument name="parent_install_date" type="string" required="no" default="">
	<cfargument name="container_remarks" type="string" required="no" default="">
	<cfargument name="width" type="string" required="no" default="">
	<cfargument name="height" type="string" required="no" default="">
	<cfargument name="length" type="string" required="no" default="">
	<cfargument name="number_positions" type="string" required="no" default="">
	<cfargument name="institution_acronym" type="string" required="no" default="MCZ">

	<cfset local.retval = StructNew()>
	<cfif len(trim(arguments.container_id)) EQ 0 OR NOT isNumeric(arguments.container_id)>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Container id is required.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif len(trim(arguments.container_type)) EQ 0 OR len(trim(arguments.label)) EQ 0 OR len(trim(arguments.parent_container_id)) EQ 0>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Container type, label, and parent container are required.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif NOT isNumeric(arguments.parent_container_id)>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Parent container must be numeric.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif len(trim(arguments.parent_install_date)) GT 0 AND NOT isDate(arguments.parent_install_date)>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Placement date must be a valid date in yyyy-mm-dd format.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif (len(trim(arguments.width)) GT 0 AND NOT isNumeric(arguments.width))
			OR (len(trim(arguments.height)) GT 0 AND NOT isNumeric(arguments.height))
			OR (len(trim(arguments.length)) GT 0 AND NOT isNumeric(arguments.length))
			OR (len(trim(arguments.number_positions)) GT 0 AND NOT isNumeric(arguments.number_positions))>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Width, height, length, and number of positions must be numeric when provided.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif len(trim(arguments.institution_acronym)) EQ 0>
		<cfset arguments.institution_acronym = "MCZ">
	</cfif>

	<cftransaction>
		<cftry>
			<cfquery name="queryGetExisting" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT
					parent_container_id,
					container_type,
					number_positions
				FROM
					container
				WHERE
					container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
			</cfquery>
			<cfif queryGetExisting.recordcount EQ 0>
				<cfset local.retval["status"] = "error">
				<cfset local.retval["message"] = "Container not found.">
				<cfreturn serializeJSON(local.retval)>
			</cfif>
			<!--- lock type institution, external, and "Deaccesioned" root containers from some edits --->
			<cfset lockedRoot = false>
			<cfif arguments.container_type EQ "institution">
				<cfset lockedRoot = true>
			<cfelseif arguments.container_type EQ "external">
				<cfset lockedRoot = true>
			<cfelseif arguments.label EQ "Deaccessioned"><!--- deprecated special case, rule is now based on container_type of external for deaccessioned --->
				<cfset lockedRoot = true>
			</cfif>

			<!--- Validate an actual container_type change against this container's current parent and
				children -- bulkModifyContainers.cfm's dedicated bulk-retype tool already runs every
				retype through validateContainerRetype's ten rules (parent/child role conflicts,
				expected-parent-type, rank order), but this single-container edit path never has,
				which meant Container.cfm's own edit form could retype a container into something
				its existing children (including position sub-containers) don't fit at all, with no
				warning. Only runs when the type is actually changing -- otherwise an edit to an
				unrelated field (a remark, a dimension) on a container whose pre-existing type/parent/
				children combo predates these rules and wouldn't itself pass them today would get
				blocked for a change that was never being requested. A "block" severity refuses the
				save outright, matching this function's existing error-response shape; a "warn"
				severity is returned to the caller rather than silently dropped, though Container.cfm's
				save flow doesn't yet have anywhere to show a warning that doesn't block the save --
				see Redmine #817 phase 5 notes. --->
			<cfif NOT lockedRoot AND trim(arguments.container_type) NEQ queryGetExisting.container_type>
				<cfset local.retypeCheck = validateContainerRetype(container_id=arguments.container_id, new_container_type=trim(arguments.container_type))>
				<cfif isSimpleValue(local.retypeCheck)>
					<cfset local.retypeCheck = deserializeJSON(local.retypeCheck)>
				</cfif>
				<cfif local.retypeCheck.severity EQ "block">
					<cfset local.retval["status"] = "error">
					<cfset local.retval["message"] = "Cannot change Container Type to #trim(arguments.container_type)# -- #ArrayToList(local.retypeCheck.blocks, ' ')#">
					<cfreturn serializeJSON(local.retval)>
				<cfelseif local.retypeCheck.severity EQ "warn">
					<cfset local.retval["warnings"] = local.retypeCheck.warnings>
				</cfif>
			</cfif>

			<!--- Guard against shrinking number_positions below existing position sub-containers --
				the MOVE_CONTAINER trigger only validates a container's placement when its OWN
				parent_container_id changes, so nothing in the database stops number_positions from
				being edited down below either occupied or merely-existing position records; the
				positions grid isn't filtered by number_positions at all (it shows every actual
				container_type='position' child regardless), so shrinking this silently leaves the
				box's declared capacity out of sync with its real position records. Only runs when
				the new value is actually lower than what's stored -- otherwise resubmitting an
				unchanged (or increased) value on an unrelated edit to a container whose position
				records already predate this guard would get blocked for a reduction that was never
				being requested. --->
			<cfset local.existingNumberPositions = val(queryGetExisting.number_positions)>
			<cfset local.newNumberPositionsValue = 0>
			<cfif len(trim(arguments.number_positions)) GT 0>
				<cfset local.newNumberPositionsValue = val(arguments.number_positions)>
			</cfif>
			<cfif NOT lockedRoot AND local.newNumberPositionsValue LT local.existingNumberPositions>
				<cfquery name="queryPositionsBeyondNewCount" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
					SELECT
						pos.label,
						(SELECT COUNT(*) FROM container occ WHERE occ.parent_container_id = pos.container_id) AS occupant_count
					FROM container pos
					WHERE pos.parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
						AND pos.container_type = 'position'
						AND REGEXP_LIKE(pos.label, '^[0-9]+$')
						AND TO_NUMBER(pos.label) > <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.newNumberPositionsValue#">
				</cfquery>
				<cfif queryPositionsBeyondNewCount.recordcount GT 0>
					<cfset local.occupiedBeyondCount = 0>
					<cfloop query="queryPositionsBeyondNewCount">
						<cfif val(queryPositionsBeyondNewCount.occupant_count) GT 0>
							<cfset local.occupiedBeyondCount = local.occupiedBeyondCount + 1>
						</cfif>
					</cfloop>
					<cfset local.retval["status"] = "error">
					<cfif local.occupiedBeyondCount GT 0>
						<cfset local.retval["message"] = "Cannot reduce Number of Positions to #local.newNumberPositionsValue# -- #local.occupiedBeyondCount# of the #queryPositionsBeyondNewCount.recordcount# position(s) beyond that count currently hold something. Move or remove their contents first.">
					<cfelse>
						<cfset local.retval["message"] = "Cannot reduce Number of Positions to #local.newNumberPositionsValue# -- #queryPositionsBeyondNewCount.recordcount# position record(s) beyond that count already exist (though currently empty). Number of Positions must stay at or above the highest existing position.">
					</cfif>
					<cfreturn serializeJSON(local.retval)>
				</cfif>
			</cfif>

			<cfquery name="queryUpdateContainer" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				UPDATE
					container
				SET
					<cfif NOT lockedRoot>
						parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.parent_container_id#">,
						container_type = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.container_type)#">,
						label = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.label)#">,
						number_positions = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#trim(arguments.number_positions)#" null="#len(trim(arguments.number_positions)) EQ 0#">,
						barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.barcode)#" null="#len(trim(arguments.barcode)) EQ 0#">,
					</cfif>
					description = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.description)#" null="#len(trim(arguments.description)) EQ 0#">,
					parent_install_date =
						<cfif len(trim(arguments.parent_install_date)) GT 0>
							<cfqueryparam cfsqltype="CF_SQL_DATE" value="#createODBCDate(parseDateTime(arguments.parent_install_date))#">
						<cfelse>
							<cfqueryparam cfsqltype="CF_SQL_DATE" value="" null="yes">
						</cfif>,
					container_remarks = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.container_remarks)#" null="#len(trim(arguments.container_remarks)) EQ 0#">,
					width = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="4" value="#trim(arguments.width)#" null="#len(trim(arguments.width)) EQ 0#">,
					height = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="4" value="#trim(arguments.height)#" null="#len(trim(arguments.height)) EQ 0#">,
					length = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="4" value="#trim(arguments.length)#" null="#len(trim(arguments.length)) EQ 0#">,
					institution_acronym = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.institution_acronym)#">
				WHERE
					container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
			</cfquery>
			<!--- provided by trigger MCZBASE.GET_CONTAINER_HISTORY --->
			<!---
			<cfif val(queryGetExisting.parent_container_id) NEQ val(arguments.parent_container_id)>
				<cfquery name="queryInsertHistory" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
					INSERT INTO container_history (
						container_id,
						parent_container_id,
						install_date
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#queryGetExisting.parent_container_id#">,
						SYSDATE
					)
				</cfquery>
			</cfif>
			--->
			<cfset local.retval["status"] = "saved">
			<cfset local.retval["container_id"] = arguments.container_id>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset local.function_called = "#GetFunctionCalledName()#">
			<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
			<cfset local.retval = StructNew()>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = cfcatch.message>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJSON(local.retval)>
</cffunction>

<!---
Function createContainerPositions. Bulk-creates the position sub-containers for a container
whose number_positions/container_type is one of a handful of known box/rack presets with
established physical dimensions (matching the retired containerPositions.cfm's "Create all
new positions" action, and the same 5 presets containers.js's positions-grid layout already
special-cases: 25/81/100-position freezer boxes, 33/48-position freezers). Refuses for any
other type/count combination, since there's no known physical dimension to give the created
positions -- and refuses if the container already has any children at all, since positions
can only be bulk-created once, before anything has been placed in the box (this also means
there is currently no way to add more positions to a container that already has some; see
Redmine #817 phase 5 notes). Each position is labeled with the bare position number, and given
a barcode built from the parent's own barcode plus an underscore plus that number when the
parent has one.
@param container_id the empty box/rack to populate with position sub-containers.
@return a JSON object: {status: "created"|"exists"|"unsupported"|"error", message, count}.
--->
<cffunction name="createContainerPositions" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_id" type="numeric" required="yes">

	<cfset local.retval = StructNew()>
	<cfquery name="local.queryContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT container_type, number_positions, institution_acronym, barcode
		FROM container
		WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
	</cfquery>
	<cfif local.queryContainer.recordcount EQ 0>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Container was not found.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>

	<cfset local.numberPositions = val(local.queryContainer.number_positions)>
	<cfset local.containerType = local.queryContainer.container_type>
	<cfset local.positionType = "">
	<cfset local.positionWidth = 0>
	<cfset local.positionHeight = 0>
	<cfset local.positionLength = 0>
	<!--- known (number_positions, container_type) presets and their position slots' physical
		dimensions -- the same boundary containers.js's layoutClassMap already assumes for grid
		display, and the exact set the legacy containerPositions.cfm supported --->
	<cfif local.numberPositions EQ 100 AND local.containerType EQ "freezer box">
		<cfset local.positionType = "position"><cfset local.positionWidth = 1.2><cfset local.positionLength = 1.2><cfset local.positionHeight = 4.9>
	<cfelseif local.numberPositions EQ 81 AND local.containerType EQ "freezer box">
		<cfset local.positionType = "position"><cfset local.positionWidth = 1.2><cfset local.positionLength = 1.2><cfset local.positionHeight = 4.9>
	<cfelseif local.numberPositions EQ 25 AND local.containerType EQ "freezer box">
		<cfset local.positionType = "position"><cfset local.positionWidth = 1.2><cfset local.positionLength = 1.2><cfset local.positionHeight = 4.9>
	<cfelseif local.numberPositions EQ 48 AND local.containerType EQ "freezer">
		<cfset local.positionType = "position"><cfset local.positionWidth = 14><cfset local.positionLength = 14><cfset local.positionHeight = 80>
	<cfelseif local.numberPositions EQ 33 AND local.containerType EQ "freezer">
		<cfset local.positionType = "position"><cfset local.positionWidth = 14><cfset local.positionLength = 14><cfset local.positionHeight = 80>
	</cfif>
	<cfif len(local.positionType) EQ 0>
		<cfset local.retval["status"] = "unsupported">
		<cfset local.retval["message"] = "Don't know the physical dimensions for #local.numberPositions# positions in a '#local.containerType#' -- positions can only be auto-created for known box/rack types. Submit a bug report to request an additional type.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>

	<cfquery name="local.queryExistingChildren" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT COUNT(*) AS c
		FROM container
		WHERE parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
	</cfquery>
	<cfif local.queryExistingChildren.c GT 0>
		<cfset local.retval["status"] = "exists">
		<cfset local.retval["message"] = "This container already has #local.queryExistingChildren.c# item(s) in it -- positions can only be auto-created for a container that's still completely empty.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>

	<cfset local.institutionAcronym = trim(local.queryContainer.institution_acronym)>
	<cfif len(local.institutionAcronym) EQ 0>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "This container has no institution acronym set -- can't create positions.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>

	<!--- when the parent has its own barcode, give each position a barcode built from it, so a
		position's barcode alone identifies which container it belongs to -- left blank (no
		barcode at all) for a parent with no barcode of its own. The label stays the bare
		position number either way. --->
	<cfset local.positionBarcodePrefix = "">
	<cfif len(trim(local.queryContainer.barcode)) GT 0>
		<cfset local.positionBarcodePrefix = "#trim(local.queryContainer.barcode)#_">
	</cfif>

	<cftransaction>
		<cftry>
			<cfloop from="1" to="#local.numberPositions#" index="local.i">
				<cfquery name="local.queryNextId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
					SELECT sq_container_id.nextval AS next_container_id FROM dual
				</cfquery>
				<cfquery name="local.queryInsertPosition" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
					INSERT INTO container (
						container_id,
						parent_container_id,
						container_type,
						label,
						barcode,
						parent_install_date,
						width,
						height,
						length,
						number_positions,
						locked_position,
						institution_acronym
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.queryNextId.next_container_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.positionType#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.i#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.positionBarcodePrefix##local.i#" null="#len(local.positionBarcodePrefix) EQ 0#">,
						sysdate,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="4" value="#local.positionWidth#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="4" value="#local.positionHeight#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" scale="4" value="#local.positionLength#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="1">,
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="1">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.institutionAcronym#">
					)
				</cfquery>
			</cfloop>
			<cfset local.retval["status"] = "created">
			<cfset local.retval["count"] = local.numberPositions>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset local.function_called = "#GetFunctionCalledName()#">
			<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
			<cfset local.retval = StructNew()>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = local.error_message>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJSON(local.retval)>
</cffunction>

<!---
Function createContainerSeries.  Bulk-creates a numbered series of container records sharing one
parent and container_type, for pre-printing or reserving a run of barcode labels (ported from the
retired /CreateContainersForBarcodes.cfm). Two label-building modes: the normal case builds
barcode = prefix & n & suffix and label = label_prefix & n & label_suffix (falling back to
prefix/suffix when label_prefix/label_suffix are blank), preserving a leading-zero width from
begin_barcode across the whole run; the "PLACE" cryo-barcode special case instead builds both
barcode and label as {4-digit n}PLACE{4-digit n}, ignoring every prefix/suffix argument. Capped at
1000 containers per call to keep one request/transaction from running away.
@return a JSON object: {status: "created"|"error", count, first_barcode, last_barcode,
	parent_container_id, parent_label, parent_barcode, message}.
--->
<cffunction name="createContainerSeries" access="remote" returntype="any" returnformat="json">
	<cfargument name="parent_container_id" type="string" required="no" default="">
	<cfargument name="container_type" type="string" required="yes">
	<cfargument name="institution_acronym" type="string" required="no" default="MCZ">
	<cfargument name="cryo_barcode" type="boolean" required="no" default="false">
	<cfargument name="prefix" type="string" required="no" default="">
	<cfargument name="suffix" type="string" required="no" default="">
	<cfargument name="label_prefix" type="string" required="no" default="">
	<cfargument name="label_suffix" type="string" required="no" default="">
	<cfargument name="remarks" type="string" required="no" default="">
	<cfargument name="begin_barcode" type="string" required="yes">
	<cfargument name="end_barcode" type="string" required="yes">

	<cfset local.retval = StructNew()>
	<cfif len(trim(arguments.container_type)) EQ 0>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Container type is required.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif len(trim(arguments.parent_container_id)) GT 0 AND NOT isNumeric(arguments.parent_container_id)>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Parent container must be numeric.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif NOT isNumeric(arguments.begin_barcode) OR NOT isNumeric(arguments.end_barcode)>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Low and High number in series must both be numbers.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfset local.parentContainerId = 1>
	<cfif len(trim(arguments.parent_container_id)) GT 0>
		<cfset local.parentContainerId = arguments.parent_container_id>
	</cfif>
	<cfset local.count = val(arguments.end_barcode) - val(arguments.begin_barcode) + 1>
	<cfif local.count LT 1>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "High number in series must not be less than the low number.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>
	<cfif local.count GT 1000>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "This series would create #local.count# containers -- split it into batches of 1000 or fewer.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>

	<cfquery name="local.queryParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT label, barcode
		FROM container
		WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.parentContainerId#">
	</cfquery>
	<cfif local.queryParent.recordcount EQ 0>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Parent container was not found.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>

	<!--- preserve begin_barcode's leading-zero width (e.g. "007") across the whole run, matching
		the retired CreateContainersForBarcodes.cfm --->
	<cfset local.numberMask = "">
	<cfif left(arguments.begin_barcode,1) EQ "0">
		<cfset local.numberMask = RepeatString("0",len(arguments.begin_barcode))>
	</cfif>
	<cfset local.labelPrefix = arguments.label_prefix>
	<cfif len(local.labelPrefix) EQ 0 AND len(arguments.prefix) GT 0>
		<cfset local.labelPrefix = arguments.prefix>
	</cfif>
	<cfset local.labelSuffix = arguments.label_suffix>
	<cfif len(local.labelSuffix) EQ 0 AND len(arguments.suffix) GT 0>
		<cfset local.labelSuffix = arguments.suffix>
	</cfif>

	<cfset local.firstBarcode = "">
	<cfset local.lastBarcode = "">
	<cftransaction>
		<cftry>
			<cfset local.n = val(arguments.begin_barcode)>
			<cfloop from="1" to="#local.count#" index="local.i">
				<cfset local.displayNumber = local.n>
				<cfif len(local.numberMask) GT 0>
					<cfset local.displayNumber = NumberFormat(local.n, local.numberMask)>
				</cfif>
				<cfif arguments.cryo_barcode>
					<cfset local.barcode = left(numberFormat(local.n,00000000),4) & "PLACE" & right(numberFormat(local.n,00000000),4)>
					<cfset local.label = local.barcode>
				<cfelse>
					<cfset local.barcode = arguments.prefix & local.displayNumber & arguments.suffix>
					<cfset local.label = local.labelPrefix & local.displayNumber & local.labelSuffix>
				</cfif>
				<cfif local.i EQ 1>
					<cfset local.firstBarcode = local.barcode>
				</cfif>
				<cfset local.lastBarcode = local.barcode>

				<cfquery name="local.queryNextId" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
					SELECT sq_container_id.nextval AS next_container_id FROM dual
				</cfquery>
				<cfquery name="local.queryInsertContainer" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
					INSERT INTO container (
						container_id,
						parent_container_id,
						container_type,
						barcode,
						label,
						container_remarks,
						locked_position,
						institution_acronym
					) VALUES (
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.queryNextId.next_container_id#">,
						<cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#local.parentContainerId#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.container_type#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.barcode#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.label#">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.remarks#" null="#len(arguments.remarks) EQ 0#">,
						<cfqueryparam cfsqltype="CF_SQL_INTEGER" value="0">,
						<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.institution_acronym#">
					)
				</cfquery>
				<cfset local.n = local.n + 1>
			</cfloop>
			<cfset local.retval["status"] = "created">
			<cfset local.retval["count"] = local.count>
			<cfset local.retval["first_barcode"] = local.firstBarcode>
			<cfset local.retval["last_barcode"] = local.lastBarcode>
			<cfset local.retval["parent_container_id"] = local.parentContainerId>
			<cfset local.retval["parent_label"] = local.queryParent.label>
			<cfset local.retval["parent_barcode"] = local.queryParent.barcode>
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset local.function_called = "#GetFunctionCalledName()#">
			<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
			<cfset local.clientMessage = cfcatch.message>
			<cfif structKeyExists(cfcatch,"Cause") AND structKeyExists(cfcatch.cause,"Message")
					AND Find("ORA-00001: unique constraint (MCZBASE.U_BARCODE) violated",cfcatch.cause.message) GT 0>
				<cfset local.clientMessage = "One or more of the identifiers/barcodes you're trying to create already exists (first failure at number #local.displayNumber#, identifier '#local.barcode#').">
			</cfif>
			<cfset local.retval = StructNew()>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = local.clientMessage>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJSON(local.retval)>
</cffunction>

<!---
Function deleteContainer.  Deletes a container record.
--->
<cffunction name="deleteContainer" access="remote" returntype="any" returnformat="json">
	<cfargument name="container_id" type="string" required="yes">

	<cfset local.retval = StructNew()>
	<cfif len(trim(arguments.container_id)) EQ 0 OR NOT isNumeric(arguments.container_id)>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = "Container id is required.">
		<cfreturn serializeJSON(local.retval)>
	</cfif>

	<cftransaction>
		<cftry>
			<cfquery name="queryCheckChildren" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				SELECT
					COUNT(*) AS child_count
				FROM
					container
				WHERE
					parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
			</cfquery>
			<cfif queryCheckChildren.child_count GT 0>
				<cfset local.retval["status"] = "error">
				<cfset local.retval["message"] = "Container cannot be deleted because it has children.">
				<cfreturn serializeJSON(local.retval)>
			</cfif>
			<cfquery name="queryDeleteContainer" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
				DELETE FROM
					container
				WHERE
					container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#arguments.container_id#">
			</cfquery>
			<cfset local.retval["status"] = "deleted">
			<cftransaction action="commit">
		<cfcatch>
			<cftransaction action="rollback">
			<cfset local.error_message = cfcatchToErrorMessage(cfcatch)>
			<cfset local.function_called = "#GetFunctionCalledName()#">
			<cfscript>reportError(function_called="#local.function_called#", error_message="#local.error_message#");</cfscript>
			<cfset local.retval = StructNew()>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = cfcatch.message>
		</cfcatch>
		</cftry>
	</cftransaction>
	<cfreturn serializeJSON(local.retval)>
</cffunction>

<!---
Function getContainerEditHtml.  Returns an HTML fragment containing the container
edit form suitable for rendering in a dialog box or embedded in another page.

@param container_id the container_id whose details should be rendered for editing.
@param idSuffix optional string to append to the IDs of elements in the returned 
  HTML fragment, to avoid collisions when multiple container edit forms are 
  rendered on the same page.
@return HTML fragment string for the container edit form, including 
  container type, label, barcode, and other editable fields.
--->
<cffunction name="getContainerEditHtml" returntype="string" access="remote" returnformat="plain">
	<cfargument name="container_id" type="numeric" required="yes">
	<cfargument name="idSuffix" type="string" required="no" default="">

	<cfset local.tn = REReplace(createUUID(), "-", "", "all")>
	<cfset local.safeIdSuffix = REReplace(arguments.idSuffix, "[^A-Za-z0-9_-]", "", "all")>
	<cfthread name="getContainerEditHtmlThread#local.tn#" container_id="#arguments.container_id#" idSuffix="#local.safeIdSuffix#">
		<cfoutput>
			<cftry>
				<cfquery name="ctContainerType" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
					SELECT
						container_type
					FROM
						ctcontainer_type
					ORDER BY
						container_type
				</cfquery>
				<cfquery name="getContainerEdit" datasource="user_login" username="#session.dbuser#"  password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
					SELECT
						c.container_id,
						c.parent_container_id,
						c.container_type,
						c.label,
						c.description,
						c.parent_install_date,
						c.container_remarks,
						c.barcode,
						c.width,
						c.height,
						c.length,
						c.number_positions,
						c.institution_acronym,
						p.label AS parent_label,
						p.barcode AS parent_barcode
					FROM
						container c
						LEFT JOIN container p ON c.parent_container_id = p.container_id
					WHERE
						c.container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#container_id#">
				</cfquery>
				<cfif getContainerEdit.recordcount EQ 0>
					<p class="text-danger">Container not found.</p>
				<cfelse>
					<cfset parentContainerText = "">
					<cfif len(trim(getContainerEdit.parent_barcode)) GT 0>
						<cfset parentContainerText = getContainerEdit.parent_barcode>
					<cfelseif len(trim(getContainerEdit.parent_label)) GT 0>
						<cfset parentContainerText = getContainerEdit.parent_label>
					</cfif>
					<cfset installDate = "">
					<cfif isDate(getContainerEdit.parent_install_date)>
						<cfset installDate = dateFormat(getContainerEdit.parent_install_date, "yyyy-mm-dd")>
					</cfif>
					<section class="row mx-0 border rounded my-2 pt-2 mb-4" aria-labelledby="containerDialogFormHeading#encodeForHtml(idSuffix)#">
						<div class="col-12">
							<h2 class="h4 ml-3 mb-1" id="containerDialogFormHeading#encodeForHtml(idSuffix)#">Edit Container</h2>
							<div class="mb-2" role="status" aria-live="polite">
								<output id="containerSaveStatus#encodeForHtml(idSuffix)#">&nbsp;</output>
							</div>
							<form class="col-12 px-0" id="containerForm#encodeForHtml(idSuffix)#" name="containerForm#encodeForHtml(idSuffix)#" method="post" novalidate>
								<input type="hidden" name="container_id" id="container_id#encodeForHtml(idSuffix)#" value="#encodeForHtml(getContainerEdit.container_id)#">
								<div class="form-row">
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="container_type#encodeForHtml(idSuffix)#" class="data-entry-label">Container Type</label>
										<select name="container_type" id="container_type#encodeForHtml(idSuffix)#" class="data-entry-select reqdClr col-12" required aria-required="true">
											<option value=""></option>
											<cfloop query="ctContainerType">
												<cfset selectedType = "">
												<cfif ctContainerType.container_type EQ getContainerEdit.container_type>
													<cfset selectedType = " selected">
												</cfif>
												<option value="#encodeForHtml(ctContainerType.container_type)#"#selectedType#>#encodeForHtml(ctContainerType.container_type)#</option>
											</cfloop>
										</select>
									</div>
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="label#encodeForHtml(idSuffix)#" class="data-entry-label">Label</label>
										<input type="text" name="label" id="label#encodeForHtml(idSuffix)#" class="data-entry-input col-12 reqdClr" required aria-required="true" value="#encodeForHtml(getContainerEdit.label)#">
									</div>
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="barcode#encodeForHtml(idSuffix)#" class="data-entry-label">Barcode</label>
										<input type="text" name="barcode" id="barcode#encodeForHtml(idSuffix)#" class="data-entry-input col-12" value="#encodeForHtml(getContainerEdit.barcode)#">
									</div>
								</div>
								<div class="form-row">
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="parentContainerText#encodeForHtml(idSuffix)#" class="data-entry-label">Parent Container</label>
										<input type="hidden" name="parent_container_id" id="parent_container_id#encodeForHtml(idSuffix)#" value="#encodeForHtml(getContainerEdit.parent_container_id)#">
										<input type="text" name="parentContainerText" id="parentContainerText#encodeForHtml(idSuffix)#" class="data-entry-input col-12 reqdClr" required aria-required="true" value="#encodeForHtml(parentContainerText)#">
									</div>
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="parent_install_date#encodeForHtml(idSuffix)#" class="data-entry-label">Placement Date</label>
										<input type="text" name="parent_install_date" id="parent_install_date#encodeForHtml(idSuffix)#" class="data-entry-input col-12" value="#encodeForHtml(installDate)#">
									</div>
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="description#encodeForHtml(idSuffix)#" class="data-entry-label">Description</label>
										<input type="text" name="description" id="description#encodeForHtml(idSuffix)#" class="data-entry-input col-12" value="#encodeForHtml(getContainerEdit.description)#">
									</div>
								</div>
								<div class="form-row">
									<div class="col-12 mb-2">
										<label for="container_remarks#encodeForHtml(idSuffix)#" class="data-entry-label">Container Remarks</label>
										<textarea name="container_remarks" id="container_remarks#encodeForHtml(idSuffix)#" rows="3" class="data-entry-input col-12">#encodeForHtml(getContainerEdit.container_remarks)#</textarea>
									</div>
								</div>
								<div class="form-row">
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="width#encodeForHtml(idSuffix)#" class="data-entry-label">Width (cm)</label>
										<input type="text" name="width" id="width#encodeForHtml(idSuffix)#" class="data-entry-input col-12" value="#encodeForHtml(getContainerEdit.width)#">
									</div>
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="height#encodeForHtml(idSuffix)#" class="data-entry-label">Height (cm)</label>
										<input type="text" name="height" id="height#encodeForHtml(idSuffix)#" class="data-entry-input col-12" value="#encodeForHtml(getContainerEdit.height)#">
									</div>
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="length#encodeForHtml(idSuffix)#" class="data-entry-label">Length (cm)</label>
										<input type="text" name="length" id="length#encodeForHtml(idSuffix)#" class="data-entry-input col-12" value="#encodeForHtml(getContainerEdit.length)#">
									</div>
								</div>
								<div class="form-row">
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="number_positions#encodeForHtml(idSuffix)#" class="data-entry-label">Number of Positions</label>
										<input type="text" name="number_positions" id="number_positions#encodeForHtml(idSuffix)#" class="data-entry-input col-12" value="#encodeForHtml(getContainerEdit.number_positions)#">
									</div>
									<div class="col-12 col-md-6 col-xl-4 mb-2">
										<label for="institution_acronym#encodeForHtml(idSuffix)#" class="data-entry-label">Institution Acronym</label>
										<input type="text" name="institution_acronym" id="institution_acronym#encodeForHtml(idSuffix)#" class="data-entry-input col-12" value="#encodeForHtml(getContainerEdit.institution_acronym)#">
									</div>
								</div>
								<div class="form-row mb-4 mt-1">
									<div class="col-12">
										<button type="button" class="btn btn-xs btn-primary" onclick="saveContainerForm('containerForm#encodeForHtml(idSuffix)#', 'saveContainer', 'containerSaveStatus#encodeForHtml(idSuffix)#')">Save Changes</button>
									</div>
								</div>
							</form>
						</div>
					</section>
				</cfif>
			<cfcatch>
				<cfset error_message = cfcatchToErrorMessage(cfcatch)>
				<cfset function_called = "#GetFunctionCalledName()#">
				<cfscript>reportError(function_called="#function_called#", error_message="#error_message#");</cfscript>
				<p class="text-danger">Unable to load container edit form.</p>
			</cfcatch>
			</cftry>
		</cfoutput>
	</cfthread>
	<cfthread action="join" name="getContainerEditHtmlThread#local.tn#" />
	<cfreturn cfthread["getContainerEditHtmlThread#local.tn#"].output>
</cffunction>

<!---
Function preflightMoveContainerByBarcode. Resolves barcodes to container ids and runs placement preflight validation.
@param child_barcode barcode of the container to move.
@param parent_barcode barcode of the destination parent container.
@return a JSON object with status (ok|notfound|error), placement validation keys from validateContainerPlacement
	(allowed, severity, warnings, blocks, child_type, parent_type, etc), and context keys:
	child_container_id, parent_container_id, child_label, child_barcode, parent_label, parent_barcode.
--->
<cffunction name="preflightMoveContainerByBarcode" access="remote" returntype="any" returnformat="json" output="false">
	<cfargument name="child_barcode" type="string" required="yes">
	<cfargument name="parent_barcode" type="string" required="yes">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfquery name="local.queryChild" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, label, barcode
			FROM container
			WHERE barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.child_barcode)#">
		</cfquery>
		<cfif local.queryChild.recordcount EQ 0>
			<cfset local.retval["status"] = "notfound">
			<cfset local.retval["message"] = "Child barcode was not found.">
			<cfset local.retval["missing"] = "child">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfquery name="local.queryParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, label, barcode
			FROM container
			WHERE barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.parent_barcode)#">
		</cfquery>
		<cfif local.queryParent.recordcount EQ 0>
			<cfset local.retval["status"] = "notfound">
			<cfset local.retval["message"] = "Parent barcode was not found.">
			<cfset local.retval["missing"] = "parent">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfset local.validationResult = validateContainerPlacement(
			child_container_id=local.queryChild.container_id,
			proposed_parent_container_id=local.queryParent.container_id
		)>
		<cfif isSimpleValue(local.validationResult)>
			<cfset local.validationResult = deserializeJSON(local.validationResult)>
		</cfif>

		<cfset local.validationResult["status"] = "ok">
		<cfset local.validationResult["child_container_id"] = local.queryChild.container_id>
		<cfset local.validationResult["child_label"] = local.queryChild.label>
		<cfset local.validationResult["child_barcode"] = local.queryChild.barcode>
		<cfset local.validationResult["parent_container_id"] = local.queryParent.container_id>
		<cfset local.validationResult["parent_label"] = local.queryParent.label>
		<cfset local.validationResult["parent_barcode"] = local.queryParent.barcode>
		<cfreturn serializeJSON(local.validationResult)>
	<cfcatch>
		<cfset local.retval = StructNew()>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = trim(cfcatch.message)>
		<cfreturn serializeJSON(local.retval)>
	</cfcatch>
	</cftry>
</cffunction>

<!---
Function moveContainerByBarcode. Moves a child container into a new parent container by barcode.
Returns status JSON and never aborts on trigger errors.
@param child_barcode barcode of the container to move.
@param parent_barcode barcode of the destination parent container.
@param move_timestamp optional timestamp string (YYYY-MM-DD HH24:MI:SS) for parent_install_date.
@return a JSON object with status (moved|notfound|error) and message, plus context fields:
	child_container_id, parent_container_id, child_barcode, parent_barcode, missing (when notfound).
--->
<cffunction name="moveContainerByBarcode" access="remote" returntype="any" returnformat="json" output="false">
	<cfargument name="child_barcode" type="string" required="yes">
	<cfargument name="parent_barcode" type="string" required="yes">
	<cfargument name="move_timestamp" type="string" required="no" default="">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfquery name="queryChild" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, label, barcode, container_type, institution_acronym
			FROM container
			WHERE barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.child_barcode)#">
		</cfquery>
		<cfif queryChild.recordcount EQ 0>
			<cfset local.retval["status"] = "notfound">
			<cfset local.retval["message"] = "Child barcode was not found.">
			<cfset local.retval["missing"] = "child">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfquery name="queryParent" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, label, barcode, container_type, institution_acronym
			FROM container
			WHERE barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.parent_barcode)#">
		</cfquery>
		<cfif queryParent.recordcount EQ 0>
			<cfset local.retval["status"] = "notfound">
			<cfset local.retval["message"] = "Parent barcode was not found.">
			<cfset local.retval["missing"] = "parent">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfif len(trim(queryChild.institution_acronym)) GT 0
			AND len(trim(queryParent.institution_acronym)) GT 0
			AND queryChild.institution_acronym NEQ queryParent.institution_acronym>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = "A container cannot be placed into a container with a different institution acronym (#queryChild.institution_acronym# vs #queryParent.institution_acronym#).">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cftry>
			<cfquery name="queryDoMove" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#" result="queryDoMove_result"> 
				UPDATE container
				SET
					parent_container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#queryParent.container_id#">
					<cfif len(trim(arguments.move_timestamp)) GT 0>
						, parent_install_date = TO_DATE(
							<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#trim(arguments.move_timestamp)#">,
							'YYYY-MM-DD HH24:MI:SS'
						)
					</cfif>
				WHERE container_id = <cfqueryparam cfsqltype="CF_SQL_DECIMAL" value="#queryChild.container_id#">
			</cfquery>
			<cfif queryDoMove_result.recordCount EQ 0>
				<cfthrow type="ChildNotFound" message="No rows updated;">
			</cfif>
		<cfcatch>
			<cfset local.userMessage = trim(REReplace(cfcatch.message, "^ORA-[0-9]+:\\s*", "", "one"))>
			<cfset local.matchPos = REFindNoCase("(You cannot|This move|A container|Institution|The child|The position)", local.userMessage)>
			<cfif local.matchPos GT 0>
				<cfset local.userMessage = mid(local.userMessage, local.matchPos, len(local.userMessage) - local.matchPos + 1)>
			</cfif>
			<cfif len(trim(local.userMessage)) EQ 0>
				<cfset local.userMessage = "Unable to move container due to a placement rule. Please review the selected parent and try again.">
			</cfif>
			<cfif cfcatch.type EQ "ChildNotFound">
				<cfset local.userMessage = "Query Error: " + cfcatch.message + " Child container was not found. It may have been deleted or moved by another user.">
			</cfif>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = local.userMessage>
			<cfreturn serializeJSON(local.retval)>
		</cfcatch>
		</cftry>

		<cfset local.retval["status"] = "moved">
		<cfset local.retval["child_container_id"] = queryChild.container_id>
		<cfset local.retval["child_label"] = queryChild.label>
		<cfset local.retval["child_type"] = queryChild.container_type>
		<cfset local.retval["parent_container_id"] = queryParent.container_id>
		<cfset local.retval["parent_label"] = queryParent.label>
		<cfset local.retval["parent_type"] = queryParent.container_type>
		<cfreturn serializeJSON(local.retval)>
	<cfcatch>
		<cfset local.retval = StructNew()>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = trim(cfcatch.message)>
		<cfreturn serializeJSON(local.retval)>
	</cfcatch>
	</cftry>
</cffunction>

<!---
Function placeContainerIntoPositionByBarcode.  Looks up a scanned/typed barcode and, if it
matches an existing container, places that container into the given position container by
delegating to moveContainerById.  Supports the positions-grid scan-to-place workflow on
viewContainer.cfm.  Returns status JSON and never aborts on trigger errors.

@param barcode barcode scanned or typed into the empty position's input.
@param position_container_id container_id of the empty position container to place into.
@return a JSON object with status (moved|notfound|error) and message, plus context fields:
	child_container_id, child_label, child_barcode, child_type, parent_container_id (when moved).
--->
<cffunction name="placeContainerIntoPositionByBarcode" access="remote" returntype="any" returnformat="json" output="false">
	<cfargument name="barcode" type="string" required="yes">
	<cfargument name="position_container_id" type="numeric" required="yes">

	<cfset local.retval = StructNew()>
	<cftry>
		<cfif NOT (isdefined("session.roles") AND listfindnocase(session.roles, "manage_container") GT 0)>
			<cfset local.retval["status"] = "error">
			<cfset local.retval["message"] = "You do not have permission to place containers.">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfset local.trimmedBarcode = trim(arguments.barcode)>
		<cfif len(local.trimmedBarcode) EQ 0>
			<cfset local.retval["status"] = "notfound">
			<cfset local.retval["message"] = "Enter or scan a barcode.">
			<cfset local.retval["missing"] = "child">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfquery name="queryChild" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
			SELECT container_id, label, barcode, container_type
			FROM container
			WHERE barcode = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#local.trimmedBarcode#">
		</cfquery>
		<cfif queryChild.recordcount EQ 0>
			<cfset local.retval["status"] = "notfound">
			<!--- encodeForHtml to prevent XSS if barcode contains HTML special characters, which will look ugly, but not for normal inputs --->
			<cfset local.retval["message"] = "No container found with barcode '#encodeForHTML(local.trimmedBarcode)#'.">
			<cfset local.retval["missing"] = "child">
			<cfreturn serializeJSON(local.retval)>
		</cfif>

		<cfset local.moveResult = deserializeJSON(moveContainerById(
			child_container_id=queryChild.container_id,
			parent_container_id=arguments.position_container_id
		))>
		<cfset local.moveResult["child_barcode"] = queryChild.barcode>
		<cfreturn serializeJSON(local.moveResult)>
	<cfcatch>
		<cfset local.retval = StructNew()>
		<cfset local.retval["status"] = "error">
		<cfset local.retval["message"] = trim(cfcatch.message)>
		<cfreturn serializeJSON(local.retval)>
	</cfcatch>
	</cftry>
</cffunction>

<!---
Function previewBulkRetypeRange. Resolves a barcode_prefix + integer range into actual containers,
for the range-analysis step of the bulk retype tool. Fetches candidates with a single parameterized
LIKE query rather than a WHERE barcode IN (...) built from the whole range, since Oracle caps an
IN-list at 1000 expressions and this tool is expected to handle ranges of a few thousand; each range
member is then confirmed with an exact string match in CF (barcode = barcode_prefix & i), matching
the original tool's exact matching logic rather than trusting the LIKE pattern alone (which would
also match longer barcodes that merely share the same prefix).
@param barcode_prefix literal prefix shared by every barcode in the range.
@param begin_barcode low end of the inclusive integer range.
@param end_barcode high end of the inclusive integer range.
@return a struct: rangeSize, matchedCount, missingCount, missingBarcodes (array, capped at 100),
	missingBarcodesTruncated (boolean), typeCounts (array of {container_type, type_count}, sorted
	by type_count descending).
--->
<cffunction name="previewBulkRetypeRange" access="public" returntype="struct" output="false">
	<cfargument name="barcode_prefix" type="string" required="yes">
	<cfargument name="begin_barcode" type="numeric" required="yes">
	<cfargument name="end_barcode" type="numeric" required="yes">

	<cfset var MAX_LISTED_MISSING = 100>
	<cfset var result = StructNew()>
	<cfset var candidates = "">
	<cfset var foundByBarcode = StructNew()>
	<cfset var typeCounts = StructNew()>
	<cfset var typeCountsArray = ArrayNew(1)>
	<cfset var sortedTypeCounts = ArrayNew(1)>
	<cfset var remaining = "">
	<cfset var expectedBarcode = "">
	<cfset var thisType = "">
	<cfset var i = 0>
	<cfset var j = 0>
	<cfset var maxIndex = 0>
	<cfset var typeName = "">
	<cfset var row = StructNew()>

	<cfset result["rangeSize"] = (arguments.end_barcode - arguments.begin_barcode) + 1>
	<cfset result["matchedCount"] = 0>
	<cfset result["missingCount"] = 0>
	<cfset result["missingBarcodes"] = ArrayNew(1)>
	<cfset result["missingBarcodesTruncated"] = false>

	<cfquery name="candidates" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT barcode, container_type
		FROM container
		WHERE barcode LIKE <cfqueryparam value="#arguments.barcode_prefix#%" cfsqltype="CF_SQL_VARCHAR">
	</cfquery>

	<cfloop query="candidates">
		<cfset foundByBarcode[candidates.barcode] = candidates.container_type>
	</cfloop>

	<cfloop from="#arguments.begin_barcode#" to="#arguments.end_barcode#" index="i">
		<cfset expectedBarcode = arguments.barcode_prefix & i>
		<cfif structKeyExists(foundByBarcode, expectedBarcode)>
			<cfset result["matchedCount"] = result["matchedCount"] + 1>
			<cfset thisType = foundByBarcode[expectedBarcode]>
			<cfif NOT structKeyExists(typeCounts, thisType)>
				<cfset typeCounts[thisType] = 0>
			</cfif>
			<cfset typeCounts[thisType] = typeCounts[thisType] + 1>
		<cfelse>
			<cfset result["missingCount"] = result["missingCount"] + 1>
			<cfif ArrayLen(result["missingBarcodes"]) LT MAX_LISTED_MISSING>
				<cfset ArrayAppend(result["missingBarcodes"], expectedBarcode)>
			<cfelse>
				<cfset result["missingBarcodesTruncated"] = true>
			</cfif>
		</cfif>
	</cfloop>

	<cfloop collection="#typeCounts#" item="typeName">
		<cfset row = StructNew()>
		<cfset row["container_type"] = typeName>
		<cfset row["type_count"] = typeCounts[typeName]>
		<cfset ArrayAppend(typeCountsArray, row)>
	</cfloop>

	<!--- manual selection sort by type_count descending -- avoids relying on closure-based ArraySort
		callbacks that may not be available on every CFML engine this application is deployed to --->
	<cfset remaining = typeCountsArray>
	<cfloop condition="ArrayLen(remaining) GT 0">
		<cfset maxIndex = 1>
		<cfloop from="2" to="#ArrayLen(remaining)#" index="j">
			<cfif remaining[j].type_count GT remaining[maxIndex].type_count>
				<cfset maxIndex = j>
			</cfif>
		</cfloop>
		<cfset ArrayAppend(sortedTypeCounts, remaining[maxIndex])>
		<cfset ArrayDeleteAt(remaining, maxIndex)>
	</cfloop>
	<cfset result["typeCounts"] = sortedTypeCounts>

	<cfreturn result>
</cffunction>

<!---
Function getContainersInRange. Resolves a barcode_prefix + integer range, filtered to containers
currently of orig_container_type, for the change-entry/dry-run/apply steps of the bulk retype tool.
Uses the same LIKE-then-exact-match approach as previewBulkRetypeRange to avoid Oracle's IN-list
size limit, and returns an array of structs rather than a query object so each field keeps whatever
type the database driver already gave it, without needing to hand-build a new typed query.
@param barcode_prefix literal prefix shared by every barcode in the range.
@param begin_barcode low end of the inclusive integer range.
@param end_barcode high end of the inclusive integer range.
@param orig_container_type only containers currently of this type are included.
@return an array of structs: container_id, barcode, label, container_type, parent_container_id,
	description, container_remarks, height, length, width, number_positions.
--->
<cffunction name="getContainersInRange" access="public" returntype="array" output="false">
	<cfargument name="barcode_prefix" type="string" required="yes">
	<cfargument name="begin_barcode" type="numeric" required="yes">
	<cfargument name="end_barcode" type="numeric" required="yes">
	<cfargument name="orig_container_type" type="string" required="yes">

	<cfset var candidates = "">
	<cfset var matchedBarcodes = StructNew()>
	<cfset var results = ArrayNew(1)>
	<cfset var i = 0>
	<cfset var row = StructNew()>

	<cfquery name="candidates" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.query_timeout#">
		SELECT container_id, barcode, label, container_type, parent_container_id,
			description, container_remarks, height, length, width, number_positions
		FROM container
		WHERE
			barcode LIKE <cfqueryparam value="#arguments.barcode_prefix#%" cfsqltype="CF_SQL_VARCHAR">
			AND container_type = <cfqueryparam value="#arguments.orig_container_type#" cfsqltype="CF_SQL_VARCHAR">
	</cfquery>

	<cfloop from="#arguments.begin_barcode#" to="#arguments.end_barcode#" index="i">
		<cfset matchedBarcodes[arguments.barcode_prefix & i] = true>
	</cfloop>

	<cfloop query="candidates">
		<cfif structKeyExists(matchedBarcodes, candidates.barcode)>
			<cfset row = StructNew()>
			<cfset row["container_id"] = candidates.container_id>
			<cfset row["barcode"] = candidates.barcode>
			<cfset row["label"] = candidates.label>
			<cfset row["container_type"] = candidates.container_type>
			<cfset row["parent_container_id"] = candidates.parent_container_id>
			<cfset row["description"] = candidates.description>
			<cfset row["container_remarks"] = candidates.container_remarks>
			<cfset row["height"] = candidates.height>
			<cfset row["length"] = candidates.length>
			<cfset row["width"] = candidates.width>
			<cfset row["number_positions"] = candidates.number_positions>
			<cfset ArrayAppend(results, row)>
		</cfif>
	</cfloop>

	<cfreturn results>
</cffunction>

<!---
Function summarizeContainerProperties. Counts how many containers in a set (as returned by
getContainersInRange) have a value for each of description, container_remarks, height, length,
width, and number_positions -- used by the bulk retype tool's range-analysis and change-entry pages
to show what's actually populated before deciding what to overwrite. For the numeric dimension/
position fields, 0 counts as not-set (this data uses 0 to mean "no value recorded", not a real
zero-size dimension), not just blank/null. For description and container_remarks, also reports how
many distinct non-blank values exist and up to 3 example values, since "N have a description" alone
doesn't say whether that's one shared boilerplate value or genuinely varied text.
@param containers array of structs as returned by getContainersInRange.
@return a struct: totalCount, descriptionCount, descriptionDistinctCount, descriptionExamples (array,
	up to 3), remarksCount, remarksDistinctCount, remarksExamples (array, up to 3), heightCount,
	lengthCount, widthCount, positionsCount.
--->
<cffunction name="summarizeContainerProperties" access="public" returntype="struct" output="false">
	<cfargument name="containers" type="array" required="yes">

	<cfset var MAX_EXAMPLES = 3>
	<cfset var summary = StructNew()>
	<cfset var i = 0>
	<cfset var seenDescriptions = StructNew()>
	<cfset var seenRemarks = StructNew()>
	<cfset summary["totalCount"] = ArrayLen(arguments.containers)>
	<cfset summary["descriptionCount"] = 0>
	<cfset summary["descriptionDistinctCount"] = 0>
	<cfset summary["descriptionExamples"] = ArrayNew(1)>
	<cfset summary["remarksCount"] = 0>
	<cfset summary["remarksDistinctCount"] = 0>
	<cfset summary["remarksExamples"] = ArrayNew(1)>
	<cfset summary["heightCount"] = 0>
	<cfset summary["lengthCount"] = 0>
	<cfset summary["widthCount"] = 0>
	<cfset summary["positionsCount"] = 0>

	<cfloop from="1" to="#ArrayLen(arguments.containers)#" index="i">
		<cfif len(trim(arguments.containers[i].description)) GT 0>
			<cfset summary["descriptionCount"] = summary["descriptionCount"] + 1>
			<cfif NOT structKeyExists(seenDescriptions, arguments.containers[i].description)>
				<cfset seenDescriptions[arguments.containers[i].description] = true>
				<cfset summary["descriptionDistinctCount"] = summary["descriptionDistinctCount"] + 1>
				<cfif ArrayLen(summary["descriptionExamples"]) LT MAX_EXAMPLES>
					<cfset ArrayAppend(summary["descriptionExamples"], arguments.containers[i].description)>
				</cfif>
			</cfif>
		</cfif>
		<cfif len(trim(arguments.containers[i].container_remarks)) GT 0>
			<cfset summary["remarksCount"] = summary["remarksCount"] + 1>
			<cfif NOT structKeyExists(seenRemarks, arguments.containers[i].container_remarks)>
				<cfset seenRemarks[arguments.containers[i].container_remarks] = true>
				<cfset summary["remarksDistinctCount"] = summary["remarksDistinctCount"] + 1>
				<cfif ArrayLen(summary["remarksExamples"]) LT MAX_EXAMPLES>
					<cfset ArrayAppend(summary["remarksExamples"], arguments.containers[i].container_remarks)>
				</cfif>
			</cfif>
		</cfif>
		<cfif len(trim(arguments.containers[i].height)) GT 0 AND val(arguments.containers[i].height) NEQ 0>
			<cfset summary["heightCount"] = summary["heightCount"] + 1>
		</cfif>
		<cfif len(trim(arguments.containers[i].length)) GT 0 AND val(arguments.containers[i].length) NEQ 0>
			<cfset summary["lengthCount"] = summary["lengthCount"] + 1>
		</cfif>
		<cfif len(trim(arguments.containers[i].width)) GT 0 AND val(arguments.containers[i].width) NEQ 0>
			<cfset summary["widthCount"] = summary["widthCount"] + 1>
		</cfif>
		<cfif len(trim(arguments.containers[i].number_positions)) GT 0 AND val(arguments.containers[i].number_positions) NEQ 0>
			<cfset summary["positionsCount"] = summary["positionsCount"] + 1>
		</cfif>
	</cfloop>

	<cfreturn summary>
</cffunction>

</cfcomponent>
