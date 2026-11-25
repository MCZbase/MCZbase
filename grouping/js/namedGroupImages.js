/*
grouping/js/namedGroupImages.js

Copyright 2026 President and Fellows of Harvard College

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Specimen image carousel on grouping/showNamedCollection.cfm: loads images by position
and prefetches the neighbours, first and last, as a group may have tens of thousands of images.
*/

/** Create the image set for a named group's specimen image carousel, used in place of an array
 * of image metadata by goNextImage, goPreviousImage and goImageByNumber in shared-scripts.js.
 * Records are fetched from getSpecimenImagesAt by position and kept; the previous, next, first
 * and last images around the shown one are fetched ahead, and their images loaded, so that
 * moving to them is immediate.
 *
 * @param underscore_collection_id the named group whose specimen images are shown.
 * @param count the number of images in the carousel.
 * @param firstRecord the record shown at position 1 when the page loads, an object with
 *   media_id, media_uri and alt (html encoded).
 * @param sizeparams the size of the carousel image, in the form &width={x}&height={y}.
 * @return an image set object with length, getImage(position, callback), prefetchAround(position)
 *   and prefetchAroundAfterLoad(position, imageElementId).
 */
function makeNamedGroupImageSet(underscore_collection_id, count, firstRecord, sizeparams) {
	var records = {};
	var callbacks = {};
	var requested = {};
	var loadedImages = {};
	var wantedImages = {};
	records[1] = firstRecord;
	// The page's img element already loads the first image.
	loadedImages[1] = true;

	/** Wrap a position past either end of the carousel around to the other end, as next and previous do.
	 * @param position a one based position, possibly 0 or count + 1.
	 * @return the position within 1 to count.
	 */
	function wrapPosition(position) {
		if (position < 1) {
			return count;
		}
		if (position > count) {
			return 1;
		}
		return position;
	}

	/** Load the carousel image for a position in the background, once; if its record is not
	 * loaded yet, the image loads when the record arrives.
	 * @param position the one based position whose image to load.
	 */
	function loadImage(position) {
		wantedImages[position] = true;
		if (loadedImages[position] || !records[position]) {
			return;
		}
		var image = new Image();
		image.src = "/media/rescaleImage.cfm?media_id=" + records[position].media_id + sizeparams;
		// Kept so the browser holds the loaded image until the carousel shows it.
		loadedImages[position] = image;
	}

	/** Fetch the records not yet loaded or requested for some positions in one request, then pass
	 * them to waiting callbacks and load the images for imagePositions.
	 * @param positions the one based positions whose records are needed.
	 * @param imagePositions the positions whose images to load in the background.
	 */
	function fetchRecords(positions, imagePositions) {
		var needed = [];
		for (var i = 0; i < positions.length; i++) {
			if (!records[positions[i]] && !requested[positions[i]] && needed.indexOf(positions[i]) === -1) {
				needed.push(positions[i]);
			}
		}
		for (var j = 0; j < imagePositions.length; j++) {
			loadImage(imagePositions[j]);
		}
		if (needed.length === 0) {
			return;
		}
		for (var k = 0; k < needed.length; k++) {
			requested[needed[k]] = true;
		}
		$.getJSON("/grouping/component/search.cfc",
			{
				method: "getSpecimenImagesAt",
				underscore_collection_id: underscore_collection_id,
				positions: needed.join(","),
				returnformat: "json"
			},
			function (result) {
				for (var m = 0; m < result.images.length; m++) {
					var position = Number(result.images[m].position);
					records[position] = result.images[m];
					if (wantedImages[position]) {
						loadImage(position);
					}
					var waiting = callbacks[position] || [];
					delete callbacks[position];
					for (var n = 0; n < waiting.length; n++) {
						waiting[n](records[position]);
					}
				}
				for (var p = 0; p < needed.length; p++) {
					delete requested[needed[p]];
				}
			}
		).fail(function (jqXHR, textStatus, error) {
			for (var r = 0; r < needed.length; r++) {
				delete requested[needed[r]];
				delete callbacks[needed[r]];
			}
			handleFail(jqXHR, textStatus, error, "loading specimen images in group");
		});
	}

	/** List the previous, next, first and last positions around a position, without duplicates and
	 * without the position itself, whose image the carousel's img element loads.
	 * @param position the one based position shown in the carousel.
	 * @return array of positions.
	 */
	function positionsAround(position) {
		var around = [wrapPosition(position - 1), wrapPosition(position + 1), 1, count];
		var positions = [];
		for (var i = 0; i < around.length; i++) {
			if (around[i] !== position && positions.indexOf(around[i]) === -1) {
				positions.push(around[i]);
			}
		}
		return positions;
	}

	var imageSet = {
		length: count,

		/** Obtain the record at a position, fetching it in the same request as the records
		 * around it if it is not yet loaded.
		 * @param position the one based position in the carousel.
		 * @param callback function invoked with the record, at once if it is already loaded.
		 */
		getImage: function (position, callback) {
			var around = positionsAround(position);
			if (records[position]) {
				callback(records[position]);
				fetchRecords(around, around);
			} else {
				if (!callbacks[position]) {
					callbacks[position] = [];
				}
				callbacks[position].push(callback);
				fetchRecords([position].concat(around), around);
			}
		},

		/** Fetch the records for the previous, next, first and last positions around a position
		 * in one request, and load their images.
		 * @param position the one based position shown in the carousel.
		 */
		prefetchAround: function (position) {
			var around = positionsAround(position);
			fetchRecords(around, around);
		},

		/** As prefetchAround, but load the images only once the image shown at the position has
		 * loaded (or failed), so that they don't compete with it on the server; the records are
		 * fetched at once.  Bound here rather than with an onload attribute, as the shown image
		 * may finish loading before this script runs, and its load event fires again each time
		 * the carousel changes its src.
		 * @param position the one based position shown in the carousel.
		 * @param imageElementId the id of the img element showing that position, without a leading #.
		 */
		prefetchAroundAfterLoad: function (position, imageElementId) {
			var around = positionsAround(position);
			var shownImage = $("#" + imageElementId);
			fetchRecords(around, []);
			if (shownImage.length === 0 || shownImage[0].complete) {
				fetchRecords(around, around);
			} else {
				shownImage.one("load error", function () {
					fetchRecords(around, around);
				});
			}
		}
	};
	return imageSet;
}
