<cfset pageTitle="Minimal Specimen Results">
<cfinclude template="/shared/_header.cfm">

<cftry>
	<cfif not isDefined("result_id") OR len(result_id) EQ 0> 
		<!--- new search --->
		<cfinclude template="/specimens/component/search.cfc" runOnce="true">
	
		<cfset search_json = "[">
		<cfset separator = "">
		<cfset join = ''>

		<cfset nest = 1>

		<cfset parameters = StructNew()>
	
		<cfif isdefined("collection_id") and len(#collection_id#) gt 0>
			<cfset StructInsert(parameters,"collection_id",collection_id)>
			<!--- lookup collection from collection_id if specified --->
			<cfquery name="lookupColl" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" timeout="#Application.short_timeout#">
				SELECT collection_cde
				FROM collection
				WHERE collection_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#collection_id#">
			</cfquery>
			<cfif lookupColl.recordcount EQ 1>
				<cfset collection_cde = lookupColl.collection_cde>
			</cfif>
		</cfif>
		<cfif isDefined("collection_cde") AND len(collection_cde) GT 0>
			<cfset StructInsert(parameters,"collection_cde",collection_cde)>
			<cfset field = '"field": "collection_cde"'>
			<cfset comparator = '"comparator": "IN"'>
			<cfset value = encodeForJSON(collection_cde)>
			<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#value#"}'>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("cat_num") AND len(cat_num) GT 0>
			<cfset StructInsert(parameters,"cat_num",cat_num)>
			<cfset clause = ScriptPrefixedNumberListToJSON(cat_num, "CAT_NUM_INTEGER", "CAT_NUM_PREFIX", true, nest, "and")>
			<cfset search_json = "#search_json##separator##clause#">
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("type_status") AND len(type_status) GT 0>
			<cfset StructInsert(parameters,"type_status",type_status)>
			<cfset field = '"field": "citations_type_status"'>
			<!--- handle special case values, any, any type, any primary --->
			<cfset type_status_value = type_status>
			<cfif lcase(type_status) EQ "any">
				<cfset type_status_value = "NOT NULL">
			<cfelseif lcase(type_status) EQ "any type">
				<cfquery name="types" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="types_result" timeout="#Application.short_timeout#">
					SELECT type_status 
					FROM ctcitation_type_status 
					WHERE category = 'Primary' OR category = 'Secondary'
				</cfquery>
				<cfset type_status_value = "">
				<cfset typeseparator = "">
				<cfloop query="types">
					<cfset type_status_value = "#type_status_value##typeseparator##types.type_status#">
					<cfset typeseparator = ",">
				</cfloop>
			<cfelseif lcase(type_status) EQ "any primary">
				<cfquery name="types" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="types_result" timeout="#Application.short_timeout#">
					SELECT type_status 
					FROM ctcitation_type_status 
					WHERE category = 'Primary'
				</cfquery>
				<cfset type_status_value = "">
				<cfset typeseparator = "">
				<cfloop query="types">
					<cfset type_status_value = "#type_status_value##typeseparator##types.type_status#">
					<cfset typeseparator = ",">
				</cfloop>
			</cfif>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#type_status_value#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("any_taxa_term") AND len(any_taxa_term) GT 0>
			<cfset StructInsert(parameters,"any_taxa_term",any_taxa_term)>
			<cfif isDefined("current_id_only") AND current_id_only EQ "current">
				<cfset field = '"field": "taxa_term"'>
			<cfelse>
				<cfset field = '"field": "taxa_term_all"'>
			</cfif>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#any_taxa_term#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("phylum") AND len(phylum) GT 0>
			<cfset StructInsert(parameters,"phylum",phylum)>
			<cfset field = '"field": "phylum"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#phylum#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("family") AND len(family) GT 0>
			<cfset StructInsert(parameters,"family",family)>
			<cfset field = '"field": "family"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#family#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("any_geography") AND len(any_geography) GT 0>
			<cfset StructInsert(parameters,"any_geography",any_geography)>
			<cfset field = '"field": "any_geography"'>
			<cfset comparator = '"comparator": ""'>
			<!--- convert operator characters from conventions used elsewhere in MCZbase to oracle CONTAINS operators --->
			<!--- 
			User enters >  converted to:  meaning
				! ->  ~   NOT
				$ ->  !   SOUNDEX
				# ->  $   STEM
				~ ->  ~   NOT  (no change made, but we don't document that ~ is allowed)
			NOTE: order of replacements matters.
			--->
			<cfset searchValue = any_geography>
			<cfset searchValue = replace(searchValue,"!","~","all")>
			<cfset searchValue = replace(searchValue,"$","!","all")>
			<cfset searchValue = replace(searchValue,"##","$","all")>
	
			<!--- escape quotes for json construction --->
			<cfset searchValueForJSON = searchValue>
			<cfset searchValueForJSON = replace(searchValueForJSON,"\","\\","all")>
			<cfset searchValueForJSON = replace(searchValueForJSON,'"','\"',"all")>
			<cfset search_json = '#search_json##separator#{"nest":"#nest#",#join##field#,#comparator#,"value": "#searchValueForJSON#"}'>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("continent_ocean") AND len(continent_ocean) GT 0>
			<cfset StructInsert(parameters,"continent_ocean",continent_ocean)>
			<cfset field = '"field": "continent_ocean"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#continent_ocean#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("country") AND len(country) GT 0>
			<cfset StructInsert(parameters,"country",country)>
			<cfset field = '"field": "country"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#country#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("island_group") AND len(island_group) GT 0>
			<cfset StructInsert(parameters,"island_group",island_group)>
			<cfset field = '"field": "island_group"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#island_group#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("islands") AND len(islands) GT 0>
			<cfset island=islands>
		</cfif>
		<cfif isDefined("island") AND len(island) GT 0>
			<cfset StructInsert(parameters,"island",island)>
			<cfset field = '"field": "island"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#island#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("spec_locality") AND len(spec_locality) GT 0>
			<cfset StructInsert(parameters,"spec_locality",spec_locality)>
			<cfset field = '"field": "spec_locality"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#spec_locality#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("date_collected") AND len(date_collected) GT 0>
			<cfset StructInsert(parameters,"date_collected",date_collected)>
			<cfset field = '"field": "date_began_date"'>
			<cfset searchText = reformatDateSearchTerm(searchText="#date_collected#") >
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#searchText#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
			<cfset field = '"field": "date_ended_date"'>
			<cfset searchText = reformatDateSearchTerm(searchText="#date_collected#") >
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#searchText#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
		<cfif isDefined("part_name") AND len(part_name) GT 0>
			<cfset StructInsert(parameters,"part_name",part_name)>
			<cfset field = '"field": "part_name"'>
			<cfset search_json = search_json & constructJsonForField(join="#join#",field="#field#",value="#part_name#",separator="#separator#",nestDepth="#nest#")>
			<cfset separator = ",">
			<cfset join='"join":"and",'>
			<cfset nest = nest + 1>
		</cfif>
	
		<cfset search_json = "#search_json#]">
		<cfif isdefined("debug") AND len(debug) GT 0>
			<cfoutput>
				<cfdump var="#search_json#">
				<cfdump var="#session.dbuser#">
			</cfoutput>
		</cfif>
		<cfif NOT IsJSON(search_json)>
			<cfthrow message="Unable to construct valid json for query.">
		</cfif>
		<cfif search_json IS "[]">
			<cfthrow message="You must provide some search parameters.">
		</cfif>
	
		<cfset result_id = CreateUUID()>
		<cfstoredproc procedure="build_query_dbms_sql" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="prepareSearch_result" timeout="#Application.query_timeout#">
			<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			<cfprocparam cfsqltype="CF_SQL_VARCHAR" value="#session.dbuser#">
			<cfprocparam cfsqltype="CF_SQL_CLOB" value="#search_json#">
			<cfprocresult name="buildsearch">
		</cfstoredproc>
	
	<cfelse>
		<!--- paging in existing search --->
		
	
	</cfif>

	<cfquery name="count" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result" timeout="#Application.query_timeout#">
		SELECT count(*) ct
		FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
			join user_search_table on user_search_table.collection_object_id = flatTableName.collection_object_id
		WHERE
			user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
	</cfquery>
	<cfquery name="search" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#" result="search_result" timeout="#Application.query_timeout#">
		SELECT
			guid, 
			get_scientific_name_auths(flatTableName.collection_object_id) scientific_name, 
			continent_ocean,
			country,
			spec_locality,
			began_date,
			ended_date,
			collectors
		FROM <cfif ucase(#session.flatTableName#) EQ 'FLAT'>FLAT<cfelse>FILTERED_FLAT</cfif> flatTableName
			join user_search_table on user_search_table.collection_object_id = flatTableName.collection_object_id
		WHERE
			user_search_table.result_id = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#result_id#">
			and rownum < 1001
	</cfquery>

	<cfoutput>
		<div class="container my-3">
			<div class="row">
				<div class="col-12 mb-2">
					<h3 class="h3">Search Results (#count.ct#)</h3>
					<cfset linkParams="">
					<cfset linkText="">
					<cfset separator="">
					<cfset textseparator="">
					<cfloop collection="#parameters#" item="key">
						<cfset value = structFind(parameters,key)>
						<cfset linkParams= "#linkParams##separator##encodeforurl(key)#=#encodeforurl(value)#">
						<cfset separator = "&">
						<cfset linkText= "#linkText##textseparator##encodeforhtml(key)#=#encodeforhtml(value)#">
						<cfset textseparator = " and ">
					</cfloop>
					<div>
						Link to this Search: <a href="/SpecimensHTML.cfm?#linkParams#">#linkText#</a>
					</div>
					<table class="table table-responsive table-striped d-lg-table">
						<thead class="thead-light">
							<tr>
								<th> GUID </th>
								<th> Scientific Name </th>
								<th> Continent/Ocean</th>
								<th> Country </th>
								<th> Locality </th>
								<th> Date </th>
								<th> Collectors </th>
							</tr>
						</thead>
						<tbody>
							<cfloop query="search">
								<cfif search.began_date EQ search.ended_date OR len(search.ended_date) EQ 0>
									<cfset eventDate = search.began_date>
								<cfelse>
									<cfset eventDate = "#search.began_date#/#search.ended_date#">
								</cfif>
								<tr>
									<td>
										<a href="/guid/#guid#" aria-label="specimen details for #guid#">#guid#</a>
										<a href="/guid/#GUID#/json"><img src="/shared/images/json-ld-data-24.png" alt="JSON-LD" aria-label="Specimen details as RDF in a JSON-LD serialization"></a>
									</td>
									<td>#scientific_name#</td>
									<td>#continent_ocean#</td>
									<td>#country#</td>
									<td>#spec_locality#</td>
									<td>#eventDate#</td>
									<td>#collectors#</td>
								</tr>
							</cfloop>
						</tbody>
					</table>
				</div>
			</div>
		</div>
	</cfoutput>
<cfcatch>
	<cfset error_message = cfcatchToErrorMessage(cfcatch)>
	<cfset function_called = "#GetFunctionCalledName()#">
	<cfoutput>
		<h2 class='h3'>Error running minmal specimen search:</h2>
		<div>#error_message#</div>
	</cfoutput>
</cfcatch>
</cftry>

<cfinclude template="/shared/_footer.cfm">
