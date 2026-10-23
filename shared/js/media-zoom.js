/**  media-zoom.js
 * Enlarged view of a media image, shown beside it while the mouse is over it or a
 * keyboard user has focused its link; replaces the multizoom library.
 * getMediaBlockHtmlUnthreaded in /media/component/public.cfc marks zoomable images with
 * data-mcz-zoom (the large image's url) and data-mcz-zoom-scale (the preview's size as a
 * multiple of the image's), and calls mczMediaZoom.pointerEnter and
 * mczMediaZoom.focusLink from inline handlers.  Styles are in /shared/css/media_zoom.css.

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

*/

var mczMediaZoom = (function () {
	var PANEL_MAX_SIZE = 600;
	var PANEL_MIN_WIDTH = 120;
	var GAP = 12;
	/* The furthest zoom shows one pixel of the large image as this many screen pixels. */
	var MAX_PIXEL_SCALE = 2;
	var WHEEL_STEP = 1.25;
	var KEY_PAN_STEP = 0.1;
	var MOUSE_HINT = "Scroll to zoom \u00b7 Esc to close";
	var KEYBOARD_HINT = "+ / \u2212 to zoom \u00b7 arrow keys to move \u00b7 Esc to close";

	var enabled = true;
	/* Large images by url: {state: "loading"|"loaded"|"error", width, height}. */
	var largeImages = {};
	var panel = null, panelView, panelHint, panelLoading, lens;
	/* Follows the shown image when the layout moves it, or a collapsing panel hides it. */
	var imageObserver = (typeof ResizeObserver !== "undefined") ? new ResizeObserver(function () { refresh(); }) : null;
	/* The image being shown, or null. */
	var current = null;

	function buildElements() {
		if (panel) {
			return;
		}
		/* aria-hidden: a visual aid only; the image's link leads to the full image. */
		panel = document.createElement("div");
		panel.className = "mcz-zoom-panel";
		panel.setAttribute("aria-hidden", "true");
		panelView = document.createElement("div");
		panelView.className = "mcz-zoom-view";
		panelLoading = document.createElement("img");
		panelLoading.className = "mcz-zoom-loading";
		panelLoading.src = "/shared/images/indicator.gif";
		panelLoading.alt = "";
		panelHint = document.createElement("div");
		panelHint.className = "mcz-zoom-hint";
		panel.appendChild(panelView);
		panel.appendChild(panelLoading);
		panel.appendChild(panelHint);
		lens = document.createElement("div");
		lens.className = "mcz-zoom-lens";
		lens.setAttribute("aria-hidden", "true");
		document.body.appendChild(panel);
		document.body.appendChild(lens);
	}

	/**
	 * loadLarge loads a large image once, then calls back.
	 * @param url the large image's url.
	 * @param callback function() called when it has loaded or failed.
	 */
	function loadLarge(url, callback) {
		var entry = largeImages[url];
		if (entry && entry.state !== "loading") {
			callback();
			return;
		}
		if (!entry) {
			entry = largeImages[url] = { state: "loading", callbacks: [] };
			var image = new Image();
			image.onload = function () {
				entry.state = "loaded";
				entry.width = image.naturalWidth;
				entry.height = image.naturalHeight;
				entry.callbacks.forEach(function (fn) { fn(); });
			};
			image.onerror = function () {
				entry.state = "error";
				entry.callbacks.forEach(function (fn) { fn(); });
			};
			image.src = url;
		}
		entry.callbacks.push(callback);
	}

	/**
	 * isShowable tells whether an image is on the page and has a size, so not removed by an
	 * AJAX reload or hidden in a collapsed panel.
	 * @param image the img element.
	 * @return true if it can be shown.
	 */
	function isShowable(image) {
		if (!document.body.contains(image)) {
			return false;
		}
		var rect = image.getBoundingClientRect();
		return rect.width > 0 && rect.height > 0;
	}

	/**
	 * layout sizes and places the panel beside the image, on the right if there is room,
	 * otherwise on whichever side has more, and hides it if neither has enough.
	 * @return false if there is no room for the panel.
	 */
	function layout() {
		var image = current.image;
		if (!isShowable(image)) {
			return false;
		}
		var rect = image.getBoundingClientRect();
		var viewWidth = document.documentElement.clientWidth;
		var viewHeight = document.documentElement.clientHeight;
		var large = largeImages[current.url];
		var aspect = (large && large.state === "loaded") ? large.width / large.height : rect.width / rect.height;
		var desiredWidth = Math.min(rect.width * current.scale, PANEL_MAX_SIZE);
		var rightSpace = viewWidth - rect.right - 2 * GAP;
		var leftSpace = rect.left - 2 * GAP;
		var onRight = rightSpace >= Math.min(desiredWidth, PANEL_MIN_WIDTH * 2) || rightSpace >= leftSpace;
		var width = Math.min(desiredWidth, onRight ? rightSpace : leftSpace);
		var height = width / aspect;
		var maxHeight = Math.min(PANEL_MAX_SIZE, viewHeight - 2 * GAP);
		if (height > maxHeight) {
			height = maxHeight;
			width = height * aspect;
		}
		if (width < PANEL_MIN_WIDTH) {
			return false;
		}
		var left = onRight ? rect.right + GAP : rect.left - GAP - width;
		var top = Math.max(GAP, Math.min(rect.top, viewHeight - GAP - height));
		current.panelWidth = width;
		current.panelHeight = height;
		current.rect = rect;
		panel.style.width = width + "px";
		panel.style.height = height + "px";
		panel.style.left = left + "px";
		panel.style.top = top + "px";
		if (large && large.state === "loaded") {
			current.maxZoom = Math.max(1, Math.min(large.width * MAX_PIXEL_SCALE / width, large.height * MAX_PIXEL_SCALE / height));
			current.zoom = Math.min(current.zoom, current.maxZoom);
		}
		return true;
	}

	/** render shows the part of the large image centred on the pointer, and the lens. */
	function render() {
		var large = largeImages[current.url];
		var loaded = large && large.state === "loaded";
		panelLoading.style.display = loaded ? "none" : "block";
		panelView.style.display = loaded ? "block" : "none";
		if (!loaded) {
			lens.style.display = "none";
			return;
		}
		var zoom = current.zoom;
		var width = current.panelWidth, height = current.panelHeight;
		var zoomedWidth = width * zoom, zoomedHeight = height * zoom;
		var x = Math.min(0, Math.max(width - zoomedWidth, width / 2 - current.fractionX * zoomedWidth));
		var y = Math.min(0, Math.max(height - zoomedHeight, height / 2 - current.fractionY * zoomedHeight));
		panelView.style.backgroundImage = 'url("' + current.url.replace(/["\\]/g, "\\$&") + '")';
		panelView.style.backgroundSize = zoomedWidth + "px " + zoomedHeight + "px";
		panelView.style.backgroundPosition = x + "px " + y + "px";
		if (zoom > 1) {
			var rect = current.rect;
			lens.style.width = (rect.width / zoom) + "px";
			lens.style.height = (rect.height / zoom) + "px";
			lens.style.left = (rect.left - x / zoomedWidth * rect.width) + "px";
			lens.style.top = (rect.top - y / zoomedHeight * rect.height) + "px";
			lens.style.display = "block";
		} else {
			lens.style.display = "none";
		}
		if (current.zoomed) {
			panelHint.textContent = "Zoom \u00d7" + (Math.round(zoom * 10) / 10) + " \u00b7 Esc to close";
		} else {
			panelHint.textContent = current.viaKeyboard ? KEYBOARD_HINT : MOUSE_HINT;
		}
		panelHint.style.display = current.maxZoom > 1 ? "block" : "none";
	}

	/** refresh lays out and redraws, or hides when the image can't be shown any longer. */
	function refresh() {
		if (!current) {
			return;
		}
		if (!isShowable(current.image)) {
			hide();
			return;
		}
		if (layout()) {
			panel.style.display = "block";
			render();
		} else {
			panel.style.display = "none";
			lens.style.display = "none";
		}
	}

	/**
	 * zoomBy changes the zoom, keeping it within range.
	 * @param factor greater than 1 to zoom in, less than 1 to zoom out.
	 */
	function zoomBy(factor) {
		current.zoom = Math.max(1, Math.min(current.maxZoom, current.zoom * factor));
		current.zoomed = true;
		render();
	}

	function onPointerMove(e) {
		var rect = current.image.getBoundingClientRect();
		current.fractionX = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width));
		current.fractionY = Math.max(0, Math.min(1, (e.clientY - rect.top) / rect.height));
		render();
	}

	function onWheel(e) {
		if (!current.maxZoom || current.maxZoom <= 1) {
			return;
		}
		e.preventDefault();
		zoomBy(e.deltaY < 0 ? WHEEL_STEP : 1 / WHEEL_STEP);
	}

	/* Escape dismisses the panel until the pointer leaves or focus moves (WCAG 1.4.13). */
	function onDocumentKeyDown(e) {
		if (e.key === "Escape" && current) {
			var image = current.image;
			hide();
			image.mczZoomDismissed = true;
			image.addEventListener("pointerleave", function () {
				image.mczZoomDismissed = false;
			}, { once: true });
		}
	}

	function onLinkKeyDown(e) {
		if (!current || !current.viaKeyboard) {
			return;
		}
		var handled = true;
		switch (e.key) {
			case "+":
			case "=":
				zoomBy(WHEEL_STEP);
				break;
			case "-":
			case "_":
				zoomBy(1 / WHEEL_STEP);
				break;
			case "ArrowLeft":
			case "ArrowRight":
			case "ArrowUp":
			case "ArrowDown":
				if (current.zoom <= 1) {
					handled = false;
					break;
				}
				var step = KEY_PAN_STEP / current.zoom;
				if (e.key === "ArrowLeft") { current.fractionX = Math.max(0, current.fractionX - step); }
				if (e.key === "ArrowRight") { current.fractionX = Math.min(1, current.fractionX + step); }
				if (e.key === "ArrowUp") { current.fractionY = Math.max(0, current.fractionY - step); }
				if (e.key === "ArrowDown") { current.fractionY = Math.min(1, current.fractionY + step); }
				render();
				break;
			default:
				handled = false;
		}
		if (handled) {
			e.preventDefault();
		}
	}

	function onPointerLeave() {
		if (current && !current.viaKeyboard) {
			hide();
		}
	}

	function onLinkBlur(e) {
		var image = e.currentTarget.querySelector("img[data-mcz-zoom]");
		if (current && current.viaKeyboard) {
			hide();
		}
		if (image) {
			image.mczZoomDismissed = false;
		}
	}

	/**
	 * show starts showing an image's enlarged view.
	 * @param image the img element, carrying data-mcz-zoom.
	 * @param viaKeyboard true when its link was focused from the keyboard.
	 * @param fractionX, fractionY the point of the image to centre on, 0 to 1.
	 */
	function show(image, viaKeyboard, fractionX, fractionY) {
		var url = image.getAttribute("data-mcz-zoom");
		if (!enabled || !url || image.mczZoomDismissed || (largeImages[url] && largeImages[url].state === "error")) {
			return;
		}
		if (current && current.image !== image) {
			hide();
		}
		buildElements();
		var scale = parseFloat(image.getAttribute("data-mcz-zoom-scale"));
		current = {
			image: image,
			link: image.closest("a"),
			url: url,
			scale: (scale > 0) ? scale : 2,
			zoom: 1,
			maxZoom: 1,
			zoomed: false,
			viaKeyboard: viaKeyboard,
			fractionX: fractionX,
			fractionY: fractionY
		};
		image.addEventListener("pointermove", onPointerMove);
		image.addEventListener("pointerleave", onPointerLeave);
		image.addEventListener("wheel", onWheel, { passive: false });
		if (current.link) {
			current.link.addEventListener("keydown", onLinkKeyDown);
		}
		document.addEventListener("keydown", onDocumentKeyDown);
		/* Capture, so scrolling inside any container moves the panel with the image. */
		window.addEventListener("scroll", refresh, true);
		window.addEventListener("resize", refresh);
		if (imageObserver) {
			imageObserver.observe(image);
		}
		refresh();
		loadLarge(url, function () {
			if (!current || current.url !== url) {
				return;
			}
			if (largeImages[url].state === "error") {
				hide();
			} else {
				refresh();
			}
		});
	}

	/** hide hides the enlarged view and stops listening for its events. */
	function hide() {
		if (!current) {
			return;
		}
		var image = current.image;
		image.removeEventListener("pointermove", onPointerMove);
		image.removeEventListener("pointerleave", onPointerLeave);
		image.removeEventListener("wheel", onWheel);
		if (current.link) {
			current.link.removeEventListener("keydown", onLinkKeyDown);
		}
		document.removeEventListener("keydown", onDocumentKeyDown);
		window.removeEventListener("scroll", refresh, true);
		window.removeEventListener("resize", refresh);
		if (imageObserver) {
			imageObserver.disconnect();
		}
		panel.style.display = "none";
		lens.style.display = "none";
		current = null;
	}

	return {
		/**
		 * pointerEnter shows an image's enlarged view for a mouse or pen; a touch goes
		 * straight to the image's link instead.  Called from the img's onpointerenter.
		 * @param image the img element.
		 * @param e the pointer event.
		 */
		pointerEnter: function (image, e) {
			if (e.pointerType === "touch") {
				return;
			}
			var rect = image.getBoundingClientRect();
			show(image, false, (e.clientX - rect.left) / rect.width, (e.clientY - rect.top) / rect.height);
		},
		/**
		 * focusLink shows the enlarged view of the image inside a link focused from the
		 * keyboard (not by a click).  Called from the link's onfocus.
		 * @param link the a element holding the img.
		 */
		focusLink: function (link) {
			var image = link.querySelector("img[data-mcz-zoom]");
			if (!image || !link.matches(":focus-visible")) {
				return;
			}
			if (!link.mczZoomBlurBound) {
				link.mczZoomBlurBound = true;
				link.addEventListener("blur", onLinkBlur);
			}
			show(image, true, 0.5, 0.5);
		},
		/**
		 * setEnabled turns the enlarged views on or off, as while the specimen page's
		 * in-page editor covers the images.
		 * @param on true to enable, false to disable and hide any shown.
		 */
		setEnabled: function (on) {
			enabled = !!on;
			if (!enabled) {
				hide();
			}
		},
		/** hide hides any enlarged view shown. */
		hide: hide
	};
})();
