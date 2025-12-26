---
title: ODK Central Client Map Architecture Patterns
type: reference
domain: ODK Central
tags:
  - odk-central
  - frontend
  - maps
  - openlayers
  - vue
  - geojson
status: approved
created: 2025-12-26
updated: 2025-12-26
---

# ODK Central Client Map Architecture Patterns

This document describes the map architecture and patterns used in ODK Central frontend for displaying geographic data.

## Overview

ODK Central uses **OpenLayers 10** (not Leaflet) for map visualization. The map system is built around:

- **Core Technology**: OpenLayers 10.x
- **Data Format**: GeoJSON FeatureCollections
- **Rendering**: WebGL for submissions/entities, Vector layers for custom use cases
- **Integration**: Vue 3 Composition API with reactive state

## Core Map Components

### GeojsonMap (WebGL-Based)

**Location**: `client/src/components/geojson-map.vue`

The core map component using OpenLayers WebGL renderer for high-performance rendering of large datasets (submissions, entities).

**Usage**:
```vue
<geojson-map :geojson-data="geojsonData" :sizer="() => 600"/>
```

**Props**:
- `geojsonData`: GeoJSON FeatureCollection with features to display
- `sizer`: Function returning map height in pixels

**Key Features**:
- WebGL rendering for performance
- Clustering for dense point data
- Shared styling from `util/map-styles.js`
- Feature selection and click handling

### MapView (Wrapper Component)

**Location**: `client/src/components/map/view.vue`

Higher-level wrapper around GeojsonMap providing popup integration.

**Pattern**:
```vue
<map-view :geojson-data="geojsonData">
  <template #popup="{ feature, listeners }">
    <custom-popup :feature="feature" v-on="listeners"/>
  </template>
</map-view>
```

**Use Cases**:
- Submission maps
- Entity maps
- Any map requiring feature popups

### MapPopup

**Location**: `client/src/components/map/popup.vue`

Reusable popup component for displaying feature details.

**Pattern**:
```vue
<map-popup v-show="featureId != null" @hide="$emit('hide')">
  <template #title>
    <span>{{ title }}</span>
  </template>
  <template #body>
    <dl>
      <div><dt>Label</dt><dd>Value</dd></div>
    </dl>
  </template>
</map-popup>
```

## Critical Architectural Principle: Isolation

**DO NOT modify shared `util/map-styles.js` for feature-specific needs.**

### Why?

- `map-styles.js` is used by WebGL renderer for submissions/entities
- WebGL shaders have strict type requirements
- Changes can break other maps with shader compilation errors
- Example error: `Fragment shader compilation failed: ERROR: 0:56: '!=' : dimension mismatch`

### Solution: Create Isolated Components

For feature-specific maps (e.g., telemetry, custom visualizations):

1. **Create a dedicated map component** (e.g., `vg-telemetry-simple-map.vue`)
2. **Use standard Vector layers** instead of WebGL
3. **Implement custom styling** within the component
4. **Keep it isolated** from other map functionality

**Example**:
```vue
<!-- vg-telemetry-simple-map.vue -->
<script setup>
import VectorLayer from 'ol/layer/Vector';
import VectorSource from 'ol/source/Vector';
import { Style, Icon, Circle } from 'ol/style';

const vectorLayer = new VectorLayer({
  source: vectorSource,
  style: (feature) => {
    const color = feature.get('markerColor') || '#3388ff';
    return new Style({
      image: new Circle({
        radius: 8,
        fill: new Fill({ color }),
        stroke: new Stroke({ color: '#fff', width: 2 })
      })
    });
  }
});
</script>
```

## OpenLayers Integration Patterns

### Basic Map Setup

**Pattern**:
```javascript
import Map from 'ol/Map';
import View from 'ol/View';
import TileLayer from 'ol/layer/Tile';
import VectorLayer from 'ol/layer/Vector';
import VectorSource from 'ol/source/Vector';
import OSM from 'ol/source/OSM';
import { fromLonLat } from 'ol/proj';

const map = new Map({
  target: mapContainer.value,
  layers: [
    new TileLayer({ source: new OSM() }),
    vectorLayer
  ],
  view: new View({
    center: fromLonLat([0, 0]),
    zoom: 2
  })
});
```

### GeoJSON Data Loading

**Pattern**:
```javascript
import GeoJSON from 'ol/format/GeoJSON';

const features = new GeoJSON().readFeatures(geojsonData, {
  featureProjection: 'EPSG:3857'  // Web Mercator
});

vectorSource.addFeatures(features);

// Fit map to features
const extent = vectorSource.getExtent();
map.getView().fit(extent, { padding: [50, 50, 50, 50], maxZoom: 16 });
```

### Custom Marker Styling

**Using SVG Data URIs**:
```javascript
const createColoredMarker = (color) => {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24">
    <circle cx="12" cy="12" r="8" fill="${color}" stroke="white" stroke-width="2"/>
  </svg>`;
  return `data:image/svg+xml;base64,${btoa(svg)}`;
};

// Use in style function
style: (feature) => new Style({
  image: new Icon({
    src: createColoredMarker(feature.get('markerColor')),
    scale: 1.5
  })
})
```

### Tooltips with Overlays

**Pattern**:
```javascript
import Overlay from 'ol/Overlay';

// Create tooltip element (Vue ref)
const tooltipElement = useTemplateRef('tooltipElement');

// Create overlay
const tooltipOverlay = new Overlay({
  element: tooltipElement.value,
  positioning: 'bottom-center',
  stopEvent: false,
  offset: [0, -15]
});

map.addOverlay(tooltipOverlay);

// Show on hover
map.on('pointermove', (evt) => {
  const feature = map.forEachFeatureAtPixel(evt.pixel, (f) => f);
  if (feature) {
    tooltipOverlay.setPosition(evt.coordinate);
    // Update tooltip content via reactive state
  }
});
```

### Feature Click Handling

**Pattern**:
```javascript
map.on('click', (evt) => {
  const feature = map.forEachFeatureAtPixel(evt.pixel, (f) => f);
  if (feature) {
    emit('feature-click', feature);
  }
});
```

## Vue Integration Patterns

### Template Refs for Map Container

**Pattern**:
```vue
<template>
  <div ref="mapContainer" class="map" :style="{height: height + 'px'}"></div>
</template>

<script setup>
import { onMounted, useTemplateRef } from 'vue';

const mapContainer = useTemplateRef('mapContainer');

onMounted(() => {
  const map = new Map({
    target: mapContainer.value,
    // ... config
  });
});
</script>
```

**CRITICAL**: Map container MUST have explicit height or map won't render.

### Reactive Tooltip State

**Pattern**:
```vue
<script setup>
import { reactive } from 'vue';

const tooltip = reactive({
  visible: false,
  title: '',
  content: ''
});

// Update in event handlers
map.on('pointermove', (evt) => {
  const feature = map.forEachFeatureAtPixel(evt.pixel, (f) => f);
  if (feature) {
    tooltip.title = feature.get('name');
    tooltip.content = feature.get('description');
    tooltip.visible = true;
  } else {
    tooltip.visible = false;
  }
});
</script>
```

### Watching Data Changes

**Pattern**:
```javascript
import { watch } from 'vue';

watch(() => props.geojsonData, () => {
  loadFeatures();
}, { deep: true });

const loadFeatures = () => {
  vectorSource.clear();
  const features = new GeoJSON().readFeatures(props.geojsonData, {
    featureProjection: 'EPSG:3857'
  });
  vectorSource.addFeatures(features);

  if (features.length > 0) {
    const extent = vectorSource.getExtent();
    map.getView().fit(extent, { padding: [50, 50, 50, 50], maxZoom: 16 });
  }
};
```

## GeoJSON Data Transformation

### From API Data to GeoJSON

**Pattern**:
```javascript
computed: {
  geojsonData() {
    if (!this.records || this.records.length === 0) return null;

    return {
      type: 'FeatureCollection',
      features: this.records
        .filter(r => r.location?.latitude != null && r.location?.longitude != null)
        .filter(r => !(r.location.latitude === 0 && r.location.longitude === 0))  // Filter null island
        .map(r => ({
          type: 'Feature',
          id: `record-${r.id}`,
          geometry: {
            type: 'Point',
            coordinates: [r.location.longitude, r.location.latitude]
          },
          properties: {
            id: r.id,
            name: r.name,
            timestamp: r.createdAt,
            // Custom styling properties
            markerColor: this.getColorForRecord(r),
            markerIcon: this.createMarkerIcon(r)
          }
        }))
    };
  }
}
```

**Best Practices**:
- Always filter out invalid coordinates (null, undefined, 0,0)
- Include all data needed for popups in `properties`
- Use unique `id` for each feature
- Coordinates order: `[longitude, latitude]` (NOT lat, lon)

## Common Issues and Solutions

### 1. Map Not Rendering

**Symptoms**: Blank space where map should be, no errors

**Causes & Solutions**:

1. **Async Component Loading**
   - Problem: `defineAsyncComponent()` prevents initial render
   - Solution: Use synchronous imports
   ```javascript
   // ❌ Don't
   import { defineAsyncComponent } from 'vue';
   const MapView = defineAsyncComponent(() => import('./map-view.vue'));

   // ✅ Do
   import MapView from './map-view.vue';
   ```

2. **Missing Height**
   - Problem: Map container has no height, ResizeObserver never triggers
   - Solution: Set explicit height
   ```vue
   <div ref="mapContainer" :style="{height: height + 'px'}"></div>
   ```

3. **Data Not Ready**
   - Problem: Map created before geojsonData is available
   - Solution: Use conditional rendering or watch
   ```vue
   <map-view v-if="geojsonData != null" :geojson-data="geojsonData"/>
   ```

### 2. Popup Z-Index Issues

**Problem**: Popup appears behind other elements (filters, headers)

**Solution**: Add explicit z-index
```scss
.map-popup {
  z-index: 1000;
}
```

### 3. WebGL Shader Compilation Errors

**Symptoms**: Console errors like `Fragment shader compilation failed: dimension mismatch`

**Cause**: Modified shared `map-styles.js` with WebGL-incompatible filters

**Solution**: Don't modify `map-styles.js`. Create isolated component with Vector layer instead.

### 4. Canvas2D Performance Warning

**Warning**: `willReadFrequently attribute set to true`

**Cause**: OpenLayers internal canvas operations

**Impact**: Informational only, doesn't affect functionality

**Action**: Can be ignored or optimized by configuring OpenLayers canvas context (advanced)

### 5. Invalid Coordinates

**Problem**: Map shows points at (0, 0) in the ocean ("Null Island")

**Solution**: Filter invalid coordinates
```javascript
.filter(r => r.location?.latitude != null && r.location?.longitude != null)
.filter(r => !(r.location.latitude === 0 && r.location.longitude === 0))
```

### 6. Map Not Fitting to Features

**Problem**: Map doesn't zoom to show all features

**Solution**: Use `fit()` after loading features
```javascript
const extent = vectorSource.getExtent();
map.getView().fit(extent, {
  padding: [50, 50, 50, 50],  // Top, right, bottom, left
  maxZoom: 16  // Prevent excessive zoom on single point
});
```

## Example: Feature-Specific Map Component

**Use Case**: Telemetry map with user-specific colored markers and hover tooltips

```vue
<!-- vg-telemetry-simple-map.vue -->
<template>
  <div class="map-wrapper">
    <div ref="mapContainer" class="map" :style="{height: height + 'px'}"></div>
    <div ref="tooltipElement" class="tooltip" v-show="tooltip.visible">
      <div><strong>{{ tooltip.user }}</strong></div>
      <div>Device: {{ tooltip.device }}</div>
      <div>{{ tooltip.dateTime }}</div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, watch, useTemplateRef, reactive } from 'vue';
import Map from 'ol/Map';
import View from 'ol/View';
import TileLayer from 'ol/layer/Tile';
import VectorLayer from 'ol/layer/Vector';
import VectorSource from 'ol/source/Vector';
import OSM from 'ol/source/OSM';
import GeoJSON from 'ol/format/GeoJSON';
import Overlay from 'ol/Overlay';
import { Style, Circle, Fill, Stroke } from 'ol/style';
import { fromLonLat } from 'ol/proj';

const props = defineProps({
  geojsonData: { type: Object, required: true },
  height: { type: Number, default: 600 }
});

const mapContainer = useTemplateRef('mapContainer');
const tooltipElement = useTemplateRef('tooltipElement');
let map = null;
let vectorSource = null;
let tooltipOverlay = null;

const tooltip = reactive({
  visible: false,
  user: '',
  device: '',
  dateTime: ''
});

onMounted(() => {
  vectorSource = new VectorSource();

  const vectorLayer = new VectorLayer({
    source: vectorSource,
    style: (feature) => {
      const color = feature.get('markerColor') || '#3388ff';
      return new Style({
        image: new Circle({
          radius: 8,
          fill: new Fill({ color }),
          stroke: new Stroke({ color: '#fff', width: 2 })
        })
      });
    }
  });

  tooltipOverlay = new Overlay({
    element: tooltipElement.value,
    positioning: 'bottom-center',
    stopEvent: false,
    offset: [0, -15]
  });

  map = new Map({
    target: mapContainer.value,
    layers: [
      new TileLayer({ source: new OSM() }),
      vectorLayer
    ],
    view: new View({
      center: fromLonLat([0, 0]),
      zoom: 2
    }),
    overlays: [tooltipOverlay]
  });

  // Hover handler
  map.on('pointermove', (evt) => {
    const feature = map.forEachFeatureAtPixel(evt.pixel, (f) => f);
    if (feature) {
      tooltip.user = feature.get('userName');
      tooltip.device = feature.get('deviceId');
      tooltip.dateTime = formatDateTime(feature.get('timestamp'));
      tooltip.visible = true;
      tooltipOverlay.setPosition(evt.coordinate);
      map.getTargetElement().style.cursor = 'pointer';
    } else {
      tooltip.visible = false;
      map.getTargetElement().style.cursor = '';
    }
  });

  loadFeatures();
});

const loadFeatures = () => {
  if (!props.geojsonData || !vectorSource) return;

  vectorSource.clear();
  const features = new GeoJSON().readFeatures(props.geojsonData, {
    featureProjection: 'EPSG:3857'
  });

  if (features.length === 0) return;

  vectorSource.addFeatures(features);
  const extent = vectorSource.getExtent();
  map.getView().fit(extent, { padding: [50, 50, 50, 50], maxZoom: 16 });
};

watch(() => props.geojsonData, loadFeatures, { deep: true });

const formatDateTime = (iso) => {
  if (!iso) return '';
  return new Date(iso).toLocaleString();
};
</script>

<style lang="scss" scoped>
.map-wrapper {
  position: relative;
}

.map {
  width: 100%;
  min-height: 400px;
}

.tooltip {
  position: absolute;
  background-color: rgba(0, 0, 0, 0.85);
  color: white;
  padding: 8px 12px;
  border-radius: 4px;
  font-size: 13px;
  pointer-events: none;
  white-space: nowrap;
  z-index: 1000;

  strong {
    font-weight: 600;
  }
}
</style>
```

## Complete Example: Custom Map Architecture (Isolated from Standard Maps)

This section demonstrates a complete multi-component architecture for adding custom maps without interfering with standard submission/entity maps.

### The Problem

You need to add a custom map feature (e.g., telemetry visualization) with:
- Custom marker colors per user
- Hover tooltips instead of click popups
- Table/map view toggle with shared filters

**Requirements**:
- Must NOT affect submission maps or entity maps
- Must NOT modify shared `util/map-styles.js`
- Must NOT break WebGL rendering in other maps

### The Solution: Isolated Component Architecture

Create three isolated components that work together:

1. **Simple Map Component** - Low-level OpenLayers map with custom styling
2. **Map View Wrapper** - Integrates map with optional popup
3. **Parent Component** - Manages data, filters, and view toggle

**File Structure**:
```
client/src/components/project/
├── vg-telemetry.vue              # Parent: data, filters, view toggle
├── vg-telemetry-map-view.vue     # Wrapper: integrates map + popup
├── vg-telemetry-simple-map.vue   # Isolated map with custom styling
└── vg-telemetry-map-popup.vue    # Popup for detailed info
```

### Component 1: Isolated Simple Map (vg-telemetry-simple-map.vue)

**Purpose**: Self-contained OpenLayers map with custom marker styling and hover tooltips.

**Key Points**:
- Uses standard Vector layer (NOT WebGL)
- Contains all OpenLayers setup
- Custom styling isolated within component
- No dependencies on shared map utilities

```vue
<!--
Copyright 2025 ODK Central Developers
Licensed under Apache 2.0
-->
<template>
  <div class="telemetry-map-wrapper">
    <div ref="mapContainer" class="telemetry-simple-map"
         :style="{height: height + 'px'}"></div>
    <div ref="tooltipElement" class="telemetry-tooltip" v-show="tooltip.visible">
      <div><strong>{{ tooltip.user }}</strong></div>
      <div>Device: {{ tooltip.device }}</div>
      <div>{{ tooltip.dateTime }}</div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, watch, useTemplateRef, reactive } from 'vue';
import Map from 'ol/Map';
import View from 'ol/View';
import TileLayer from 'ol/layer/Tile';
import VectorLayer from 'ol/layer/Vector';
import VectorSource from 'ol/source/Vector';
import OSM from 'ol/source/OSM';
import GeoJSON from 'ol/format/GeoJSON';
import Overlay from 'ol/Overlay';
import { Style, Icon, Circle, Fill, Stroke } from 'ol/style';
import { fromLonLat } from 'ol/proj';

defineOptions({
  name: 'VgTelemetrySimpleMap'
});

const props = defineProps({
  geojsonData: {
    type: Object,
    required: true
  },
  height: {
    type: Number,
    default: 600
  },
  appUsers: {
    type: Array,
    default: () => []
  }
});

const mapContainer = useTemplateRef('mapContainer');
const tooltipElement = useTemplateRef('tooltipElement');
let map = null;
let vectorSource = null;
let tooltipOverlay = null;

const tooltip = reactive({
  visible: false,
  user: '',
  device: '',
  dateTime: ''
});

const formatDateTime = (isoString) => {
  if (!isoString) return '';
  const date = new Date(isoString);
  return date.toLocaleString();
};

const getAppUserName = (appUserId) => {
  const user = props.appUsers.find(u => u.id === appUserId);
  return user?.displayName || 'Unknown';
};

onMounted(() => {
  // Create vector source
  vectorSource = new VectorSource();

  // Create vector layer with custom styling
  // NOTE: This styling is ISOLATED - doesn't use map-styles.js
  const vectorLayer = new VectorLayer({
    source: vectorSource,
    style: (feature) => {
      const markerIcon = feature.get('markerIcon');
      const markerColor = feature.get('markerColor') || '#3388ff';

      if (markerIcon) {
        // Use custom colored icon from SVG data URI
        return new Style({
          image: new Icon({
            src: markerIcon,
            scale: 1.5
          })
        });
      }

      // Fallback to circle style
      return new Style({
        image: new Circle({
          radius: 8,
          fill: new Fill({ color: markerColor }),
          stroke: new Stroke({ color: '#fff', width: 2 })
        })
      });
    }
  });

  // Create tooltip overlay
  tooltipOverlay = new Overlay({
    element: tooltipElement.value,
    positioning: 'bottom-center',
    stopEvent: false,
    offset: [0, -15]
  });

  // Create map instance
  map = new Map({
    target: mapContainer.value,
    layers: [
      new TileLayer({ source: new OSM() }),
      vectorLayer
    ],
    view: new View({
      center: fromLonLat([0, 0]),
      zoom: 2
    }),
    overlays: [tooltipOverlay]
  });

  // Add hover handler for tooltips
  map.on('pointermove', (evt) => {
    const feature = map.forEachFeatureAtPixel(evt.pixel, (f) => f);

    if (feature) {
      // Show tooltip
      const appUserId = feature.get('appUserId');
      const deviceId = feature.get('deviceId');
      const dateTime = feature.get('dateTime');

      tooltip.user = getAppUserName(appUserId);
      tooltip.device = deviceId || 'Unknown';
      tooltip.dateTime = formatDateTime(dateTime);
      tooltip.visible = true;

      tooltipOverlay.setPosition(evt.coordinate);

      // Change cursor to pointer
      map.getTargetElement().style.cursor = 'pointer';
    } else {
      // Hide tooltip
      tooltip.visible = false;
      map.getTargetElement().style.cursor = '';
    }
  });

  // Load initial data
  loadFeatures();
});

const loadFeatures = () => {
  if (!props.geojsonData || !vectorSource) return;

  // Clear existing features
  vectorSource.clear();

  // Read features from GeoJSON
  const features = new GeoJSON().readFeatures(props.geojsonData, {
    featureProjection: 'EPSG:3857'
  });

  if (features.length === 0) return;

  // Add features to source
  vectorSource.addFeatures(features);

  // Fit map to features
  const extent = vectorSource.getExtent();
  map.getView().fit(extent, { padding: [50, 50, 50, 50], maxZoom: 16 });
};

// Watch for data changes
watch(() => props.geojsonData, () => {
  loadFeatures();
}, { deep: true });
</script>

<style lang="scss">
.telemetry-map-wrapper {
  position: relative;
}

.telemetry-simple-map {
  width: 100%;
  min-height: 400px;

  .ol-zoom {
    top: 0.5em;
    left: auto;
    right: 0.5em;
  }
}

.telemetry-tooltip {
  position: absolute;
  background-color: rgba(0, 0, 0, 0.85);
  color: white;
  padding: 8px 12px;
  border-radius: 4px;
  font-size: 13px;
  line-height: 1.4;
  pointer-events: none;
  white-space: nowrap;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
  z-index: 1000;

  strong {
    font-weight: 600;
  }

  div {
    margin: 2px 0;
  }

  &::after {
    content: '';
    position: absolute;
    bottom: -6px;
    left: 50%;
    transform: translateX(-50%);
    width: 0;
    height: 0;
    border-left: 6px solid transparent;
    border-right: 6px solid transparent;
    border-top: 6px solid rgba(0, 0, 0, 0.85);
  }
}
</style>
```

### Component 2: Map View Wrapper (vg-telemetry-map-view.vue)

**Purpose**: Thin wrapper that integrates the simple map with optional popup component.

**Key Points**:
- Manages feature selection state
- Passes data to both map and popup
- Can be extended with additional controls

```vue
<!--
Copyright 2025 ODK Central Developers
Licensed under Apache 2.0
-->
<template>
  <div id="telemetry-map-view" ref="el">
    <vg-telemetry-simple-map
      :geojson-data="geojsonData"
      :height="600"
      :app-users="appUsers"
      @feature-click="handleFeatureClick"/>
    <vg-telemetry-map-popup :telemetry-id="selectedTelemetryId"
      :feature="selectedFeature" :app-users="appUsers"
      @hide="hidePopup"/>
  </div>
</template>

<script setup>
import { shallowRef } from 'vue';

import VgTelemetrySimpleMap from './vg-telemetry-simple-map.vue';
import VgTelemetryMapPopup from './vg-telemetry-map-popup.vue';

defineOptions({
  name: 'VgTelemetryMapView'
});

const props = defineProps({
  geojsonData: {
    type: Object,
    default: null
  },
  appUsers: {
    type: Array,
    default: () => []
  }
});

const selectedFeature = shallowRef(null);
const selectedTelemetryId = shallowRef(null);

const handleFeatureClick = (feature) => {
  if (!feature) return;

  // Convert OpenLayers feature to simple object
  selectedFeature.value = {
    id: feature.getId(),
    properties: feature.getProperties()
  };
  selectedTelemetryId.value = feature.getId();
};

const hidePopup = () => {
  selectedFeature.value = null;
  selectedTelemetryId.value = null;
};
</script>

<style lang="scss">
#telemetry-map-view {
  min-height: 500px;
}
</style>
```

### Component 3: Parent Component (vg-telemetry.vue)

**Purpose**: Manages data fetching, filtering, GeoJSON transformation, and view toggle.

**Key Points**:
- Transforms API data to GeoJSON
- Generates user-specific colors
- Creates SVG marker icons
- Manages table/map view state
- Filters work for both views

```vue
<template>
  <div id="project-telemetry">
    <div class="page-body-heading">
      <p>{{ $t('heading') }}</p>
    </div>

    <loading :state="initiallyLoading"/>

    <!-- Filters (work for both table and map) -->
    <form class="telemetry-filters" @submit.prevent="applyFilters">
      <label class="form-group">
        <select v-model.number="filters.appUserId" class="form-control">
          <option :value="null">{{ $t('filter.anyUser') }}</option>
          <option v-for="fieldKey of appUsers" :key="fieldKey.id"
                  :value="fieldKey.id">
            {{ fieldKey.displayName }} ({{ fieldKey.username }})
          </option>
        </select>
        <span class="form-label">{{ $t('filter.appUser') }}</span>
      </label>

      <form-group v-model.trim="filters.deviceId"
        :placeholder="$t('filter.deviceId')"/>

      <form-group v-model="filters.dateFrom" type="datetime-local"
        :placeholder="$t('filter.dateFrom')"/>

      <form-group v-model="filters.dateTo" type="datetime-local"
        :placeholder="$t('filter.dateTo')"/>

      <div class="filter-actions">
        <button type="submit" class="btn btn-primary">
          {{ $t('action.apply') }}
        </button>
        <button type="button" class="btn btn-link" @click="clearFilters">
          {{ $t('action.clear') }}
        </button>
      </div>
    </form>

    <!-- View toggle -->
    <radio-field v-model="dataView" :options="viewOptions"
      :button-appearance="true"/>

    <!-- Table view -->
    <table v-if="dataView === 'table' && telemetry.length !== 0" class="table">
      <thead>
        <tr>
          <th>{{ $t('header.receivedAt') }}</th>
          <th>{{ $t('header.appUser') }}</th>
          <th>{{ $t('header.deviceId') }}</th>
          <th>{{ $t('header.location') }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="row of telemetry" :key="row.id">
          <td><date-time :iso="row.dateTime"/></td>
          <td>{{ appUserName(row.appUserId) }}</td>
          <td>{{ row.deviceId }}</td>
          <td class="location">
            <template v-if="row.location">
              {{ row.location.latitude }}, {{ row.location.longitude }}
            </template>
            <template v-else>{{ $t('common.notAvailable') }}</template>
          </td>
        </tr>
      </tbody>
    </table>

    <!-- Map view (ISOLATED from standard maps) -->
    <vg-telemetry-map-view v-else-if="dataView === 'map' && geojsonData != null"
      :geojson-data="geojsonData" :app-users="appUsers"/>

    <!-- Empty states -->
    <p v-else-if="!initiallyLoading && telemetry.length === 0"
       class="empty-table-message">
      {{ $t('emptyTable') }}
    </p>
    <p v-else-if="!initiallyLoading && dataView === 'map' &&
                  (geojsonData == null || geojsonData.features.length === 0)"
       class="empty-table-message">
      {{ $t('emptyMap') }}
    </p>

    <pagination v-if="dataView === 'table' && totalCount > 0"
                v-model:page="pagination.page"
                v-model:size="pagination.size" :count="totalCount"/>
  </div>
</template>

<script>
import DateTime from '../date-time.vue';
import FormGroup from '../form-group.vue';
import Loading from '../loading.vue';
import Pagination from '../pagination.vue';
import RadioField from '../radio-field.vue';
import VgTelemetryMapView from './vg-telemetry-map-view.vue';

import useDataView from '../../composables/data-view';
import useRequest from '../../composables/request';
import { useRequestData } from '../../request-data';
import { apiPaths } from '../../util/request';

export default {
  name: 'VgProjectTelemetry',
  components: {
    DateTime, FormGroup, Loading, Pagination, RadioField, VgTelemetryMapView
  },
  setup() {
    const { fieldKeys } = useRequestData();
    const { request, awaitingResponse } = useRequest();
    const { dataView, options: viewOptions } = useDataView();
    return { fieldKeys, request, awaitingResponse, dataView, viewOptions };
  },
  data() {
    return {
      telemetry: [],
      totalCount: 0,
      initiallyLoading: false,
      pagination: { page: 0, size: 10 },
      filters: {
        appUserId: null,
        deviceId: '',
        dateFrom: '',
        dateTo: ''
      }
    };
  },
  computed: {
    appUsers() {
      return (this.fieldKeys?.dataExists)
        ? Array.from(this.fieldKeys)
        : [];
    },

    // Transform API data to GeoJSON with custom styling
    geojsonData() {
      if (!this.telemetry || this.telemetry.length === 0) return null;

      // Generate colors for each unique app user
      const userColors = this.getUserColors();

      return {
        type: 'FeatureCollection',
        features: this.telemetry
          .filter(t => t.location?.latitude != null && t.location?.longitude != null)
          // Filter out 0,0 coordinates (null island - invalid location data)
          .filter(t => !(t.location.latitude === 0 && t.location.longitude === 0))
          .map(t => {
            const color = userColors[t.appUserId] || '#3388ff';
            return {
              type: 'Feature',
              id: `telemetry-${t.id}`,
              geometry: {
                type: 'Point',
                coordinates: [t.location.longitude, t.location.latitude]
              },
              properties: {
                id: t.id,
                deviceId: t.deviceId,
                appUserId: t.appUserId,
                collectVersion: t.collectVersion,
                deviceDateTime: t.deviceDateTime,
                dateTime: t.dateTime,
                location: t.location,
                // Custom styling properties (ISOLATED from standard maps)
                markerColor: color,
                markerIcon: this.createColoredMarkerIcon(color)
              }
            };
          })
      };
    }
  },
  methods: {
    getUserColors() {
      // Distinct color palette for different users
      const colorPalette = [
        '#e41a1c', '#377eb8', '#4daf4a', '#984ea3',
        '#ff7f00', '#ffff33', '#a65628', '#f781bf',
        '#999999', '#1b9e77', '#d95f02', '#7570b3',
        '#e7298a', '#66a61e', '#e6ab02', '#a6761d'
      ];

      const uniqueUserIds = [...new Set(this.telemetry.map(t => t.appUserId))];
      const userColors = {};
      uniqueUserIds.forEach((userId, index) => {
        userColors[userId] = colorPalette[index % colorPalette.length];
      });

      return userColors;
    },

    createColoredMarkerIcon(color) {
      // Create SVG circle marker with specified color
      const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
        <circle cx="12" cy="12" r="8" fill="${color}" stroke="white" stroke-width="2"/>
      </svg>`;
      // Convert to data URI
      return `data:image/svg+xml;base64,${btoa(svg)}`;
    },

    appUserName(appUserId) {
      const match = this.fieldKeys?.find(fk => fk.id === appUserId);
      return match?.displayName ?? 'Unknown';
    },

    applyFilters() {
      this.fetchTelemetry(true);
    },

    clearFilters() {
      this.filters = {
        appUserId: null,
        deviceId: '',
        dateFrom: '',
        dateTo: ''
      };
      this.fetchTelemetry(true);
    },

    fetchTelemetry(resetPage = false) {
      if (resetPage && this.pagination.page !== 0) {
        this.pagination.page = 0;
        return;
      }

      if (this.telemetry.length === 0) this.initiallyLoading = true;

      const query = {
        projectId: Number(this.projectId),
        appUserId: this.filters.appUserId ?? undefined,
        deviceId: this.filters.deviceId.trim() || undefined,
        dateFrom: this.filters.dateFrom || undefined,
        dateTo: this.filters.dateTo || undefined,
        limit: this.pagination.size,
        offset: this.pagination.page * this.pagination.size
      };

      this.request({ url: apiPaths.systemAppUserTelemetry(query) })
        .then(response => {
          this.totalCount = Number(response.headers['x-total-count']) || 0;
          this.telemetry = response.data;
          this.initiallyLoading = false;
        })
        .catch(() => {
          this.initiallyLoading = false;
        });
    }
  }
};
</script>
```

### Why This Architecture Works

**Isolation Achieved**:
1. ✅ **No shared dependencies**: Custom map doesn't import `map-styles.js`
2. ✅ **Separate rendering**: Uses Vector layer, not WebGL
3. ✅ **Independent styling**: All styles contained within component
4. ✅ **No side effects**: Doesn't affect submission/entity maps

**Maintainability**:
- Clear separation of concerns (data, view, rendering)
- Easy to modify custom map without touching standard maps
- Can be extended with additional features independently
- Follows Vue component best practices

**Reusability**:
- Simple map component can be used in other contexts
- Pattern can be replicated for other custom visualizations
- Components are self-documenting

### What NOT to Do

❌ **Don't modify shared map utilities**:
```javascript
// ❌ WRONG - Don't do this
// util/map-styles.js
export const getStyles = () => [
  // ... existing styles ...
  {
    filter: all(/* custom filter for telemetry */),  // BREAKS OTHER MAPS
    style: /* custom style */
  }
];
```

❌ **Don't extend GeojsonMap with feature-specific logic**:
```vue
<!-- ❌ WRONG - Don't do this -->
<!-- geojson-map.vue -->
<script>
export default {
  props: {
    // ... existing props ...
    telemetryMode: Boolean,  // POLLUTES SHARED COMPONENT
    userColors: Object       // ADDS FEATURE-SPECIFIC CODE
  }
}
</script>
```

❌ **Don't use conditional logic in shared components**:
```javascript
// ❌ WRONG - Don't do this
// In geojson-map.vue or map-styles.js
if (this.telemetryMode) {
  // Apply telemetry-specific styling
  // This makes the shared component complex and fragile
}
```

### Do This Instead

✅ **Create isolated components**:
```vue
<!-- ✅ CORRECT -->
<!-- vg-telemetry-simple-map.vue -->
<script setup>
// Self-contained OpenLayers setup
// No dependencies on shared map utilities
// All custom logic isolated here
</script>
```

✅ **Use composition, not modification**:
```vue
<!-- ✅ CORRECT -->
<!-- vg-telemetry-map-view.vue -->
<template>
  <!-- Compose with custom map component -->
  <vg-telemetry-simple-map :geojson-data="geojsonData"/>
</template>
```

✅ **Transform data at the parent level**:
```javascript
// ✅ CORRECT - In vg-telemetry.vue
computed: {
  geojsonData() {
    return {
      features: this.telemetry.map(t => ({
        properties: {
          markerColor: this.getUserColor(t.appUserId),
          markerIcon: this.createIcon(t)
        }
      }))
    };
  }
}
```

### Testing Isolation

To verify your custom map doesn't interfere with standard maps:

1. **Navigate to submission map**: `/projects/{id}/submissions`
2. **Check for errors**: Console should be clean
3. **Test interactions**: Click features, verify popups work
4. **Navigate to your custom map**: Should work independently
5. **Go back to submissions**: Should still work correctly

If you see errors in submission maps after adding your custom map, you've broken isolation.

## Best Practices

### Do's

✅ Use synchronous imports for map components
✅ Set explicit height on map containers
✅ Filter invalid coordinates (null, 0,0)
✅ Create isolated components for feature-specific maps
✅ Use Vector layers for custom styling needs
✅ Include all popup data in GeoJSON properties
✅ Use reactive state for tooltips/popups
✅ Fit map to features after loading
✅ Add z-index to popups/overlays

### Don'ts

❌ Don't modify `util/map-styles.js` for feature-specific needs
❌ Don't use `defineAsyncComponent` for maps
❌ Don't forget to set map container height
❌ Don't include credentials in feature properties
❌ Don't skip coordinate validation
❌ Don't use WebGL for simple custom styling
❌ Don't forget to clean up map instances on unmount

## Table/Map View Toggle Pattern

**Use Case**: Switching between table and map views of the same data

**Pattern** (using `useDataView` composable):

```vue
<template>
  <div>
    <!-- Filters -->
    <form @submit.prevent="applyFilters">
      <!-- filter inputs -->
    </form>

    <!-- View toggle -->
    <radio-field v-model="dataView" :options="viewOptions"
      :button-appearance="true"/>

    <!-- Table view -->
    <table v-if="dataView === 'table' && data.length > 0">
      <!-- table content -->
    </table>

    <!-- Map view -->
    <custom-map-view v-else-if="dataView === 'map' && geojsonData != null"
      :geojson-data="geojsonData"/>

    <!-- Empty states -->
    <p v-else-if="data.length === 0">No data found</p>
    <p v-else-if="dataView === 'map' && geojsonData == null">No location data</p>

    <!-- Pagination (table only) -->
    <pagination v-if="dataView === 'table'" v-model:page="page"/>
  </div>
</template>

<script>
import useDataView from '../../composables/data-view';

export default {
  setup() {
    const { dataView, options: viewOptions } = useDataView();
    return { dataView, viewOptions };
  },
  computed: {
    geojsonData() {
      // Transform data to GeoJSON
    }
  }
};
</script>
```

## Performance Considerations

### When to Use WebGL (GeojsonMap)

Use for:
- Large datasets (1000+ features)
- Submissions/entities (existing pattern)
- Standard feature styling

### When to Use Vector Layers

Use for:
- Custom marker styling
- Feature-specific maps
- Interactive features (hover, custom tooltips)
- Moderate datasets (<1000 features)

### Optimization Tips

1. **Limit features**: Use pagination or filtering to reduce feature count
2. **Simplify geometries**: Don't include unnecessary coordinate precision
3. **Lazy load**: Only load map when view is activated
4. **Debounce updates**: Avoid excessive re-renders on data changes
5. **Clean up**: Remove event listeners and destroy map on unmount

## Related

- [[client-ui-patterns]] - General UI patterns
- [[vg-client-customizations]] - VG fork customizations

## References

- client/src/components/geojson-map.vue - Core WebGL map
- client/src/components/map/view.vue - Map wrapper
- client/src/components/map/popup.vue - Popup component
- client/src/util/map-styles.js - Shared WebGL styles (DO NOT MODIFY)
- client/src/components/submission/map-view.vue - Submission map pattern
- OpenLayers 10 Documentation: https://openlayers.org/
