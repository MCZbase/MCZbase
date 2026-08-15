/**** projects/js/projects.js
Search-field autocomplete bindings for /Projects.cfm.
 ******/

/**
 * makeProjectTitleSearchAutocomplete binds a text input to a substring-matching
 * autocomplete of existing project titles (projects/component/search.cfc's
 * getProjectAutocompleteMeta), so the Title search field suggests real project names
 * instead of accepting unconstrained free text.
 *
 * @param fieldId the id of the text input to bind (without a leading # selector).
 */
function makeProjectTitleSearchAutocomplete(fieldId) {
	jQuery("#" + fieldId).autocomplete({
		source: function (request, response) {
			$.ajax({
				url: "/projects/component/search.cfc",
				data: { term: request.term, method: "getProjectAutocompleteMeta" },
				dataType: "json",
				success: function (data) { response(data); },
				error: function (jqXHR, textStatus, error) {
					handleFail(jqXHR, textStatus, error, "making a project title autocomplete");
				}
			});
		},
		select: function (event, result) {
			event.preventDefault();
			$("#" + fieldId).val(result.item.value);
		},
		minLength: 3
	}).autocomplete("instance")._renderItem = function (ul, item) {
		return $("<li>").append("<span>" + item.meta + "</span>").appendTo(ul);
	};
}

/**** Edit-page (/projects/Project.cfm) wiring below. Each refresh{Section} function
 * re-fetches and swaps in that section's HTML fragment.
 ******/

/** handleChange reflects an unsaved edit to the main project form in saveResultDiv;
 * bound to the form's inputs via monitorForChangesGeneric (shared/js/internal-scripts.js).
 */
function handleChange() {
	$("#saveResultDiv").html("Unsaved changes.");
	$("#saveResultDiv").addClass("text-danger");
	$("#saveResultDiv").removeClass("text-success");
	$("#saveResultDiv").removeClass("text-warning");
}

/** saveEdits saves the main project record via this app's standard
 * saveEditsFromFormCallback helper (shared/js/internal-scripts.js), then reflects the
 * saved title in the page heading.
 */
function saveEdits() {
	saveEditsFromFormCallback("projectForm", "/projects/component/functions.cfc", "saveResultDiv", "saving project record", updateProjectNameHeading);
}

/** updateProjectNameHeading reflects the just-saved project_name in the page heading. */
function updateProjectNameHeading() {
	$("#projectNameHeading").text($("#project_name").val());
}

/** refreshProjectAgents re-fetches and swaps in the Agents section fragment.
 * @param project_id the project being edited.
 */
function refreshProjectAgents(project_id) {
	jQuery.ajax({
		url: "/projects/component/functions.cfc",
		data: { method: "getAgentsHtml", project_id: project_id },
		success: function (result) { $("#agentsDiv").html(result); },
		error: function (jqXHR, textStatus, error) { handleFail(jqXHR, textStatus, error, "obtaining agents for a project"); },
		dataType: "html"
	});
}

/** addProjectAgent adds the agent picked in the Agents section's add-row to the project. */
function addProjectAgent(project_id) {
	jQuery.getJSON("/projects/component/functions.cfc",
		{
			method: "addProjectAgent",
			project_id: project_id,
			agent_name_id: $("#new_agent_id").val(),
			project_agent_role: $("#new_agent_role").val(),
			agent_position: $("#new_agent_position").val(),
			returnformat: "json",
			queryformat: "struct"
		},
		function (result) {
			refreshProjectAgents(project_id);
			if (result[0].STATUS != 1) { alert(result[0].MESSAGE); }
		}
	).fail(function (jqXHR, textStatus, error) {
		handleFail(jqXHR, textStatus, error, "adding an agent to a project");
	});
}

/** saveProjectAgent saves an existing agent row's role/position.
 * @param roleControl the id of that row's role select, without a leading # selector.
 * @param positionControl the id of that row's position select, without a leading # selector.
 */
function saveProjectAgent(project_id, agent_name_id, roleControl, positionControl) {
	jQuery.getJSON("/projects/component/functions.cfc",
		{
			method: "saveProjectAgent",
			project_id: project_id,
			agent_name_id: agent_name_id,
			project_agent_role: $("#" + roleControl).val(),
			agent_position: $("#" + positionControl).val(),
			returnformat: "json",
			queryformat: "struct"
		},
		function (result) {
			refreshProjectAgents(project_id);
			if (result[0].STATUS != 1) { alert(result[0].MESSAGE); }
		}
	).fail(function (jqXHR, textStatus, error) {
		handleFail(jqXHR, textStatus, error, "updating an agent on a project");
	});
}

/** removeProjectAgent unlinks an agent from the project. */
function removeProjectAgent(project_id, agent_name_id) {
	jQuery.getJSON("/projects/component/functions.cfc",
		{
			method: "removeProjectAgent",
			project_id: project_id,
			agent_name_id: agent_name_id,
			returnformat: "json",
			queryformat: "struct"
		},
		function (result) {
			refreshProjectAgents(project_id);
			if (result[0].STATUS != 1) { alert(result[0].MESSAGE); }
		}
	).fail(function (jqXHR, textStatus, error) {
		handleFail(jqXHR, textStatus, error, "removing an agent from a project");
	});
}

/** refreshProjectSponsors re-fetches and swaps in the Sponsors section fragment. */
function refreshProjectSponsors(project_id) {
	jQuery.ajax({
		url: "/projects/component/functions.cfc",
		data: { method: "getSponsorsHtml", project_id: project_id },
		success: function (result) { $("#sponsorsDiv").html(result); },
		error: function (jqXHR, textStatus, error) { handleFail(jqXHR, textStatus, error, "obtaining sponsors for a project"); },
		dataType: "html"
	});
}

/** addProjectSponsor adds the agent picked in the Sponsors section's add-row as a sponsor. */
function addProjectSponsor(project_id) {
	jQuery.getJSON("/projects/component/functions.cfc",
		{
			method: "addProjectSponsor",
			project_id: project_id,
			agent_name_id: $("#new_sponsor_id").val(),
			acknowledgement: $("#new_sponsor_ack").val(),
			returnformat: "json",
			queryformat: "struct"
		},
		function (result) {
			refreshProjectSponsors(project_id);
			if (result[0].STATUS != 1) { alert(result[0].MESSAGE); }
		}
	).fail(function (jqXHR, textStatus, error) {
		handleFail(jqXHR, textStatus, error, "adding a sponsor to a project");
	});
}

/** saveProjectSponsor saves an existing sponsor row's acknowledgement.
 * @param ackControl the id of that row's acknowledgement input, without a leading # selector.
 */
function saveProjectSponsor(project_sponsor_id, ackControl) {
	var project_id = $("#project_id").val();
	jQuery.getJSON("/projects/component/functions.cfc",
		{
			method: "saveProjectSponsor",
			project_sponsor_id: project_sponsor_id,
			acknowledgement: $("#" + ackControl).val(),
			returnformat: "json",
			queryformat: "struct"
		},
		function (result) {
			refreshProjectSponsors(project_id);
			if (result[0].STATUS != 1) { alert(result[0].MESSAGE); }
		}
	).fail(function (jqXHR, textStatus, error) {
		handleFail(jqXHR, textStatus, error, "updating a sponsor on a project");
	});
}

/** removeProjectSponsor unlinks a sponsor from the project. */
function removeProjectSponsor(project_id, project_sponsor_id) {
	jQuery.getJSON("/projects/component/functions.cfc",
		{
			method: "removeProjectSponsor",
			project_id: project_id,
			project_sponsor_id: project_sponsor_id,
			returnformat: "json",
			queryformat: "struct"
		},
		function (result) {
			refreshProjectSponsors(project_id);
			if (result[0].STATUS != 1) { alert(result[0].MESSAGE); }
		}
	).fail(function (jqXHR, textStatus, error) {
		handleFail(jqXHR, textStatus, error, "removing a sponsor from a project");
	});
}

/** refreshProjectLoans re-fetches and swaps in the Loans section fragment. */
function refreshProjectLoans(project_id) {
	jQuery.ajax({
		url: "/projects/component/functions.cfc",
		data: { method: "getLoansHtml", project_id: project_id },
		success: function (result) { $("#loansDiv").html(result); },
		error: function (jqXHR, textStatus, error) { handleFail(jqXHR, textStatus, error, "obtaining loans for a project"); },
		dataType: "html"
	});
}

/** addProjectLoan links the loan picked in the Loans section's add-row to the project. */
function addProjectLoan(project_id) {
	jQuery.getJSON("/projects/component/functions.cfc",
		{
			method: "addProjectTransaction",
			project_id: project_id,
			transaction_id: $("#new_loan_transaction_id").val(),
			project_trans_remarks: $("#new_loan_remarks").val(),
			returnformat: "json",
			queryformat: "struct"
		},
		function (result) {
			refreshProjectLoans(project_id);
			if (result[0].STATUS != 1) { alert(result[0].MESSAGE); }
		}
	).fail(function (jqXHR, textStatus, error) {
		handleFail(jqXHR, textStatus, error, "adding a loan to a project");
	});
}

/** refreshProjectAccessions re-fetches and swaps in the Accessions section fragment. */
function refreshProjectAccessions(project_id) {
	jQuery.ajax({
		url: "/projects/component/functions.cfc",
		data: { method: "getAccessionsHtml", project_id: project_id },
		success: function (result) { $("#accessionsDiv").html(result); },
		error: function (jqXHR, textStatus, error) { handleFail(jqXHR, textStatus, error, "obtaining accessions for a project"); },
		dataType: "html"
	});
}

/** addProjectAccession links the accession picked in the add-row to the project. */
function addProjectAccession(project_id) {
	jQuery.getJSON("/projects/component/functions.cfc",
		{
			method: "addProjectTransaction",
			project_id: project_id,
			transaction_id: $("#new_accn_transaction_id").val(),
			project_trans_remarks: $("#new_accn_remarks").val(),
			returnformat: "json",
			queryformat: "struct"
		},
		function (result) {
			refreshProjectAccessions(project_id);
			if (result[0].STATUS != 1) { alert(result[0].MESSAGE); }
		}
	).fail(function (jqXHR, textStatus, error) {
		handleFail(jqXHR, textStatus, error, "adding an accession to a project");
	});
}

/** removeProjectTransaction unlinks a loan or accession from the project; refreshes both
 * fragments, since the caller doesn't track which type the transaction was.
 */
function removeProjectTransaction(project_id, transaction_id) {
	jQuery.getJSON("/projects/component/functions.cfc",
		{
			method: "removeProjectTransaction",
			project_id: project_id,
			transaction_id: transaction_id,
			returnformat: "json",
			queryformat: "struct"
		},
		function (result) {
			refreshProjectLoans(project_id);
			refreshProjectAccessions(project_id);
			if (result[0].STATUS != 1) { alert(result[0].MESSAGE); }
		}
	).fail(function (jqXHR, textStatus, error) {
		handleFail(jqXHR, textStatus, error, "removing a transaction from a project");
	});
}

/** refreshProjectPublications re-fetches and swaps in the Publications section fragment. */
function refreshProjectPublications(project_id) {
	jQuery.ajax({
		url: "/projects/component/functions.cfc",
		data: { method: "getPublicationsHtml", project_id: project_id },
		success: function (result) { $("#publicationsDiv").html(result); },
		error: function (jqXHR, textStatus, error) { handleFail(jqXHR, textStatus, error, "obtaining publications for a project"); },
		dataType: "html"
	});
}

/** addProjectPublication links the publication picked in the add-row to the project. */
function addProjectPublication(project_id) {
	jQuery.getJSON("/projects/component/functions.cfc",
		{
			method: "addProjectPublication",
			project_id: project_id,
			publication_id: $("#new_publication_id").val(),
			returnformat: "json",
			queryformat: "struct"
		},
		function (result) {
			refreshProjectPublications(project_id);
			if (result[0].STATUS != 1) { alert(result[0].MESSAGE); }
		}
	).fail(function (jqXHR, textStatus, error) {
		handleFail(jqXHR, textStatus, error, "adding a publication to a project");
	});
}

/** removeProjectPublication unlinks a publication from the project. */
function removeProjectPublication(project_id, publication_id) {
	jQuery.getJSON("/projects/component/functions.cfc",
		{
			method: "removeProjectPublication",
			project_id: project_id,
			publication_id: publication_id,
			returnformat: "json",
			queryformat: "struct"
		},
		function (result) {
			refreshProjectPublications(project_id);
			if (result[0].STATUS != 1) { alert(result[0].MESSAGE); }
		}
	).fail(function (jqXHR, textStatus, error) {
		handleFail(jqXHR, textStatus, error, "removing a publication from a project");
	});
}

/** refreshProjectTaxonomy re-fetches and swaps in the Taxonomy section fragment. */
function refreshProjectTaxonomy(project_id) {
	jQuery.ajax({
		url: "/projects/component/functions.cfc",
		data: { method: "getTaxonomyHtml", project_id: project_id },
		success: function (result) { $("#taxonomyDiv").html(result); },
		error: function (jqXHR, textStatus, error) { handleFail(jqXHR, textStatus, error, "obtaining taxonomy for a project"); },
		dataType: "html"
	});
}

/** addProjectTaxon links the taxon picked in the add-row to the project. */
function addProjectTaxon(project_id) {
	jQuery.getJSON("/projects/component/functions.cfc",
		{
			method: "addProjectTaxon",
			project_id: project_id,
			taxon_name_id: $("#new_taxon_name_id").val(),
			returnformat: "json",
			queryformat: "struct"
		},
		function (result) {
			refreshProjectTaxonomy(project_id);
			if (result[0].STATUS != 1) { alert(result[0].MESSAGE); }
		}
	).fail(function (jqXHR, textStatus, error) {
		handleFail(jqXHR, textStatus, error, "adding a taxon to a project");
	});
}

/** removeProjectTaxon unlinks a taxon from the project. */
function removeProjectTaxon(project_id, taxon_name_id) {
	jQuery.getJSON("/projects/component/functions.cfc",
		{
			method: "removeProjectTaxon",
			project_id: project_id,
			taxon_name_id: taxon_name_id,
			returnformat: "json",
			queryformat: "struct"
		},
		function (result) {
			refreshProjectTaxonomy(project_id);
			if (result[0].STATUS != 1) { alert(result[0].MESSAGE); }
		}
	).fail(function (jqXHR, textStatus, error) {
		handleFail(jqXHR, textStatus, error, "removing a taxon from a project");
	});
}
