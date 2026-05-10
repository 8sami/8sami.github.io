# Detailed Timeline of IM Wrapper Plugin Development

## Before Coding Period Begins

**Date:** 10 May to 24 May 2026

**Goal:** I will ensure that every prerequisite is fully resolved before coding begins on May 25.

**Which Includes:**

- Getting Meta Business, notifications templates, and display name verification done.
- Getting appropriate access to the IW Wrapper Meta Developer App.
- Setting up the FE (`care_hello_fe`) and BE (`care-plugin-cookiecutter`) plugin repos.
- Finalising the features, database schemas and overall implementation plan with mentors.
- Studying the codebase and gaining knowledge about testing, docs and things I don't know about, eg: RBAC, Celery beat, `care.audit_log` package, `care_hello_fe` etc.
- Making sure all the assigned PRs in `care_fe` are merged.

## Coding Period

### Week 1

**Date:** 25 May to 31 May 2026

**Goal:** I will build the basic IM Wrapper abstract provider structure and complete the WhatsApp webhook challenge.

**Which Includes:**

- Defining the Base IM Provider abstract class with the appropriate methods for fetching data, sending, receiving and parsing messages.
- Building the models for managing sessions, notifications, and signed urls.
- Defining webhooks for completing providers' verification challenge.

## Week 2

**Date:** 1 June to 7 June 2026

**Goal:** I will focus on building the authentication flow and conversation states.

**Which Includes:**

- Writing the 2-step auth logic by matching the inbound message's phone number against patients' and staff's phone numbers and then prompting for the DOB to match against the year of birth/DOB for both.
- Writing logic for handling cases where a patient's phone number is same as a staff member's phone number or when multiple patients have the same phone number.
- Writing logic for creating and storing the auth session and upating the conversation state.
- Writing logic for enforcing a cooldown period after a number of incorrect DOB/birth of year are provided.

## Week 3

**Date:** 8 June to 14 June 2026

**Goal:** I will write the logic for fetching the data in a provider agnostic way with proper RBAC enforcement.

**Which Includes:**

- Creating handlers for both patient and staff menu options, the focus being:
  - Encounter details
  - Current medications
  - Procedures/Service requests
  - Schedules/Appointments
  - Patient summary
  - Lab reports
  - Patient lookup using their phone number or name (staff only)
- Enforcing RBAC using the technique suggested by [yaswanth on slack](https://rebuildearth.slack.com/archives/C010GQBMFJ9/p1778014189612319?thread_ts=1778002950.083649&cid=C010GQBMFJ9).
- Writing logic for generating and returning signed urls for PDF documents.

## Week 4

**Date:** 15 June to 21 June 2026

**Goal:** I will work on implementing data sanitization, rate limiting, caching, and request debouncing.

**Which Includes:**

- Writing logic to strip away or censor PII of users which isn't explicitly required.
- Implementing proper rate limiting and debouncing to prevent spamming and abuse.
- Writing logic for configurable caching and cache invalidation to keep things nice and fast.

## Week 5

**Date:** 22 June to 28 June 2026

**Goal:** I will work on writing tests, integrating `care.audit_log` package for audit logging and doing left over work.

**Which Includes:**

- Writing proper tests and doing manual testing of the authentication, conversation states, data fetching, RBAC enforcement, rate limiting, caching etc.
- Integrating the `care.audit_log` package for proper audit logging, keeping in mind the PII of users.
- If there is any left over work from previous week, my focus will be completing it.

## Week 6

**Date:** 29 June to 5 July 2026

**Goal:** 

**Which Includes:**

- 
