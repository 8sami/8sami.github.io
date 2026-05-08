# Detailed Timeline of IM Wrapper Plugin

**Scope:** WhatsApp is the only supported messaging provider for now. However, the entire system will be built as a modular IM wrapper with a provider-agnostic interface, so adding support for a new provider in the future will only require implementing a new adapter without touching the core logic.

**Key dates:**

- Coding period begins: May 25, 2026
- Midterm evaluation: July 6, 2026
- Final evaluation and project handover: August 17, 2026

**Weekly meetings:** Weekly syncs with mentors will be held throughout the project to review progress and unblock issues. All blockers must be raised before the weekly meeting rather than allowed to sit.

---

## Pre-Coding Period: May 10 to May 24

**Goal:** I will ensure that every prerequisite is fully resolved before coding begins on May 25.

### Prerequisites

**Alignment with mentors:**

- Confirm the final agreed-upon scope and features of the plugin
- Confirm the data models and API architecture with the engineering team
- Confirm the agreed-upon behavior for edge cases:
  - What happens when a staff member and a patient share the same phone number?
  - How should messages exceeding WhatsApp's character limit be handled: split into multiple messages, or redirect to a signed frontend URL?
  - When a patient has multiple encounters, should the bot prompt them to select one, or aggregate data across all encounters?
- Confirm which Care API endpoints the plugin will call and whether any new endpoints need to be added to Care core for the plugin to work

**WhatsApp Business API access:**

- Apply for Meta Business account and complete the verification process
- Set up the WhatsApp Business API
- Confirm webhook delivery is working end-to-end in the development environment using ngrok
- Research and understand WhatsApp rate limits, message templates, and conversation window policies

**Repository and environment setup:**

- Setup the BE plugin repo using the `care-plugin-cookiecutter` template
- Setup the FE plugin repo using `care_hello_fe`
- Set up Redis, Celery, Celery beat, ngrok
- Confirm the plugins register correctly with `care` and `care_fe`

**Codebase study:**

- Read through `care_scribe` and `care_scribe_fe` completely to understand the patterns the team uses for plugin architecture, model design, API integration, and frontend plugin structure
- Read Care's audit logging, RBAC, and Celery setup to understand what can be reused directly

**Pending contributions:**

- Make sure all assigned PRs on `care_fe` are merged before the coding period starts

**Milestone:** Both plugin repos are setup and running locally. WhatsApp API access is confirmed. The implementation plan is understood and agreed upon with mentors.

---

## Phase 1: Backend Foundation

### Week 1: May 25 to May 31

**Goal:** Define the IM wrapper abstraction and build the structural foundation of the plugin

**IM wrapper interface:**

- Define an abstract `IMProvider` base class that all current and future providers must implement:
  - `verify_webhook(request) -> bool`: validates incoming webhook requests using the provider's signature/challenge mechanism
  - `parse_incoming(raw_payload) -> NormalizedMessage`: converts a provider-specific webhook payload into a standardized internal format
  - `send_message(recipient, payload) -> bool`: formats and dispatches an outgoing message via the provider's API
- Define a `NormalizedMessage` dataclass that represents a provider-agnostic incoming message (sender, content, timestamp, message type)
- Extend `IMProvider` to implement the WhatsApp provider as the first implementation

**Models:**

- `IMSession`: tracks active sessions per phone number, including authentication step, number of failed DOB attempts, block expiry timestamp, authenticated user reference, and session TTL
- `IMNotification`: stores a record of every notification dispatched, including recipient, provider used, payload, status (pending, sent, failed, retried), scheduled time, sent time, and retry count
- `SignedLink`: stores time-limited signed URLs generated for patient document access, including the target resource, expiry datetime, and a flag for whether the link has already been used

**WhatsApp webhook:**

- Implement the Meta challenge-response webhook verification flow
- Implement incoming message parsing using `parse_incoming` and map it to `NormalizedMessage`
- Implement outgoing message dispatch via the WhatsApp Cloud API using `send_message`
- Register the webhook URL in the plugin's URL configuration

**Milestone:** Models are migrated. The WhatsApp webhook is live locally via ngrok, receives an incoming message, parses it correctly, and responds. WhatsApp API is authenticated.

---

### Week 2: June 1 to June 7

**Goal:** Implement the two-step authentication system and the conversation states.

**Two-step authentication:**

- Step 1: On any incoming message from an unauthenticated number, query both the `Patient` model and the `User` model in Care for records matching that phone number. If no match is found in either, reply with an appropriate message and stop.
- Step 2: Prompt the user to enter their year of birth. Care stores `year_of_birth` for all patients (derived from `date_of_birth` if provided, or calculated from a provided age). Using year of birth rather than full DOB handles both cases uniformly: patients who provided an exact date of birth and patients who only provided their age at registration.
- If multiple records match the phone number (e.g. multiple patients, or a person who is registered as both a staff member and a patient), do not authenticate immediately. Present a numbered list so the user can choose which profile to log in as. Examples: `1. Patient: Samiullah (DOB: 2001)`, `2. Staff: samiullah.javed`. Limit the list to 5 entries per page and support pagination via numbered replies if there are more.
- Once the user selects a profile, create the `IMSession` for that specific record and mark them as authenticated.
- Track failed year-of-birth attempts in `IMSession`. After 3 failed attempts from a number, block all further requests from that number for 15 minutes and reset the counter on success.
- Store all auth state in `IMSession` backed by Redis with a configurable session TTL.

**Conversation states:**

- Define a clear set of states: `UNAUTHENTICATED`, `AWAITING_YEAR_OF_BIRTH`, `AWAITING_PROFILE_SELECTION`, `AUTHENTICATED`, `AT_MENU`, and sub-states for specific data flows.
- All incoming messages are routed through the state machine. Each state has a defined handler that processes the input and transitions to the next state or returns an error without crashing.
- State is stored per phone number in Redis with a configurable session TTL. Inactivity beyond the TTL resets the state to `UNAUTHENTICATED`.

**Role detection and RBAC:**

- After a profile is selected and the session is created, determine whether the authenticated record is a patient or a staff user and route to the correct menu.
- For staff, use Care's existing `AuthorizationController.call(permission, user, instance)` to enforce permissions on every data access. Staff can only retrieve data their Care role permits. This is enforced at the data layer, not only at the menu level.
- Most required permissions already exist in Care core. Custom permissions will only be defined if no existing permission maps to the required action, using `care_teleicu_devices` as the reference implementation.

**Milestone:** A real phone number can send a message to the WhatsApp number, complete the full auth flow including profile selection when multiple matches exist, get routed to the correct menu based on role, and be locked out after 3 failed attempts.

---

## Phase 2: Data Access

### Week 3: June 8 to June 14

**Goal:** Implement data-fetching logic for both the patient and staff flows, with RBAC enforcement and data sanitization.

**Patient-facing data access:**

- Implement handlers for each patient menu option, calling the relevant Care backend API endpoints:
  - Upcoming appointments schedules
  - Active medications list
  - Lab reports
  - Encounters details
  - Patient summary
- Format each response into a clean, readable WhatsApp message and provide signed links for accessing the PDFs.

**Staff-facing data access:**

- Implement handlers for each staff menu option:
  - All of the above for each patient +
  - Look up a patient by name or phone number
  - View the list of patients currently assigned to the staff member
- All staff data access must respect Care's RBAC system. The staff member's Care permissions govern what data they can retrieve.

**Data sanitization:**

- For every response, strip any fields that are not necessary for the reply
- Do not include sensitive PII fields unless they are explicitly required by the query
- Log every data access event (what was fetched, by whom, and when) via `care.audit_log`

**Milestone:** Both the patient and staff menus are fully functional over WhatsApp, returning live data from the Care backend with RBAC enforced.

---

### Week 4: June 15 to June 21

**Goal:** Implement caching, rate limiting, and request debouncing to make the plugin production-ready under real-world usage.

**Caching with django-redis:**

- Cache responses for data that changes infrequently, such as patient profiles, medication lists, and care team assignments
- Configurable TTL per data type so that each can be tuned independently
- Implement cache invalidation where Care's data may change in real time (e.g. appointments)
- Store session state (IMSession) in Redis rather than the database to reduce latency on every incoming message

**Rate limiting:**

- Enforce per-phone-number rate limits on the webhook endpoint to prevent a single number from flooding the system
- Enforce a global rate limit on outgoing WhatsApp API calls to stay within Meta's messaging limits and avoid overspending
- All thresholds must be configurable via the plugin's settings, not hardcoded

**Request debouncing:**

- If a user sends multiple messages in rapid succession (e.g. double-tapping a menu option), deduplicate the requests and process only one
- This prevents race conditions in the state machine and avoids duplicate API calls

**Milestone:** The plugin handles high-frequency and abusive input gracefully. Rate limits and caching behavior are verified with simulated load.

---

### Week 5: June 22 to June 28

**Goal:** Implement structured error handling, complete audit logging coverage, and write the first set of unit tests.

**Error handling:**

- WhatsApp Cloud API failures: catch API errors, log them, and send a user-facing fallback message.
- Care backend API failures: catch connection errors and timeouts, log internally, and reply with a clean error message without exposing internal details
- Unexpected state transitions: if the state machine receives an input it does not expect in the current state, fall back to the main menu with a clear message rather than crashing
- Blocked users attempting to message during a lockout period: respond with the lockout duration without processing the message further

**Audit logging:**

- Use the `care.audit_log` package for:
  - Every authentication attempt, whether successful or failed
  - Every DOB verification attempt and outcome
  - Every lockout triggered and when it expires
  - Every data access event: what resource was accessed, by whom, and at what time
  - Every rate limit trigger
  - Every notification dispatched
- Ensure audit log entries contain enough detail to satisfy HIPAA-grade audit trail requirements

**Unit tests:**

- Write unit tests for the authentication flow (all success and failure paths)
- Write unit tests for the state machine (all state transitions)
- Write unit tests for data sanitization logic

**Milestone:** All failure paths are handled gracefully. Audit logging is complete. Unit test suite passes.

---

## Phase 3: Notifications and Frontend Plugin

### Week 6: June 29 to July 5

**Goal:** Implement the asynchronous notification system.

**Django signal listeners:**

- Django's built-in signals (`post_save`, `post_delete`) are emitted automatically for every model save and delete in the entire Django project, including all Care core models. No changes to Care core are required. The plugin simply connects receiver functions to these signals from within its own `signals.py` file, which is imported in the plugin's `AppConfig.ready()` method so receivers are registered when Django starts.
- Connect receivers to the relevant Care models for events that should trigger notifications:
  - `Appointment` post_save: check if the appointment was newly created or if the status field transitioned to a state that warrants a notification (e.g. confirmed, cancelled, rescheduled)
  - `LabResult` (or equivalent) post_save: check if the result status transitioned to a final/published state
  - `Encounter` post_save: check for discharge events
  - Additional models as agreed with mentors during pre-coding alignment
- Each receiver checks the specific field transitions on the instance to avoid firing on every save, then creates an `IMNotification` record and enqueues a Celery task. The receiver itself does no heavy work.
- If a very specific business logic event is needed that a `post_save` filter cannot cleanly capture, that is the only case where a PR to Care core would be needed to emit a custom signal. This will be identified and agreed upon during pre-coding.

**Celery tasks:**

- The Celery task receives the notification payload, formats the message through the `IMProvider.send_message` interface (completely provider-agnostic), and dispatches it via WhatsApp
- On WhatsApp API rate-limit errors or transient failures, the task retries automatically using Celery's retry mechanism with exponential backoff
- The `IMNotification` record is updated with the outcome: sent, failed, or queued for retry

**Notification status tracking:**

- Staff should be able to see the status of outgoing notifications (pending, sent, failed, retried) via the frontend UI built in Week 7

**Milestone (Midterm Deliverable):** A fully functional backend plugin capable of serving authenticated patient and staff queries via WhatsApp, with automated notifications firing in response to Care events. All audit logging, error handling, caching, and rate limiting are in place.

> **Midterm evaluation: July 6, 2026**

---

### Week 7: July 7 to July 12

**Goal:** Set up the frontend plugin and implement the staff-facing notification management interface.

**Frontend setup:**

- Initialize `care_im_wrapper_fe` using `care_hello_fe` as the base
- Configure the frontend plugin to register within Care's frontend plugin system
- Set up routing, layout, and shared component imports from `care_fe` where applicable
- Implement the API client layer for communicating with the backend plugin's REST endpoints

**Notifications UI:**

- Staff-facing interface for managing notifications:
  - List view showing all scheduled, sent, and failed notifications with status indicators and timestamps
  - Create notification form: recipient selection (individual patient, care team, or broadcast), message content, optional cron schedule for recurring notifications
  - Edit and delete for scheduled (not yet sent) notifications
  - Manual "Send Now" button for immediate one-off dispatch
- RBAC enforcement: only users with the appropriate Care role can create, edit, or delete notifications. Read-only access for lower-privilege roles. Enforced on both the frontend (show/hide controls) and backend (API-level permission checks).

**Backend API endpoints for the notification UI:**

- `GET /notifications/`: paginated list with filters for status, date range, and recipient
- `POST /notifications/`: create a new notification record
- `PATCH /notifications/{id}/`: update a scheduled notification
- `DELETE /notifications/{id}/`: cancel a scheduled notification
- `POST /notifications/{id}/send/`: manually trigger an immediate send

**Milestone:** Staff can log into Care, open the IM wrapper panel, and fully manage notifications through the UI.

---

### Week 8: July 13 to July 19

**Goal:** Implement signed URL generation and the patient-facing document access page.

**Signed URL generation (backend):**

- When a patient requests a document (lab report, medication list, encounter summary) and the content is too long for a WhatsApp message, generate a time-limited signed URL
- The signed URL is stored in the `SignedLink` model with an expiry datetime (e.g. 24 hours) and a single-use flag
- Send the signed URL to the patient via WhatsApp
- On the backend, validate every request to a signed URL: check expiry, check the single-use flag, and reject invalid or expired links with a clear error response

**Patient-facing document page (frontend):**

- The patient opens the signed URL in any browser, no login required
- The frontend verifies the link's validity by calling the backend, then renders the document:
  - For PDFs (lab reports, prescriptions), render a preview using existing `care_fe` components where possible, with a download button
- Expired links show a clear expiry message
- Already-used single-use links show an appropriate message
- The page is mobile-first since patients are likely opening it on the same phone that received the WhatsApp message

**CORS configuration:**

- Ensure the backend plugin's API allows cross-origin requests from the frontend plugin's domain
- Configure CORS headers correctly for both the signed URL endpoints and the notification management API

**Milestone:** A patient receives a signed link on WhatsApp, opens it on their phone, sees a preview of their document, and can download it. Expired and used links are rejected cleanly.

---

## Phase 4: Integration, Edge Cases, and Final Polish

### Week 9: July 20 to July 26

**Goal:** Harden the fully integrated system by addressing all known edge cases and conducting thorough end-to-end testing.

**Long message handling:**

- Audit every data fetch handler to identify cases where the response could exceed WhatsApp's text character limit
- For each such case, implement the agreed-upon strategy: either split the message into sequential numbered parts, or redirect the user to a signed frontend URL for the full content
- Test with real data sets of varying sizes to confirm the cutoff logic is correct

**Edge case coverage:**

- Message arrives mid-session from a new device or after Redis TTL expiry: session should reset cleanly to `UNAUTHENTICATED` without error
- Care backend is temporarily unavailable: every menu handler must fail gracefully with a user-facing message and an internal log entry, not an unhandled exception
- A notification fails after all Celery retries are exhausted: the `IMNotification` record must be marked as permanently failed and the staff should see this in the UI
- WhatsApp sends a duplicate webhook delivery (Meta guarantees at-least-once delivery): the system must be idempotent and not process the same message twice
- The signed URL is accessed after expiry or after it has already been used: both cases must return a clean error page, not a 500

**Full integration test pass:**

- Run through the complete patient flow end-to-end: message the bot, authenticate, navigate the menu, request a document, receive a signed URL, open the document in the browser, download it
- Run through the complete staff flow: authenticate as staff, look up a patient, retrieve their summary, trigger a manual notification from the UI, confirm delivery
- Confirm the Celery notification pipeline fires correctly for each configured signal

**Milestone:** No known unhandled edge cases remain. Full end-to-end integration test passes for both the patient and staff flows.

---

## Phase 5: Testing, Documentation, and Project Handover

### Week 10: July 27 to August 2

**Goal:** Write the complete backend test suite.

**Unit tests:**

- Authentication flow: all success paths, all failure paths, lockout trigger, lockout expiry
- State machine: all valid transitions, all invalid input scenarios, Redis TTL expiry and reset
- Data access handlers: correct data returned for each menu option, RBAC enforcement (staff cannot access data their role does not permit, patients cannot access other patients' data)
- Data sanitization: verify that PII fields that should be stripped are absent from responses
- Rate limiting: verify that limits are enforced and that thresholds are respected
- Caching: verify cache hits return cached data, cache misses call the API, invalidation works correctly
- Notification dispatch: Celery task called correctly, retry behavior on failure, IMNotification record updated with correct status
- Signed URL: correct generation, correct expiry validation, single-use enforcement

**Integration tests:**

- Webhook receives message, state machine processes it, correct response is sent back via WhatsApp
- Auth flow: full two-step authentication over the normalized message interface
- Data fetch: authenticated request triggers Care API call, response is formatted and sent
- Notification pipeline: Django signal fires, Celery task is enqueued, task dispatches message, IMNotification updated

**Coverage:** Aim for meaningful coverage of all critical paths. Use `coverage` and review the report to identify any untested branches.

**Milestone:** Backend test suite passes. All critical paths have test coverage.

---

### Week 11: August 3 to August 9

**Goal:** Write the frontend test suite and complete all documentation.

**Frontend tests (Playwright):**

- Notification list page: renders notifications, filters work correctly, pagination works
- Create notification form: valid submission creates a notification, invalid input shows validation errors, RBAC restriction hides form for unauthorized roles
- Manual send: clicking "Send Now" triggers the correct API call and updates the notification status in the UI
- Signed URL page: valid link renders the document, expired link shows the correct message, used link shows the correct message

**API documentation:**

- Generate documentation for all backend plugin API endpoints using swagger
- Every endpoint must be documented with request parameters, request body schema, response schema, and example responses
- Authentication and permission requirements must be documented for each endpoint

**Developer documentation (Sphinx):**

- Architecture overview: how the plugin is structured, how it fits into Care, how the IM wrapper abstraction works
- How to add a new IM provider: step-by-step guide for implementing a new `IMProvider` subclass and registering it, written for a developer who has never seen this codebase before
- Configuration reference: every configurable setting (Redis TTL, rate limit thresholds, WhatsApp API credentials, signed URL expiry, etc.) documented with type, default value, and description
- Deployment guide: how to install and configure the plugin in a production Care deployment, including WhatsApp Business API setup steps

**Milestone:** Frontend test suite passes. API documentation and developer documentation are complete and reviewed.

---

### Week 12: August 10 to August 17

**Goal:** Final cleanup, demonstration materials, and project handover by August 17.

**Code cleanup:**

- Remove all debug statements, commented-out code, unused imports, and TODO comments
- Ensure consistent code style throughout both the backend and frontend plugin
- Ensure all public functions, classes, and methods have proper docstrings
- Run linters and formatters one final time across both repos

**Demonstration materials:**

- Record a demonstration video of the patient flow: start from an unauthenticated message, complete auth, navigate the menu, request a lab report, receive a signed link, open the document page, and download
- Record a demonstration video of the staff flow: authenticate, look up a patient, view their summary, trigger a manual notification via the WhatsApp bot, and verify delivery
- Record a demonstration video of the frontend UI: notification management, creating a scheduled notification, viewing sent and failed notifications
- Write a setup guide covering how to install the plugin, configure WhatsApp API credentials, configure Redis and Celery, and run the first end-to-end test
- Write a brief user guide for staff covering how to use the frontend notification panel

**Final handover:**

- All code merged and ready for review in the agreed-upon branches
- Both plugin repos in a clean, fully documented state
- All demonstration videos and guides linked from the repo READMEs
- Final sync with mentors to confirm the handover is complete

**Milestone (Final Deliverable):** A fully functional, tested, documented, and deployable IM Wrapper plugin for Care. Backend plugin handles patient and staff queries via WhatsApp with complete auth, RBAC, caching, rate limiting, audit logging, and async notifications. Frontend plugin provides staff with a notification management interface and patients with secure document access via signed URLs. The architecture is modular and ready for future provider integrations.

> **Final evaluation and project handover: August 17, 2026**

---

## Deliverables Summary

| # | Deliverable |
|---|-------------|
| 1 | `care_im_wrapper`: Django backend plugin with WhatsApp provider, two-step auth, state machine, patient and staff data access, caching, rate limiting, audit logging, and Celery-based notifications |
| 2 | `care_im_wrapper_fe`: Frontend plugin built on `care_hello_fe` with staff notification management UI and patient-facing signed URL document access page |
| 3 | Backend test suite using Django's `unittest`-style `APITestCase` with `model_bakery` for fixtures and `coverage` for reporting |
| 4 | Frontend test suite using Playwright |
| 5 | API documentation using Swagger |
| 6 | Developer documentation using Sphinx including architecture overview, provider extension guide, configuration reference, and deployment guide |
| 7 | Demo videos covering patient flow, staff flow, and frontend UI |
| 8 | Setup guide and staff user guide |
