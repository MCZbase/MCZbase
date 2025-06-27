<cfinclude template = "/shared/_header.cfm">
<cfset detailscol = "{text: '', datafield: 'action', width: 40, cellsrenderer: function(row, columnfield, value, defaulthtml, columnproperties, rowdata) { return '<button type=\'button\' class=\'details-btn\' tabindex=\'0\' aria-label=\'Show details\' data-row=\'' + row + '\'>&#8230;</button>'; }, editable: false, hidable: false, hidden: false }," >
	<div id="fixedsearchResultsGrid"></div>
<script>
$('#fixedsearchResultsGrid').jqxGrid({
    width: 700,
    autoheight: true,
    source: dataAdapter,
    selectionmode: 'singlecell',
    columns: [
        #detailscol#
        { text: 'Name', datafield: 'name', width: 200 },
        { text: 'Value', datafield: 'value', width: 200 }
    ]
});

$('#fixedsearchResultsGrid').on('click', '.details-btn', function(e) {
    e.preventDefault();
    var rowIndex = $(this).data('row');
    var grid = $('#fixedsearchResultsGrid');
    var rowData = grid.jqxGrid('getrowdata', rowIndex);
    alert('You clicked row ' + rowIndex + ':\n\n' + JSON.stringify(rowData, null, 2));
});
</script>
	
	<cfinclude template = "/shared/_footer.cfm">