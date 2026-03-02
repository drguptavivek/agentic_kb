---
title: JAX-RS ContainerRequestFilter in Keycloak 26 Quarkus Provider JARs
type: howto
domain: Keycloak
tags:
  - keycloak
  - keycloak-26
  - quarkus
  - jax-rs
  - containerrequestfilter
  - provider-jar
  - jandex
  - spi
  - http-403
  - prematching
status: approved
created: 2026-03-02
updated: 2026-03-02
---

# JAX-RS ContainerRequestFilter in Keycloak 26 Quarkus Provider JARs

## Problem / Context

You want to intercept HTTP requests to Keycloak's Admin REST API before they reach the handler — for example, to return a proper `403` for operations that an `EventListenerProvider` cannot block (because `AdminEventBuilder` swallows all exceptions).

Two questions arise:

1. Can a plain `@Provider ContainerRequestFilter` placed in a Keycloak provider JAR be auto-discovered?
2. Can it access `KeycloakSession` at filter execution time?

Both answers are **yes**, with specific requirements.

---

## Critical Pitfall: @PreMatching Breaks KeycloakSession Access

### The Bug

```java
@Provider
@PreMatching          // ← THIS IS THE PROBLEM
@Priority(Priorities.AUTHORIZATION + 10)
public class MyGuardFilter implements ContainerRequestFilter {

    @Context
    KeycloakSession session;  // ← ALWAYS NULL when @PreMatching

    @Override
    public void filter(ContainerRequestContext ctx) {
        if (session == null) {  // ← always true; filter is a no-op
            return;
        }
        // ... never reached
    }
}
```

### Why It Fails

Keycloak's Quarkus-based server sets up the `KeycloakSession` via its own internal request filter. The Keycloak session filter runs AFTER pre-matching but BEFORE post-matching (regular) `ContainerRequestFilter` execution.

```
Request arrives
    │
    ▼
@PreMatching filters          ← KeycloakSession NOT yet in context
    │
    ▼
URL route matching
    │
    ▼
Keycloak's session setup filter  ← KeycloakSession pushed into @Context here
    │
    ▼
@Priority post-match filters  ← KeycloakSession IS available here ✅
    │
    ▼
Resource method handler
```

`@PreMatching` puts your filter in the first phase — before Keycloak has set up the session context. So `@Context KeycloakSession session` will always be `null`.

### The Fix

Remove `@PreMatching`. A post-matching filter still runs **before the resource method executes**, so `ctx.abortWith(response)` still prevents the handler from running.

```java
@Provider
// @PreMatching  ← remove this
@Priority(Priorities.AUTHORIZATION + 10)
public class MyGuardFilter implements ContainerRequestFilter {

    @Context
    KeycloakSession session;  // ← populated correctly now

    @Override
    public void filter(ContainerRequestContext ctx) {
        if (session == null) {
            return;  // safety guard; should not happen in post-match context
        }
        // ... session.getContext().getRealm() works correctly
    }
}
```

---

## Provider JAR Discovery: Jandex Index Required

### The Myth

> "Plain `@Provider` in a providers/ JAR is NOT auto-discovered by RESTEasy in Keycloak Quarkus."

This is **incorrect**. Provider JARs ARE scanned — but only if they include a Jandex annotation index.

### How Keycloak Discovers @Provider Classes

Keycloak's Quarkus build step (`KeycloakProcessor`) constructs a `CombinedIndexBuildItem` from all JARs on the classpath. JARs that contain `META-INF/jandex.idx` are automatically included in this combined Jandex index. RESTEasy then discovers `@Provider`-annotated classes from the combined index.

Without `META-INF/jandex.idx`, the class is **invisible** to `kc.sh build`.

### How to Add the Jandex Index

Add the `jandex-maven-plugin` to your provider JAR's `pom.xml`:

```xml
<properties>
    <!-- Must match the Jandex version bundled in the target Keycloak/Quarkus release -->
    <jandex.version>3.2.0</jandex.version>
</properties>

<build>
    <plugins>
        <plugin>
            <groupId>io.smallrye</groupId>
            <artifactId>jandex-maven-plugin</artifactId>
            <version>${jandex.version}</version>
            <executions>
                <execution>
                    <id>make-index</id>
                    <goals>
                        <goal>jandex</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

This generates `META-INF/jandex.idx` inside the JAR at build time. After `kc.sh build` processes the providers, the class is registered as a global JAX-RS provider.

### CDI beans.xml (Optional but Harmless)

Including a `META-INF/beans.xml` with `bean-discovery-mode="all"` is **not required** for JAX-RS provider discovery. Quarkus ignores `bean-discovery-mode="all"` and treats it as `annotated` — meaning CDI won't scan all classes. However, it does not interfere with JAX-RS Jandex-based discovery.

```xml
<!-- META-INF/beans.xml — optional for JAX-RS @Provider discovery -->
<beans xmlns="https://jakarta.ee/xml/ns/jakartaee"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="https://jakarta.ee/xml/ns/jakartaee https://jakarta.ee/xml/ns/jakartaee/beans_4_0.xsd"
       version="4.0"
       bean-discovery-mode="all">
</beans>
```

---

## Complete Working Pattern

### Filter class

```java
package org.example.keycloak;

import jakarta.annotation.Priority;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.services.managers.AppAuthManager;
import org.keycloak.services.managers.AuthenticationManager;
import java.io.IOException;

@Provider
// ← NO @PreMatching: run after route match, where KeycloakSession context is set
@Priority(Priorities.AUTHORIZATION + 10)
public class MyGuardFilter implements ContainerRequestFilter {

    @Context
    KeycloakSession session;  // injected by RESTEasy after route match

    @Override
    public void filter(ContainerRequestContext ctx) throws IOException {
        if (session == null) return;  // safety guard

        String path = ctx.getUriInfo().getPath();
        if (!path.startsWith("/admin/realms/")) return;  // fast-path

        RealmModel realm = session.getContext().getRealm();
        if (realm == null) return;

        // Validate the bearer token
        AuthenticationManager.AuthResult auth =
            new AppAuthManager.BearerTokenAuthenticator(session)
                .setRealm(realm)
                .setUriInfo(session.getContext().getUri())
                .setConnection(session.getContext().getConnection())
                .setHeaders(session.getContext().getRequestHeaders())
                .authenticate();

        if (auth == null || auth.getUser() == null) return;

        // Your role checks and blocking logic here:
        // ctx.abortWith(Response.status(403).entity("{\"error\":\"access_denied\"}").build());
    }
}
```

### pom.xml excerpt

```xml
<dependencies>
    <dependency>
        <groupId>org.keycloak</groupId>
        <artifactId>keycloak-core</artifactId>
        <version>26.5.4</version>
        <scope>provided</scope>
    </dependency>
    <dependency>
        <groupId>org.keycloak</groupId>
        <artifactId>keycloak-server-spi</artifactId>
        <version>26.5.4</version>
        <scope>provided</scope>
    </dependency>
    <dependency>
        <groupId>org.keycloak</groupId>
        <artifactId>keycloak-server-spi-private</artifactId>
        <version>26.5.4</version>
        <scope>provided</scope>
    </dependency>
    <dependency>
        <groupId>org.keycloak</groupId>
        <artifactId>keycloak-services</artifactId>
        <version>26.5.4</version>
        <scope>provided</scope>
    </dependency>
    <dependency>
        <groupId>jakarta.ws.rs</groupId>
        <artifactId>jakarta.ws.rs-api</artifactId>
        <version>3.1.0</version>
        <scope>provided</scope>
    </dependency>
</dependencies>

<build>
    <plugins>
        <plugin>
            <groupId>io.smallrye</groupId>
            <artifactId>jandex-maven-plugin</artifactId>
            <version>3.2.0</version>
            <executions>
                <execution>
                    <id>make-index</id>
                    <goals><goal>jandex</goal></goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

---

## Debugging Checklist

If the filter is not firing:

- [ ] Is `META-INF/jandex.idx` present in the built JAR? (`jar tf your.jar | grep jandex`)
- [ ] Was `kc.sh build` re-run after copying the JAR?
- [ ] Is `@PreMatching` present? Remove it.
- [ ] Is `session` null at filter execution? Indicates the filter is running pre-match.
- [ ] Check Keycloak startup logs for the filter class being registered.

If you see `session == null` at runtime despite removing `@PreMatching`, add logging:

```java
LOG.infof("FILTER FIRED: session=%s path=%s", session, ctx.getUriInfo().getPath());
```

A null `session` means the filter is not being called in the correct request phase.

---

## Why Not a Quarkus Extension?

A Quarkus extension (deployment + runtime JAR pair with `quarkus-extension.yaml`) is NOT needed for this use case. It is significantly more complex to build and maintain. The provider JAR + Jandex approach is the correct Keycloak mechanism for adding JAX-RS providers.

A full Quarkus extension would only be needed if you require CDI producer beans, build-time code generation, or other Quarkus augmentation features.

---

## Related

- [[keycloak-delegated-admin-guard-spi]]
- [[keycloak-spi]]
- [[keycloak-fgap-v2-delegated-admin]]
