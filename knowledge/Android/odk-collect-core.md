---
title: ODK Collect Core Architecture
type: reference
domain: Android Development
tags:
  - odk
  - architecture
  - android
  - mvvm
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# ODK Collect Core Architecture

## Overview
ODK Collect is a data collection Android app centered around the XForms standard. It uses **JavaRosa** as the form engine and follows modern Android architecture guidelines (MVVM, Repository Pattern).

## Key Modules

### `collect_app`
The main application module containing the UI and business logic.
- **Activities**: `MainMenuActivity`, `FormEntryActivity`.
- **Fragments**: Used extensively for navigation and reusable UI.
- **Views**: Custom views for specific Question Widgets (e.g., `StringWidget`, `GeoPointWidget`).

### `android-common`
Shared Android utilities used across different ODK tools.

### `projects` / `settings`
Manages multi-project support. ODK Collect allows switching between different "Projects" (Servers), each with its own configuration and form isolation.

### `open-rosa`
Handles the networking layer compliant with the OpenRosa API standard (Form List, Submission, Headers).

## Key Components & Defaults

### Main Entry Point
- **Activity**: `MainMenuActivity` is the dashboard.
- **Form Entry**: `FormEntryActivity` handles the actual filling of forms (navigating prompts).

### Identifiers
- **Device ID (Install ID)**: A semi-anonymous identifier formatted as `collect:randomString(16)`. Stored in `MetaKeys.KEY_INSTALL_ID`. ODK Collect does NOT use the persistent hardware IMEI/Android ID.
- **Project ID**:
    -   **Internal**: A UUID (e.g., `8a7b...`) used locally to scope databases/files.
    -   **Server (Central)**: Typically an **Integer** (e.g., `1`), derived from the URL (e.g., `.../projects/1`).
-   **User ID**: Often synonymous with the basic auth username or a specialized metadata field depending on form configuration.

### Submission Logic
Collect determines where to send data in this order:
1.  **Form Definition** (Priority): The `<submission action="...">` attribute in the Form XML. For **ODK Central**, this is usually a tokenized URL (e.g., `.../v1/key/{token}/submission`).
2.  **Legacy Fallback**: `KEY_SERVER_URL` + `/submission`.

### Multi-Project Architecture
ODK Collect supports multiple independent "Projects" (Servers), allowing users to switch contexts without data leakage.

1.  **Project Registry**:
    -   Stored in `meta` shared preferences under `MetaKeys.KEY_PROJECTS`.
    -   **Format**: JSON Array of objects containing properties like `uuid`, `name`, `icon`, `color`.
    -   **Current Project**: `MetaKeys.CURRENT_PROJECT_ID` stores the UUID of the active project.

2.  **Per-Project Isolation**:
    -   **Preferences**: Each project has its own settings files, suffixed with the Project UUID.
        -   **General**: `general_prefs<uuid>` (Server URL, Form settings).
        -   **Admin**: `admin_prefs<uuid>` (Password, Access control).
    -   **Storage**: Files are stored in project-specific directories: `/Android/data/.../files/projects/<uuid>/`.

### Detailed Preferences
Key preferences stored in `general_prefs<uuid>` (via `ProjectKeys`):

**1. Server Configuration**
-   `KEY_SERVER_URL`: OpenRosa Endpoint (e.g., `https://example.com`).
-   `KEY_USERNAME` / `KEY_PASSWORD`: Basic Auth credentials.

**2. Form Management**
-   `KEY_AUTOSEND`: (`off`, `wifi_only`, `cellular_only`) - Auto-upload finalized forms.
-   `KEY_INSTANCE_SYNC`: (`true`/`false`) - Auto-download updates to existing instances.
-   `KEY_PERIODIC_FORM_UPDATES_CHECK`: Frequency of blank form updates.
-   `KEY_IMAGE_SIZE`: (`original_image_size`, `very_small`, etc.) - Downscaling factor.

**3. User Interface**
-   `KEY_APP_LANGUAGE`: Override system language.
-   `KEY_NAVIGATION`: (`swipe`, `buttons`, `both`).
-   `KEY_FONT_SIZE`: Question text size.

**4. Maps**
-   `KEY_BASEMAP_SOURCE`: (`google`, `mapbox`, `osm`).
-   `KEY_REFERENCE_LAYER`: Path to offline layer file.

**5. Metadata (Form Audit)**
-   `KEY_METADATA_USERNAME`: Injected into `username` meta field.
-   `KEY_METADATA_EMAIL`: Injected into `email` meta field.
-   `KEY_METADATA_PHONENUMBER`: Injected into `phonenumber` meta field.

## Core Technologies
- **Dagger 2**: Dependency Injection.
- **RxJava / Coroutines**: Asynchronous operations (Disk I/O, Network).
- **Jetpack Components**: `ViewModel`, `LiveData`, `Room` (Database).
- **JavaRosa**: External library for parsing XForms and managing Form Controller logic.

## Data Storage
- **SQLite**: Stores metadata about forms (`forms.db`) and instances (`instances.db`).
- **Disk**: XML files and media attachments are stored in scoped storage: `/Android/data/org.odk.collect.android/files/projects/{uuid}/...`.

## Key Workflows
1.  **Get Blank Form**: Fetch XML definition from OpenRosa server -> Save to Disk -> Register in DB.
2.  **Fill Form**: `FormEntryActivity` loads XML via JavaRosa -> Renders Widgets -> User inputs data.
3.  **Finalize**: Save answers to `instance.xml` -> Mark as Complete.
4.  **Send**: Upload `instance.xml` + attachments to Submission URL.
