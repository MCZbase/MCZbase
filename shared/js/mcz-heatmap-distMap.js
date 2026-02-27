// 
//js code for heat map and distribution map include deckgl
//
//
// /shared/js/mcz-heatmap.js

var map;
var overlay;
var heatmapLayer;
var pointLayer;
var currentView = 'heatmap'; // 'heatmap' or 'points'

function initMap() {
  // Expect these to be defined by the CF page
  if (!window.MCZ_HEATMAP_DATA || !window.MCZ_BOUNDS) {
    console.error("initMap: Missing MCZ_HEATMAP_DATA or MCZ_BOUNDS");
    return;
  }

  var ne = new google.maps.LatLng(MCZ_BOUNDS.maxlat, MCZ_BOUNDS.maxlong);
  var sw = new google.maps.LatLng(MCZ_BOUNDS.minlat, MCZ_BOUNDS.minlong);
  var bounds = new google.maps.LatLngBounds(sw, ne);
  var centerpoint = bounds.getCenter();

  var mapOptions = {
    zoom: 1,
    minZoom: 1,
    maxZoom: 13,
    center: centerpoint,
    controlSize: 20,
    mapTypeId: "hybrid"
  };

  map = new google.maps.Map(document.getElementById('map'), mapOptions);
  map.fitBounds(bounds);

  overlay = new deck.GoogleMapsOverlay({
    layers: []
  });
  overlay.setMap(map);

  // Clean/sanitize data from MCZ_HEATMAP_DATA
  var raw = MCZ_HEATMAP_DATA || [];
  var data = [];

  for (var i = 0; i < raw.length; i++) {
    var d = raw[i];
    if (!d) continue;

    var lat = parseFloat(d.latitude);
    var lon = parseFloat(d.longitude);
    var w = d.weight || 1;

    // Skip rows with non-finite or out-of-range lat/lon
    if (!isFinite(lat) || !isFinite(lon)) {
      continue;
    }
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      continue;
    }

    data.push({
      latitude: lat,
      longitude: lon,
      weight: w
    });
  }

  console.log("initMap: raw points =", raw.length, "valid points =", data.length);

  if (!data.length) {
    console.error("initMap: No valid points for heatmap");
  }
  // Heatmap layer
  heatmapLayer = new deck.HeatmapLayer({
    id: 'mcz-heatmap',
    data: data,
    getPosition: function (d) { return [d.longitude, d.latitude]; },
    getWeight: function (d) { return d.weight || 1; },
    radiusPixels: 30,
    intensity: 1,
    threshold: 0.05,
    opacity: 0.9,
    colorRange: [
      [0, 255, 255, 0],
      [0, 255, 255, 255],
      [0, 191, 255, 255],
      [0, 127, 255, 255],
      [0, 63, 255, 255],
      [0, 0, 255, 255],
      [0, 0, 223, 255],
      [0, 0, 191, 255],
      [0, 0, 159, 255],
      [0, 0, 127, 255],
      [63, 0, 91, 255],
      [127, 0, 63, 255],
      [191, 0, 31, 255],
      [255, 0, 0, 255]
    ]
  });

  // Point distribution layer
  pointLayer = new deck.ScatterplotLayer({
    id: 'mcz-points',
    data: data,
    getPosition: function (d) { return [d.longitude, d.latitude]; },
    getRadius: function () { return 1000; },
    radiusMinPixels: 2,
    radiusMaxPixels: 10,
    getFillColor: function () { return [0, 255, 0, 180]; },
    pickable: false
  });

  // Start in heatmap view
  currentView = 'heatmap';
  overlay.setProps({ layers: [heatmapLayer] });
	
 
  // Wire up buttons
  var btnGradient = document.getElementById("change-gradient");
  if (btnGradient) {
    btnGradient.addEventListener("click", changeGradient);
  }

  var btnToggleView = document.getElementById("toggle-view");
  if (btnToggleView) {
    btnToggleView.addEventListener("click", toggleView);
  }

  console.log("initMap: initialized, starting in heatmap view");
}

function toggleView() {
  if (!overlay || !window.MCZ_CLEAN_DATA) {
    console.error("toggleView: overlay or data not ready");
    return;
  }

  var data = window.MCZ_CLEAN_DATA;

  if (currentView === 'heatmap') {
    // Switch to points
    currentView = 'points';
    console.log("toggleView: switching to points");

    pointLayer = new deck.ScatterplotLayer({
      id: 'mcz-points',
      data: data,
      getPosition: function (d) { return [d.longitude, d.latitude]; },
      getRadius: function () { return 1000; },
      radiusMinPixels: 2,
      radiusMaxPixels: 10,
      getFillColor: function () { return [0, 255, 0, 180]; },
      pickable: false
    });

    overlay.setProps({ layers: [pointLayer] });
  } else {
    // Switch to heatmap
    currentView = 'heatmap';
    console.log("toggleView: switching to heatmap");

    heatmapLayer = new deck.HeatmapLayer({
      id: 'mcz-heatmap',
      data: data,
      getPosition: function (d) { return [d.longitude, d.latitude]; },
      getWeight: function (d) { return d.weight || 1; },
      radiusPixels: 30,
      intensity: 1,
      threshold: 0.05,
      opacity: 0.9,
      colorRange: (heatmapLayer && heatmapLayer.props && heatmapLayer.props.colorRange) || [
        [0, 255, 255, 0],
        [0, 255, 255, 255],
        [0, 191, 255, 255],
        [0, 127, 255, 255],
        [0, 63, 255, 255],
        [0, 0, 255, 255],
        [0, 0, 223, 255],
        [0, 0, 191, 255],
        [0, 0, 159, 255],
        [0, 0, 127, 255],
        [63, 0, 91, 255],
        [127, 0, 63, 255],
        [191, 0, 31, 255],
        [255, 0, 0, 255]
      ]
    });

    overlay.setProps({ layers: [heatmapLayer] });
  }
}

function changeGradient() {
  if (!window.MCZ_CLEAN_DATA) {
    console.error("changeGradient: data not ready");
    return;
  }

  var data = window.MCZ_CLEAN_DATA;

  var defaultGradient = [
    [0, 255, 255, 0],
    [0, 255, 255, 255],
    [0, 191, 255, 255],
    [0, 127, 255, 255],
    [0, 63, 255, 255],
    [0, 0, 255, 255],
    [0, 0, 223, 255],
    [0, 0, 191, 255],
    [0, 0, 159, 255],
    [0, 0, 127, 255],
    [63, 0, 91, 255],
    [127, 0, 63, 255],
    [191, 0, 31, 255],
    [255, 0, 0, 255]
  ];

  var altGradient = [
    [255, 255, 178, 0],
    [254, 204, 92, 255],
    [253, 141, 60, 255],
    [240, 59, 32, 255],
    [189, 0, 38, 255]
  ];

  // Decide which gradient to use next
  var current = (heatmapLayer && heatmapLayer.props && heatmapLayer.props.colorRange) || defaultGradient;
  var useAlt =
    current.length === altGradient.length &&
    current[0][0] === altGradient[0][0];

  var newColorRange = useAlt ? defaultGradient : altGradient;

  // Rebuild heatmapLayer with new gradient
  heatmapLayer = new deck.HeatmapLayer({
    id: 'mcz-heatmap',
    data: data,
    getPosition: function (d) { return [d.longitude, d.latitude]; },
    getWeight: function (d) { return d.weight || 1; },
    radiusPixels: 30,
    intensity: 1,
    threshold: 0.05,
    opacity: 0.9,
    colorRange: newColorRange
  });

  if (currentView === 'heatmap' && overlay) {
    overlay.setProps({ layers: [heatmapLayer] });
  }

  console.log("changeGradient: updated gradient");
}