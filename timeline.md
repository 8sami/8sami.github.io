# Detailed Timeline for IM Wrapper Implementation

## Questions

- I want to ask about the frontend implementation of the im_wrapper plugin, which will be of course a plugin in itself.
  - Features in my mind:   
    1. Provide the ability to do CRUD on notifications and configure their cron schedule.
    2. Proper RBAC to only allow selected roles to perform CRUD operations on notifications 
    3. Allow patients to view and download PDFs of medications and lab reports using signed URLs.
  - Questions in my mind:
    1. Should the FE plugin also support display of texts which are too long to be fit inside a single message (eg: list of medications)? or should it manage all texts via whatsapp by splitting them?
    2. What should ideally happen if a staff member is also registered as a patient?


## Timeline:

### Phase 1: Project Setup
**Before Week 1: May 10 - May 24**
- **Goal:** 
  - Setup and development environment configuration.
  - Apply for all the Meta and Whatsapp verifications.
  - Get to know the team.
  - Get every doubt clear related to the project.
  - Clear up any work on assigned PRs.
  - Setup plugin BE repo using `care-plugin-cookiecutter`
  - Setup plugin FE repo using `care_hello_fe`
- **Milestone:** Development environment fully configured and nothing blocking me from getting started.

**Week 1: May 25 - May 31**
- **Goal:** 
  - Imp
- **Week 1:**
- **Week 2:**
  - **Goal:** Plugin architecture setup.
  - Setup `im_wrapper` plugin structure as per OpenMRS development guidelines.
  - Understand `mw-core-bundle` structure and plugin integration patterns.
  - Setup CI/CD pipelines for the new plugin.
  - **Milestone:** Plugin structure defined and CI/CD ready.

### Phase 2: Backend Development (Notifications & RBAC)
**Week 3-6: June 10 - July 7**
- **Week 3-4:**
  - **Goal:** Implement core notification management.
  - Implement Notification entity with fields: `name`, `type`, `schedule`, `active`.
  - Create NotificationService for CRUD operations and scheduled execution.
  - Create custom REST API endpoints for notification management.
  - **Milestone:** Notification CRUD endpoints functional.
- **Week 5:**
  - **Goal:** Implement RBAC and permission management.
  - Integrate with OpenMRS RBAC module.
  - Create specific roles (e.g., `NotificationAdmin`) for managing notifications.
  - Implement permission checks for all CRUD operations.
  - **Milestone:** RBAC implemented and tested.
- **Week 6:**
  - **Goal:** Scheduled notifications and WhatsApp integration.
  - Implement cron-based notification dispatch using NotificationService.
  - Integrate `whatsapp_connector` to send template messages.
  - Handle different notification types (e.g., Appointment Reminders, Medication Alerts).
  - **Milestone:** Backend notifications with WhatsApp integration complete.

### Phase 3: Frontend Development
**Week 7-9: July 8 - July 28**
- **Week 7-8:**
  - **Goal:** Develop Notification Management UI.
  - Create Notification List page with filtering and search capabilities.
  - Develop Add/Edit Notification form with schedule configuration.
  - Implement visual indicators for active/inactive notifications.
  - **Milestone:** Notification management UI complete.
- **Week 9:**
  - **Goal:** Integrate frontend with backend APIs.
  - Connect frontend components to NotificationService.
  - Implement real-time updates using polling or webhooks.
  - Handle error states and user feedback.
  - **Milestone:** Frontend fully functional with backend.

### Phase 4: Document Management & Signed URLs
**Week 10-11: July 29 - August 11**
- **Week 10:**
  - **Goal:** Implement Document Service and PDF generation.
  - Create DocumentService to handle storage and retrieval of patient documents.
  - Integrate with `PdfGeneratorService` for creating PDFs (Lab Reports, Prescriptions).
  - Implement file upload and versioning.
  - **Milestone:** PDF generation pipeline functional.
- **Week 11:**
  - **Goal:** Signed URL generation and secure access.
  - Implement secure signed URL generation using OpenMRS storage service.
  - Integrate with notification system to send secure download links.
  - Implement access control and expiry mechanisms.
  - **Milestone:** Signed URL access control implemented.

### Phase 5: Testing & Refinement
**Week 12-13: August 12 - August 25**
- **Week 12:**
  - **Goal:** Comprehensive testing.
  - Write unit tests for all backend services and components.
  - Write integration tests for frontend and backend interactions.
  - Conduct manual testing of all features.
  - **Milestone:** All tests passing.
- **Week 13:**
  - **Goal:** Documentation and final polishing.
  - Create comprehensive plugin documentation (user guide, API docs).
  - Create demo videos for key features.
  - Prepare presentation for final evaluation.
  - Address any last-minute feedback from mentors.
  - **Milestone:** Project documentation complete and polished.

### Week 14: Submission
- Finalize all code and documentation.
- Prepare final project report.
- Submit project for evaluation.