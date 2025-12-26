---
title: ODK Module Refactoring & Best Practices
type: howto
domain: Android Development
tags:
  - refactoring
  - odk
  - android
  - dagger
  - testing
  - gradle
status: draft
created: 2025-12-26
---

# ODK Module Refactoring & Best Practices

This guide documents patterns, issues, and solutions encountered when refactoring modules within the ODK Collect codebase (specifically derived from the `aiims-auth-module` refactor).

## 1. Module Configuration & Naming

### Naming Convention
*   **Pattern:** Modules should use **lowercase, dash-separated** names.
*   **Bad:** `aiims_auth_module` (underscores)
*   **Good:** `aiims-auth-module` (dashes)
*   **Action:** Rename directory and update `settings.gradle` (`include ':aiims-auth-module'`).

### Quality Checks
All modules must enforce project-wide quality standards.
*   **Action:** Add the following to the bottom of the module's `build.gradle`:
    ```groovy
    apply from: '../config/quality.gradle'
    ```
*   **Tools Enforced:** `Checkstyle` (Java), `PMD` (Java), `KtLint` (Kotlin).
*   **Command:** Run `./gradlew :module-name:ktlintCheck` or `./gradlew :module-name:ktlintFormat` to verify/fix.

## 2. Dependency Injection (Dagger 2)

ODK Collect uses Dagger 2. Avoid manual Singleton patterns (`getInstance()`) which make testing difficult.

### Migration Pattern
**Goal:** Move from `Singleton.getInstance(context)` to `@Inject` constructor.

1.  **Refactor Manager Class:**
    ```kotlin
    // BEFORE
    class MyManager private constructor(context: Context) {
        companion object {
            fun getInstance(context: Context) = ...
        }
    }

    // AFTER
    @Singleton
    class MyManager @Inject constructor(
        private val context: Context,
        private val otherDependency: OtherDependency
    ) { ... }
    ```

2.  **Module-Specific Component:**
    For library modules, define a component that exposes the manager and an injection interface.
    ```kotlin
    @Component(modules = [MyModule::class])
    @Singleton
    interface MyComponent {
        fun inject(activity: MyActivity)
        val myManager: MyManager
    }
    ```

3.  **Application Bridge:**
    Implement a `ComponentProvider` interface in the main `Collect` application class to wire the module's graph to the main app graph.

4.  **Activity Injection:**
    Use a BaseActivity to handle injection cleanly.
    ```kotlin
    abstract class BaseActivity : AppCompatActivity() {
        @Inject lateinit var myManager: MyManager

        override fun onCreate(savedInstanceState: Bundle?) {
            super.onCreate(savedInstanceState)
            injectDependencies()
        }

        protected open fun injectDependencies() {
            // Cast application to your Provider interface
            (application as? MyComponentProvider)?.myComponent?.inject(this as? ConcreteActivity ?: return)
        }
    }
    ```

**Gotcha:** Dagger cannot inject into `private` or `protected` fields. Fields must be `public` (default in Kotlin) or `lateinit var`.

## 3. Testing Standards

### Assertions
*   **Pattern:** Favor **Hamcrest** matchers over JUnit assertions for readability and better error messages.
*   **Bad:** `assertEquals("expected", actual)`
*   **Good:** `assertThat(actual, equalTo("expected"))`
*   **Dependency:** Ensure `testImplementation libs.hamcrest` is in `build.gradle`.

### Naming
*   **Pattern:** Use backtick-enclosed sentences for Kotlin test names.
*   **Example:** ``fun `#login stores token and updates state when success`()``

### Mocks & Constructors
*   **Pattern:** When testing classes with dependencies, pass mocks via the constructor.
*   **Issue:** If a class uses `Singleton.getInstance()` internally, it is hard to mock.
*   **Solution:** Refactor to constructor injection (see Section 2) to pass mock objects in `setUp()`.

## 4. Resources & Theming

### String Resources
*   **Rule:** NEVER use hardcoded strings in UI (Activities, Toasts, Views).
*   **Solution:** Extract to `res/values/strings.xml`.
*   **Benefit:** Enables localization and prevents duplication.

### Theme Naming
*   **Pattern:** `<Type>.<Package>.<Name>`
*   **Bad:** `Theme.AiimsAuth`
*   **Good:** `Theme.Aiims.Auth` (matches `Theme.Material3.DayNight`)

## 5. Common Pitfalls

*   **Wildcard Imports:** `ktlint` forbids `import java.util.*`. Use explicit imports.
*   **Trailing Spaces:** `ktlint` enforces no trailing spaces.
*   **Unused Imports:** Remove unused imports to pass lint checks.
*   **Property Initialization:** In tests, ensure `@Mock` or `lateinit` properties are initialized (e.g., in `@Before`) before the subject under test is instantiated.
