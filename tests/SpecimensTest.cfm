<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>jqxGrid Keyboard Navigation Test 20</title>
  <link rel="stylesheet" href="https://jqwidgets.com/public/jqwidgets/styles/jqx.base.css">
  <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
  <script src="https://jqwidgets.com/public/jqwidgets/jqxcore.js"></script>
  <script src="https://jqwidgets.com/public/jqwidgets/jqxdata.js"></script>
  <script src="https://jqwidgets.com/public/jqwidgets/jqxbuttons.js"></script>
  <script src="https://jqwidgets.com/public/jqwidgets/jqxscrollbar.js"></script>
  <script src="https://jqwidgets.com/public/jqwidgets/jqxmenu.js"></script>
  <script src="https://jqwidgets.com/public/jqwidgets/jqxgrid.js"></script>
  <script src="https://jqwidgets.com/public/jqwidgets/jqxgrid.selection.js"></script>
</head>
<body>
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