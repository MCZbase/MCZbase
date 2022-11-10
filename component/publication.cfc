<cfcomponent>
<!--- TODO:  Replace this code with stored procedures and assemble short/long citations directly in the backend database.  --->
<cffunction name="shortCitation" access="remote">
  <cfargument name="publication_id" type="numeric" required="yes">
  <cfquery name="p" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select published_year from publication where publication_id=#publication_id#
	</cfquery>
  <cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select
			nvl(last_name,agent_name) as last_name,
			author_position
		from
			publication_author_name,
			agent_name,
			person
		where
			publication_author_name.agent_name_id=agent_name.agent_name_id and
			agent_name.agent_id=person.person_id(+) and
			publication_author_name.publication_id=#publication_id# and
            publication_author_name.author_role ='author'
		order by
			author_position
	</cfquery>
  <cfquery name="f" dbtype="query">
		select count(*) c from a where last_name is null
	</cfquery>
  <cfif f.c gt 0>
    <cfquery name="p" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
			select SUBSTR(publication_title,1,20) || '...' pt from publication where publication_id=#publication_id#
		</cfquery>
    <cfreturn p.pt>
  </cfif>
  <cfquery name="atts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from publication_attributes where publication_id=#publication_id#
	</cfquery>
  <cfquery name="publishedYearRange" dbtype="query">
		select pub_att_value from atts where publication_attribute='published year range'
  </cfquery>
  <cfset publicationYear = "">
  <cfif publishedYearRange.recordcount EQ 1>
		<cfset publicationYear = publishedYearRange.pub_att_value>
  <cfelse>
		<cfif len(p.published_year) GT 0>
			<cfset publicationYear = "#p.published_year#">
		</cfif>
  </cfif>
  <cfif a.recordcount is 1>
    <cfset as=a.last_name>
  <cfelseif a.recordcount is 2>
    <cfset as=a.last_name[1] & ' and ' & a.last_name[2]>
  <cfelse>
    <cfset as=a.last_name[1] & ' et al.'>
  </cfif>
  <cfset r=as & ' ' & publicationYear>
  <cfreturn r>
</cffunction>
<!------------------------------------------------------------------------------------------------>
<cffunction name="longCitation" access="remote" output="true">
  <cfargument name="publication_id" type="numeric" required="yes">
  <cfquery name="p" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select
			publication_title,
			published_year,
			publication_type,
      doi
		from publication where publication_id=#publication_id#
	</cfquery>
  <cfquery name="a" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select
			agent_name,
			author_position
		from
			publication_author_name,
			agent_name
		where
			publication_author_name.agent_name_id=agent_name.agent_name_id and
			publication_author_name.publication_id=#publication_id# and
			author_role='author'
		order by
			author_position
	</cfquery>
  <cfquery name="e" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select
			agent_name,
			author_position
		from
			publication_author_name,
			agent_name
		where
			publication_author_name.agent_name_id=agent_name.agent_name_id and
			publication_author_name.publication_id=#publication_id# and
			publication_author_name.author_role='editor'
		order by
			author_position
	</cfquery>
 <cfset as="">
  <cfset es="">
  <cfif a.recordcount is 1>
    <cfset as=a.agent_name>
    <cfelseif a.recordcount is 2>
    <cfset as=a.agent_name[1] & ' and ' & a.agent_name[2]>
     <cfelseif a.recordcount is 3>
    <cfset as=a.agent_name[1] & ', ' & a.agent_name[2] & ', and ' & a.agent_name[3]>
    <cfelseif a.recordcount is 4>
    <cfset as=a.agent_name[1] & ', ' & a.agent_name[2] & ', ' & a.agent_name[3] & ', and ' & a.agent_name[4]>
    <cfelse>
    <cfset as=valuelist(a.agent_name,", ")>
  </cfif>
  <cfif right(as,1) is '.'>
    <cfset as=left(as,len(as)-1)>
  </cfif>
  <cfif e.recordcount is 1>
    <cfset es=e.agent_name>
    <cfelseif e.recordcount is 2>
    <cfset es=e.agent_name[1] & ' and ' & e.agent_name[2]>
     <cfelseif e.recordcount is 3>
    <cfset es=e.agent_name[1] & ', ' & e.agent_name[2] & ', and ' & e.agent_name[3]>
    <cfelseif e.recordcount is 4>
    <cfset es=e.agent_name[1] & ', ' & e.agent_name[2] & ', ' & e.agent_name[3] & ', and ' & e.agent_name[4]>
    <cfelseif e.recordcount gt 4>
    <cfset es=e.agent_name[1] & ', ' & e.agent_name[2] & ', ' & e.agent_name[3] & ', ' & e.agent_name[4] & ' <i>et al.</i>'>
    <cfelse>
    <cfset es=valuelist(e.agent_name,", ")>
  </cfif>
  <cfif right(es,1) is '.'>
    <cfset es=left(es,len(es)-1)>
  </cfif>
  <cfquery name="atts" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
		select * from publication_attributes where publication_id=#publication_id#
	</cfquery>
  <cfquery name="publishedYearRange" dbtype="query">
		select pub_att_value from atts where publication_attribute='published year range'
  </cfquery>
  <cfset publicationYear = "">
  <cfif publishedYearRange.recordcount EQ 1>
	<cfset publicationYear = publishedYearRange.pub_att_value>
  <cfelse>
	<cfif len(p.published_year) GT 0>
		<cfset publicationYear = "#p.published_year#">
	</cfif>
  </cfif>
  <cfquery name="journal" dbtype="query">
		select pub_att_value from atts where publication_attribute='journal name'
	</cfquery>
  <cfquery name="journalsection" dbtype="query">
		select pub_att_value from atts where publication_attribute='journal section'
	</cfquery>
  <cfquery name="issue" dbtype="query">
		select pub_att_value from atts where publication_attribute='issue'
	</cfquery>
  <cfquery name="series" dbtype="query">
		select pub_att_value from atts where publication_attribute='series'
	</cfquery>
  <cfquery name="volume" dbtype="query">
		select pub_att_value from atts where publication_attribute='volume'
	</cfquery>
  <cfquery name="book_title" dbtype="query">
		select pub_att_value from atts where publication_attribute='book title'
	</cfquery>
  <cfquery name="begin" dbtype="query">
		select pub_att_value from atts where publication_attribute='begin page'
	</cfquery>
  <cfquery name="end" dbtype="query">
		select pub_att_value from atts where publication_attribute='end page'
	</cfquery>
  <cfquery name="publisher" dbtype="query">
		select pub_att_value from atts where publication_attribute='publisher'
	</cfquery>
  <cfquery name="alternate" dbtype="query">
		select pub_att_value from atts where publication_attribute='alternate journal name'
	</cfquery>
  <cfquery name="part" dbtype="query">
		select pub_att_value from atts where publication_attribute='part'
	</cfquery>
  <cfquery name="supplement" dbtype="query">
		select pub_att_value from atts where publication_attribute='supplement'
	</cfquery>
  <cfquery name="number" dbtype="query">
		select pub_att_value from atts where publication_attribute='number'
	</cfquery>
  <cfquery name="version" dbtype="query">
		select pub_att_value from atts where publication_attribute='version'
	</cfquery>
  <cfquery name="pagetotal" dbtype="query">
		select pub_att_value from atts where publication_attribute='page total'
	</cfquery>
      <cfquery name="translation" dbtype="query">
		select pub_att_value from atts where publication_attribute='translation'
	</cfquery>
  <cfquery name="edition" dbtype="query">
		select pub_att_value from atts where publication_attribute='edition'
	</cfquery>

  <cfquery name="bookauthor" dbtype="query">
		select pub_att_value from atts where publication_attribute='book author (book section)'
	</cfquery>



<!--- Begin Journal Article--->
  <cfif p.publication_type is "journal article">
       <cfif right(p.publication_title,1) is not '.' and right(p.publication_title,1) is not '?' and right(p.publication_title,1) is not ','>
    <cfset publication_title=p.publication_title & '. '>
    <cfelse>
    <cfset publication_title=p.publication_title>
  </cfif>
  <cfset r=as & '. '>
  <cfif len(publicationYear) gt 0>
    <cfset r=r & publicationYear & '. '>
    </cfif>
    <cfset r=r & publication_title>
    <cfset r=r & ' ' & journal.pub_att_value & ''>
    <cfif len(translation.pub_att_value) gt 0>
    <cfset r=r & '[' & translation.pub_att_value & ']'>
    </cfif>
    <cfif len(series.pub_att_value) gt 0>
      <cfset r=r & ', Series ' & series.pub_att_value & ','>
    </cfif>
    <cfif len(part.pub_att_value) gt 0>
    	<cfset r=r & ' Part ' & part.pub_att_value & ', '>
        </cfif>
    <cfif len(volume.pub_att_value) gt 0>
      <cfset r=r & ' ' & volume.pub_att_value>
    </cfif>
    <cfif len(number.pub_att_value) gt 0 and len(volume.pub_att_value) eq 0>
    	<cfset r=r & ' ' & number.pub_att_value>
     <cfelseif len(number.pub_att_value) gt 0>
      <cfset r=r & '(' & number.pub_att_value & ')'>
      <cfelse>
       <cfset r=r & number.pub_att_value >
    </cfif>
     <cfif len(issue.pub_att_value) gt 0 and len(volume.pub_att_value) eq 0>
    	<cfset r=r & ' ' & issue.pub_att_value>
     <cfelseif len(issue.pub_att_value) gt 0>
      <cfset r=r & '(' & issue.pub_att_value & ')'>
      <cfelse>
       <cfset r=r &  issue.pub_att_value>
    </cfif>
    <cfif begin.pub_att_value is not end.pub_att_value>
      <cfset r=r & ':' & 	begin.pub_att_value & '&ndash;' & end.pub_att_value & '. '>
    </cfif>
    <cfif begin.pub_att_value eq end.pub_att_value>
      <cfset r=r & ': ' & 	begin.pub_att_value &  '. '>
    </cfif>
     <cfif len(supplement.pub_att_value) gt 0>
      <cfset r=r & ' Supplement ' & supplement.pub_att_value &  '.'>
    </cfif>
    <cfif len(p.doi) gt 0>
      <cfset r=r &  ' doi: ' & p.doi & '.'>
    </cfif>

<!--- End Journal Article--->


<!--- Begin Journal Section--->
       <cfelseif p.publication_type is "journal section">
    <cfset r=as & '. ' & publicationYear & '. ' & publication_title & ', ' >
    <cfif len(journalsection.pub_att_value) gt 0>
      <cfset r=r & ' <i>In</i> ' & es>
      <cfif e.recordcount gt 1>
        <cfset r=r & '., (eds.) '>
        <cfelseif e.recordcount eq 1>
        <cfset r=r & '., (ed.) '>
        <cfelse>
        <cfset r=r & ''>
      </cfif>
      <cfset r=r &  journalsection.pub_att_value & '.' >
      <cfset r=r &  ' '& journal.pub_att_value & ' '>

        <cfif len(series.pub_att_value) gt 0>
        <cfset r=r & ' Series ' & series.pub_att_value & ','>
      </cfif>
     <cfif len(volume.pub_att_value) gt 0>
      <cfset r=r & ' ' & volume.pub_att_value>
    </cfif>
    <cfif len(number.pub_att_value) gt 0 and len(volume.pub_att_value) eq 0>
    	<cfset r=r & ' ' & number.pub_att_value>
     <cfelseif len(number.pub_att_value) gt 0>
      <cfset r=r & '(' & number.pub_att_value & ')'>
      <cfelse>
       <cfset r=r & number.pub_att_value >
    </cfif>
     <cfif len(issue.pub_att_value) gt 0 and len(volume.pub_att_value) eq 0>
    	<cfset r=r & ' No. ' & issue.pub_att_value>
     <cfelseif len(issue.pub_att_value) gt 0>
      <cfset r=r & '(' & issue.pub_att_value & ')'>
      <cfelse>
       <cfset r=r &  issue.pub_att_value>
    </cfif>
     <cfif len(supplement.pub_att_value) gt 0>
      <cfset r=r & ' Supplement ' & supplement.pub_att_value>
    </cfif>
      <cfset r=r & ':' & 	begin.pub_att_value & '-' & end.pub_att_value & ''>
      <cfset r=r & '.'>
    </cfif>
    <cfif len(p.doi) gt 0>
      <cfset r=r &  ' doi: ' & p.doi & '.'>
    </cfif>
  <!--- End Journal Section--->
  <!--- Begin Special Publication Series (generalized as a serial monographic work) --->
        <cfelseif p.publication_type is "serial monograph">
       <cfif right(p.publication_title,1) is not '.' and right(p.publication_title,1) is not '?' and right(p.publication_title,1) is not ','>
    <cfset publication_title=p.publication_title & '. '>
    <cfelse>
    <cfset publication_title=p.publication_title>
  </cfif>
  <cfset r=as & '. '>
  <cfif len(publicationYear) gt 0>
    <cfset r=r & publicationYear & '.  '>
    </cfif>
    <cfset r=r & publication_title>
    <cfif len(journal.pub_att_value) gt 0>
    <cfset r=r & ' ' & journal.pub_att_value & ', '>
    </cfif>
    <cfif len(series.pub_att_value) gt 0>
      <cfset r=r & ' ' & series.pub_att_value & ','>
    </cfif>

    <cfif len(volume.pub_att_value) gt 0 and len(part.pub_att_value) eq 0>
      <cfset r=r & ' Vol. ' & volume.pub_att_value & '.'>
    </cfif>
        <cfif len(volume.pub_att_value) gt 0 and len(part.pub_att_value) gt 0>
      <cfset r=r & ' Vol. ' & volume.pub_att_value & ', '>
    </cfif>
     <cfif len(part.pub_att_value) gt 0 and right(part.pub_att_value,1) is not '.'>
    	<cfset r=r & 'Part ' & part.pub_att_value & '.'>
        </cfif>
        <cfif right(part.pub_att_value,1) is '.'>
    <cfset part.pub_att_value=left(part.pub_att_value,len(part.pub_att_value)-1)>
  </cfif>

    <cfif len(number.pub_att_value) gt 0 and len(volume.pub_att_value) eq 0>
    	<cfset r=r & ' no. ' & number.pub_att_value & '. '>
     <cfelseif len(number.pub_att_value) gt 0>
      <cfset r=r & '(' & number.pub_att_value & ')'>
      <cfelseif len(number.pub_att_value) gt 0 and len(volume.put_att_value) gt 0>
      <cfset r=r & '(' & number.pub_att_value & ')'>
      <cfset number.pub_att_value=left(number.pub_att_value,len(number.pub_att_value)-1)>
      <cfelse>
       <cfset r=r & number.pub_att_value >
    </cfif>
     <cfif len(issue.pub_att_value) gt 0 and len(volume.pub_att_value) gt 0>
    	<cfset r=r & ' issue ' & issue.pub_att_value>
     <cfelseif len(issue.pub_att_value) gt 0>
      <cfset r=r & '(' & issue.pub_att_value & ')'>
      <cfelse>
       <cfset r=r & issue.pub_att_value>
    </cfif>
      <cfif len(supplement.pub_att_value) gt 0 and right(supplement.pub_att_value,1) is not '.'>
      <cfset r=r &  ' ' & supplement.pub_att_value & '.'>
    </cfif>
      <cfif len(publisher.pub_att_value) gt 0>
      <cfset r=r &  ' ' & publisher.pub_att_value & '.'>
    </cfif>
    <cfif begin.pub_att_value is not end.pub_att_value>
      <cfset r=r & ' p. ' & 	begin.pub_att_value & '&ndash;' & end.pub_att_value & '. '>
    </cfif>
    <cfif begin.pub_att_value eq end.pub_att_value>
      <cfset r=r & ' p. ' & 	begin.pub_att_value &  '. '>
    </cfif>
    <cfif len(p.doi) gt 0>
      <cfset r=r &  ' doi: ' & p.doi & '.'>
    </cfif>
  <!--- End Special Publication Series--->


  <!--- Begin Data Release --->
        <cfelseif p.publication_type is "data release">
       <cfif right(p.publication_title,1) is not '.' and right(p.publication_title,1) is not '?' and right(p.publication_title,1) is not ','>
    <cfset publication_title=p.publication_title & '. '>
    <cfelse>
    <cfset publication_title=p.publication_title>
  </cfif>
  <cfset r=as & '. '>
  <cfif len(publicationYear) gt 0>
    <cfset r=r & publicationYear & '.  '>
    </cfif>
    <cfset r=r & publication_title>
    <cfif len(p.doi) gt 0>
      <cfset r=r & ' doi: ' & p.doi & ''>
    </cfif>
      <cfif len(publisher.pub_att_value) gt 0>
      <cfset r=r &  ', ' & publisher.pub_att_value & ''>
    </cfif>
    <cfif len(version.pub_att_value) gt 0>
      <cfset r=r & ', ' & version.pub_att_value & '. '>
    </cfif>
  <!--- End Data Release--->

   <!--- Begin Annual Report--->
    <cfelseif p.publication_type is "annual report">
    <cfset r=as & '. ' & publicationYear & '. ' & publication_title & ', ' >
    <cfif len(journal.pub_att_value) gt 0>
	<cfset r=r & ' <i>' & journal.pub_att_value & '.</i>'>
    </cfif>
    <cfif len(number.pub_att_value) gt 0>
      <cfset r=r & ' no. ' & number.pub_att_value & '.'>
      </cfif>
 		<cfset r=r &  ' ' & publisher.pub_att_value & '.'>
    <cfif len(p.doi) gt 0>
      <cfset r=r &  ' doi: ' & p.doi & '.'>
    </cfif>
   <!--- End Annual Report--->
         <!--- Begin Newsletter--->
       <cfelseif p.publication_type is "newsletter">
    <cfset r=as & '. ' & publicationYear & '. ' & publication_title & ' ' >
     <cfif len(volume.pub_att_value) gt 0>
      <cfset r=r & ' ' & volume.pub_att_value & ''>
    </cfif>
 	 <cfif len(number.pub_att_value) gt 0 & len(volume.pub_att_value) lt 0>
    	<cfset r=r & ' No. ' & number.pub_att_value & '.'>
     <cfelseif len(number.pub_att_value) gt 0 and len(volume.pub_att_value) gt 0>
      <cfset r=r & '(' & number.pub_att_value & ')'>
      <cfelse>
       <cfset r=r & number.pub_att_value >
    </cfif>
     <cfif len(issue.pub_att_value) gt 0 and len(volume.pub_att_value) eq 0>
    	<cfset r=r & ' No. ' & issue.pub_att_value>
     <cfelseif len(issue.pub_att_value) gt 0>
      <cfset r=r & '(' & issue.pub_att_value & ')'>
      <cfelse>
       <cfset r=r &  issue.pub_att_value>
    </cfif>
     <cfset r=r & ': ' & begin.pub_att_value & '-' & end.pub_att_value & '.'>
     <cfif len(p.doi) gt 0>
       <cfset r=r &  ' doi: ' & p.doi & '.'>
     </cfif>

      <!--- End Newsletter--->

     <!--- Begin Book--->
     <cfelseif p.publication_type is "book">
       <cfif right(p.publication_title,1) is not '.' and right(p.publication_title,1) is not '?' and right(p.publication_title,1) is not ','>
    <cfset publication_title=p.publication_title & '.'>
    <cfelse>
    <cfset publication_title=p.publication_title>
  </cfif>
  <cfset publication_title=replace(publication_title,' In: ',' <i>In:</i> ')>
    <cfset r=as & '. ' & publicationYear & '. '>
    <cfif e.recordcount gt 1>
      <cfset editor = ', Eds. ' >
      <cfset r=r & es & editor >
      <cfelseif e.recordcount eq 1>
      <cfset editor = ', Ed. ' >
      <cfset r=r & es & editor >
      <cfelse>
      <cfset r=r & es >
    </cfif>
    <cfset r=r & '<i>' & publication_title & '</i> '>
    <cfif len(volume.pub_att_value) gt 0 and len(part.pub_att_value) gt 0>
      <cfset r=r & ' Vol. ' & volume.pub_att_value & ', Part ' & part.pub_att_value & '. '>
      <cfelseif len(volume.pub_att_value) gt 0>
      <cfset r=r & ' Vol. ' & volume.pub_att_value & '.'>
      <cfelse>
      <cfset r=r & ' ' & volume.pub_att_value>
    </cfif>
   <!--- <cfif len(part.pub_att_value) gt 0>
      <cfset r=r &  'Part ' & part.pub_att_value & '' & '.' >
    </cfif>--->
    <cfif len(supplement.pub_att_value) gt 0>
		<cfset r=r &  ' Supplement ' & supplement.pub_att_value & '' & '.' >
    </cfif>
    <cfif len(series.pub_att_value) gt 0>
      <cfset r=r &  '(Series ' & series.pub_att_value & ')' & '.' >
    </cfif>
        <cfif len(edition.pub_att_value) gt 0 and right(edition.pub_att_value,1) is not '.'>
      <cfset r=r &  ' ' & edition.pub_att_value & ' edition.' >
      <cfelse>
      <cfset r=r &  ' ' & edition.pub_att_value & ' ' >
      </cfif>
    <cfif len(publisher.pub_att_value gt 0)>
      <cfset r=r &  ' ' & publisher.pub_att_value & '.'>
    </cfif>
   <cfif len(pagetotal.pub_att_value) gt 0>
     <cfset r=r &  ' ' & pagetotal.pub_att_value & ' pp.'>
     </cfif>
     <cfif len(p.doi) gt 0>
       <cfset r=r &  ' doi: ' & p.doi & '.'>
     </cfif>
      <!--- End Book--->


     <!--- Begin Book Section--->
	<cfelseif p.publication_type is "book section">
      <cfif right(p.publication_title,1) is not '.' and right(p.publication_title,1) is not '?' and right(p.publication_title,1) is not ','>
         <cfset publication_title=p.publication_title & '.'>
      <cfelse>
         <cfset publication_title=p.publication_title>
      </cfif>
      <cfset r=as & '. ' & publicationYear & '. ' & publication_title & ' '>
    <cfset r=r & ' Pp. ' & 	begin.pub_att_value & '-' & end.pub_att_value & '. '>
    <cfif len(book_title.pub_att_value) gt 0>
       <cfset enclosingTitle = book_title.pub_att_value>
    </cfif>
    <cfif isDefined("enclosingTitle") AND len(enclosingTitle) gt 0>
      <cfset r=r & ' <i>In</i> '>
      <cfif e.recordcount gt 1>
        <cfset editor = '. (eds.)' >
        <cfset r=r & es & editor >
        <cfelseif e.recordcount eq 1>
        <cfset editor = '. (ed.)' >
        <cfset r=r & es & editor >
        <cfelse>
        <cfset r=r & es >
      </cfif>
      <cfif len(bookauthor.pub_att_value) gt 0>
        <cfset r=r &  ' ' & bookauthor.pub_att_value & ''>
      </cfif>
      <cfset r=r &  ' <i>'& enclosingTitle & '.</i> '>
      <cfif len(edition.pub_att_value) gt 0 and right(edition.pub_att_value,1) is not '.'>
      <cfset r=r &  ' ' & edition.pub_att_value & ' edition.' >
      <cfelse>
      <cfset r=r &  ' ' & edition.pub_att_value & ' ' >
      </cfif>
       <cfif len(volume.pub_att_value) gt 0 and len(part.pub_att_value) gt 0>
      <cfset r=r & 'Vol. ' & volume.pub_att_value & ', Part ' & part.pub_att_value & '. '>
      <cfelseif len(volume.pub_att_value) gt 0 and len(part.pub_att_value) eq 0>
      <cfset r=r & 'Vol. ' & volume.pub_att_value & '. '>
      <cfelse>
      <cfset r=r & ' ' & volume.pub_att_value &''>
    </cfif>
    <cfif len(part.pub_att_value) gt 0 and len(volume.pub_att_value) eq 0>
      <cfset r=r &  ' Part ' & part.pub_att_value & '. ' >
    </cfif>

          <cfif right(publisher.pub_att_value,1) is '.'>
    <cfset publisher.pub_att_value=left(publisher.pub_att_value,len(publisher.pub_att_value)-1)>
  </cfif>

      <cfif len(publisher.pub_att_value) gt 0>
        <cfset r=r  & publisher.pub_att_value & '.' >
      </cfif>
    </cfif>
   <cfif len(pagetotal.pub_att_value) gt 0>
     <cfset r=r &  ' ' & pagetotal.pub_att_value & ' pp.'>
     </cfif>
     <cfif len(p.doi) gt 0>
       <cfset r=r &  ' doi: ' & p.doi & '.'>
     </cfif>
  <!--- End Book Section--->


   <cfif right(p.publication_title,1) is not '.' and right(p.publication_title,1) is not '?' and right(p.publication_title,1) is not ','>
    <cfset publication_title=p.publication_title & '.'>
    <cfelse>
    <cfset publication_title=p.publication_title>
  </cfif>
  <cfset publication_title=replace(publication_title,' In: ',' <i>In:</i> ')>

    <cfelse>
    <cfset r=as>
    <cfif len(publicationYear) gt 0>
      <cfset r=r & '. ' & publicationYear>
    </cfif>
    <cfset r=r & '. ' & publication_title & '.'>
  </cfif>
  <cfif len(r) is 0>
    <cfset r="unknown format">
  </cfif>
  <cfreturn r>
</cffunction>
</cfcomponent>
