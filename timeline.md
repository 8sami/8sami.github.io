# Detailed Timeline of IM Wrapper Plugin Development

## Before Coding Period Begins

**Date:** 10 May to 24 May 2026

**Goal:** I will ensure that every prerequisite is fully resolved before coding begins on May 25.

**Which Includes:**

- Getting Meta Business, notifications templates, and display name verification done.
- Getting appropriate access to the IM Wrapper Meta Developer App.
- Setting up the FE (`create-care-mfe-plug`) and BE (`care-plugin-cookiecutter`) plugin repos.
- Finalising the features, database schemas and overall implementation plan with mentors.
- Studying the codebase and gaining knowledge about testing, docs and things I don't know about, eg: RBAC, Celery beat, `care.audit_log` package, `create-care-mfe-plug` etc.
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

- Writing the 2-step auth logic by matching the inbound message's phone number against patients' and staffs' phone numbers and then prompting for the DOB to match against the year of birth/DOB for both.
- Writing logic for handling cases where a patient's phone number is same as a staff member's phone number or when multiple patients have the same phone number.
- Creating and storing the auth session and upating the conversation state.
- Enforcing a cooldown period after a number of incorrect DOB/birth of year are provided.

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
- Will try to write logic for generating and returning signed urls for PDF documents.

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

**Goal:** I will focus on building the notification functionality's backend integration.

**Which Includes:**

- Figuring out when to trigger notifications using django signals.
- Saving each notification with their status in the respective models and then dispatching them through background tasks using celery and redis.
- Building the logic for scheduling notifications using celery beat.
- Creating the respective APIs for performing CRUD and dispatching of the saved notifications.

## Midterm Evaluation

**Date:** 6 July 2026

## Week 7

**Date:** 6 July to 12 July 2026

**Goal:** I will build the notification functionality's frontend.

**Which Includes:**

- Making a rough figma wireframe of the UI and getting approval for it.
- Figuring out which existing components from `care_fe` can be reused.
- Setting up routes, adding navigation links and building the UI using the APIs built in the previous week.
- Doing manual testing of the frontend.

## Week 8

**Date:** 13 July to 19 July 2026

**Goal:** I will implement the functionality for generating, saving and then fetching data and generating PDF documents based on those signed URLs. 

**Which Includes:**

- Like in the week 7, making a rough figma wireframe and getting approval for it.
- Figuring out which existing components from `care_fe` can be reused for generating, previewing and downloading the PDF documents.
- Writing logic for signed urls validation and routing.
- Fetching data and generating the PDF documents for the user to preview and download (similar to how `care_fe` is doing it).
- Ensuring the users are provided with the signed URLs and that they are being expired after use or after the validity period.
- Making sure backend implementation is complete and functional before starting work on the frontend part.

## Week 9

**Date:** 20 July to 26 July 2026

**Goal:** I will finalize the development by handling edge cases, doing manual testing, cleaning up code and implementing possible optimizations.

**Which Includes:**

- Testing every use case and scenario and ensuring that everything works as expected.
- Trying out edge cases and writing logic for the unhandled ones.
- Cleaning up code by removing redundant and unused code, implementing possible optimizations and doing final touches.
- Catching up to any unfinished task or unresolved blockers.

## Week 10

**Date:** 27 July to 2 August 2026

**Goal:** I will write tests and documentation for the backend plugin.

**Which Includes:**

- Writing tests for all the major functionalities such as authentication, data fetching, RBAC enforcement, audit logging, data sanitization, caching, debouncing, rate limiting, notifications and signed URLs functionality etc
- Documenting all the api routes with swagger
- Documenting the rest of the backend implementation using sphinx.
- Ensuring that all tests pass and has full test coverage.

## Week 11

**Date:** 3 August to 9 August 2026

**Goal:** I will write tests and documentation for the frontend plugin.

**Which Includes:**

- Writing tests covering all the functionalities of the frontend plugin using playwright.
- Documenting each and everything using mdx and saving it in the `/docs` folder at the root level.
- Ensuring each test passes.

## Week 12

**Date:** 10 August to 16 August 2026

**Goal:** I will create guides on how to install, use and develop the plugin and work with the team to deploy and handover the project.

**Which Includes:**

- Creating detailed and comprehensive guides on how to install, use and develop the plugins.
- Working with the team to make deployments.
- Preparing for the final submission.
- Handing over all the finished work and keep contributing.

## Final Submission

**Date:** 17 August 2026
