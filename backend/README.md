# Family Tree Web Application

A comprehensive web application for building and managing family trees with interactive visualization features.

## Backend Setup

1. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Set up environment variables:
Create a `.env` file in the `backend` directory with the following variables:
```
DEBUG=True
SECRET_KEY=your-secret-key
DB_ENGINE=django.db.backends.postgresql
DB_NAME=familytree
DB_USER=postgres
DB_PASSWORD=your-local-password
DB_HOST=localhost
DB_PORT=5432
```

4. Run migrations:
```bash
python manage.py migrate
```

5. Create a superuser:
```bash
python manage.py createsuperuser
```

6. Run the development server:
```bash
python manage.py runserver
```

## API Documentation

The API documentation will be available at `/api/docs/` when the server is running.

## Features

- Interactive family tree visualization
- Comprehensive data management
- User-friendly interface
- Data import/export capabilities
- Media management
- User authentication and authorization
- RESTful API endpoints
## Reviewed family joining

`/api/family-access/` supports owner-managed invitations, reviewed profile claims/parent connections, explicit viewing/editing roles and opt-in ancestry suggestions. See `../FAMILY_JOINING_IMPLEMENTATION.md` for behavior, privacy boundaries and current limits. Apply migration `family.0006` with the normal migration process before serving this source. Local PC testing applies it only to the isolated device-test database.


## Account lifecycle finishing

Apply users migrations 0005–0007 with the matching backend after reviewing the snapshot/collision checks in `../ACCOUNT_FINISHING_REVIEW.md`. Personal sign-in secrets remain usable through a stored verifier and are shown only on creation. Old JWTs without password binding require sign-in again.

Account settings use `/api/auth/account/`. Verification and recovery require the mail configuration in `.env.example`; recovery uses `/api/auth/recovery/`. The isolated PC configuration writes test messages to `.device-test/outbox` instead of sending real email. Deletion requests are review records, not completed deletion. The operator queue and `/account/deletion/` request form need a reviewed disposition policy and operating process before launch.


## Current workflow closure and release audit

The private launch configuration blocks outsider reads of historical public trees; discovery remains independently opt-in and family approval grants whole-tree viewing. Apply family migrations 0007 (normalized ancestry search names) and 0008 (private content report receipts), in addition to the prior migration requirements, only after a snapshot rehearsal. Backup format 8 includes reports and reads compatible formats 4–8.

`python manage.py check_release` is a read-only configuration/workflow audit. A nonzero result means release inputs are missing; it never deploys, sends mail or deletes records. It checks basic configuration shape and must be followed by real delivery, private-storage, off-device restore and signed-device evidence. Configure the release values in `.env.example` only from real reviewed resources. Run Django's `check --deploy` against the actual staging/production configuration too.

`/api/content-reports/` accepts reports about accessible existing profiles/content and exposes only the reporter's receipts. Admin users triage them; resolving a report requires a response. An operational owner and reviewed handling policy are still required. Account deletion remains a pending review request, not completed erasure. See `../PRODUCTION_GAP_CLOSURE_REVIEW.md` for the current release blockers and verification record.
