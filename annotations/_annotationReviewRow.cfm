<!---
_annotationReviewRow.cfm

Copyright 2008-2017 Contributors to Arctos
Copyright 2008-2025 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Shared include template for rendering a single annotation review row with
ajax-based save via doAnnotationUpdate(). Caller must set the following
variables in the variables scope before including this template:
  rr_annotation_id        numeric annotation primary key
  rr_annotation_display   annotation text (may contain HTML from body_value)
  rr_cf_username          annotator login username
  rr_email                annotator e-mail address
  rr_annotate_date        date the annotation was created
  rr_motivation           annotation motivation string
  rr_reviewed_fg          0 or 1 – whether the annotation has been reviewed
  rr_reviewer             reviewer name string (may be empty)
  rr_reviewer_comment     reviewer comment text
  rr_mask_annotation_fg   0 or 1 – annotation visibility flag
--->
<cfoutput>
<div class="card-body bg-light border-bottom py-2">
	<div class="form-row mx-0 col-12 px-0">
		<div class="col-12 col-md-5 pt-2 px-1">
			<span class="data-entry-label font-weight-bold">Annotation:</span>
			<div class="px-1 small">#rr_annotation_display#</div>
		</div>
		<div class="col-12 col-md-4 pt-2 px-1">
			<span class="data-entry-label font-weight-bold">Annotator:</span>
			<div class="px-1 small">
				<strong>#encodeForHTML(rr_cf_username)#</strong>
				(#encodeForHTML(rr_email)#)
				on #dateformat(rr_annotate_date,"yyyy-mm-dd")#
			</div>
		</div>
		<div class="col-12 col-md-3 pt-2 px-1">
			<span class="data-entry-label font-weight-bold">Motivation:</span>
			<div class="px-1 small">#encodeForHTML(rr_motivation)#</div>
		</div>
	</div>
	<div class="form-row mx-0 col-12 px-0 pt-1">
		<div class="col-12 col-md-2 py-1 px-1">
			<label for="reviewed_fg_#rr_annotation_id#" class="data-entry-label font-weight-bold">Reviewed?</label>
			<select id="reviewed_fg_#rr_annotation_id#" class="data-entry-select col-12">
				<option value="0" <cfif val(rr_reviewed_fg) EQ 0>selected="selected"</cfif>>No</option>
				<option value="1" <cfif val(rr_reviewed_fg) EQ 1>selected="selected"</cfif>>Yes</option>
			</select>
			<cfif len(rr_reviewer) GT 0>
				<div class="pt-1 small">Last review by: #encodeForHTML(rr_reviewer)#</div>
			</cfif>
		</div>
		<cfif isDefined("session.roles") AND listfindnocase(session.roles,"manage_collection")>
		<div class="col-12 col-md-2 py-1 px-1">
			<label for="mask_annotation_fg_#rr_annotation_id#" class="data-entry-label font-weight-bold">Visibility:</label>
			<select id="mask_annotation_fg_#rr_annotation_id#" class="data-entry-select col-12">
				<option value="0" <cfif val(rr_mask_annotation_fg) EQ 0>selected="selected"</cfif>>Public</option>
				<option value="1" <cfif val(rr_mask_annotation_fg) EQ 1>selected="selected"</cfif>>Hidden</option>
			</select>
		</div>
		</cfif>
		<div class="col-12 col-md-6 py-1 px-1">
			<label for="reviewer_comment_#rr_annotation_id#" class="data-entry-label font-weight-bold">Review Comments</label>
			<textarea id="reviewer_comment_#rr_annotation_id#" class="data-entry-textarea col-12" rows="2" maxlength="4000">#encodeForHTML(rr_reviewer_comment)#</textarea>
		</div>
		<div class="col-12 col-md-2 py-1 px-1 d-flex align-items-end">
			<div>
				<button type="button" class="btn btn-xs btn-primary mb-1" onclick="doAnnotationUpdate(#rr_annotation_id#)">Save Review</button>
				<output id="feedbackDiv_#rr_annotation_id#" aria-live="polite"></output>
			</div>
		</div>
	</div>
</div>
</cfoutput>
