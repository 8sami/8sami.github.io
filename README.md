# IM Wrapper Proposal with POC

<table>
    <thead>
        <tr>
            <th width="203">Personal Details</th>
            <th>Description</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><strong>Name</strong></td>
            <td>Samiullah Javed</td>
        </tr>
        <tr>
            <td><strong>Organisation Details</strong></td>
            <td>College: Islamia Govt. Science College Sukkur<br>Program: Computer Science<br>Grade: 12th<br>Expected Graduation Date: June 2026</td>
        </tr>
        <tr>
            <td><strong>Contact Details</strong></td>
            <td>Phone No: +92 326 3672475 <br>Email ID: samiullahjavedd@gmail.com</td>
        </tr>
        <tr>
            <td><strong>Current Timezone</strong></td>
            <td>Pakistan Standard Time</td>
        </tr>
        <tr>
            <td><strong>Github Profile</strong> </td>
            <td><a href="https://github.com/8sami">https://github.com/8sami</a></td>
        </tr>
        <tr>
            <td><strong>Linkedin Profile</strong></td>
            <td><a href="https://www.linkedin.com/in/samiullahjaved">https://www.linkedin.com/in/samiullahjaved</a></td>
        </tr>
        <tr>
            <td><strong>Resume</strong></td>
            <td><a href="https://samiullahjaved.com/Samiullah_Javed.pdf">https://samiullahjaved.com/Samiullah_Javed.pdf</a></td>
        </tr>
        <tr>
            <td><strong>Portfolio Website</strong></td>
            <td><a href="https://samiullahjaved.com">https://samiullahjaved.com</a></td>
        </tr>
    </tbody>
</table>

#### Project Proposal

* **Title**: Whatsapp bot for Care
* **Project Overview**:
    IM wrapper is a django plugin based instant messaging provider meant to provide staff and patients ease of access to medical data through any messaging app, quickly and securely. Additionally, it also aims to add functionality of sending alerts and notifications via the configured messaging providers.

    Although the Care web app already provides all the information, but people such as those living in rural/remote areas could greatly benefit from accessing their medical records and appointments through a simple message on WhatsApp instead of having to navigate a web app which could prove difficult for people with limited digital exposure.

    The provider approach makes the instant messaging functionality independent of any messaging app, ensuring each one's support can be developed, maintained and tested without interfering with other messaging provider's implementation.

    Developing it as a plugin ensures that we won't have to worry about it interfering with Care's backend. As a plugin, it can be removed, added, updated any time without affecting the core backend. This keeps the core backend clean and lean which ensures good maintainability and good developer experience.

    **Specification:**
    1. **Architecture**: Plugin based, using the [django plugin cookiecutter template](https://github.com/ohcnetwork/care-plugin-cookiecutter). Provider agnostic approach so that the plugin could support multiple messaging providers.
    2. **Authentication**: Two step authentication; first step is matching the requestor's phone number with the number associated with a patient or staff member in the database. The second step is asking for DOB to confirm identity. If the requestor fails to provide correct DOB within 3 attempts, the request is blocked for 15 minutes.
    3. **Authorization**: The authorization is managed via the type of account (staff, patient etc) and roles permissions (RBAC) logic in the Care backend. For example a patient can only access their own data, while staff can access the data of patients.
    4. **Caching**: Implemented using Redis through django-redis to reduce latency and database load, with configurable TTL.
    5. **Rate Limiting**: Rate limiting and debouncing of message requests to prevent spam, abuse and overspending credits.
    6. **Error Handling**: Proper error handling following Care's implementation and guidelines.
    7. **Audit Logging**: Audit logging using the existing care.audit_log package of all important events.
    8. **Frontend**: The frontend will be developed using [care_hello_fe](https://github.com/ohcnetwork/care_hello_fe) to allow requestors to download PDFs of medications, lab reports etc and (maybe) for rendering content too long to be sent as messages. Will also provide staff with ui to manually send out notifications and alerts.
    9. **Notification**: To handle alerts asynchronously, the plugin will rely on Care's existing celery setup. We listen to django signals which trigger a background celery task. The task will call a method in the IM wrapper that will just format the payload and send it off, regardless of the messaging provider. Celery's retry mechanism will trigger if any of the providers' API rate-limits us or goes down. The notifications can also be sent out manually by staff through the frontend plugin.
    10. **Testing**: Proper tests using pytest, coverage and playwright, taking inspiration from existing tests of Care.
    11. **Documentation**: Documentation using sphinx and swagger.

    **Proof of Concept:**
    To support my claims and get hands-on experience, I developed a working prototype of the IM wrapper as a django plugin using the [django plugin cookiecutter template](https://github.com/ohcnetwork/care-plugin-cookiecutter) with the help of AI.

    My plan was to architect it as an IM provider which could be extended to support any messaging app. Since it's a proof of concept, I only implemented the patient side of things and the WhatsApp provider. There are many things that could have been done better and many things are intentionally kept simple, but I believe it is somewhat successful in properly conveying my ideas.
    
    Below is the list of things I focused on implementing for the POC:

    * Implemented the two step auth, in which the first step verifies the requestor's phone number with the number associated with a patient in the db. The second step asks for DOB to confirm identity. 
    
        If the requestor fails to provide correct DOB within 3 attempts, all requests from that number are blocked for 15 minutes.
    * Proper state management is implemented so that the 'bot' is fool-proof and somewhat context-aware.
    * Caching with configurable TTL is also implemented. 
    * The plugin is using care.audit_log package to log all the events to comply with HIPAA security regulations.
    * Fetches live data instead of returning dummy data from faker.
    * Data sanitization is also implemented to prevent sending irrelevant sensitive information that could put PII of patients at risk.

    Below are the links to the Github repo and a YouTube video demonstration of the POC:

    * **Github repo**: [https://github.com/8sami/im_wrapper_poc](https://github.com/8sami/im_wrapper_poc)
    * **YouTube video**: [https://www.youtube.com/watch?v=wKRil3z-d5s](https://www.youtube.com/watch?v=wKRil3z-d5s)

    This flowchart provides a high level 'flow of program' of the POC (click to view it in miro):

    <a href="https://miro.com/app/board/uXjVG1KxNJM=/">
    <img title="Click to open the flowchart in miro" src="media/flowchart.png" alt="flowchart illustrating the flow of program" width="800"/>
    </a>

    **Additional Information:**
    * The word "WhatsApp" can be used interchangeably with any or all of the messaging apps/providers that could be integrated in the plugin in the future.
    * During the development of POC, I had AI create me [im_wrapper_setup.sh](https://github.com/8sami/gsoc-proposal/blob/main/media/im_wrapper_setup.sh) script to help automate the setup and running of the development environment (which had started to become annoying doing daily, manually).

        The script [im_wrapper_setup.sh](https://github.com/8sami/gsoc-proposal/blob/main/media/im_wrapper_setup.sh) pulls the latest changes from origin develop, rebuilds containers, loads fixtures, logins as admin, creates a service account, generates service account token, creates a read only role and assigns it to the service account, gets all organizations and assigns the service account to them, then updates the service account token and username in plug_config.py and then starts up ngrok on port 9000.
    * I have also put together [plugin_setup.md](https://github.com/8sami/gsoc-proposal/blob/main/media/plugin_setup.md) to help with the setup of the POC plugin.
    * A few thoughts I had during the development of POC:
        * "I wonder if the IM wrapper plugin will also need a frontend implementation (just like [scribe_fe](https://github.com/ohcnetwork/care_scribe_fe)) for providing users with the ability to download PDFs of invoices, medications etc, as sending these PDFs via WhatsApp might not be a good idea."
        * "We will surely need a frontend implementation to be able to send notifications and alerts to patients and staff or maybe we could add a staff-only option to allow them to do this using just the interactive menu of WhatsApp and other providers."
        * "Since each encounter (visit) can have different medications and service requests etc, will it make more sense to first prompt user to select an encounter when they message the plugin for, let's say, medications (if a patient has multiple encounters) or instead, just list out all the medications of all the encounters (as it currently does in the POC)?"
        * "I was also thinking of implementing a one-time otp verification, just to be extra careful, but since we will be matching requestor's phone number against patients in the db and the requestor will already have access to that phone number; it will just be an additional unnecessary cost."
        * "What should ideally happen if a staff member is also registered as a patient using the same phone number?", I faced this scenario while testing the POC and wasn't sure how to handle it.
        * "I wonder what could be the best way to handle long messages, such as those exceeding 4,096 characters.", still haven't found an answer for this.

    **Use Cases**:
    1. Since Care provides teleICU services to many remote areas of India, it makes a lot of sense to provide ease of access to medical data to the people living in those areas where issues like internet connectivity, digital literacy and lack of access to computers are prevalent.
    2. Using messaging apps like WhatsApp is more comfortable and easier to use for people because of its familiarity than navigating a web app, which can be daunting for some.
    3. Accessing information via WhatsApp is much more convenient and faster than having to log in to the Care web app.

        The image below aims to depict the time it may take to access information via both methods by showing the difference in number of steps:

        <img title="Difference in time taken to access medical info" src="media/difference_in_time_taken.png" alt="image illustrating the difference b/w the time it takes to access info" width="800"/>

* **Features**:
  1. I honestly really liked the plugin approach and it was my first time seeing something like that. It's so good at keeping the core project clean and makes it really easy to add new features without worrying about breaking existing implementations... I will surely be using this approach in my own projects.
  2. It was my first time seeing the implementation of RBAC based roles and permission too and I sure learned a lot.
  3. The care_scribe plugin was so amazing too! I read its docs completely, word to word. I really liked that filling up forms by hand is a seemingly minor inconvenience but how it's saving doctors and nurses quite a lot of time.
  4. I have learned a lot contributing to the care_fe project and got to learn many new different things that I didn't know existed before, so I am really grateful to the core team for welcoming me and helping me whenever I bothered them :D

#### Technical Skills and Relevant experience

* My technical skills include python, javascript, typescript, react, nextjs, django, flask, SQL, git, github, docker, linux
* My first full stack project, "Simple Invoice Generator" was built using django, weasyprint, crispy-bootstrap5 and jinja. That project recorded almost 20 million of transactions for a procurement service provider and then as I was developing its v2 using nextjs, shadcn, reactPDF and django ninja the business completed its tenure and I had to stop its development. I reviewed the code a few weeks ago... it needs a lot of work but I plan to deploy it as a free open source tool this year.

    I have experience working on production grade code across various projects using different technologies at my last job. Working in a high stakes environment has taught me a lot about problem solving while respecting tight deadlines.

#### Implementation Timeline and Milestones
I propose a 3-phase approach for this 12 week, medium size project with the timeline and milestones being:

**Phase 1: Core Backend (Weeks 1-5)**

* **Week 1**: 
1. Gather additional requirements.
2. Setup plugin repo using cookie cutter template
3. Setup messaging providers' development envs

* **Week 2**: 
1. Define the models for storing notifications and signed links for frontend
2. Build the webhooks for the providers (WhatsApp initially)
3. Implement the 2-step authentication

* **Week 3**: 
1. Define views and methods to fetch data from Care backend.
2. Implement data sanitization logic

* **Week 4**: 
1. Work on requests debouncing and rate limiting
2. Implement caching using django-redis
3. Configure and test WhatsApp provider

* **Week 5**:
1. Implement error handling and proper fallback messages.
2. Add audit logging using the care.audit_log package.

* **Deliverable & Milestone 1**: 
A functional backend plugin capable of serving patient and staff queries securely to authenticated users through Whatsapp.

**Phase 2: Notifications & Frontend Plugin (Weeks 6–9)**

* **Week 6**:
1. Build the notification functionality using Celery and Redis.
2. Create listeners for Django signals in Care to trigger automated alerts.

--- *Midterm Evaluation* ---

* **Week 7**:
1. Setup the frontend using care_hello_fe.
2. Implement the UI for the staff to manually send out notifications.

* **Week 8**:
1. Implement logic to create signed URLs
2. Use existing care_fe components for implementing functionality of previewing and downloading PDFs.

* **Week 9**:
1. Ensure CORS compatibility
2. Handle edge cases such as long messages, staff and patient having same phone number and other issues
3. Integrate other messaging providers apart from WhatsApp

* **Deliverable & Milestone 2**: Fully integrated notification system and functionality to preview and download PDFs securely.

**Week 10**:
1. Buffer week for completing blocked, pending or additional tasks

**Week 11**:
1. Write proper tests for both backend and frontend
2. Generate complete, accurate and comprehensive documentation using Swagger and Sphinx.
3. Create deployments

**Week 12**:
1. Record demonstration videos
2. Prepare guides for setting up and using the plugin. 
3. Cleanup codebase
4. Prepare for final submission

* **Deliverable & Milestone 3**: A completely tested, documented, deployed IM wrapper system integrated in Care and ready for production deployment.

--- *Final Evaluation and Submission :D* ---
  
**Deliverables:**
1. A fully functional django plugin acting as the backend.
2. The frontend developed using [care_hello_fe](https://github.com/ohcnetwork/care_hello_fe).
3. Proper tests for both the backend and frontend.
4. Comprehensive documentation of plugin's backend and frontend both. Along with demonstration videos and guides for setting up and using the plugin.
5. Deployments of both backend and frontend plugin.

#### Summary About Me

A short intro of me: [Watch on YouTube](https://youtube.com/shorts/5Gx_Yw9gSZU?si=rSZAJvbkG9n7dxrv) :)

 I am a curious person. I like trying out new stuff and doing things that seem fun to me. Problem solving and product development are one of those things that I very much enjoy doing. I have a year of experience working as a software developer in an Australian agency where I resigned from in February to explore my interests and focus on my studies to try and get into MIT. I started programming when I was in 9th grade, as it seemed really interesting and its just as fun now as it was back then.

 My motivation for winning gsoc is that it aligns with my goals and I have also developed a love for open source in the process. I genuinely enjoy contributing to something bigger than me, something that would go on to live and make people's lives easier even after me.

#### Availability and Commitment

* 40-50 hours per week
* I'll be done with board exams by 25 April 2026 and I won't be preparing for entrance exams until next year so I am totally available to see this project till the end (and beyond).

#### Contribution to OHC Repo (if applicable)

* **Pull Requests**:
  1. <https://github.com/ohcnetwork/care_fe/pull/16144>
  2. <https://github.com/ohcnetwork/care_fe/pull/16086>
  3. <https://github.com/ohcnetwork/care_fe/pull/16085>
  4. <https://github.com/ohcnetwork/care_fe/pull/15828>
  5. <https://github.com/ohcnetwork/care_fe/pull/15546>
  6. <https://github.com/ohcnetwork/care_fe/pull/15454>
  7. <https://github.com/ohcnetwork/care_fe/pull/15098>

* **Issues**: 
  1. <https://github.com/ohcnetwork/care_fe/issues/15719>
  2. <https://github.com/ohcnetwork/care_fe/issues/15494>

* I lowkenuinely really love guiding and helping other people out in the community :D