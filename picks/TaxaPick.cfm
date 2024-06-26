<cfinclude template="../includes/_pickHeader.cfm">
<cfif NOT isDefined("keepValue")><cfset keepValue=0></cfif>
<cfoutput>
	<cfif len(scientific_name) is 0 or scientific_name is 'undefined'>
		<form name="s" method="post" action="TaxaPick.cfm">
			<input type="hidden" name="formName" value="#formName#">
			<input type="hidden" name="taxonIdFld" value="#taxonIdFld#">
			<input type="hidden" name="taxonNameFld" value="#taxonNameFld#">
			<label for="scientific_name">Scientific Name</label>
			<input type="text" name="scientific_name" id="scientific_name" size="50">
			<br><input type="submit" class="lnkBtn" value="Search">
		</form>
		<cfabort>
	</cfif>
	<cfquery name="getTaxa" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cookie.cfid)#">
			SELECT
				scientific_name,
				author_text,
				taxon_name_id,
				valid_catalog_term_fg
			FROM (
				SELECT
					scientific_name,
					author_text,
					taxon_name_id,
					valid_catalog_term_fg
				from
					taxonomy
				where
					UPPER(scientific_name) LIKE <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#ucase(scientific_name)#%'>
					OR
					UPPER(scientific_name || ' ' || author_text) LIKE <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#ucase(scientific_name)#%'>
				UNION
				SELECT
					a.scientific_name,
					a.author_text,
					a.taxon_name_id,
					a.valid_catalog_term_fg
				from
					taxonomy a
					left join taxon_relations on a.taxon_name_id = taxon_relations.taxon_name_id
					left join taxonomy b on taxon_relations.related_taxon_name_id = b.taxon_name_id
				where
					UPPER(B.scientific_name) LIKE <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#ucase(scientific_name)#%'>
					OR
					UPPER(B.scientific_name || ' ' || B.author_text) LIKE <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#ucase(scientific_name)#%'>
				UNION
				SELECT
					b.scientific_name,
					b.author_text,
					b.taxon_name_id,
					b.valid_catalog_term_fg
				from
					taxonomy a
					left join taxon_relations on a.taxon_name_id = taxon_relations.taxon_name_id
					left join taxonomy b on taxon_relations.related_taxon_name_id = b.taxon_name_id
				where
					UPPER(a.scientific_name) LIKE <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#ucase(scientific_name)#%'>
					OR
					UPPER(a.scientific_name || ' ' || a.author_text) LIKE <cfqueryparam cfsqltype='CF_SQL_VARCHAR' value='#ucase(scientific_name)#%'>
			)
			where scientific_name is not null
			ORDER BY scientific_name
	</cfquery>
</cfoutput>
<cfif #getTaxa.recordcount# is 1>
	<cfoutput>
		<cfif #getTaxa.valid_catalog_term_fg# is "1">
		<script>
			opener.document.#formName#.#taxonIdFld#.value='#getTaxa.taxon_name_id#';opener.document.#formName#.#taxonNameFld#.value='#getTaxa.scientific_name#';self.close();
		</script>
		<cfelse>
			<a href="##" onClick="javascript: opener.document.#formName#.#taxonIdFld#.value='#getTaxa.taxon_name_id#';opener.document.#formName#.#taxonNameFld#.value='#getTaxa.scientific_name#';self.close();"><font color="##FF0000"><i>#getTaxa.scientific_name#</i> #gettaxa.author_text# (unaccepted)</font></a>
		</cfif>
	</cfoutput>
<cfelseif #getTaxa.recordcount# is 0>
	<cfif #keepValue# is 1>
		<cfoutput>
			<!---  Allow a keepValue parameter that doesn't reset taxonNameFld to an empty string  --->
			Nothing matched #scientific_name#. <a href="javascript:void(0);" onClick="opener.document.#formName#.#taxonIdFld#.value='';opener.document.#formName#.#taxonNameFld#.value='';opener.document.#formName#.#taxonNameFld#.focus();self.close();">Try again</a>, or <a href="javascript:void(0);" onClick="self.close();">Keep if #scientific_name# is a hybrid or or uses a taxonomic formula</a> (i.e., "?", "cf.", "sp.", "ssp." ,"or")
		</cfoutput>
	<cfelse>
		<!---  otherwise reset taxonNameFld  --->
		<cfoutput>
			Nothing matched #scientific_name#. <a href="javascript:void(0);" onClick="opener.document.#formName#.#taxonIdFld#.value='';opener.document.#formName#.#taxonNameFld#.value='';opener.document.#formName#.#taxonNameFld#.focus();self.close();">Try again.</a>
		</cfoutput>
	</cfif>
<cfelse>
	<cfoutput query="getTaxa">
		<cfif #getTaxa.valid_catalog_term_fg# is "1">
			<br><a href="##" onClick="javascript: opener.document.#formName#.#taxonIdFld#.value='#taxon_name_id#';opener.document.#formName#.#taxonNameFld#.value='#scientific_name#';self.close();"><i>#scientific_name#</i> #author_text#</a>
		<cfelse>
			<br><a href="##" onClick="javascript: opener.document.#formName#.#taxonIdFld#.value='#taxon_name_id#';opener.document.#formName#.#taxonNameFld#.value='#scientific_name#';self.close();"><font color="##FF0000"><i>#scientific_name#</i> #author_text#(unaccepted)</font></a>
		</cfif>
	</cfoutput>
</cfif>
<cfinclude template="../includes/_pickFooter.cfm">
