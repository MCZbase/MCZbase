<!DOCTYPE html>
<html>
<head>
<link rel="stylesheet" href="https://jqwidgets.com/public/jqwidgets/styles/jqx.base.css">
<script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
<script src="https://jqwidgets.com/public/jqwidgets/jqxcore.js"></script>
<script src="https://jqwidgets.com/public/jqwidgets/jqxdata.js"></script>
<script src="https://jqwidgets.com/public/jqwidgets/jqxbuttons.js"></script>
<script src="https://jqwidgets.com/public/jqwidgets/jqxscrollbar.js"></script>
<script src="https://jqwidgets.com/public/jqwidgets/jqxmenu.js"></script>
<script src="https://jqwidgets.com/public/jqwidgets/jqxgrid.js"></script>
<script src="https://jqwidgets.com/public/jqwidgets/jqxgrid.selection.js"></script>
</head>
<body>
<div id="testGrid"></div>
<script>
var data = [ { name: "A", age: 1 }, { name: "B", age: 2 } ];
var source = { datatype: "array", localdata: data };
var dataAdapter = new $.jqx.dataAdapter(source);

$("#testGrid").jqxGrid({
    width: 300,
    autoheight: true,
    source: dataAdapter,
    selectionmode: "singlecell",
    keyboardnavigation: true,
    columns: [
        { text: "Name", datafield: "name", width: 150 },
        { text: "Age", datafield: "age", width: 150 }
    ]
});
</script>

							
			

</cfoutput>
<cfinclude template="/shared/_footer.cfm">
