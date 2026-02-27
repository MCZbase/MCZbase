// 
//js code for heat map and distribution map include deckgl
//
//
var map;
var overlay;
var heatmapLayer;
var pointLayer;
var heatmapVisible = true;
var useAltGradient = false;
var currentView = 'heatmap';

// This will be filled from the page via a global variable
// e.g., window.MCZ_HEATMAP_DATA
function initMap() {
  if (!window.MCZ_HEATMAP_DATA || !window.MCZ_BOUNDS) {
    console.error("Missing MCZ_HEATMAP_DATA or MCZ_BOUNDS");
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

  var heatmapData = MCZ_HEATMAP_DATA;

  heatmapLayer = new deck.HeatmapLayer({
    id: 'mcz-heatmap',
    data: heatmapData,
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

  pointLayer = new deck.ScatterplotLayer({
    id: 'mcz-points',
    data: heatmapData,
    getPosition: function (d) { return [d.longitude, d.latitude]; },
    getRadius: function () { return 1000; },
    getFillColor: function () { return [0, 255, 0, 180]; },
    radiusMinPixels: 2,
    radiusMaxPixels: 10,
    pickable: false
  });

  currentView = 'heatmap';
  overlay.setProps({ layers: [heatmapLayer] });

  var btnGradient = document.getElementById("change-gradient");
  if (btnGradient) {
    btnGradient.addEventListener("click", changeGradient);
  }

  var btnToggleView = document.getElementById("toggle-view");
  if (btnToggleView) {
    btnToggleView.addEventListener("click", toggleView);
  }
}

function toggleView() {
  if (currentView === 'heatmap') {
    currentView = 'points';
    overlay.setProps({ layers: [pointLayer] });
  } else {
    currentView = 'heatmap';
    overlay.setProps({ layers: [heatmapLayer] });
  }
}

function changeGradient() {
  useAltGradient = !useAltGradient;

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

  var newColorRange = useAltGradient ? altGradient : defaultGradient;

  heatmapLayer = new deck.HeatmapLayer({
    id: heatmapLayer.props.id,
    data: heatmapLayer.props.data,
    getPosition: heatmapLayer.props.getPosition,
    getWeight: heatmapLayer.props.getWeight,
    radiusPixels: heatmapLayer.props.radiusPixels,
    intensity: heatmapLayer.props.intensity,
    threshold: heatmapLayer.props.threshold,
    opacity: heatmapLayer.props.opacity,
    colorRange: newColorRange
  });

  if (currentView === 'heatmap') {
    overlay.setProps({ layers: [heatmapLayer] });
  }
}