# PolyH.T

PolyH.T (Polytechnic House Test) is a full-stack mobile application system with two Flutter apps and a MySQL-backed REST API.

- `apps/polyht_admin`: Flutter admin app for uploading PDFs, scheduling tests, and managing exam papers.
- `apps/polyht_student`: Flutter student app for secure scheduled PDF test access.
- `backend`: Node.js, Express, JWT, MySQL, and local PDF upload storage.
- `docs`: API and database documentation.

## Quick Start

1. Create a MySQL database and run `backend/database/schema.sql`.
2. Copy `backend/.env.example` to `backend/.env` and update values.
3. Install dependencies and create real college users. Replace these values with actual admin and student records:

```bash
cd backend
npm install
npm run create-user -- admin "Admin User" admin@college.edu secret123
npm run create-user -- student "Student User" CO2026001 secret123 CO
```

4. Start the API:

```bash
npm run dev
```

5. Open either Flutter app folder and run:

```bash
flutter pub get
flutter run
```

Update `ApiConfig.baseUrl` in each Flutter app for your development machine or server.
