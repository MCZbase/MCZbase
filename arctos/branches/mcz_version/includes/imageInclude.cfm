<cfif not isdefined("action")>
	<cfset action="nothing">
</cfif>
<cfif not isdefined("content_url")>
	<cfset content_url="">
</cfif>
<cfinclude template="/includes/functionLib.cfm">
<link rel="stylesheet" type="text/css" href="/includes/style.css" >
<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.9.2/jquery.min.js"></script>
<script type='text/javascript' language="javascript" src='/includes/ajax.min.js'></script>
<script language="JavaScript" src="/includes/jquery/jquery.ui.datepicker.min.js" type="text/javascript"></script>

<link rel="stylesheet" href="includes/js/multizoom/multizoom.css" type="text/css" />
<script type="text/javascript" src="includes/js/multizoom/multizoom.js">

// Featured Image Zoomer (w/ optional multizoom and adjustable power)- By Dynamic Drive DHTML code library (www.dynamicdrive.com)
// Multi-Zoom code (c)2012 John Davenport Scheuer
// as first seen in http://www.dynamicdrive.com/forums/
// username: jscheuer1 - This Notice Must Remain for Legal Use
// Visit Dynamic Drive at http://www.dynamicdrive.com/ for this script and 100s more

</script>

<script type="text/javascript">

jQuery(document).ready(function($){

	$('#image1').addimagezoom({ // single image zoom
		zoomrange: [3, 10],
		magnifiersize: [300,300],
		magnifierpos: 'right',
		cursorshade: true,
		largeimage: 'hayden.jpg' //<-- No comma after last option!
	})


	$('#image2').addimagezoom() // single image zoom with default options

	$('#multizoom1').addimagezoom({ // multi-zoom: options same as for previous Featured Image Zoomer's addimagezoom unless noted as '- new'
		descArea: '#description', // description selector (optional - but required if descriptions are used) - new
		speed: 1500, // duration of fade in for new zoomable images (in milliseconds, optional) - new
		descpos: true, // if set to true - description position follows image position at a set distance, defaults to false (optional) - new
		imagevertcenter: true, // zoomable image centers vertically in its container (optional) - new
		magvertcenter: true, // magnified area centers vertically in relation to the zoomable image (optional) - new
		zoomrange: [3, 10],
		magnifiersize: [250,250],
		magnifierpos: 'right',
		cursorshadecolor: '#fdffd5',
		cursorshade: true //<-- No comma after last option!
	});

	$('#multizoom2').addimagezoom({ // multi-zoom: options same as for previous Featured Image Zoomer's addimagezoom unless noted as '- new'
		descArea: '#description2', // description selector (optional - but required if descriptions are used) - new
		disablewheel: true // even without variable zoom, mousewheel will not shift image position while mouse is over image (optional) - new
				//^-- No comma after last option!
	});

})

</script>