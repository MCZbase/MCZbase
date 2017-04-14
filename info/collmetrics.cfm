<cfinclude template = "/includes/_header.cfm">
<cfset title = "Collections Metrics">
<cfoutput>
<script src="/includes/sorttable.js"></script>

<cfset datefilter='2016-07-01'>

<cfquery name="colls" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
	select collection_cde, collection from collection where collection_cde not in ('MCZ', 'SC', 'HerpOBS') order by collection_cde
</cfquery>

<H1>Collections Stats as of 2016-06-30</H1>
<cfquery name = "itemStatsMCZ" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(distinct f.collection_object_id) lots,
		sum(decode(TOTAL_PARTS, null, 1, TOTAL_PARTS)) specs,
		trunc(sum(decode(dec_lat, null, 0, 1))/count(distinct f.collection_object_id),3)*100 || '%' georeflots,
		trunc(sum(decode(dec_lat, null, 0, TOTAL_PARTS))/sum(decode(TOTAL_PARTS, null, 1, TOTAL_PARTS)),3)*100 || '%' georefspecs
		from flat f, coll_object co where
		F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
		and CO.COLL_OBJECT_ENTERED_DATE < '#datefilter#'
	</cfquery>

	<cfquery name = "localityStatsMCZ" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(*) locs, sum(decode(dec_lat, null, 0, 1)) georeflocs, trunc(sum(decode(dec_lat, null, 0, 1))/count(*), 3)*100 || '%' percgeoref from
		(select distinct locality_id, dec_lat, dec_long
		from flat f, coll_object co
		where F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
		and CO.COLL_OBJECT_ENTERED_DATE < '#datefilter#')
	</cfquery>

	<cfquery name = "imageStatsMCZ" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(distinct m.media_id) imgs from media m, media_relations mr
		where m.media_id = mr.media_id
		and mr.media_relationship = 'shows cataloged_item'
  		and mr.related_primary_key in
  			(select collection_object_id from flat)
	</cfquery>

<H2>MCZ All Collections</h2>
	<cfloop query="itemStatsMCZ">
		## of cataloged items/lots: #lots#<br>
		## of specimens: #specs#<br>
		% of georeferenced cataloged items/lots: #georeflots#<br>
		% of georeferenced specimens: #georefspecs#<br>
	</cfloop>
	<cfloop query="localityStatsMCZ">
		## of distinct localities: #locs#<br>
		## of georeferenced localities: #georeflocs#<br>
		% of localities georeferenced: #percgeoref#<br>
	</cfloop>
	<cfloop query="imageStatsMCZ">
		## of images of cataloged items: #imgs#
	</cfloop>
	<br>
______________________________________________________________________________________________________________________


<cfloop query="colls">
<cfif colls.collection_cde EQ 'IZ'>
	<cfquery name = "itemStatsIZ" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(distinct f.collection_object_id) lots,
		sum(decode(TOTAL_PARTS, null, 1, TOTAL_PARTS)) specs,
		trunc(sum(decode(dec_lat, null, 0, 1))/count(distinct f.collection_object_id),3)*100 || '%' georeflots,
		trunc(sum(decode(dec_lat, null, 0, TOTAL_PARTS))/sum(decode(TOTAL_PARTS, null, 1, TOTAL_PARTS)),3)*100 || '%' georefspecs
		from flat f, coll_object co where
		collection_cde = '#colls.collection_cde#' and
		F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
		and CO.COLL_OBJECT_ENTERED_DATE < '#datefilter#'
		and upper(full_taxon_name) not like '%ECHINODERMATA%'
		and upper(full_taxon_name) not like '%BRYOZOA%'
		and upper(full_taxon_name) not like '%CHORDATA%'
	</cfquery>
	<cfquery name = "itemStatsMI" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(distinct f.collection_object_id) lots,
		sum(decode(TOTAL_PARTS, null, 1, TOTAL_PARTS)) specs,
		trunc(sum(decode(dec_lat, null, 0, 1))/count(distinct f.collection_object_id),3)*100 || '%' georeflots,
		trunc(sum(decode(dec_lat, null, 0, TOTAL_PARTS))/sum(decode(TOTAL_PARTS, null, 1, TOTAL_PARTS)),3)*100 || '%' georefspecs
		from flat f, coll_object co where
		collection_cde = '#colls.collection_cde#' and
		F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
		and CO.COLL_OBJECT_ENTERED_DATE < '#datefilter#'
		and (upper(full_taxon_name)  like '%ECHINODERMATA%'
			or upper(full_taxon_name)  like '%BRYOZOA%'
			or upper(full_taxon_name)  like '%CHORDATA%')
	</cfquery>
	<cfquery name = "localityStatsIZ" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(*) locs, sum(decode(dec_lat, null, 0, 1)) georeflocs, trunc(sum(decode(dec_lat, null, 0, 1))/count(*), 3)*100 || '%' percgeoref from
		(select distinct locality_id, dec_lat, dec_long
		from flat f, coll_object co where collection_cde = '#colls.collection_cde#'
		and F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
		and CO.COLL_OBJECT_ENTERED_DATE < '#datefilter#'
		and upper(full_taxon_name) not like '%ECHINODERMATA%'
		and upper(full_taxon_name) not like '%BRYOZOA%'
		and upper(full_taxon_name) not like '%CHORDATA%')
	</cfquery>
	<cfquery name = "localityStatsMI" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(*) locs, sum(decode(dec_lat, null, 0, 1)) georeflocs, trunc(sum(decode(dec_lat, null, 0, 1))/count(*), 3)*100 || '%' percgeoref from
		(select distinct locality_id, dec_lat, dec_long
		from flat f, coll_object co where collection_cde = '#colls.collection_cde#'
		and F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
		and CO.COLL_OBJECT_ENTERED_DATE < '#datefilter#'
		and (upper(full_taxon_name)  like '%ECHINODERMATA%'
			or upper(full_taxon_name)  like '%BRYOZOA%'
			or upper(full_taxon_name)  like '%CHORDATA%'))
	</cfquery>
	<cfquery name = "imageStatsIZ" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(distinct m.media_id) imgs from media m, media_relations mr
		where m.media_id = mr.media_id
		and mr.media_relationship = 'shows cataloged_item'
  		and mr.related_primary_key in
  			(select f.collection_object_id from flat f, coll_object co where collection_cde ='#colls.collection_cde#'
			and F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
			and CO.COLL_OBJECT_ENTERED_DATE < '#datefilter#'
			and upper(full_taxon_name) not like '%ECHINODERMATA%'
			and upper(full_taxon_name) not like '%BRYOZOA%'
			and upper(full_taxon_name) not like '%CHORDATA%')
	</cfquery>
	<cfquery name = "imageStatsMI" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(distinct m.media_id) imgs from media m, media_relations mr
		where m.media_id = mr.media_id
		and mr.media_relationship = 'shows cataloged_item'
  		and mr.related_primary_key in
  			(select f.collection_object_id from flat f, coll_object co where collection_cde ='#colls.collection_cde#'
			and F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
			and CO.COLL_OBJECT_ENTERED_DATE < '#datefilter#'
			and (upper(full_taxon_name)  like '%ECHINODERMATA%'
			or upper(full_taxon_name)  like '%BRYOZOA%'
			or upper(full_taxon_name)  like '%CHORDATA%'))
	</cfquery>
<cfelseif colls.collection_cde EQ 'Ent'>
	<cfquery name = "itemStatsEnt" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(distinct f.collection_object_id) lots,
		sum(decode(TOTAL_PARTS, null, 1, TOTAL_PARTS)) specs,
		trunc(sum(decode(dec_lat, null, 0, 1))/count(distinct f.collection_object_id),3)*100 || '%' georeflots,
		trunc(sum(decode(dec_lat, null, 0, TOTAL_PARTS))/sum(decode(TOTAL_PARTS, null, 1, TOTAL_PARTS)),3)*100 || '%' georefspecs
		from flat f, coll_object co where
		collection_cde = '#colls.collection_cde#' and
		F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
		and CO.COLL_OBJECT_ENTERED_DATE < '#datefilter#'
		and (cat_num_prefix is not null or family <> 'Formicidae')
	</cfquery>
	<cfquery name = "itemStatsAnts" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(distinct f.collection_object_id) lots,
		sum(decode(TOTAL_PARTS, null, 1, TOTAL_PARTS)) specs,
		trunc(sum(decode(dec_lat, null, 0, 1))/count(distinct f.collection_object_id),3)*100 || '%' georeflots,
		trunc(sum(decode(dec_lat, null, 0, TOTAL_PARTS))/sum(decode(TOTAL_PARTS, null, 1, TOTAL_PARTS)),3)*100 || '%' georefspecs
		from flat f, coll_object co where
		collection_cde = '#colls.collection_cde#' and
		F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
		and cat_num_prefix is null
		and family = 'Formicidae'
	</cfquery>
	<cfquery name = "localityStatsEnt" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(*) locs, sum(decode(dec_lat, null, 0, 1)) georeflocs, trunc(sum(decode(dec_lat, null, 0, 1))/count(*), 3)*100 || '%' percgeoref from
		(select distinct locality_id, dec_lat, dec_long
		from flat f, coll_object co where collection_cde = '#colls.collection_cde#'
		and F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
		and CO.COLL_OBJECT_ENTERED_DATE < '#datefilter#'
		and (cat_num_prefix is not null or family <> 'Formicidae'))
	</cfquery>
	<cfquery name = "localityStatsAnts" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(*) locs, sum(decode(dec_lat, null, 0, 1)) georeflocs, trunc(sum(decode(dec_lat, null, 0, 1))/count(*), 3)*100 || '%' percgeoref from
		(select distinct locality_id, dec_lat, dec_long
		from flat f, coll_object co where collection_cde = '#colls.collection_cde#'
		and F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
		and CO.COLL_OBJECT_ENTERED_DATE < '#datefilter#'
		and cat_num_prefix is null
		and family = 'Formicidae')
	</cfquery>
	<cfquery name = "imageStatsEnt" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(distinct m.media_id) imgs from media m, media_relations mr
		where m.media_id = mr.media_id
		and mr.media_relationship = 'shows cataloged_item'
  		and mr.related_primary_key in
  			(select f.collection_object_id from flat f, coll_object co where collection_cde ='#colls.collection_cde#'
			and F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
			and CO.COLL_OBJECT_ENTERED_DATE < '#datefilter#'
			and (cat_num_prefix is not null or family <> 'Formicidae'))
	</cfquery>
	<cfquery name = "imageStatsAnts" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(distinct m.media_id) imgs from media m, media_relations mr
		where m.media_id = mr.media_id
		and mr.media_relationship = 'shows cataloged_item'
  		and mr.related_primary_key in
  			(select f.collection_object_id from flat f, coll_object co where collection_cde ='#colls.collection_cde#'
			and F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
			and CO.COLL_OBJECT_ENTERED_DATE < '#datefilter#'
			and cat_num_prefix is null
			and family = 'Formicidae')
	</cfquery>
<cfelse>
	<cfquery name = "itemStats" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(distinct f.collection_object_id) lots,
		sum(decode(TOTAL_PARTS, null, 1, TOTAL_PARTS)) specs,
		trunc(sum(decode(dec_lat, null, 0, 1))/count(distinct f.collection_object_id),3)*100 || '%' georeflots,
		trunc(sum(decode(dec_lat, null, 0, TOTAL_PARTS))/sum(decode(TOTAL_PARTS, null, 1, TOTAL_PARTS)),3)*100 || '%' georefspecs
		from flat f, coll_object co where
		collection_cde = '#colls.collection_cde#' and
		F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
		and CO.COLL_OBJECT_ENTERED_DATE < '#datefilter#'
	</cfquery>

	<cfquery name = "localityStats" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(*) locs, sum(decode(dec_lat, null, 0, 1)) georeflocs, trunc(sum(decode(dec_lat, null, 0, 1))/count(*), 3)*100 || '%' percgeoref from
		(select distinct locality_id, dec_lat, dec_long
		from flat f, coll_object co where collection_cde = '#colls.collection_cde#'
		and F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
		and CO.COLL_OBJECT_ENTERED_DATE < '#datefilter#')
	</cfquery>

	<cfquery name = "imageStats" datasource="uam_god" cachedwithin="#createtimespan(0,0,60,0)#">
		select count(distinct m.media_id) imgs from media m, media_relations mr
		where m.media_id = mr.media_id
		and mr.media_relationship = 'shows cataloged_item'
  		and mr.related_primary_key in
  			(select f.collection_object_id from flat f, coll_object co where collection_cde ='#colls.collection_cde#'
			and F.COLLECTION_OBJECT_ID = CO.COLLECTION_OBJECT_ID
			and CO.COLL_OBJECT_ENTERED_DATE < '#datefilter#')
	</cfquery>
</cfif>


<cfif colls.collection_cde EQ 'IZ'>
	<H2>#collection# (non MI)</h2>
	<cfloop query="itemStatsIZ">
		## of cataloged items/lots: #lots#<br>
		## of specimens: #specs#<br>
		% of georeferenced cataloged items/lots: #georeflots#<br>
		% of georeferenced specimens: #georefspecs#<br>
	</cfloop>
	<cfloop query="localityStatsIZ">
		## of distinct localities: #locs#<br>
		## of georeferenced localities: #georeflocs#<br>
		% of localities georeferenced: #percgeoref#<br>
	</cfloop>
	<cfloop query="imageStatsIZ">
		## of images of cataloged items: #imgs#
	</cfloop>
	<br>
		<H2>#collection# (MI)</h2>
	<cfloop query="itemStatsMI">
		## of cataloged items/lots: #lots#<br>
		## of specimens: #specs#<br>
		% of georeferenced cataloged items/lots: #georeflots#<br>
		% of georeferenced specimens: #georefspecs#<br>
	</cfloop>
	<cfloop query="localityStatsMI">
		## of distinct localities: #locs#<br>
		## of georeferenced localities: #georeflocs#<br>
		% of localities georeferenced: #percgeoref#<br>
	</cfloop>
	<cfloop query="imageStatsMI">
		## of images of cataloged items: #imgs#
	</cfloop>
	<br>
<cfelseif colls.collection_cde EQ 'Ent'>
	<H2>#collection# (non Ants)</h2>
	<cfloop query="itemStatsEnt">
		## of cataloged items/lots: #lots#<br>
		## of specimens: #specs#<br>
		% of georeferenced cataloged items/lots: #georeflots#<br>
		% of georeferenced specimens: #georefspecs#<br>
	</cfloop>
	<cfloop query="localityStatsEnt">
		## of distinct localities: #locs#<br>
		## of georeferenced localities: #georeflocs#<br>
		% of localities georeferenced: #percgeoref#<br>
	</cfloop>
	<cfloop query="imageStatsEnt">
		## of images of cataloged items: #imgs#
	</cfloop>
	<br>
		<H2>#collection# (Ants)</h2>
	<cfloop query="itemStatsAnts">
		## of cataloged items/lots: #lots#<br>
		## of specimens: #specs#<br>
		% of georeferenced cataloged items/lots: #georeflots#<br>
		% of georeferenced specimens: #georefspecs#<br>
	</cfloop>
	<cfloop query="localityStatsAnts">
		## of distinct localities: #locs#<br>
		## of georeferenced localities: #georeflocs#<br>
		% of localities georeferenced: #percgeoref#<br>
	</cfloop>
	<cfloop query="imageStatsAnts">
		## of images of cataloged items: #imgs#
	</cfloop>
	<br>
<cfelse>
<H2>#collection#</h2>
	<cfloop query="itemStats">
		## of cataloged items/lots: #lots#<br>
		## of specimens: #specs#<br>
		% of georeferenced cataloged items/lots: #georeflots#<br>
		% of georeferenced specimens: #georefspecs#<br>
	</cfloop>
	<cfloop query="localityStats">
		## of distinct localities: #locs#<br>
		## of georeferenced localities: #georeflocs#<br>
		% of localities georeferenced: #percgeoref#<br>
	</cfloop>
	<cfloop query="imageStats">
		## of images of cataloged items: #imgs#
	</cfloop>
	<br>
</cfif>
</cfloop>
</cfoutput>
<br><br>
<cfinclude template = "/includes/_footer.cfm">