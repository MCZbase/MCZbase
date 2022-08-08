<cfset pageTitle="Manage Download Field Profiles">
<cfinclude template="/shared/_header.cfm">
<cfinclude template="/users/component/functions.cfc" runOnce="true">

<script type="text/javascript" language="javascript">
	function deleteDownloadProfile(download_profile_id) {
		jQuery.ajax({
			url: "/users/component/functions.cfc",
			data: {
				method : "deleteDownloadProfile",
				download_profile_id : download_profile_id,
				returnformat : "json",
				queryformat : "column"
			},
			success : function(result) { 
				retval = JSON.parse(result)
				if (retval.DATA.STATUS[0]=="deleted") { 
					$("#tr" + download_profile_id).hide();
					$("#feedbackDiv").html("Deleted Record");
					$("#userSearchCount").html(retval.DATA.USER_SEARCH_COUNT[0]);
				} else {
					// we should not get here, but in case.
					alert("Error, problem deleting download profile");
				}
				reloadDownloadProfileList();
			}, 
			error: function (jqXHR, textStatus, error) {
				handleFail(jqXHR,textStatus,error,"deleting a download profile");
			}
		});
	};
	function reloadDownloadProfileList() { 
		jQuery.ajax({
			url: "/users/component/functions.cfc",
			data: {
				method : "getDownloadProfilesHtml",
				returnformat: "plain"
			},
			success : function(result) { 
				$("#profileBlock").html(result);
			}, 
			error: function (jqXHR, textStatus, error) {
				handleFail(jqXHR,textStatus,error,"loading list of download profiles");
			}
		});
	};
	function loadNewDownloadProfileForm() { 
		$("#feedbackDiv").html("");
		jQuery.ajax({
			url: "/users/component/functions.cfc",
			data: {
				method : "editDownloadProfileHtml",
				returnformat: "plain"
			},
			success : function(result) { 
				$("#manageProfileBlock").html(result);
			}, 
			error: function (jqXHR, textStatus, error) {
				handleFail(jqXHR,textStatus,error,"loading form to create a download profile");
			}
		});
	};
	function loadEditDownloadProfileForm(download_profile_id) { 
		$("#feedbackDiv").html("");
		jQuery.ajax({
			url: "/users/component/functions.cfc",
			data: {
				method : "editDownloadProfileHtml",
				returnformat: "plain",
				download_profile_id: download_profile_id
			},
			success : function(result) { 
				$("#manageProfileBlock").html(result);
			}, 
			error: function (jqXHR, textStatus, error) {
				handleFail(jqXHR,textStatus,error,"loading form to edit a download profile");
			}
		});
	};
</script>

<cfoutput>
	<main class="container py-3" id="content" >
		<section class="row border rounded my-2 p-2">
			<div class="col-12 pt-2">
				<h1 class="h2 w-100">Manage profiles for columns in Specimen Search CSV downloads for #encodeForHtml(session.username)#</h1>
				<cfset profileBlockContent = getDownloadProfilesHtml()>
				<div id="profileBlock">#profileBlockContent#</div>
				<button class="btn btn-xs btn-secondary" onClick="loadNewDownloadProfileForm();">New</button>
				<output id="feedbackDiv"></output>
				<div id="manageProfileBlock"></div>
			</div>
		</section>
	</main>
</cfoutput>

<cfinclude template="/shared/_footer.cfm">
