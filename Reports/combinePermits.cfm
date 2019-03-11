<cfquery name="getPermitMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        select distinct media_id, uri, permit_type, permit_num 
        from (
           select media.media_id, media.media_uri as uri, p.permit_type, p.permit_num
           from loan_item li
                left join specimen_part sp on li.collection_object_id = sp.collection_object_id
                left join cataloged_item ci on sp.derived_from_cat_item = ci.collection_object_id
                left join accn on ci.accn_id = accn.transaction_id
                left join permit_trans on accn.transaction_id = permit_trans.transaction_id
                left join permit p on permit_trans.permit_id = p.permit_id
                left join media_relations on p.permit_id = media_relations.related_primary_key
                left join media on media_relations.media_id = media.media_id
           where li.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
                and (
                    media_relations.related_primary_key is null
                    or (media_relations.media_relationship = 'shows permit' and mime_type = 'application/pdf')
                )
                and media.media_id is not null
         union
           select media.media_id, media.media_uri as uri, p.permit_type, p.permit_num
           from shipment s
                left join permit_shipment ps on s.shipment_id = ps.shipment_id
                left join permit p on ps.permit_id = p.permit_id
                left join media_relations on p.permit_id = media_relations.related_primary_key
                left join media on media_relations.media_id = media.media_id
           where s.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
                and (
                   media_relations.related_primary_key is null
                   or (media_relations.media_relationship = 'shows permit' and mime_type = 'application/pdf')
                )
        )
        where permit_type is not null
             and media_id is not null
</cfquery>
<!--- Note on names: --->
<!--- see: https://www.bennadel.com/blog/1483-strange-coldfusion-urldecode-and-getencoding-behavior.htm --->
<!--- variable named url will be a coldfusion.filter.UrlScope object, not a java.net.URL object --->

<!--- create (coldfusion proxy instances over) instances of java objects to work with --->
<!--- See: https://www.bennadel.com/blog/737-how-coldfusion-createobject-really-works-with-java-objects.htm --->
<cfset mergeUtility = CreateObject("java","org.apache.pdfbox.multipdf.PDFMergerUtility") >
<cfset fileProxy = CreateObject("java","java.io.File") >
<cfset urlProxy = CreateObject("java","java.net.URL") >
<!--- we don't need an instance of FileUtils, using static method only.--->
<!--- coldfusion includes an older FileUtils class, added library isn't used, so not all methods are available --->
<cfobject type="Java" name="fileUtilsProxy"  class="org.apache.commons.io.FileUtils" >
<!--- We don't need an instance of HttpClients, using static factory method only.  --->
<!--- Use cfobject to obtain instance of coldfusion proxy over class --->
<cfobject type="Java" name="httpClientsProxy"  class="org.apache.http.impl.client.HttpClients" >
<cfset httpGetProxy = CreateObject("java","org.apache.http.client.methods.HttpGet") >
<cfset httpClient = httpClientsProxy.createDefault() >
<cfset downloadFile = "permits_#session.DownloadFileID#.pdf">
<cfset downloadTarget = "#Application.DownloadPath#/#downloadFile#">
<cfset n=0>
<cfloop query="getPermitMedia">
    <cfset n=n+1 >
    <cfset tempTarget = "#Application.DownloadPath#/temp#n#_#downloadFile#" >
    <cfset tempFile = fileProxy.init(JavaCast("string",#tempTarget#)) >
    <cfset httpGet = httpGetProxy.init(JavaCast("string",#uri#))>
    <cfset httpResponse = httpClient.execute(#httpGet#) >
    <cfset fileEntity = httpResponse.getEntity() >
    <cfif not isNull(fileEntity) >
        <cfset tempFileOS = CreateObject("java","java.io.FileOutputStream").Init(#tempFile#) >
        <!--- fileUtils.copyInputStreamToFile isn't available --->
        <cfscript>
           fileEntity.writeTo(#tempFileOS#);
           mergeUtility.addSource(#tempFile#);
        </cfscript>
    </cfif>
    <cfscript>
           httpGet.releaseConnection();
    </cfscript>
</cfloop>
<cfscript>
    mergeUtility.setDestinationFileName(JavaCast("string",#downloadTarget#));
    mergeUtility.mergeDocuments(); 
</cfscript>
<!--- cleanup temporary files --->
<cfset n=0>
<cfloop query="getPermitMedia">
    <cfset n=n+1 >
    <cfset tempTarget = "#Application.DownloadPath#/temp#n#_#downloadFile#" >
    <cfset tempFile = fileProxy.init(JavaCast("string",#tempTarget#)) >
    <cfscript>
           tempFile.delete();
    </cfscript>
</cfloop>

<cfheader name="Content-Disposition" value="attachment; filename=#downloadFile#" >
<cfcontent file="#downloadTarget#" type="application/pdf" deleteFile="yes" >
