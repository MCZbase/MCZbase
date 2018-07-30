<cfquery name="getPermitMedia" datasource="user_login" username="#session.dbuser#" password="#decrypt(session.epw,cfid)#">
        select distinct media_id, uri, permit_type, permit_num from (
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
                and (media_relations.related_primary_key is null
                or (media_relations.media_relationship = 'shows permit'
                    and mime_type = 'application/pdf'))
                and media_id is not null
        union
                select media.media_id, media.media_uri as uri, p.permit_type, p.permit_num
           from shipment s
           left join permit_shipment ps on s.shipment_id = ps.shipment_id
           left join permit p on ps.permit_id = p.permit_id
           left join media_relations on p.permit_id = media_relations.related_primary_key
           left join media on media_relations.media_id = media.media_id
                where s.transaction_id = <cfqueryparam CFSQLType="CF_SQL_DECIMAL" value="#transaction_id#">
                and (media_relations.related_primary_key is null
                or (media_relations.media_relationship = 'shows permit'
                    and mime_type = 'application/pdf'))
        ) where permit_type is not null
                and media_id is not null
</cfquery>

<cfset mergeUtility = CreateObject("java","org.apache.pdfbox.multipdf.PDFMergerUtility") >
<cfset fileProxy = CreateObject("java","java.io.File") >
<cfset downloadFile = "permits_#session.DownloadFileID#.pdf">
<cfset downloadTarget = "#Application.DownloadPath#/#downloadFile#">
<cfloop query="getPermitMedia">
    <cfset targetFile = fileProxy.init(#uri#) >
    <cfscript>mergeUtility.addSource(targetFile);</cfscript>
</cfloop>
<cfscript>
    mergeUtility.addDestinationFileName(downloadTarget);
    mergeUtility.mergeDocuments();
</cfscript>

<cfheader name="Content-Disposition" value="attachmeht; filename=/downloads/#downloadFile#" >
<cfcontent file="downloads/#downloadFile#" type="application/pdf" deleteFile="yes" >
