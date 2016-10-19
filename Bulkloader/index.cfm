<cfinclude template="/includes/_header.cfm">
    <div class="BulkSpec">
<h2 class="wikilink">Bulkload Specimens <img src="/images/info_i_2.gif" onClick="getMCZDocs('Bulk_Upload_a_Spreadsheet_with_multiple_specimen_records')" class="likeLink" alt="[ help ]">
		</h2>

<!---There are 2 online methods by which you may bulkload specimens. --->
<ul>
	<li>
        The <span style="font-weight:bold"><a href="/Bulkloader/BulkloadSpecimens.cfm">INSERT-based-Bulkload-Specimens Application</a></span>
		 will handle about 1000 records. <!---This application
		is entirely ColdFusion, and is generally more stable and easier to debug
		than the SQLLDR application. It accepts CSV files. We highly recommend
		it's usage when possible.--->
	</li>
	<!---li>
		The <a href="/Bulkloader/bulkloaderLoader.cfm">SQLLDR-based application</a>
		 will theoretically handle any number of records,
		and calls an Oracle application to insert a text file into the bulkloader table.
		Practical use is limited by your upload speed and serverside preprocessing time.
		This method can be used for ca. 10,000 records on a good connection. It's also very picky,
		potentially hard to debug, requires tab-delimited text files,
		and can have issues with non-ASCII characters when called from
		Web application.
	</li--->
	<li>
		Large datasets may be impossible to load without DBA assistance due to network speeds and timeout
		settings, and your browser's ability to handle very large text files. Contact a DBA if you're having
		trouble with the above methods.
	</li>
</ul>
<br>
<br>
<h3>Other Links</h3>
        <p>You may create your own templates with the <a href="/Bulkloader/bulkloaderBuilder.cfm">Bulkloader Builder</a>.     Select the required fields to have the most basic bulkloader spreadsheet or use one of the templates from the <a href="https://code.mcz.harvard.edu/wiki/index.php/Bulkloader_Templates">MCZbase Wiki Page</a>.</p>

<p>Use <a href="/Bulkloader/bulkloader_status.cfm">Bulkloader Status</a> to see what's made it to the
bulkloader but not yet to MCZbase</p>

<p>Some additional documentation can be found on the <a href="https://code.mcz.harvard.edu/wiki/index.php/Upload_Records_to_MCZbase">MCZbase Wiki</a>
</p>
    </div>
<cfinclude template="/includes/_footer.cfm">