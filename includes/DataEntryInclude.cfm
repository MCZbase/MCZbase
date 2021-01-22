<cfif not isdefined("action")>
	<cfset action="nothing">
</cfif>
<cfif not isdefined("content_url")>
	<cfset content_url="">
</cfif>
<cfinclude template="/includes/functionLib.cfm">	
	<link rel="stylesheet" href="/lib/bootstrap/bootstrap-4.5.0-dist/css/bootstrap.min.css">
<link rel="stylesheet" type="text/css" href="/includes/style.css" >
<link rel="stylesheet" type="text/css" href="/includes/jquery/jquery-ui-1.11.4.custom/jquery-ui.min.css" >
<script type="text/javascript" src="/includes/jquery/1.11.3/jquery-1.11.3.min.js"></script>
<script type="text/javascript" src="/includes/jquery/1.11.3/jquery-migrate-1.2.1.min.js"></script>
<script type='text/javascript' language="javascript" src='/includes/jquery/jquery-ui-1.11.4.custom/jquery-ui.js'></script>
<script type='text/javascript' language="javascript" src='/includes/ajax.min.js'></script>
<script type="text/javascript" src="/lib/bootstrap/bootstrap-4.5.0-dist/js/bootstrap.bundle.min.js"></script>
<script language="javascript" type="text/javascript">
	jQuery(document).ready(function(){
		jQuery("ul.sf-menu").supersubs({
			minWidth:    '10rem',
			maxWidth:    'auto',
			extraWidth:  '1'
		}).superfish({
			delay:       600,
			animation:   {opacity:'show',height:'show'},
			speed:       0
		});
		if (top.location!=document.location) {
			// the page is being included in a frame or a dialog within a page which already contains the header, main menu, and footer
			// so hide these elements.
			$("#footerContentBox").hide();
			$("#headerContent").hide();
			$(".sf-mainMenuWrapper").hide();
		}
	});
</script>

   
