<cfset pageTitle = "Search Specimen | Basic">
<cfinclude template = "/shared/_header.cfm">
	
<cfset defaultSelectionMode = "none">
<cfif defaultSelectionMode EQ "none">
	<cfset defaultenablebrowserselection = "true">
<cfelse>
	<cfset defaultenablebrowserselection = "false">
</cfif>	

<cfif isdefined("session.roles") and listfindnocase(session.roles,"coldfusion_user")>
	<cfset oneOfUs = 1>
<cfelse>
	<cfset oneOfUs = 0>
</cfif>
  <div id="fixedsearchResultsGrid"></div>
  <script>
    var data = [
      { name: 'Alice', action: '<a href="#">Link</a>' },
      { name: 'Bob',   action: '<a href="#">Link</a>' }
    ];
    var source = {
      datatype: "array",
      localdata: data,
      datafields: [
        { name: 'name', type: 'string'},
        { name: 'action', type: 'string'}
      ]
    };
    var dataAdapter = new $.jqx.dataAdapter(source);

    $('#fixedsearchResultsGrid').jqxGrid({
      width: 400,
      autoheight: true,
      source: dataAdapter,
      columns: [
        { text: 'Name', datafield: 'name', width: 150 },
        { text: 'Action', datafield: 'action', width: 150, cellsrenderer: function(row, columnfield, value) { return value; } }
      ],
      selectionmode: 'singlecell',
      keyboardnavigation: true
    });

    // Ensure tabindex for focusing
    $('#fixedsearchResultsGrid').attr('tabindex', 0);

    $('#fixedsearchResultsGrid').on('bindingcomplete', function() {
      setTimeout(function() {
        var columns = $('#fixedsearchResultsGrid').jqxGrid('columns').records;
        if (columns.length) {
          $('#fixedsearchResultsGrid').jqxGrid('selectcell', 0, columns[0].datafield);
          $('#fixedsearchResultsGrid').focus();
        }
      }, 100);
    });
  </script>
  <p>Tab into the grid with your keyboard, and use arrow keys.</p>
</body>
</html>