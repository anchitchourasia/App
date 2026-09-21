# HEG Mobile — Secure Deployment Plan

**Publishing the VPMS / CVPS Mobile APIs through the Company DMZ Gateway**

| | |
|---|---|
| **Status** | Awaiting IT gateway setup (UAT phase) |
| **Prepared by** | Mobile Development Team |
| **Audience** | Management, IT / Network / Security, Tomcat Administrator, DBA, Business Owner |
| **Related documents** | `README.md` (product overview), `Jenkinsfile` (build & release pipeline) |

---

## 1. Executive Summary

The mobile application is **built and functional**. It consumes the **existing** VPMS/CVPS backend — **no new server-side business logic was required**.

The only outstanding item is **secure network access**. Today the app reaches the backend over the internal company LAN by addressing the internal server IP directly, which is not possible from a mobile device on Wi-Fi, VPN, or mobile data.

**Proposed solution:** publish **only the approved VPMS/CVPS API paths** through the company's **existing DMZ reverse proxy / API gateway**, served over **HTTPS (TCP 443)**. The gateway forwards approved requests to the existing internal Tomcat server.

**Key outcomes:**

- Nothing new is exposed to the internet — only the approved API routes.
- The **Tomcat server IP, its port, and the Oracle database remain internal**.
- **Oracle credentials never leave the backend** and are never stored in the app.
- Our side of the change is a **base-URL swap (approximately three lines of configuration)**.
- IT's side is **one gateway route and one firewall rule**.

> **Recommendation:** Route the mobile app through the existing DMZ gateway over HTTPS, keep Tomcat and Oracle internal, and leave backend business logic unchanged.

---

## 2. The Problem

### 2.1 Current situation

| Scenario | Access path | Result |
|---|---|---|
| Employee on a **company PC** | Browser → internal Tomcat server | Works (existing web UI) |
| Employee on a **mobile device** (Wi-Fi / VPN / mobile data) | App → `http://192.168.9.130:9092` | Fails — internal IP is unreachable |

### 2.2 Why the internal server cannot simply be exposed

- Exposing **Tomcat** to mobile devices would expose the entire web application.
- Exposing **Oracle** is never acceptable; the database must remain reachable only by the backend.
- Embedding database credentials inside a distributed phone application is a security violation.

### 2.3 Requirement

The mobile application must **never** know the internal server IP, the internal port, or any database credential. It must communicate with exactly **one** approved HTTPS address.

---

## 3. Target Architecture

```
   Flutter Mobile App  (company Wi-Fi / VPN / mobile data)
                |
                |   HTTPS  -  TCP 443        <- the ONLY channel a phone may use
                v
   Company DMZ Reverse Proxy / API Gateway
   (for example: api-gw.company-domain)
                |
                |   Restricted internal route to the approved Tomcat port only
                v
   Tomcat Server  -  port 9092
   /vpms/**   /cvps/**   (existing VPMS/CVPS web UI + backend)
                |
                |   Existing JDBC connection
                v
   Oracle Database  -  internal only
   (never exposed to the DMZ, the internet, or mobile devices)
```

### Security principles

1. Mobile devices reach **only** the company HTTPS gateway.
2. The gateway exposes **only** the approved API routes.
3. The **Tomcat IP is never exposed** to mobile users or the internet.
4. The **Oracle database is never exposed** to the DMZ or to mobile users.
5. Firewall rules permit **only the minimum required traffic**.

---
## 4. How Data Actually Flows

### 4.1 External-to-internal route mapping

The DMZ gateway performs **path rewriting**: the external prefix is stripped and the request is forwarded to the existing internal context path.

| External route (what the phone calls) | Internal route (what Tomcat already serves) |
|---|---|
| `https://api-gw.company-domain/heg/vpms/**` | `http://<tomcat-internal>:9092/vpms/**` |
| `https://api-gw.company-domain/heg/cvps/**` | `http://<tomcat-internal>:9092/cvps/**` |
| `https://api-gw.company-domain/heg/ws-chat` | `http://<tomcat-internal>:9092/ws-chat` *(only if chat is included in the release)* |

> The `/heg/` prefix is **owned by the gateway**. It must **not** be hardcoded into Java controller mappings. Existing mappings such as `/vpms/api/...` and `/cvps/api/...` remain exactly as they are.

### 4.2 Worked example — read a record (GET)

1. App calls: `GET https://api-gw.company-domain/heg/vpms/api/passes/listV1`
2. Gateway validates the route is allowed, rewrites the path, and forwards:
   `GET http://tomcat-internal:9092/vpms/api/passes/listV1`
3. Tomcat handles it exactly as it does for the web UI and returns JSON.
4. Gateway returns the response to the app over TLS.

### 4.3 Worked example — create a pass with a document upload (POST, multipart)

1. App calls: `POST https://api-gw.company-domain/heg/vpms/api/passes/save`
   with a multipart body containing `request.json` and one or more attached document files.
2. Gateway must:
   - permit the route,
   - **forward the `x-api-key` header unchanged** (this is the application's authentication),
   - **allow a request body larger than the default limit** (see §5).
3. Tomcat saves the pass and files, and returns the created record.

### 4.4 What must pass through unchanged

| Item | Reason |
|---|---|
| `x-api-key` header | Sole authentication mechanism of the API |
| Multipart form data | Pass/document uploads |
| Query strings and path parameters | Filtering and lookups |
| JSON request/response bodies | Standard API payloads |

---

## 5. Scope

**Included in the first release (Phase 1):**

- VPMS: pass registry, pass entry (create/update), approver workflow, pass sticker, pass history.
- CVPS: request list, request detail, vehicle permission pass (PDF), workflow status.
- Gate entry/exit (IN / OUT) logging.
- Document upload and download.

**Deferred (Phase 2) — unless IT confirms support now:**

- Realtime chat over WebSocket (STOMP / SockJS).

> **Decision required:** The application already ships a chat feature. If chat is not published through the gateway, the chat button and unread badge should be disabled in the first release, or the following routes must also be published:
> `GET /heg/api/chat/history/**`, `GET /heg/api/chat/presence/**`, `GET /heg/api/chat/conversations/**`, `GET|POST /heg/api/chat/availability/**`, `POST /heg/api/chat/send`, and the WebSocket endpoint `/heg/ws-chat` **with WebSocket upgrade enabled**.

---

## 6. What IT / Network / Security Must Provide

| # | Requirement | Detail |
|---|---|---|
| 1 | UAT gateway hostname | For example `https://api-gw-uat.company-domain` |
| 2 | Production gateway hostname | For example `https://api-gw.company-domain` |
| 3 | TLS certificate | Valid certificate on the gateway; the app uses HTTPS only |
| 4 | Route mapping | `/heg/vpms/**` → Tomcat `/vpms/**`; `/heg/cvps/**` → Tomcat `/cvps/**` (plus chat routes if in scope) |
| 5 | Header pass-through | Forward `x-api-key` (and standard headers) unchanged |
| 6 | Request body size | Raised to accommodate document uploads. The backend permits 10–12 MB; upstream proxies commonly default to 1 MB, which silently breaks uploads |
| 7 | Proxy read timeout | At least 60 seconds. The app's own client timeout is 12–15 seconds, so the proxy timeout must be longer |
| 8 | Forwarded headers | Send `X-Forwarded-For`, `X-Forwarded-Proto: https`, `X-Forwarded-Host` |
| 9 | Firewall rules | Device network → gateway on TCP 443; gateway → Tomcat on the approved port only; existing Tomcat → Oracle traffic unchanged |
| 10 | Mobile access policy | Confirm company Wi-Fi only, VPN, mobile data, MDM-managed devices vs BYOD, and any IP allow-list |

### 6.1 Tomcat proxy-awareness (Tomcat administrator)

So that Tomcat logs the real client address rather than the proxy address, the administrator should add a `RemoteIpValve` to `server.xml`, trusting **only** the approved gateway IP or range:

```xml
<Valve className="org.apache.catalina.valves.RemoteIpValve"
       internalProxies="<DMZ_PROXY_IP_OR_APPROVED_RANGE>"
       remoteIpHeader="x-forwarded-for"
       protocolHeader="x-forwarded-proto" />
```

Procedure: back up `server.xml` → apply the change → restart Tomcat through the approved procedure → verify the existing web UI still works → verify gateway calls are logged with HTTPS and the correct client information.

---

## 7. What the Mobile Team Changes

Because all network configuration is centralised, the change is small and low-risk.

```dart
class AppConfig {
  static const String gatewayHost = 'https://api-gw-uat.company-domain';
  static const String vpmsBaseUrl  = '$gatewayHost/heg/vpms';
  static const String cvpsBaseUrl  = '$gatewayHost/heg/cvps';
}
```

Existing API calls continue to work without modification, for example:

```dart
final vpmsUrl = '${AppConfig.vpmsBaseUrl}/api/passes/listV1';
final cvpsUrl = '${AppConfig.cvpsBaseUrl}/api/requests';
```

**Additional changes:**

1. Set the chat base URL to the gateway host so the WebSocket and chat REST calls resolve correctly.
2. Replace the temporary emulator address (`10.0.2.2:8080`) used for gate-log testing with the real gateway route.
3. Ensure every request uses **HTTPS** (no remaining `http://` calls).

**No backend Java code change is required** for DMZ routing.

---
## 8. Phased Plan and Timeline

| Phase | Activity | Owner | Deliverable | Gate |
|---|---|---|---|---|
| 0 | Document current Tomcat host, port, VPMS/CVPS context paths, and one GET + one POST sample API per context | Mobile / Backend team | Current architecture details | — |
| 1 | Define the DMZ routing model and the exact API scope for the mobile release | Mobile team | Target architecture and route list | — |
| 2 | Raise the formal request with IT, Network, and Security (attach this document) | Project owner | Approved infrastructure ticket | IT acknowledges |
| 3 | Allocate the UAT gateway hostname; configure TLS, routing, firewall rules, and forwarded headers | IT / Network / Security | Live UAT gateway endpoint | UAT host reachable |
| 4 | Configure `RemoteIpValve` with the approved proxy IPs; restart and verify Tomcat | Tomcat administrator | Proxy-aware Tomcat deployment | Web UI still works |
| 5 | Update the Flutter configuration with the UAT gateway host; produce the UAT build | Mobile team | UAT APK | Build succeeds |
| 6 | Execute UAT against the UAT gateway (see §9) | Mobile team + business users | UAT report and defect list | All critical tests pass |
| 7 | Review results and issue UAT sign-off | Business owner | Signed UAT approval | Formal sign-off |
| 8 | Provide and configure the production gateway hostname and route rules | IT / Network / Security | Production gateway endpoint | Prod host reachable |
| 9 | Build the production app against the production hostname; release via the approved process | Release team + mobile team | Production mobile app | Jenkins pipeline green |
| 10 | Monitor gateway, Tomcat, backend logs, and user feedback | Support teams | Post-go-live support record | Stabilisation |

> Durations are driven mainly by IT change windows. The mobile team's work in Phases 5 and 9 is measured in hours, not days.

---

## 9. UAT Test Checklist

To be executed from an approved mobile device on the approved network, against the UAT gateway.

**Connectivity and security**

- [ ] The app reaches the UAT HTTPS gateway successfully.
- [ ] A mobile device **cannot** reach the internal Tomcat IP directly.
- [ ] A mobile device **cannot** reach the Oracle database.
- [ ] The app contains no database credentials or internal server IPs.

**Authentication and authorisation**

- [ ] Valid users can log in and receive the correct role.
- [ ] Invalid credentials are rejected with a clear message.
- [ ] Users cannot perform actions outside their role (for example, an employee cannot approve).

**VPMS**

- [ ] Fetch the vehicle/pass registry.
- [ ] Create a new pass (Save, then Submit).
- [ ] Update an existing permitted pass.
- [ ] Approver workflow: Approve, Reject, Send for modification.
- [ ] View pass history.
- [ ] Generate the pass sticker.

**CVPS**

- [ ] Fetch CVPS requests and workflow status.
- [ ] Open request detail and download documents.
- [ ] Generate the vehicle permission pass (PDF).

**Gate and documents**

- [ ] Record gate IN and OUT actions.
- [ ] Upload a document (confirm the gateway does not reject the body size).
- [ ] Download a document.

**Failure handling**

- [ ] Timeout, no-network, invalid login, and server-error paths show sensible messages.

Business sign-off is required before production go-live.

---

## 10. Risks and Mitigations

| # | Risk | Impact | Mitigation |
|---|---|---|---|
| 1 | Gateway request-body limit is lower than the document upload size | Document uploads fail silently (HTTP 413) | Confirm and raise the limit during UAT (Requirement 6); test an upload at maximum size |
| 2 | Chat / WebSocket upgrade not supported or not routed | Chat button and unread badge fail | Publish the chat routes with upgrade support, or disable chat in the first release (see §5) |
| 3 | Proxy timeout shorter than backend response time | Occasional 504 errors on slow queries | Set the proxy read timeout to at least 60 seconds (Requirement 7) |
| 4 | `app_config.dart` and `api_config.dart` are excluded from version control | The repository does not build without them | Provide these files during the build (for example, via the Jenkins pipeline or as templates) — see §11 |
| 5 | A legacy internal/emulator address remains in configuration | Some calls fail on a real device | Replace all addresses with gateway URLs before release (§7) |

---
## 11. Go-Live Process

1. Obtain UAT sign-off (§9).
2. Confirm the production DMZ / API gateway hostname and route mapping.
3. Confirm the production Tomcat configuration trusts **only** the production gateway / proxy IPs.
4. Confirm the production backend is connected to the approved production Oracle datasource.
5. Build the production mobile application against the production gateway hostname.
6. Deploy through the company's approved release process (the Jenkins pipeline in this repository).
7. Monitor gateway access logs, Tomcat logs, backend errors, and Oracle performance.

### 11.1 Configuration note (build pipeline)

The files `HEG/lib/core/app_config.dart`, `HEG/lib/core/api_config.dart`, and `HEG/assets/.env` are **excluded from version control** (intentional — they hold environment-specific URLs and keys). Consequently:

- The repository will **not build** unless these files are present.
- They must be supplied during the build — for example by the Jenkins pipeline, which already injects `assets/.env` from a stored credential.
- `app_config.dart` and `api_config.dart` should likewise be generated or provided per environment (UAT / production).

### 11.2 Rollback plan

- Revert the mobile release to the previous approved build, or rebuild with the previous configuration.
- Ask IT to disable the gateway route if a critical issue is found on the gateway side.
- No backend or database change is involved, so no data rollback is required.

---

## 12. Decisions Required from Management and IT

| # | Question | Needed from |
|---|---|---|
| 1 | Should mobile access be permitted from company Wi-Fi only, VPN only, or external mobile data as well? | IT / Security |
| 2 | Are only MDM-managed company phones permitted, or is BYOD allowed? | Management / Security |
| 3 | Which existing DMZ / API gateway is the approved platform for internal employee mobile applications? | IT / Network |
| 4 | What UAT and production hostnames and path-prefix conventions should be used? | IT / Network |
| 5 | What authentication, logging, rate-limit, and audit requirements apply to mobile API access? | Security |
| 6 | Who owns the Tomcat `server.xml` change and the restart activity? | Tomcat administrator |
| 7 | Is chat / WebSocket included in the first release, or deferred? | Business owner / IT |

---

## 13. Responsibility Summary (RACI)

| Responsibility | Mobile Developer | IT / Network / Security | Tomcat Administrator | DBA | Business Owner / UAT Users |
|---|---|---|---|---|---|
| Prepare technical API / path details | **R** | C | C | — | I |
| Raise and clarify the infrastructure request | **R** | C | I | I | I |
| Provide UAT and production gateway hostnames | I | **R** | — | — | I |
| Configure HTTPS / TLS, routing, firewall, access control, logging | I | **R** | C | — | I |
| Provide proxy IP information for Tomcat trust configuration | I | **R** | C | — | I |
| Configure `RemoteIpValve`; restart and verify Tomcat | C | C | **R** | — | I |
| Update Flutter base URLs; produce UAT build | **R** | — | — | — | I |
| Test mobile API flows in UAT | **R** | C | C | — | C |
| Execute business scenarios; validate workflow and data correctness | C | — | — | — | **R** |
| Maintain Oracle security and approved connectivity | — | C | — | **R** | I |
| Provide UAT sign-off before go-live | I | I | I | — | **R** |
| Production release and monitoring | **R** | C | C | C | I |

*R = Responsible, C = Consulted, I = Informed.*

---

## 14. Glossary

| Term | Meaning |
|---|---|
| **DMZ** | A screened network segment between the internal network and untrusted networks; hosts only what must be reachable from outside |
| **Reverse proxy** | A server that accepts external requests and forwards them to an internal server, hiding the internal server's address |
| **API gateway** | A reverse proxy specialised for APIs, offering routing, TLS termination, header handling, rate limiting, and logging |
| **TLS / HTTPS** | Encryption for web traffic; the mobile app uses HTTPS on port 443 only |
| **Path rewriting** | Changing the URL path at the gateway (for example `/heg/vpms/**` → `/vpms/**`) so the internal application is unchanged |
| **Forwarded headers** | `X-Forwarded-*` headers added by the proxy so the backend can identify the real client and protocol |
| **RemoteIpValve** | A Tomcat component that reads forwarded headers to log the true client address |
| **Multipart upload** | An HTTP request that carries a form plus one or more attached files |
| **WebSocket / STOMP / SockJS** | Protocols used for realtime chat between the app and the backend |
| **UAT** | User Acceptance Testing — business validation before production release |
| **BYOD** | Bring Your Own Device — employee-owned phones |
| **MDM** | Mobile Device Management — centrally managed company phones |

---

## 15. Appendix — API Surface Used by the Mobile App

The following categories of endpoints are consumed by the app and therefore need gateway routes.

| Module | Base path (internal) | Purpose |
|---|---|---|
| VPMS | `/vpms/api/authority/**` | Login and role lookup |
| VPMS | `/vpms/api/reports/employee-department/**` | Employee detail lookup |
| VPMS | `/vpms/api/passes/**` | Pass list, save, update, status, documents |
| VPMS | `/vpms/api/history/**` | Pass history |
| CVPS | `/cvps/api/requests/**` | Request list, detail, create, update, delete, history |
| CVPS | `/cvps/api/manpower/**` | Driver / person documents |
| CVPS | `/cvps/api/bp-records/**` | Contractor lookup |
| CVPS | `/cvps/api/dept/**` | Department list |
| CVPS | `/cvps/api/documents/**` | Document download |
| CVPS | `/cvps/api/gate-logs/**` | Gate IN / OUT logging |
| Chat *(optional)* | `/api/chat/**`, `/ws-chat` | Realtime chat and history |

*Final route naming and the external prefix are subject to the values approved by IT / Network.*

---

<div align="center">

**HEG Mobile — Secure Deployment Plan**

Prepared by the Mobile Development Team.

*Route through the existing DMZ gateway over HTTPS; keep Tomcat and Oracle internal; change nothing in the backend business logic.*

</div>
