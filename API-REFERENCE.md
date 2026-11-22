# HRIS Google Apps Script Backend — Master API Reference

Dokumen referensi resmi terpusat untuk seluruh REST API endpoint yang tersedia pada Backend HRIS Google Apps Script (GAS). Dokumen ini mencakup spesifikasi teknis dari **Foundation Phase**, **Modul 1 (`employees`)**, **Modul 2 (`users` / Auth)**, **Modul 3 (`shifts`)**, **Modul 4 (`shift_assignments`)**, **Modul 5 (`attendance`)**, **Modul 6 (`leave_requests`)**, **Modul 7 (`leave_balances`)**, **Modul 8 (`leave_transactions`)**, **Modul 9 (`overtime_requests`)**, **Modul 10 (`payroll_periods`)**, **Modul 11 (`payslips`)**, **Modul 12 (`cash_advances`)**, **Modul 13 (`cash_advance_installments`)**, hingga **Modul 14 (`cash_advance_transactions`)**.

---

## 1. Konvensi Protokol & Transport Google Apps Script

### A. Mekanisme Komunikasi REST melalui `doGet(e)` dan `doPost(e)`

Google Apps Script Web App berjalan di atas infrastruktur Google Cloud dengan batasan runtime:

1. **Header Kustom Tidak Didukung:** Runtime GAS tidak mengekspos request header kustom (`e.headers` fiktif dan tidak ada).
2. **Tunneling HTTP Method:**
   - Permintaan baca data menggunakan metode HTTP `GET` (`doGet(e)`).
   - Seluruh mutasi data (`POST`, `PUT`, `DELETE`) dikirimkan melalui metode HTTP `POST` (`doPost(e)`). Untuk operasi `PUT` atau `DELETE`, sertakan properti `"_method": "PUT"` atau `"_method": "DELETE"` di dalam payload JSON.
3. **Pencegahan Penolakan CORS Preflight Browser:**
   - Pemanggilan `POST` dari web browser wajib menggunakan header `Content-Type: text/plain;charset=utf-8` agar browser tidak mengirimkan preflight `OPTIONS` yang ditolak oleh GAS.
4. **Pengiriman Token Autentikasi (`auth_token`):**
   - **Pada `GET`:** Dikirimkan via query parameter: `?path=...&auth_token=<JWT_TOKEN>`
   - **Pada `POST` / `PUT` / `DELETE`:** Dikirimkan di dalam JSON body envelope: `{"auth_token": "<JWT_TOKEN>", ...}`
5. **Dukungan Idempotensi (`idempotency_key`):**
   - Sertakan `idempotency_key` pada payload `POST` untuk mencegah eksekusi ganda pada jaringan tidak stabil.

### B. Standar Format Response JSON

#### 1. Respons Berhasil (`200 OK` / `201 Created`)

```json
{
  "success": true,
  "status": 200,
  "data": { ... },
  "meta": {
    "serverTimeUtc": "2026-11-20T10:00:00.000Z",
    "total": 1,
    "limit": 50,
    "offset": 0
  }
}
```

#### 2. Respons Error (`400`, `401`, `403`, `404`, `409`, `500`)

```json
{
  "success": false,
  "status": 400,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed for employee data",
    "details": [{ "field": "nik", "message": "nik must be exactly 16 digits" }]
  }
}
```

---

## 2. Foundation Phase Endpoints

### 2.1. API Information (`GET /`)

- **Method:** `GET`
- **Path:** `/`
- **Role:** Publik (Tanpa Autentikasi)
- **Query Parameters:**
  - `path`: `/` (Wajib jika via Web App URL)
- **Contoh curl:**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=/"
  ```
- **Contoh Response (200):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "name": "HRIS Backend - Google Apps Script",
      "version": "1.0.0",
      "phase": "Foundation Phase",
      "status": "ACTIVE",
      "serverTimeUtc": "2026-11-20T10:00:00.000Z"
    }
  }
  ```

---

### 2.2. Health Check (`GET /health` atau `GET /api/v1/health`)

- **Method:** `GET`
- **Path:** `/health` atau `/api/v1/health`
- **Role:** Publik
- **Contoh curl:**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=health"
  ```
- **Contoh Response (200 Healthy):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "status": "HEALTHY",
      "timestamp": "2026-11-20T10:00:00.000Z",
      "services": {
        "spreadsheet": { "healthy": true, "name": "HRIS Database Sheet" },
        "lockService": { "healthy": true },
        "cacheService": { "healthy": true }
      }
    }
  }
  ```

---

### 2.3. Schema Registry Summary (`GET /api/v1/schemas`)

- **Method:** `GET`
- **Path:** `/api/v1/schemas`
- **Role:** Publik
- **Contoh curl:**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/schemas"
  ```
- **Contoh Response (200):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "totalTables": 15,
      "tables": [
        { "name": "employees", "columnsCount": 13, "primaryKey": "id" },
        { "name": "users", "columnsCount": 7, "primaryKey": "id" },
        { "name": "shifts", "columnsCount": 9, "primaryKey": "id" },
        { "name": "shift_assignments", "columnsCount": 6, "primaryKey": "id" },
        { "name": "attendance", "columnsCount": 14, "primaryKey": "id" }
      ]
    }
  }
  ```

---

### 2.4. Initialize Database Sheets (`POST /api/v1/admin/init-database`)

- **Method:** `POST`
- **Path:** `/api/v1/admin/init-database`
- **Role:** Setup Awal (memerlukan `setup_key` jika `SETUP_KEY` terpasang di Script Properties, atau token `OWNER`/`ADMIN`)
- **Request Payload:**
  ```json
  {
    "setup_key": "bootstrap-setup-key-company-2026", // Opsional, wajib jika Script Properties aktif
    "force": false // Opsional, true untuk bypass proteksi re-inisialisasi
  }
  ```
- **Proteksi Re-inisialisasi (Idempotency Guard):**
  Jika seluruh 15 tabel database sudah tergenerate di Google Spreadsheet, request tidak akan memodifikasi/menimpa sheet yang ada dan langsung mengembalikan response `200 OK` dengan flag `alreadyInitialized: true`.
- **Contoh Response (201 Created — Inisialisasi Pertama Kali):**
  ```json
  {
    "success": true,
    "status": 201,
    "data": {
      "message": "Database sheets initialized successfully",
      "result": {
        "initializedSheets": [
          "employees",
          "users",
          "shifts",
          "... (15 sheets)"
        ],
        "existingSheets": []
      }
    }
  }
  ```
- **Contoh Response (200 OK — Proteksi Aktif / Tabel Sudah Ada):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "message": "Database initialization skipped: all 15 tables are already generated",
      "alreadyInitialized": true,
      "totalTables": 15,
      "tables": ["employees", "users", "..."],
      "result": {
        "initializedSheets": [],
        "existingSheets": ["employees", "users", "..."]
      }
    }
  }
  ```

---

## 3. Modul 1: Manajemen Karyawan (`employees`)

### 3.1. Create Employee (`POST /api/v1/employees`)

- **Method:** `POST`
- **Path:** `/api/v1/employees`
- **Role:** `OWNER`, `ADMIN`
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "nik": "3201234567890001",
    "name": "Budi Santoso",
    "email": "budi.santoso@company.com",
    "phone": "081234567890",
    "department": "Engineering",
    "position": "Backend Developer",
    "join_date": "2026-01-15",
    "employment_status": "ACTIVE",
    "base_salary": 12500000
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/employees" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN",
      "nik": "3201234567890001",
      "name": "Budi Santoso",
      "email": "budi.santoso@company.com",
      "phone": "081234567890",
      "department": "Engineering",
      "position": "Backend Developer",
      "join_date": "2026-01-15",
      "employment_status": "ACTIVE",
      "base_salary": 12500000
    }'
  ```
- **Contoh Response (201):**
  ```json
  {
    "success": true,
    "status": 201,
    "data": {
      "id": "e4b5f8c2-3e44-4f81-a589-918237461234",
      "nik": "3201234567890001",
      "name": "Budi Santoso",
      "email": "budi.santoso@company.com",
      "phone": "081234567890",
      "department": "Engineering",
      "position": "Backend Developer",
      "join_date": "2026-01-15",
      "employment_status": "ACTIVE",
      "base_salary": 12500000,
      "created_at": "2026-11-20T10:00:00.000Z",
      "updated_at": "2026-11-20T10:00:00.000Z",
      "deleted_at": null
    }
  }
  ```

---

### 3.2. List Employees (`GET /api/v1/employees`)

- **Method:** `GET`
- **Path:** `/api/v1/employees`
- **Role:** `OWNER`, `ADMIN`
- **Query Parameters:**
  - `search` (opsional): Pencarian nama, NIK, atau email
  - `department` (opsional): Filter divisi
  - `employment_status` (opsional): `ACTIVE` atau `INACTIVE`
  - `limit` (opsional, default 50, maks 100)
  - `offset` (opsional, default 0)
- **Contoh curl:**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/employees&auth_token=YOUR_TOKEN&search=Budi&limit=10"
  ```

---

### 3.3. Get Employee Detail (`GET /api/v1/employees/:id`)

- **Method:** `GET`
- **Path:** `/api/v1/employees/:id`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE` (Karyawan dibatasi pada datanya sendiri)
- **Contoh curl:**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/employees/e4b5f8c2-3e44-4f81-a589-918237461234&auth_token=YOUR_TOKEN"
  ```

---

### 3.4. Update Employee (`PUT /api/v1/employees/:id`)

- **Method:** `POST` (dengan `_method: "PUT"`)
- **Path:** `/api/v1/employees/:id`
- **Role:** `OWNER`, `ADMIN`
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "_method": "PUT",
    "position": "Engineering Lead",
    "base_salary": 15000000
  }
  ```

---

### 3.5. Soft Delete Employee (`DELETE /api/v1/employees/:id`)

- **Method:** `POST` (dengan `_method: "DELETE"`)
- **Path:** `/api/v1/employees/:id`
- **Role:** `OWNER`, `ADMIN`
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "_method": "DELETE"
  }
  ```

---

## 4. Modul 2: Autentikasi & Akun Pengguna (`users`)

### 4.1. Cek Status Inisialisasi Akun User / Owner (`GET /api/v1/auth/setup-status`)

- **Method:** `GET`
- **Path:** `/api/v1/auth/setup-status`
- **Role:** Publik (Tanpa token autentikasi)
- **Fungsi:** Mengetahui apakah tabel `users` masih kosong (`needsSetup: true`) sehingga aplikasi (Flutter/Web) dapat menentukan apakah harus menampilkan layar **Setup Owner Pertama Kali** atau langsung ke layar **Login**.
- **Contoh curl:**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/auth/setup-status"
  ```
- **Contoh Response (200 — Tabel Users Masih Kosong):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "needsSetup": true,
      "hasOwner": false,
      "totalUsers": 0,
      "activeOwners": 0,
      "message": "No user accounts exist in the system. Initial owner setup required via POST /api/v1/auth/setup-owner"
    }
  }
  ```
- **Contoh Response (200 — Akun Owner Sudah Terdaftar):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "needsSetup": false,
      "hasOwner": true,
      "totalUsers": 1,
      "activeOwners": 1,
      "message": "User accounts already configured. Please proceed to login via POST /api/v1/auth/login"
    }
  }
  ```

---

### 4.2. Inisialisasi Akun OWNER Pertama (`POST /api/v1/auth/setup-owner`)

- **Method:** `POST`
- **Path:** `/api/v1/auth/setup-owner`
- **Role:** Publik (Hanya dapat dieksekusi 1x saat tabel `users` masih kosong 0 baris)
- **Request Payload:**
  ```json
  {
    "email": "owner@company.com",
    "password": "SuperSecretPassword123!"
  }
  ```
- **Contoh Response (201):**
  ```json
  {
    "success": true,
    "status": 201,
    "data": {
      "user": {
        "id": "11111111-2222-4333-8444-555555555555",
        "email": "owner@company.com",
        "role": "OWNER",
        "is_active": true
      },
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
  }
  ```

---

### 4.2. Login Akun (`POST /api/v1/auth/login`)

- **Method:** `POST`
- **Path:** `/api/v1/auth/login`
- **Role:** Publik
- **Request Payload:**
  ```json
  {
    "email": "budi.santoso@company.com",
    "password": "PasswordRahasia123!"
  }
  ```
- **Contoh Response (200):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "user": {
        "id": "22222222-3333-4444-8555-666666666666",
        "email": "budi.santoso@company.com",
        "role": "EMPLOYEE",
        "employee_id": "e4b5f8c2-3e44-4f81-a589-918237461234",
        "is_active": true
      },
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
  }
  ```

---

### 4.3. Profile Pengguna Aktif (`GET /api/v1/auth/me`)

- **Method:** `GET`
- **Path:** `/api/v1/auth/me`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE`
- **Contoh curl:**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/auth/me&auth_token=YOUR_TOKEN"
  ```

---

### 4.4. Ganti Password Mandiri (`POST /api/v1/auth/change-password`)

- **Method:** `POST`
- **Path:** `/api/v1/auth/change-password`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE`
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "old_password": "PasswordLama123!",
    "new_password": "PasswordBaru456!"
  }
  ```

---

### 4.5. Create User Akun Baru (`POST /api/v1/users`)

- **Method:** `POST`
- **Path:** `/api/v1/users`
- **Role:** `OWNER`, `ADMIN`
- **Aturan Relasi:**
  - Jika `role: "EMPLOYEE"`, field `employee_id` **wajib diisi** dengan UUID karyawan aktif yang ada di tabel `employees`.
  - Jika `role: "ADMIN"`, field `employee_id` bersifat **opsional** (`null` diperbolehkan).
  - Role `ADMIN` tidak diizinkan membuat akun ber-role `OWNER` (hierarki akun).
- **Request Payload (Contoh Akun Karyawan):**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "email": "dewi.lestari@company.com",
    "password": "PasswordDewi123!",
    "role": "EMPLOYEE",
    "employee_id": "<PASTE_ID_DARI_POST_EMPLOYEES>",
    "is_active": true
  }
  ```
- **Request Payload (Contoh Akun Administrator):**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "email": "admin.hr@company.com",
    "password": "PasswordAdmin123!",
    "role": "ADMIN",
    "employee_id": null,
    "is_active": true
  }
  ```

---

## 5. Modul 3: Jadwal Shift (`shifts`)

### 5.1. Create Shift (`POST /api/v1/shifts`)

- **Method:** `POST`
- **Path:** `/api/v1/shifts`
- **Role:** `OWNER`, `ADMIN`
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "name": "Shift Malam (22:00 - 06:00)",
    "start_time": "22:00",
    "end_time": "06:00",
    "break_minutes": 60,
    "late_tolerance_minutes": 15,
    "is_active": true
  }
  ```
- **Contoh Response (201):**
  ```json
  {
    "success": true,
    "status": 201,
    "data": {
      "id": "33333333-4444-4555-8666-777777777777",
      "name": "Shift Malam (22:00 - 06:00)",
      "start_time": "22:00",
      "end_time": "06:00",
      "break_minutes": 60,
      "late_tolerance_minutes": 15,
      "is_active": true,
      "is_overnight": true,
      "gross_working_minutes": 480,
      "net_working_minutes": 420
    }
  }
  ```

---

### 5.2. List Shifts (`GET /api/v1/shifts`)

- **Method:** `GET`
- **Path:** `/api/v1/shifts`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE`
- **Query Parameters:**
  - `search` (opsional): Filter nama shift
  - `is_active` (opsional): `true` atau `false`

---

### 5.3. Get Shift Detail (`GET /api/v1/shifts/:id`)

- **Method:** `GET`
- **Path:** `/api/v1/shifts/:id`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE`
- **Response Data:**
  Detail shift lengkap beserta kalkulasi otomatis `is_overnight`, `gross_working_minutes`, dan `net_working_minutes`.

---

### 5.4. Update Shift (`PUT /api/v1/shifts/:id`)

- **Method:** `POST` (dengan `_method: "PUT"`)
- **Path:** `/api/v1/shifts/:id`
- **Role:** `OWNER`, `ADMIN`
- **Catatan Kebijakan Penonaktifan Shift:**  
  Tabel `shifts` **tidak menyediakan endpoint `DELETE`** demi menjaga integritas data riwayat presensi dan penugasan yang pernah merujuk ke shift tersebut. Untuk menonaktifkan shift yang tidak lagi digunakan, lakukan `PUT` dengan properti `"is_active": false`.
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "_method": "PUT",
    "name": "Shift Pagi Operasional (Koreksi)",
    "start_time": "08:00",
    "end_time": "17:00",
    "break_minutes": 60,
    "late_tolerance_minutes": 15,
    "is_active": true
  }
  ```

---

## 6. Modul 4: Penugasan Shift (`shift_assignments`)

### 6.1. Single Shift Assignment (`POST /api/v1/shift-assignments`)

- **Method:** `POST`
- **Path:** `/api/v1/shift-assignments`
- **Role:** `OWNER`, `ADMIN`
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "employee_id": "e4b5f8c2-3e44-4f81-a589-918237461234",
    "shift_id": "33333333-4444-4555-8666-777777777777",
    "work_date": "2026-11-21"
  }
  ```

---

### 6.2. Bulk Shift Assignment (`POST /api/v1/shift-assignments/bulk`)

- **Method:** `POST`
- **Path:** `/api/v1/shift-assignments/bulk`
- **Role:** `OWNER`, `ADMIN`
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "shift_id": "33333333-4444-4555-8666-777777777777",
    "start_date": "2026-11-21",
    "end_date": "2026-11-25",
    "employee_ids": [
      "e4b5f8c2-3e44-4f81-a589-918237461234",
      "f5a6b7c8-9012-4345-8678-9abcdef01234"
    ]
  }
  ```
- **Contoh Response (201):**
  ```json
  {
    "success": true,
    "status": 201,
    "data": {
      "count": 10,
      "totalDays": 5,
      "totalEmployees": 2
    }
  }
  ```

---

### 6.3. List Shift Assignments (`GET /api/v1/shift-assignments`)

- **Method:** `GET`
- **Path:** `/api/v1/shift-assignments`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE` (Karyawan hanya dapat melihat jadwal miliknya)
- **Query Parameters:**
  - `employee_id` (opsional untuk Admin)
  - `shift_id` (opsional)
  - `start_date` (opsional, `YYYY-MM-DD`)
  - `end_date` (opsional, `YYYY-MM-DD`)
  - `limit` (opsional, default 50)
  - `offset` (opsional, default 0)

---

## 7. Modul 5: Presensi & Absensi (`attendance`)

### 7.1. Check-In Masuk (`POST /api/v1/attendance/check-in`)

- **Method:** `POST`
- **Path:** `/api/v1/attendance/check-in`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE`
- **Aturan Keamanan Stempel Waktu (Zero-Trust) & Anti-Mock GPS:**
  - Parameter `check_in` atau `check_out` **dilarang dikirimkan** oleh client (stempel waktu UTC ditentukan murni oleh server).
  - Mendukung proteksi anti-spoofing dari Flutter (`safe_device`):
    - Jika client mengirim `"is_mock_location": true`, server otomatis menandai field `notes` dengan awalan `[MOCK_GPS_DETECTED]`.
    - Jika client mengirim `"reject_mock": true` bersamaan dengan `"is_mock_location": true`, request langsung ditolak dengan `400 VALIDATION_ERROR`.
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "lat": -6.2088,
    "lng": 106.8456,
    "is_mock_location": false, // Opsional, flag dari SafeDevice.isMockLocation di Flutter
    "reject_mock": false, // Opsional, true jika ingin ditolak langsung 400 Bad Request
    "notes": "Clocking in from mobile app (WFO)"
  }
  ```
  _(Catatan: Untuk role `OWNER`/`ADMIN`, properti `employee_id` dapat disertakan jika ingin melakukan check-in atas nama karyawan)._
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/attendance/check-in" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_EMPLOYEE_TOKEN",
      "lat": -6.2088,
      "lng": 106.8456,
      "notes": "Clocking in from office"
    }'
  ```
- **Contoh Response (201 Created):**
  ```json
  {
    "success": true,
    "status": 201,
    "data": {
      "id": "77777777-8888-4999-8000-111122223333",
      "employee_id": "e4b5f8c2-3e44-4f81-a589-918237461234",
      "work_date": "2026-11-20",
      "shift_id": "33333333-4444-4555-8666-777777777777",
      "check_in": "2026-11-20T08:04:12.345Z",
      "check_out": null,
      "check_in_lat": -6.2088,
      "check_in_lng": 106.8456,
      "check_out_lat": null,
      "check_out_lng": null,
      "status": "PRESENT",
      "notes": "Clocking in from office",
      "employee_name": "Budi Santoso",
      "employee_nik": "3201234567890001",
      "shift_name": "Shift Pagi (08:00 - 17:00)",
      "shift_start_time": "08:00",
      "shift_end_time": "17:00",
      "duration_minutes": null
    }
  }
  ```
- **Contoh Error Respons (409 Conflict):**
  ```json
  {
    "success": false,
    "status": 409,
    "error": {
      "code": "CONFLICT",
      "message": "Employee \"Budi Santoso\" already has an active check-in session from 2026-11-20 (2026-11-20T08:04:12.345Z). Please check out first before checking in again."
    }
  }
  ```

---

### 7.2. Check-Out Pulang (`POST /api/v1/attendance/check-out`)

- **Method:** `POST`
- **Path:** `/api/v1/attendance/check-out`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE`
- **Aturan Bisnis:** Menemukan sesi aktif karyawan yang masih terbuka (`check_in !== null && check_out === null`), mengisi `check_out` dengan stempel waktu server, dan menghitung `duration_minutes`.
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "lat": -6.2088,
    "lng": 106.8456,
    "notes": "Clocking out (selesai tugas harian)"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/attendance/check-out" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_EMPLOYEE_TOKEN",
      "lat": -6.2088,
      "lng": 106.8456,
      "notes": "Clocking out"
    }'
  ```
- **Contoh Response (200 OK):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "77777777-8888-4999-8000-111122223333",
      "employee_id": "e4b5f8c2-3e44-4f81-a589-918237461234",
      "work_date": "2026-11-20",
      "shift_id": "33333333-4444-4555-8666-777777777777",
      "check_in": "2026-11-20T08:04:12.345Z",
      "check_out": "2026-11-20T17:08:45.678Z",
      "check_in_lat": -6.2088,
      "check_in_lng": 106.8456,
      "check_out_lat": -6.2088,
      "check_out_lng": 106.8456,
      "status": "PRESENT",
      "notes": "Clocking in from office | Check-out: Clocking out",
      "employee_name": "Budi Santoso",
      "employee_nik": "3201234567890001",
      "shift_name": "Shift Pagi (08:00 - 17:00)",
      "shift_start_time": "08:00",
      "shift_end_time": "17:00",
      "duration_minutes": 545
    }
  }
  ```
- **Contoh Error Respons (404 Not Found):**
  ```json
  {
    "success": false,
    "status": 404,
    "error": {
      "code": "NOT_FOUND",
      "message": "No active check-in session found for employee \"Budi Santoso\". You must check in before checking out."
    }
  }
  ```

---

### 7.3. Manual Attendance Creation (`POST /api/v1/attendance`)

- **Method:** `POST`
- **Path:** `/api/v1/attendance`
- **Role:** `OWNER`, `ADMIN` (Pencatatan presensi manual oleh admin, misalnya pencatatan karyawan mangkir/alpa atau koreksi kehadiran)
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "employee_id": "e4b5f8c2-3e44-4f81-a589-918237461234",
    "work_date": "2026-11-19",
    "shift_id": "33333333-4444-4555-8666-777777777777",
    "status": "ABSENT",
    "notes": "Mangkir tanpa kabar"
  }
  ```
- **Contoh Response (201 Created):**
  ```json
  {
    "success": true,
    "status": 201,
    "data": {
      "id": "88888888-9999-4000-8111-222233334444",
      "employee_id": "e4b5f8c2-3e44-4f81-a589-918237461234",
      "work_date": "2026-11-19",
      "shift_id": "33333333-4444-4555-8666-777777777777",
      "check_in": null,
      "check_out": null,
      "status": "ABSENT",
      "notes": "Mangkir tanpa kabar",
      "employee_name": "Budi Santoso",
      "duration_minutes": null
    }
  }
  ```

---

### 7.4. List Attendance Records (`GET /api/v1/attendance`)

- **Method:** `GET`
- **Path:** `/api/v1/attendance`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE` (Karyawan dibatasi pada datanya sendiri)
- **Query Parameters:**
  - `employee_id` (opsional, khusus Admin)
  - `shift_id` (opsional)
  - `status` (opsional: `PRESENT`, `LATE`, `ABSENT`)
  - `start_date` (opsional, `YYYY-MM-DD`)
  - `end_date` (opsional, `YYYY-MM-DD`)
  - `limit` (opsional, default 50, maks 100)
  - `offset` (opsional, default 0)
- **Contoh curl:**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/attendance&auth_token=YOUR_TOKEN&start_date=2026-11-01&end_date=2026-11-30&status=LATE"
  ```

---

### 7.5. Get Attendance Detail (`GET /api/v1/attendance/:id`)

- **Method:** `GET`
- **Path:** `/api/v1/attendance/:id`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE` (Karyawan dibatasi pada datanya sendiri)
- **Contoh curl:**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/attendance/77777777-8888-4999-8000-111122223333&auth_token=YOUR_TOKEN"
  ```

---

### 7.6. Adjust Attendance Record (`PUT /api/v1/attendance/:id`)

- **Method:** `POST` (dengan `_method: "PUT"`)
- **Path:** `/api/v1/attendance/:id`
- **Role:** `OWNER`, `ADMIN` (Koreksi jam atau status oleh admin)
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "_method": "PUT",
    "status": "PRESENT",
    "notes": "Dispensasi keterlambatan karena banjir (disetujui manajemen)"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/attendance/77777777-8888-4999-8000-111122223333" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN",
      "_method": "PUT",
      "status": "PRESENT",
      "notes": "Dispensasi keterlambatan karena banjir"
    }'
  ```

---

## 8. Modul 6: Pengajuan Cuti, Sakit, & Izin (`leave_requests`)

Tabel `leave_requests` mengelola alur pengajuan permohonan cuti tahunan, sakit, dan izin karyawan dengan state machine yang ketat, pencegahan irisan tanggal permohonan (_Date Overlap Guard_), serta pembatasan mandiri (_Self-Boundary RBAC_).

### 8.1. Create Leave Request (`POST /api/v1/leave-requests`)

- **Method:** `POST`
- **Path:** `/api/v1/leave-requests`
- **Role:** `EMPLOYEE` (untuk dirinya sendiri), `OWNER`, `ADMIN` (dapat mengajukan atas nama karyawan manapun)
- **Zero-Trust Security:**
  - Client dilarang mengirimkan `status`, `approved_by`, atau `approved_at`. Nilai awal selalu diinisialisasi otomatis oleh server sebagai `status = 'PENDING'`, `approved_by = null`, dan `approved_at = null`.
  - Jika pemanggil ber-role `EMPLOYEE`, maka `employee_id` otomatis dikunci ke `req.user.employee_id` yang terikat pada token JWT.
- **Date Overlap Guard:**
  - Menolak pengajuan jika karyawan telah memiliki permohonan aktif (`PENDING` atau `APPROVED`) yang rentang tanggalnya beririsan (`start_date <= existing.end_date && end_date >= existing.start_date`) dengan kode error `409 Conflict`. Permohonan yang berstatus `REJECTED` atau `CANCELLED` diizinkan untuk tumpang-tindih (karyawan boleh mengajukan kembali permohonan baru pada rentang tanggal yang sebelumnya ditolak/dibatalkan).
- **Dukungan Idempotensi:** Mendukung `idempotency_key` pada payload JSON.
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "idempotency_key": "lr-create-001",
    "employee_id": "11111111-2222-4333-8444-555555555555",
    "request_type": "ANNUAL_LEAVE",
    "start_date": "2026-12-01",
    "end_date": "2026-12-03",
    "reason": "Acara pernikahan keluarga di luar kota",
    "attachment_url": "https://drive.google.com/file/d/sample/view"
  }
  ```
- **Contoh Response Berhasil (`201 Created`):**
  ```json
  {
    "success": true,
    "status": 201,
    "data": {
      "id": "aaaa1111-bb22-4c33-8d44-eeee55556666",
      "employee_id": "11111111-2222-4333-8444-555555555555",
      "request_type": "ANNUAL_LEAVE",
      "start_date": "2026-12-01",
      "end_date": "2026-12-03",
      "reason": "Acara pernikahan keluarga di luar kota",
      "attachment_url": "https://drive.google.com/file/d/sample/view",
      "status": "PENDING",
      "approved_by": null,
      "approved_at": null,
      "created_at": "2026-11-20T12:00:00.000Z",
      "updated_at": "2026-11-20T12:00:00.000Z",
      "requested_days": 3
    },
    "message": "Leave request submitted successfully"
  }
  ```
- **Contoh Response Error Overlap (`409 Conflict`):**
  ```json
  {
    "success": false,
    "status": 409,
    "error": {
      "code": "DATE_OVERLAP_CONFLICT",
      "message": "Employee already has an active leave request (PENDING or APPROVED) overlapping with dates 2026-12-01 to 2026-12-03."
    }
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/leave-requests" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_TOKEN",
      "idempotency_key": "lr-create-001",
      "request_type": "ANNUAL_LEAVE",
      "start_date": "2026-12-01",
      "end_date": "2026-12-03",
      "reason": "Acara pernikahan keluarga"
    }'
  ```

---

### 8.2. List Leave Requests (`GET /api/v1/leave-requests`)

- **Method:** `GET`
- **Path:** `/api/v1/leave-requests`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE` (Role `EMPLOYEE` otomatis dibatasi hanya dapat melihat permohonan miliknya sendiri berdasarkan `req.user.employee_id`)
- **Query Parameters:**
  - `status` (opsional): Filter status (`PENDING`, `APPROVED`, `REJECTED`, `CANCELLED`)
  - `request_type` (opsional): Filter tipe (`ANNUAL_LEAVE`, `SICK`, `PERMISSION`)
  - `employee_id` (opsional): Filter per karyawan (diabaikan jika role EMPLOYEE)
  - `start_date` (opsional): Filter tanggal awal `YYYY-MM-DD`
  - `end_date` (opsional): Filter tanggal akhir `YYYY-MM-DD`
  - `limit` (opsional): Batas baris (default: 50)
  - `offset` (opsional): Offset data (default: 0)
- **Contoh curl:**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/leave-requests&status=PENDING&auth_token=YOUR_TOKEN"
  ```

---

### 8.3. Get Leave Request Detail (`GET /api/v1/leave-requests/:id`)

- **Method:** `GET`
- **Path:** `/api/v1/leave-requests/:id`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE` (Role `EMPLOYEE` ditolak `403 Forbidden` jika mencoba melihat permohonan karyawan lain)
- **Contoh curl:**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/leave-requests/aaaa1111-bb22-4c33-8d44-eeee55556666&auth_token=YOUR_TOKEN"
  ```

---

### 8.4. Approve Leave Request (`POST /api/v1/leave-requests/:id/approve`)

- **Method:** `POST`
- **Path:** `/api/v1/leave-requests/:id/approve`
- **Role:** `OWNER`, `ADMIN`
- **Aturan Transisi State:**
  - Hanya dapat menyetujui request dengan status `PENDING`.
  - Jika request berstatus `APPROVED`, `REJECTED`, atau `CANCELLED`, server merespons dengan `409 Conflict`.
  - Menetapkan `status = 'APPROVED'`, `approved_by = req.user.id`, dan `approved_at = nowIso()`.
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/leave-requests/aaaa1111-bb22-4c33-8d44-eeee55556666/approve" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN"
    }'
  ```

---

### 8.5. Reject Leave Request (`POST /api/v1/leave-requests/:id/reject`)

- **Method:** `POST`
- **Path:** `/api/v1/leave-requests/:id/reject`
- **Role:** `OWNER`, `ADMIN`
- **Aturan Transisi State:**
  - Hanya dapat menolak request dengan status `PENDING`.
  - Jika request tidak berstatus `PENDING`, server merespons dengan `409 Conflict`.
  - Menetapkan `status = 'REJECTED'`, `approved_by = req.user.id`, dan `approved_at = nowIso()`.
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/leave-requests/aaaa1111-bb22-4c33-8d44-eeee55556666/reject" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN"
    }'
  ```

---

### 8.6. Cancel Leave Request (`POST /api/v1/leave-requests/:id/cancel`)

- **Method:** `POST`
- **Path:** `/api/v1/leave-requests/:id/cancel`
- **Role:** `EMPLOYEE` (pemilik permohonan jika status `PENDING`), `OWNER`, `ADMIN` (dapat membatalkan status `PENDING` atau `APPROVED`)
- **Aturan Transisi State & Otorisasi:**
  - Jika status saat ini `PENDING`:
    - Pemilik permohonan (`EMPLOYEE`), `ADMIN`, atau `OWNER` dapat membatalkan.
  - Jika status saat ini `APPROVED`:
    - **Hanya `OWNER` dan `ADMIN`** yang diizinkan membatalkan. Karyawan (`EMPLOYEE`) yang mencoba membatalkan request `APPROVED` akan ditolak dengan `403 Forbidden`.
    - Jika `request_type === 'ANNUAL_LEAVE'`, response menyertakan `requires_balance_reversal: true` sebagai sinyal pengembalian saldo kuota cuti.
  - Jika status saat ini sudah `REJECTED` atau `CANCELLED`:
    - Ditolak dengan `409 Conflict`.
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>"
  }
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "aaaa1111-bb22-4c33-8d44-eeee55556666",
      "status": "CANCELLED",
      "requires_balance_reversal": true,
      "updated_at": "2026-11-20T12:15:00.000Z"
    },
    "message": "Leave request cancelled successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/leave-requests/aaaa1111-bb22-4c33-8d44-eeee55556666/cancel" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_TOKEN"
    }'
  ```

---

## 9. Modul 7: Saldo & Kuota Cuti Karyawan (`leave_balances`)

Tabel `leave_balances` mengelola kuota cuti tahunan (_annual leave balance_) per karyawan per tahun kalender dengan invarian saldo matematika `remaining_days = total_days - used_days`, dukungan alokasi massal (_bulk allocate_) atomik, dan integrasi pemotongan/pengembalian otomatis saat pengajuan cuti tahunan disetujui atau dibatalkan.

### 9.1. Create Single Leave Balance (`POST /api/v1/leave-balances`)

- **Method:** `POST`
- **Path:** `/api/v1/leave-balances`
- **Role:** `OWNER`, `ADMIN`
- **Aturan Bisnis:**
  - Hanya dapat dialokasikan ke karyawan berstatus aktif (`deleted_at === null` dan `employment_status === 'ACTIVE'`).
  - Kombinasi `employee_id + leave_type + year` wajib unik. Duplikasi pada tahun yang sama ditolak `409 Conflict`.
  - Invarian saldo: `remaining_days` dihitung otomatis oleh server (`total_days - used_days`). Jika `total_days < used_days`, permintaan ditolak `400 ValidationError`.
- **Dukungan Idempotensi:** Mendukung `idempotency_key` pada payload JSON.
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "idempotency_key": "balance-single-2026-001",
    "employee_id": "11111111-2222-4333-8444-555555555555",
    "year": 2026,
    "total_days": 12,
    "leave_type": "ANNUAL_LEAVE"
  }
  ```
- **Contoh Response Berhasil (`201 Created`):**
  ```json
  {
    "success": true,
    "status": 201,
    "data": {
      "id": "bbbb2222-cc33-4d44-8e55-ffff66667777",
      "employee_id": "11111111-2222-4333-8444-555555555555",
      "leave_type": "ANNUAL_LEAVE",
      "year": 2026,
      "total_days": 12,
      "used_days": 0,
      "remaining_days": 12,
      "employee_name": "Rudi Hartono",
      "employee_nik": "3201010101010001",
      "created_at": "2026-11-20T12:00:00.000Z",
      "updated_at": "2026-11-20T12:00:00.000Z"
    },
    "message": "Leave balance allocated successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/leave-balances" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN",
      "employee_id": "11111111-2222-4333-8444-555555555555",
      "year": 2026,
      "total_days": 12
    }'
  ```

---

### 9.2. Bulk Allocate Annual Leave (`POST /api/v1/leave-balances/bulk-allocate`)

- **Method:** `POST`
- **Path:** `/api/v1/leave-balances/bulk-allocate`
- **Role:** `OWNER`, `ADMIN`
- **Aturan Bisnis:**
  - Mengalokasikan kuota cuti tahunan kepada banyak karyawan sekaligus dalam **satu kali Batch Write**.
  - Jika `employee_ids` dikosongkan/omitted, server otomatis menargetkan seluruh karyawan aktif yang belum memiliki saldo `ANNUAL_LEAVE` pada `year` tersebut (karyawan yang sudah punya saldo otomatis dilewati / _skipped_ tanpa memicu error).
- **Dukungan Idempotensi:** Mendukung `idempotency_key` pada payload JSON.
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "idempotency_key": "bulk-alloc-2026-all",
    "year": 2026,
    "total_days": 12
  }
  ```
- **Contoh Response Berhasil (`201 Created`):**
  ```json
  {
    "success": true,
    "status": 201,
    "data": {
      "count": 25,
      "year": 2026,
      "total_days": 12,
      "skipped_count": 3,
      "allocated": [ ... ]
    },
    "message": "Successfully allocated annual leave to 25 employees (3 skipped)"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/leave-balances/bulk-allocate" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN",
      "year": 2026,
      "total_days": 12
    }'
  ```

---

### 9.3. List Leave Balances (`GET /api/v1/leave-balances`)

- **Method:** `GET`
- **Path:** `/api/v1/leave-balances`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE` (Role `EMPLOYEE` otomatis dibatasi hanya dapat melihat saldo kuota miliknya sendiri)
- **Query Parameters:**
  - `year` (opsional): Filter tahun kalender, misal `2026`
  - `employee_id` (opsional): Filter ID karyawan (diabaikan jika role EMPLOYEE)
  - `leave_type` (opsional): Filter tipe cuti (default `ANNUAL_LEAVE`)
  - `limit` (opsional): Batas baris data (default: 50)
  - `offset` (opsional): Offset data (default: 0)
- **Contoh curl:**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/leave-balances&year=2026&auth_token=YOUR_TOKEN"
  ```

---

### 9.4. Get Leave Balance Detail (`GET /api/v1/leave-balances/:id`)

- **Method:** `GET`
- **Path:** `/api/v1/leave-balances/:id`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE` (Role `EMPLOYEE` ditolak `403 Forbidden` jika mencoba mengakses saldo karyawan lain)
- **Contoh curl:**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/leave-balances/bbbb2222-cc33-4d44-8e55-ffff66667777&auth_token=YOUR_TOKEN"
  ```

---

### 9.5. Adjust Leave Balance Quota (`PUT /api/v1/leave-balances/:id`)

- **Method:** `POST` (dengan tunneling `_method: "PUT"`)
- **Path:** `/api/v1/leave-balances/:id`
- **Role:** `OWNER`, `ADMIN`
- **Aturan Invarian:**
  - Hanya dapat memperbarui kuota `total_days`.
  - Jika `total_days < used_days`, permintaan ditolak `400 ValidationError` (`total_days cannot be less than used_days`).
  - Nilai `remaining_days` selalu dihitung ulang otomatis sebagai `total_days - used_days`.
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "_method": "PUT",
    "total_days": 15
  }
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "bbbb2222-cc33-4d44-8e55-ffff66667777",
      "employee_id": "11111111-2222-4333-8444-555555555555",
      "leave_type": "ANNUAL_LEAVE",
      "year": 2026,
      "total_days": 15,
      "used_days": 3,
      "remaining_days": 12,
      "employee_name": "Rudi Hartono",
      "employee_nik": "3201010101010001",
      "updated_at": "2026-11-20T12:30:00.000Z"
    },
    "message": "Leave balance quota updated successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/leave-balances/bbbb2222-cc33-4d44-8e55-ffff66667777" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN",
      "_method": "PUT",
      "total_days": 15
    }'
  ```

---

## 10. Modul 8: Leave Transactions (Buku Besar Mutasi Cuti)

Tabel `leave_transactions` merupakan **buku besar append-only (immutable ledger)** yang mencatat setiap peristiwa mutasi saldo cuti (`ALLOCATION`, `USAGE`, `ADJUSTMENT`, `REVERSAL`).
Tabel ini memiliki **tepat 10 kolom** dan **tidak memiliki kolom `updated_at` maupun `deleted_at`**.
Sistem **tidak menyediakan endpoint `PUT` atau `DELETE`** untuk transaksi demi menjamin integritas audit forensik.

### Karakteristik Buku Besar:

1. **Konvensi Nilai Bertanda (`days`):**
   - `ALLOCATION`: Nilai positif `+total_days` (penambahan kuota). `leave_request_id`: `null`.
   - `USAGE`: Nilai negatif `-requested_days` (pemotongan cuti disetujui). `leave_request_id`: ID pengajuan cuti.
   - `REVERSAL`: Nilai positif `+requested_days` (pengembalian cuti yang dibatalkan). `leave_request_id`: ID pengajuan cuti.
   - `ADJUSTMENT`: Nilai bertanda non-nol (+ atau -) untuk penyesuaian kuota. `leave_request_id`: `null`.
2. **Invarian Rekonsiliasi Matematis:**
   $$\sum \text{days} = \text{remaining\_days}$$
   Total akumulasi seluruh nilai `days` untuk suatu `leave_balance_id` selalu sama persis dengan `remaining_days` pada tabel `leave_balances`.

---

### 10.1. List Leave Transactions (`GET /api/v1/leave-transactions`)

- **Method:** `GET`
- **Path:** `/api/v1/leave-transactions`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE`
- **Isolasi Self-Boundary:** Karyawan (`EMPLOYEE`) hanya dapat melihat transaksi miliknya sendiri. Jika menyertakan parameter `employee_id` milik orang lain, sistem menolak dengan `403 Forbidden`.
- **Query Parameters:**
  - `employee_id` (opsional, UUID): Filter ID karyawan (khusus Admin/Owner)
  - `leave_balance_id` (opsional, UUID): Filter ID saldo cuti tertentu
  - `leave_request_id` (opsional, UUID): Filter ID pengajuan cuti terkait
  - `transaction_type` (opsional, ENUM): `ALLOCATION`, `USAGE`, `ADJUSTMENT`, `REVERSAL`
  - `start_date` (opsional, DATE: `YYYY-MM-DD`): Filter tanggal awal transaksi
  - `end_date` (opsional, DATE: `YYYY-MM-DD`): Filter tanggal akhir transaksi
  - `limit` (opsional, INTEGER): Jumlah baris (default: 50, maks: 200)
  - `offset` (opsional, INTEGER): Posisi awal data (default: 0)
- **Contoh Request (curl):**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/leave-transactions&transaction_type=USAGE&auth_token=YOUR_TOKEN"
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": [
      {
        "id": "77777777-8888-4999-8000-111122223333",
        "employee_id": "11111111-2222-4333-8444-555555555555",
        "leave_balance_id": "bbbb2222-cc33-4d44-8e55-ffff66667777",
        "leave_request_id": "aaaa1111-bb22-4c33-8d44-eeee55556666",
        "transaction_type": "USAGE",
        "days": -3,
        "transaction_date": "2026-11-20",
        "notes": "Leave request approved (ID: aaaa1111-bb22-4c33-8d44-eeee55556666)",
        "created_by": "00000000-0000-4000-8000-000000000001",
        "created_at": "2026-11-20T10:15:30.000Z",
        "employee_name": "Rudi Hartono",
        "employee_nik": "3201010101010001",
        "creator_email": "admin@company.com"
      }
    ],
    "meta": {
      "total": 1,
      "limit": 50,
      "offset": 0,
      "page": 1
    }
  }
  ```

---

### 10.2. Get Leave Transaction Detail (`GET /api/v1/leave-transactions/:id`)

- **Method:** `GET`
- **Path:** `/api/v1/leave-transactions/:id`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE` (Role `EMPLOYEE` ditolak `403 Forbidden` jika mencoba mengakses transaksi karyawan lain)
- **Contoh Request (curl):**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/leave-transactions/77777777-8888-4999-8000-111122223333&auth_token=YOUR_TOKEN"
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "77777777-8888-4999-8000-111122223333",
      "employee_id": "11111111-2222-4333-8444-555555555555",
      "leave_balance_id": "bbbb2222-cc33-4d44-8e55-ffff66667777",
      "leave_request_id": "aaaa1111-bb22-4c33-8d44-eeee55556666",
      "transaction_type": "USAGE",
      "days": -3,
      "transaction_date": "2026-11-20",
      "notes": "Leave request approved (ID: aaaa1111-bb22-4c33-8d44-eeee55556666)",
      "created_by": "00000000-0000-4000-8000-000000000001",
      "created_at": "2026-11-20T10:15:30.000Z",
      "employee_name": "Rudi Hartono",
      "employee_nik": "3201010101010001",
      "creator_email": "admin@company.com"
    }
  }
  ```

---

### 10.3. Manual / Controlled Balance Adjustment (`POST /api/v1/leave-transactions/adjust`)

- **Method:** `POST`
- **Path:** `/api/v1/leave-transactions/adjust`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak `403 Forbidden`)
- **Tujuan:** Melakukan penyesuaian kuota/saldo cuti secara terkontrol disertai justifikasi audit wajib (`notes`). Secara atomik memperbarui `total_days` dan `remaining_days` pada tabel `leave_balances`, serta menambahkan 1 baris catatan `ADJUSTMENT` pada buku besar `leave_transactions`.
- **Aturan Validasi & Invarian:**
  - `leave_balance_id` (wajib, UUID): ID record saldo cuti yang valid.
  - `days` (wajib, angka bertanda non-nol): Positif `+` untuk menambah kuota, negatif `-` untuk memotong kuota.
  - `notes` (wajib, teks min 3 karakter): Alasan/justifikasi penyesuaian untuk audit forensik.
  - Penolakan jika penyesuaian menyebabkan `remaining_days < 0` (`ValidationError`).
  - Penolakan jika penyesuaian menyebabkan `total_days < used_days` (`ValidationError`).
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_ADMIN_TOKEN",
    "leave_balance_id": "bbbb2222-cc33-4d44-8e55-ffff66667777",
    "days": 2.5,
    "notes": "Kompensasi lembur proyek migrasi database Q4"
  }
  ```
- **Contoh Response Berhasil (`201 Created`):**
  ```json
  {
    "success": true,
    "status": 201,
    "data": {
      "transaction": {
        "id": "88888888-9999-4000-8111-222233334444",
        "employee_id": "11111111-2222-4333-8444-555555555555",
        "leave_balance_id": "bbbb2222-cc33-4d44-8e55-ffff66667777",
        "leave_request_id": null,
        "transaction_type": "ADJUSTMENT",
        "days": 2.5,
        "transaction_date": "2026-11-20",
        "notes": "Kompensasi lembur proyek migrasi database Q4",
        "created_by": "00000000-0000-4000-8000-000000000001",
        "created_at": "2026-11-20T11:00:00.000Z",
        "employee_name": "Rudi Hartono",
        "employee_nik": "3201010101010001",
        "creator_email": "admin@company.com"
      },
      "balance": {
        "id": "bbbb2222-cc33-4d44-8e55-ffff66667777",
        "employee_id": "11111111-2222-4333-8444-555555555555",
        "leave_type": "ANNUAL_LEAVE",
        "year": 2026,
        "total_days": 14.5,
        "used_days": 3,
        "remaining_days": 11.5,
        "employee_name": "Rudi Hartono",
        "employee_nik": "3201010101010001",
        "updated_at": "2026-11-20T11:00:00.000Z"
      }
    },
    "message": "Leave balance adjusted and transaction recorded successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/leave-transactions/adjust" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN",
      "leave_balance_id": "bbbb2222-cc33-4d44-8e55-ffff66667777",
      "days": 2.5,
      "notes": "Kompensasi lembur proyek migrasi database Q4"
    }'
  ```

---

## 11. Modul 9: Pengajuan Lembur (`overtime_requests`)

Tabel `overtime_requests` mengelola alur pengajuan lembur karyawan dengan penegakan validasi _Zero-Trust_, kontrol durasi murni di backend, kalkulasi estimasi upah lembur regulasi ketenagakerjaan Indonesia (Kepmenakertrans No. 102/2004 & PP No. 35/2021), pencegahan irisan waktu (_Time Overlap Guard_), serta pembatasan mandiri (_Self-Boundary RBAC_).

### 11.1. Create Overtime Request (`POST /api/v1/overtime-requests`)

- **Method:** `POST`
- **Path:** `/api/v1/overtime-requests`
- **Role:** `EMPLOYEE` (untuk dirinya sendiri), `OWNER`, `ADMIN` (dapat mengajukan atas nama karyawan aktif manapun)
- **Zero-Trust Security:**
  - Client dilarang mengirimkan `duration_minutes`, `status`, `approved_by`, atau `approved_at`. Jika dikirim, request ditolak dengan `400 Bad Request`.
  - Jika pemanggil ber-role `EMPLOYEE`, maka `employee_id` otomatis dikunci ke `req.user.employee_id` yang terikat pada token JWT.
- **Kalkulasi Durasi & Rentang:**
  - `duration_minutes` dihitung otomatis dari selisih `end_time - start_time`.
  - Waktu mulai dan selesai wajib format ISO 8601 UTC penuh.
  - Durasi minimal: 15 menit, durasi maksimal: 720 menit (12 jam).
- **Time Overlap Guard:**
  - Menolak pengajuan jika karyawan memiliki lembur aktif (`PENDING` atau `APPROVED`) yang rentang waktunya beririsan ($[start, end)$). Lembur dengan status `REJECTED` atau `CANCELLED` diabaikan sehingga slot waktu dapat diajukan kembali.
- **Dukungan Idempotensi:** Mendukung `idempotency_key` pada payload JSON.
- **Request Payload:**
  ```json
  {
    "auth_token": "<JWT_TOKEN>",
    "idempotency_key": "ot-create-001",
    "employee_id": "11111111-2222-4333-8444-555555555555",
    "overtime_date": "2026-11-20",
    "start_time": "2026-11-20T10:00:00.000Z",
    "end_time": "2026-11-20T13:00:00.000Z",
    "reason": "Deploy rilis backend HRIS v1.0 ke production"
  }
  ```
- **Contoh Response Berhasil (`201 Created`):**
  ```json
  {
    "success": true,
    "status": 201,
    "data": {
      "id": "22222222-3333-4444-8555-666666666666",
      "employee_id": "11111111-2222-4333-8444-555555555555",
      "overtime_date": "2026-11-20",
      "start_time": "2026-11-20T10:00:00.000Z",
      "end_time": "2026-11-20T13:00:00.000Z",
      "duration_minutes": 180,
      "duration_hours": 3,
      "reason": "Deploy rilis backend HRIS v1.0 ke production",
      "status": "PENDING",
      "approved_by": null,
      "approved_at": null,
      "created_at": "2026-11-20T10:05:00.000Z",
      "updated_at": "2026-11-20T10:05:00.000Z",
      "employee_name": "Rudi Hartono",
      "employee_nik": "3201010101010001",
      "estimated_overtime_pay": 173410.4
    },
    "message": "Overtime request created successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/overtime-requests" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_TOKEN",
      "employee_id": "11111111-2222-4333-8444-555555555555",
      "overtime_date": "2026-11-20",
      "start_time": "2026-11-20T10:00:00.000Z",
      "end_time": "2026-11-20T13:00:00.000Z",
      "reason": "Deploy rilis backend HRIS v1.0 ke production"
    }'
  ```

---

### 11.2. List Overtime Requests (`GET /api/v1/overtime-requests`)

- **Method:** `GET`
- **Path:** `/api/v1/overtime-requests`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE` (Role `EMPLOYEE` otomatis dibatasi hanya melihat permohonan lemburnya sendiri)
- **Query Parameters:**
  - `employee_id` (opsional, UUID karyawan, hanya efektif untuk ADMIN/OWNER)
  - `status` (opsional: `PENDING`, `APPROVED`, `REJECTED`, `CANCELLED`)
  - `start_date` (opsional, filter tanggal awal `YYYY-MM-DD` terhadap `overtime_date`)
  - `end_date` (opsional, filter tanggal akhir `YYYY-MM-DD` terhadap `overtime_date`)
  - `limit` (opsional, default 50, maks 100)
  - `offset` (opsional, default 0)
- **Contoh Request (curl):**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/overtime-requests&auth_token=YOUR_TOKEN&status=PENDING"
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": [
      {
        "id": "22222222-3333-4444-8555-666666666666",
        "employee_id": "11111111-2222-4333-8444-555555555555",
        "overtime_date": "2026-11-20",
        "start_time": "2026-11-20T10:00:00.000Z",
        "end_time": "2026-11-20T13:00:00.000Z",
        "duration_minutes": 180,
        "duration_hours": 3,
        "reason": "Deploy rilis backend HRIS v1.0 ke production",
        "status": "PENDING",
        "approved_by": null,
        "approved_at": null,
        "created_at": "2026-11-20T10:05:00.000Z",
        "updated_at": "2026-11-20T10:05:00.000Z",
        "employee_name": "Rudi Hartono",
        "employee_nik": "3201010101010001",
        "approver_email": null,
        "estimated_overtime_pay": 173410.4
      }
    ],
    "meta": {
      "total": 1,
      "limit": 50,
      "offset": 0,
      "page": 1
    }
  }
  ```

---

### 11.3. Get Overtime Request Detail (`GET /api/v1/overtime-requests/:id`)

- **Method:** `GET`
- **Path:** `/api/v1/overtime-requests/:id`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE` (Role `EMPLOYEE` dibatasi pada datanya sendiri, ditolak `403 Forbidden` jika mengakses milik karyawan lain)
- **Contoh Request (curl):**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/overtime-requests/22222222-3333-4444-8555-666666666666&auth_token=YOUR_TOKEN"
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "22222222-3333-4444-8555-666666666666",
      "employee_id": "11111111-2222-4333-8444-555555555555",
      "overtime_date": "2026-11-20",
      "start_time": "2026-11-20T10:00:00.000Z",
      "end_time": "2026-11-20T13:00:00.000Z",
      "duration_minutes": 180,
      "duration_hours": 3,
      "reason": "Deploy rilis backend HRIS v1.0 ke production",
      "status": "APPROVED",
      "approved_by": "00000000-0000-4000-8000-000000000001",
      "approved_at": "2026-11-20T10:30:00.000Z",
      "created_at": "2026-11-20T10:05:00.000Z",
      "updated_at": "2026-11-20T10:30:00.000Z",
      "employee_name": "Rudi Hartono",
      "employee_nik": "3201010101010001",
      "approver_email": "admin@company.com",
      "estimated_overtime_pay": 173410.4
    }
  }
  ```

---

### 11.4. Approve Overtime Request (`POST /api/v1/overtime-requests/:id/approve`)

- **Method:** `POST`
- **Path:** `/api/v1/overtime-requests/:id/approve`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak `403 Forbidden`)
- **Aturan State Machine:**
  - Hanya dapat menyetujui permohonan berstatus `PENDING`.
  - Mengubah status menjadi `APPROVED`, mencatat `approved_by = req.user.id` dan `approved_at = nowIso()`.
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_ADMIN_TOKEN"
  }
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "22222222-3333-4444-8555-666666666666",
      "status": "APPROVED",
      "approved_by": "00000000-0000-4000-8000-000000000001",
      "approved_at": "2026-11-20T10:30:00.000Z"
    },
    "message": "Overtime request approved successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/overtime-requests/22222222-3333-4444-8555-666666666666/approve" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{ "auth_token": "YOUR_ADMIN_TOKEN" }'
  ```

---

### 11.5. Reject Overtime Request (`POST /api/v1/overtime-requests/:id/reject`)

- **Method:** `POST`
- **Path:** `/api/v1/overtime-requests/:id/reject`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak `403 Forbidden`)
- **Aturan State Machine:**
  - Hanya dapat menolak permohonan berstatus `PENDING`.
  - Mengubah status menjadi `REJECTED`, mencatat `approved_by` dan `approved_at`.
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_ADMIN_TOKEN",
    "reason": "Kebutuhan lembur belum mendapat justifikasi urgensi dari manajer"
  }
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "22222222-3333-4444-8555-666666666666",
      "status": "REJECTED",
      "approved_by": "00000000-0000-4000-8000-000000000001",
      "approved_at": "2026-11-20T10:30:00.000Z"
    },
    "message": "Overtime request rejected successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/overtime-requests/22222222-3333-4444-8555-666666666666/reject" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN",
      "reason": "Kebutuhan lembur belum mendapat justifikasi urgensi"
    }'
  ```

---

### 11.6. Cancel Overtime Request (`POST /api/v1/overtime-requests/:id/cancel`)

- **Method:** `POST`
- **Path:** `/api/v1/overtime-requests/:id/cancel`
- **Role:** `EMPLOYEE` (pemilik data), `OWNER`, `ADMIN`
- **Aturan Pembatalan Karyawan & Admin:**
  - Permohonan berstatus `PENDING` dapat dibatalkan oleh `EMPLOYEE` pemilik pengajuan, `ADMIN`, maupun `OWNER`.
  - Permohonan berstatus `APPROVED` **hanya** dapat dibatalkan oleh `ADMIN` atau `OWNER`. Jika `EMPLOYEE` mencoba membatalkan lembur yang telah disetujui, ditolak dengan `403 Forbidden`.
  - Permohonan yang sudah `REJECTED` atau `CANCELLED` tidak dapat dibatalkan kembali (`409 Conflict`).
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_TOKEN"
  }
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "22222222-3333-4444-8555-666666666666",
      "status": "CANCELLED"
    },
    "message": "Overtime request cancelled successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/overtime-requests/22222222-3333-4444-8555-666666666666/cancel" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{ "auth_token": "YOUR_TOKEN" }'
  ```

---

## 12. Modul 10: Periode Penggajian (`payroll_periods`)

Tabel `payroll_periods` mengelola siklus periode penggajian (payroll cycle) dengan penegakan validasi _Zero-Trust_, kontrol immutabilitas terkunci (_Immutability Lock_ setelah status `FINALIZED`/`PAID`), pencegahan tumpang tindih tanggal antar periode (_Period Overlap Guard_), serta pembatasan akses data (_RBAC Visibility_).

### 12.1. Create Payroll Period (`POST /api/v1/payroll-periods`)

- **Method:** `POST`
- **Path:** `/api/v1/payroll-periods`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak `403 Forbidden`)
- **Zero-Trust Security:**
  - Client dilarang mengirimkan `status`. Nilai awal selalu diinisialisasi server sebagai `'DRAFT'`. Upaya mengirim status ditolak `400 Bad Request`.
  - Field `period_name` wajib unik (case-insensitive) dan minimal 3 karakter.
  - Tanggal `end_date` wajib `>= start_date`.
  - Jika `payment_date` disertakan, wajib `>= start_date`.
- **Period Overlap Guard:**
  - Menolak pembuatan periode dengan `409 Conflict` jika rentang `[start_date, end_date]` beririsan dengan periode lain yang sudah terdaftar (`existing.start_date <= new.end_date && existing.end_date >= new.start_date`).
- **Dukungan Idempotensi:** Mendukung `idempotency_key` pada payload JSON.
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_ADMIN_TOKEN",
    "idempotency_key": "pay-period-2026-11",
    "period_name": "November 2026",
    "start_date": "2026-11-01",
    "end_date": "2026-11-30",
    "payment_date": "2026-11-30"
  }
  ```
- **Contoh Response Berhasil (`201 Created`):**
  ```json
  {
    "success": true,
    "status": 201,
    "data": {
      "id": "11111111-2222-4333-8444-555555555555",
      "period_name": "November 2026",
      "start_date": "2026-11-01",
      "end_date": "2026-11-30",
      "payment_date": "2026-11-30",
      "status": "DRAFT",
      "duration_days": 30,
      "is_locked": false,
      "created_at": "2026-11-20T10:00:00.000Z",
      "updated_at": "2026-11-20T10:00:00.000Z"
    },
    "message": "Payroll period created successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/payroll-periods" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN",
      "period_name": "November 2026",
      "start_date": "2026-11-01",
      "end_date": "2026-11-30",
      "payment_date": "2026-11-30"
    }'
  ```

---

### 12.2. List Payroll Periods (`GET /api/v1/payroll-periods`)

- **Method:** `GET`
- **Path:** `/api/v1/payroll-periods`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE`
- **RBAC Visibility Rules:**
  - `OWNER` & `ADMIN`: Melihat semua status periode (`DRAFT`, `FINALIZED`, `PAID`).
  - `EMPLOYEE`: Secara otomatis disaring hanya melihat periode dengan status `FINALIZED` atau `PAID` (periode `DRAFT` disembunyikan).
- **Query Parameters:**
  - `status` (opsional: `DRAFT`, `FINALIZED`, `PAID`)
  - `year` (opsional: filter 4 digit tahun kalender misal `2026`)
  - `limit` (opsional, default 50, maks 100)
  - `offset` (opsional, default 0)
- **Contoh Request (curl):**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/payroll-periods&auth_token=YOUR_TOKEN&year=2026"
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": [
      {
        "id": "11111111-2222-4333-8444-555555555555",
        "period_name": "November 2026",
        "start_date": "2026-11-01",
        "end_date": "2026-11-30",
        "payment_date": "2026-11-30",
        "status": "DRAFT",
        "duration_days": 30,
        "is_locked": false,
        "created_at": "2026-11-20T10:00:00.000Z",
        "updated_at": "2026-11-20T10:00:00.000Z"
      }
    ],
    "meta": {
      "total": 1,
      "limit": 50,
      "offset": 0,
      "page": 1
    }
  }
  ```

---

### 12.3. Get Payroll Period Detail (`GET /api/v1/payroll-periods/:id`)

- **Method:** `GET`
- **Path:** `/api/v1/payroll-periods/:id`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE`
- **RBAC Rule:** Role `EMPLOYEE` ditolak `403 Forbidden` jika periode masih berstatus `DRAFT`.
- **Contoh Request (curl):**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/payroll-periods/11111111-2222-4333-8444-555555555555&auth_token=YOUR_TOKEN"
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "11111111-2222-4333-8444-555555555555",
      "period_name": "November 2026",
      "start_date": "2026-11-01",
      "end_date": "2026-11-30",
      "payment_date": "2026-11-30",
      "status": "FINALIZED",
      "duration_days": 30,
      "is_locked": true,
      "created_at": "2026-11-20T10:00:00.000Z",
      "updated_at": "2026-11-20T11:00:00.000Z"
    }
  }
  ```

---

### 12.4. Update Payroll Period (`PUT /api/v1/payroll-periods/:id`)

- **Method:** `POST` (dengan `_method: "PUT"`)
- **Path:** `/api/v1/payroll-periods/:id`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak `403 Forbidden`)
- **Immutability Lock:** Hanya diizinkan pada status `DRAFT`. Jika periode telah `FINALIZED` atau `PAID`, sistem menolak pembaruan dengan `409 Conflict` (`PAYROLL_PERIOD_LOCKED`).
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_ADMIN_TOKEN",
    "_method": "PUT",
    "period_name": "November 2026 Revisi",
    "payment_date": "2026-11-29"
  }
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "11111111-2222-4333-8444-555555555555",
      "period_name": "November 2026 Revisi",
      "start_date": "2026-11-01",
      "end_date": "2026-11-30",
      "payment_date": "2026-11-29",
      "status": "DRAFT",
      "duration_days": 30,
      "is_locked": false,
      "created_at": "2026-11-20T10:00:00.000Z",
      "updated_at": "2026-11-20T10:15:00.000Z"
    },
    "message": "Payroll period updated successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/payroll-periods/11111111-2222-4333-8444-555555555555" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN",
      "_method": "PUT",
      "period_name": "November 2026 Revisi"
    }'
  ```

---

### 12.5. Delete Payroll Period (`DELETE /api/v1/payroll-periods/:id`)

- **Method:** `POST` (dengan `_method: "DELETE"`)
- **Path:** `/api/v1/payroll-periods/:id`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak `403 Forbidden`)
- **Immutability Lock:** Hanya diizinkan pada status `DRAFT`. Jika periode telah `FINALIZED` atau `PAID`, sistem menolak penghapusan dengan `409 Conflict` (`PAYROLL_PERIOD_LOCKED`). Menjalankan hard delete pada sheet database.
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_ADMIN_TOKEN",
    "_method": "DELETE"
  }
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "11111111-2222-4333-8444-555555555555",
      "deleted": true,
      "message": "Payroll period \"November 2026\" deleted successfully."
    },
    "message": "Payroll period deleted successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/payroll-periods/11111111-2222-4333-8444-555555555555" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN",
      "_method": "DELETE"
    }'
  ```

---

### 12.6. Finalize Payroll Period (`POST /api/v1/payroll-periods/:id/finalize`)

- **Method:** `POST`
- **Path:** `/api/v1/payroll-periods/:id/finalize`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak `403 Forbidden`)
- **Aturan State Machine:**
  - Hanya dapat dijalankan dari status `DRAFT`.
  - Mengubah status menjadi `FINALIZED` dan mengunci seluruh modifikasi tanggal/nama periode.
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_ADMIN_TOKEN"
  }
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "11111111-2222-4333-8444-555555555555",
      "period_name": "November 2026",
      "status": "FINALIZED",
      "is_locked": true,
      "updated_at": "2026-11-20T11:00:00.000Z"
    },
    "message": "Payroll period finalized successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/payroll-periods/11111111-2222-4333-8444-555555555555/finalize" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{ "auth_token": "YOUR_ADMIN_TOKEN" }'
  ```

---

### 12.7. Mark Payroll Period as Paid (`POST /api/v1/payroll-periods/:id/pay`)

- **Method:** `POST`
- **Path:** `/api/v1/payroll-periods/:id/pay`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak `403 Forbidden`)
- **Aturan State Machine:**
  - Hanya dapat dijalankan dari status `FINALIZED`.
  - Transisi langsung dari `DRAFT` ke `PAID` ditolak `409 Conflict`.
  - Mengubah status menjadi `PAID` dan menetapkan tanggal pembayaran `payment_date`.
  - Menerima opsi `payment_date` (default `todayIso()` jika tidak dikirim, wajib `>= start_date`).
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_ADMIN_TOKEN",
    "payment_date": "2026-11-30"
  }
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "11111111-2222-4333-8444-555555555555",
      "period_name": "November 2026",
      "status": "PAID",
      "payment_date": "2026-11-30",
      "is_locked": true,
      "updated_at": "2026-11-20T11:30:00.000Z"
    },
    "message": "Payroll period marked as paid successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/payroll-periods/11111111-2222-4333-8444-555555555555/pay" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN",
      "payment_date": "2026-11-30"
    }'
  ```

---

## 13. Modul 11: Slip Gaji Digital (`payslips`)

Modul `payslips` mengelola pembuatan, rekonsiliasi, pemutakhiran tunjangan/potongan, serta pembayaran slip gaji karyawan. Modul ini terintegrasi erat dengan data gaji pokok karyawan (`employees.base_salary`), kalkulasi lembur disetujui (`overtime_requests`), siklus periode penggajian (`payroll_periods`), serta hook pemotongan kasbon (`cash_advances`).

### Invarian Bisnis & Formula:

1. **Gross Salary:** `gross_salary = round2(basic_salary + overtime_pay + allowances)`
2. **Net Salary (Take Home Pay):** `net_salary = round2(gross_salary - deductions - cash_advance_deduction)`
3. **Validasi THP Non-Negatif:** `net_salary` wajib `>= 0`. Jika potongan melebihi pendapatan kotor, request ditolak `400 Bad Request` (`NET_SALARY_NEGATIVE`).
4. **Idempotent Upsert:** Menjalankan `generate` berulang kali pada periode yang sama akan memperbarui `basic_salary` dan `overtime_pay` tanpa membuat rekaman ganda, serta mempertahankan nilai custom `allowances` dan `deductions` yang telah dimasukkan sebelumnya.
5. **Kekebalan Mutasi (Immutability):** Pembuatan dan pengeditan slip gaji HANYA diizinkan ketika status periode penggajian adalah `DRAFT`. Jika `FINALIZED` atau `PAID`, operasi ditolak `409 Conflict` (`PAYROLL_PERIOD_LOCKED`).
6. **Pembayaran Slip Gaji:** Individual `pay` hanya dapat diproses pada periode `FINALIZED` atau `PAID`. Ketika periode ditandai `PAID` via `POST /api/v1/payroll-periods/:id/pay`, seluruh slip gaji `UNPAID` pada periode tersebut secara otomatis ikut ditandai sebagai `PAID`.
7. **RBAC & Self-Boundary:** `EMPLOYEE` hanya dapat melihat slip gaji miliknya sendiri (`employee_id === user.employee_id`) dan HANYA ketika status periode telah `FINALIZED` atau `PAID` (slip pada periode `DRAFT` disembunyikan). Seluruh mutasi dilarang (`403 Forbidden`).

---

### 13.1. Generate Payslips (`POST /api/v1/payslips/generate`)

- **Method:** `POST`
- **Path:** `/api/v1/payslips/generate`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak `403 Forbidden`)
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_ADMIN_TOKEN",
    "payroll_period_id": "11111111-2222-4333-8444-555555555555",
    "employee_ids": ["emp-uuid-1", "emp-uuid-2"],
    "idempotency_key": "optional-uuid"
  }
  ```
- **Contoh Response Berhasil (`201 Created`):**
  ```json
  {
    "success": true,
    "status": 201,
    "data": {
      "total_generated": 2,
      "new_count": 2,
      "updated_count": 0,
      "payslips": [
        {
          "id": "slip-uuid-1",
          "payroll_period_id": "11111111-2222-4333-8444-555555555555",
          "employee_id": "emp-uuid-1",
          "employee_name": "Budi Santoso",
          "employee_nik": "3201010101010001",
          "period_name": "November 2026",
          "basic_salary": 10000000,
          "overtime_pay": 202312.14,
          "allowances": 0,
          "deductions": 0,
          "cash_advance_deduction": 0,
          "gross_salary": 10202312.14,
          "net_salary": 10202312.14,
          "payment_status": "UNPAID",
          "generated_at": "2026-11-20T10:00:00.000Z",
          "paid_at": null
        }
      ]
    },
    "message": "Payslips generated successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/payslips/generate" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN",
      "payroll_period_id": "11111111-2222-4333-8444-555555555555"
    }'
  ```

---

### 13.2. List Payslips (`GET /api/v1/payslips`)

- **Method:** `GET`
- **Path:** `/api/v1/payslips`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE` (Karyawan dibatasi hanya melihat slip gaji miliknya pada periode non-DRAFT)
- **Query Parameters:**
  - `auth_token`: Token JWT aktif
  - `payroll_period_id`: Filter UUID periode penggajian
  - `employee_id`: Filter UUID karyawan (Hanya `OWNER`/`ADMIN`)
  - `payment_status`: Filter `UNPAID` atau `PAID`
  - `limit`: Default 50, maks 100
  - `offset`: Default 0
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": [
      {
        "id": "slip-uuid-1",
        "payroll_period_id": "11111111-2222-4333-8444-555555555555",
        "employee_id": "emp-uuid-1",
        "employee_name": "Budi Santoso",
        "basic_salary": 10000000,
        "overtime_pay": 202312.14,
        "allowances": 500000,
        "deductions": 100000,
        "cash_advance_deduction": 0,
        "gross_salary": 10702312.14,
        "net_salary": 10602312.14,
        "payment_status": "UNPAID"
      }
    ],
    "meta": {
      "total": 1,
      "limit": 50,
      "offset": 0
    }
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/payslips&auth_token=YOUR_TOKEN&payroll_period_id=11111111-2222-4333-8444-555555555555"
  ```

---

### 13.3. Get Payslip by ID (`GET /api/v1/payslips/:id`)

- **Method:** `GET`
- **Path:** `/api/v1/payslips/:id`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE` (Role `EMPLOYEE` ditolak `403 Forbidden` jika mencoba melihat slip karyawan lain atau slip pada periode DRAFT)
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "slip-uuid-1",
      "payroll_period_id": "11111111-2222-4333-8444-555555555555",
      "employee_id": "emp-uuid-1",
      "employee_name": "Budi Santoso",
      "basic_salary": 10000000,
      "overtime_pay": 202312.14,
      "allowances": 500000,
      "deductions": 100000,
      "cash_advance_deduction": 0,
      "gross_salary": 10702312.14,
      "net_salary": 10602312.14,
      "payment_status": "UNPAID",
      "generated_at": "2026-11-20T10:00:00.000Z",
      "paid_at": null
    }
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/payslips/slip-uuid-1&auth_token=YOUR_TOKEN"
  ```

---

### 13.4. Update Payslip Adjustments (`PUT /api/v1/payslips/:id` via `_method: "PUT"`)

- **Method:** `POST` (dengan `_method: "PUT"`)
- **Path:** `/api/v1/payslips/:id`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak `403 Forbidden`)
- **Aturan Immutability:**
  - Hanya diizinkan pada periode `DRAFT`. Jika periode `FINALIZED` atau `PAID`, ditolak `409 Conflict`.
  - Jika slip sudah berstatus `PAID`, ditolak `409 Conflict`.
  - Jika potongan melebihi penghasilan kotor sehingga THP menjadi negatif, ditolak `400 Bad Request`.
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_ADMIN_TOKEN",
    "_method": "PUT",
    "allowances": 750000,
    "deductions": 200000
  }
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "slip-uuid-1",
      "basic_salary": 10000000,
      "overtime_pay": 202312.14,
      "allowances": 750000,
      "deductions": 200000,
      "gross_salary": 10952312.14,
      "net_salary": 10752312.14,
      "payment_status": "UNPAID"
    },
    "message": "Payslip updated successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/payslips/slip-uuid-1" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN",
      "_method": "PUT",
      "allowances": 750000,
      "deductions": 200000
    }'
  ```

---

### 13.5. Mark Payslip as Paid (`POST /api/v1/payslips/:id/pay`)

- **Method:** `POST`
- **Path:** `/api/v1/payslips/:id/pay`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak `403 Forbidden`)
- **Aturan State Machine:**
  - Periode penggajian harus berstatus `FINALIZED` atau `PAID`. (Ditolak `409 Conflict` jika masih `DRAFT`).
  - Ditolak `409 Conflict` jika slip gaji sudah berstatus `PAID`.
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_ADMIN_TOKEN"
  }
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "slip-uuid-1",
      "payment_status": "PAID",
      "paid_at": "2026-11-20T11:45:00.000Z"
    },
    "message": "Payslip marked as paid successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/payslips/slip-uuid-1/pay" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN"
    }'
  ```

---

## 14. Modul 12: Cash Advances (`cash_advances`)

Modul ini mengelola siklus hidup pengajuan kasbon (pinjaman karyawan / _cash advance_) dengan aturan:

- **Tepat 14 Kolom:** `id`, `employee_id`, `request_date`, `amount`, `installment_amount`, `installment_count`, `approved_amount`, `approved_by`, `approved_at`, `disbursement_date`, `status`, `notes`, `created_at`, `updated_at`.
- **Status State Machine:** `PENDING` $\rightarrow$ `APPROVED` $\rightarrow$ `ACTIVE` (saat dicairkan/disburse) $\rightarrow$ `PAID_OFF` (saat lunas di Modul 13–14). Status juga dapat berakhir pada `REJECTED` atau `CANCELLED`.
- **Duplicate Pending Guard:** Karyawan dilarang mengajukan kasbon baru jika masih memiliki kasbon aktif/menunggu dalam status `PENDING` atau `APPROVED` (`409 Conflict`). Pengajuan baru diizinkan kembali jika kasbon sebelumnya sudah berstatus `ACTIVE`, `PAID_OFF`, `REJECTED`, atau `CANCELLED`.
- **Zero-Trust Input Validation:** Menolak manipulasi client atas field terkelola server (`status`, `approved_amount`, `approved_by`, `approved_at`, `disbursement_date`, `installment_amount`).
- **Persetujuan Sebagian (_Partial Approval_):** Admin/Owner dapat menyetujui dengan nominal disetujui (`approved_amount`) lebih kecil atau sama dengan nominal pengajuan (`amount`). Nilai cicilan (`installment_amount`) dihitung ulang secara deterministik: $\text{installment\_amount} = \text{round2}(\text{approved\_amount} / \text{installment\_count})$.
- **Pencairan Dana (_Disbursement Flow_):** Kasbon HANYA dapat dicairkan jika sudah berstatus `APPROVED`. Kasbon yang dicairkan otomatis berpindah status menjadi `ACTIVE` dan mencatat `disbursement_date` (wajib $\ge$ `request_date`). Disiapkan hook `onCashAdvanceDisbursed` untuk Modul 13 (`cash_advance_installments`).
- **Aturan Pembatalan (_Cancellation Flow_):**
  - Kasbon `PENDING`: Dapat dibatalkan oleh karyawan pemohon atau Admin/Owner.
  - Kasbon `APPROVED`: HANYA dapat dibatalkan oleh Admin/Owner. Karyawan ditolak `403 Forbidden`.
  - Kasbon `ACTIVE`, `PAID_OFF`, `REJECTED`, `CANCELLED`: Ditolak `409 Conflict` (tidak dapat dibatalkan setelah dicairkan).
- **Audit Logging:** Setiap mutasi (`CREATE`, `APPROVE`, `REJECT`, `DISBURSE`, `CANCEL`) otomatis tercatat pada `audit_logs` dengan diff payload.

---

### 14.1. Submit Cash Advance Request (`POST /api/v1/cash-advances`)

- **Method:** `POST`
- **Path:** `/api/v1/cash-advances`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE`
- **Aturan Validasi & Otorisasi:**
  - Role `EMPLOYEE` otomatis menggunakan `employee_id` dari profil terautentikasi (field `employee_id` di body diabaikan/ditimpa).
  - Role `ADMIN` / `OWNER` wajib mencantumkan `employee_id` UUID karyawan aktif (`employment_status === 'ACTIVE'` dan belum dihapus).
  - `amount`: Nominal kasbon wajib $> 0$ (contoh: `2000000`).
  - `installment_count`: Jumlah termin cicilan bilangan bulat $1 \le n \le 24$.
  - `installment_amount`: Dihitung otomatis oleh server: $\text{round2}(\text{amount} / \text{installment\_count})$.
  - `request_date`: Format tanggal strict `YYYY-MM-DD` (opsional, default hari ini).
  - `notes`: Catatan/tujuan pengajuan kasbon (opsional, maks 1000 karakter).
  - **Duplicate Pending Guard:** Ditolak `409 Conflict` jika pemohon masih memiliki kasbon berstatus `PENDING` atau `APPROVED`.
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_EMPLOYEE_TOKEN",
    "amount": 3000000,
    "installment_count": 3,
    "notes": "Keperluan renovasi atap rumah darurat",
    "idempotency_key": "ca-req-20261120-001"
  }
  ```
- **Contoh Response Berhasil (`201 Created`):**
  ```json
  {
    "success": true,
    "status": 201,
    "data": {
      "id": "ca-uuid-1111",
      "employee_id": "emp-uuid-1234",
      "request_date": "2026-11-20",
      "amount": 3000000,
      "installment_amount": 1000000,
      "installment_count": 3,
      "approved_amount": null,
      "approved_by": null,
      "approved_at": null,
      "disbursement_date": null,
      "status": "PENDING",
      "notes": "Keperluan renovasi atap rumah darurat",
      "created_at": "2026-11-20T14:00:00.000Z",
      "updated_at": "2026-11-20T14:00:00.000Z",
      "employee_name": "Rudi Hartono",
      "employee_nik": "3201010101010001",
      "approver_email": null
    },
    "message": "Cash advance request submitted successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/cash-advances" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_EMPLOYEE_TOKEN",
      "amount": 3000000,
      "installment_count": 3,
      "notes": "Keperluan renovasi atap rumah darurat",
      "idempotency_key": "ca-req-20261120-001"
    }'
  ```

---

### 14.2. List Cash Advances (`GET /api/v1/cash-advances`)

- **Method:** `GET`
- **Path:** `/api/v1/cash-advances`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE`
- **Aturan Akses:**
  - Role `EMPLOYEE` otomatis dibatasi hanya dapat melihat daftar kasbon miliknya sendiri.
  - Role `OWNER` / `ADMIN` dapat melihat seluruh kasbon atau menyaring berdasarkan query filter.
- **Query Parameters:**
  - `employee_id` (opsional UUID, hanya berlaku untuk Admin/Owner)
  - `status` (opsional: `PENDING`, `APPROVED`, `REJECTED`, `ACTIVE`, `PAID_OFF`, `CANCELLED`)
  - `start_date` (opsional `YYYY-MM-DD`, menyaring `request_date` $\ge$ `start_date`)
  - `end_date` (opsional `YYYY-MM-DD`, menyaring `request_date` $\le$ `end_date`)
  - `limit` (opsional integer $1 \le n \le 100$, default 50)
  - `offset` (opsional integer $\ge 0$, default 0)
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": [
      {
        "id": "ca-uuid-1111",
        "employee_id": "emp-uuid-1234",
        "request_date": "2026-11-20",
        "amount": 3000000,
        "installment_amount": 1000000,
        "installment_count": 3,
        "approved_amount": null,
        "approved_by": null,
        "approved_at": null,
        "disbursement_date": null,
        "status": "PENDING",
        "notes": "Keperluan renovasi atap rumah darurat",
        "created_at": "2026-11-20T14:00:00.000Z",
        "updated_at": "2026-11-20T14:00:00.000Z",
        "employee_name": "Rudi Hartono",
        "employee_nik": "3201010101010001",
        "approver_email": null
      }
    ],
    "meta": {
      "total": 1,
      "limit": 50,
      "offset": 0,
      "page": 1
    }
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/cash-advances&auth_token=YOUR_TOKEN&status=PENDING"
  ```

---

### 14.3. Get Cash Advance Detail (`GET /api/v1/cash-advances/:id`)

- **Method:** `GET`
- **Path:** `/api/v1/cash-advances/:id`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE`
- **Aturan Akses:**
  - Role `EMPLOYEE` hanya dapat melihat detail jika kasbon tersebut milik dirinya sendiri. Akses ke kasbon karyawan lain ditolak `403 Forbidden`.
  - Role `OWNER` / `ADMIN` dapat melihat detail seluruh kasbon.
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "ca-uuid-1111",
      "employee_id": "emp-uuid-1234",
      "request_date": "2026-11-20",
      "amount": 3000000,
      "installment_amount": 1000000,
      "installment_count": 3,
      "approved_amount": null,
      "approved_by": null,
      "approved_at": null,
      "disbursement_date": null,
      "status": "PENDING",
      "notes": "Keperluan renovasi atap rumah darurat",
      "created_at": "2026-11-20T14:00:00.000Z",
      "updated_at": "2026-11-20T14:00:00.000Z",
      "employee_name": "Rudi Hartono",
      "employee_nik": "3201010101010001",
      "approver_email": null
    }
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X GET "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/cash-advances/ca-uuid-1111&auth_token=YOUR_TOKEN"
  ```

---

### 14.4. Approve Cash Advance (`POST /api/v1/cash-advances/:id/approve`)

- **Method:** `POST`
- **Path:** `/api/v1/cash-advances/:id/approve`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak `403 Forbidden`)
- **Aturan State Machine & Validasi:**
  - Kasbon wajib berstatus `PENDING`. Ditolak `409 Conflict` jika sudah `APPROVED`, `ACTIVE`, `REJECTED`, dll.
  - `approved_amount`: Nominal yang disetujui (opsional). Jika diisi, wajib $> 0$ dan $\le$ `amount`. Jika tidak dikirimkan, default sama dengan `amount`.
  - Nilai cicilan per bulan (`installment_amount`) dihitung ulang secara otomatis berdasarkan `approved_amount`: $\text{installment\_amount} = \text{round2}(\text{approved\_amount} / \text{installment\_count})$.
  - Status bertransisi menjadi `APPROVED`. Mencatat `approved_by` dan `approved_at` (ISO 8601 UTC server).
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_ADMIN_TOKEN",
    "approved_amount": 2400000,
    "notes": "Disetujui sebagian sesuai batas maksimal plafon grade 3"
  }
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "ca-uuid-1111",
      "employee_id": "emp-uuid-1234",
      "amount": 3000000,
      "approved_amount": 2400000,
      "installment_count": 3,
      "installment_amount": 800000,
      "status": "APPROVED",
      "approved_by": "admin-user-uuid",
      "approved_at": "2026-11-20T14:15:00.000Z",
      "notes": "Disetujui sebagian sesuai batas maksimal plafon grade 3"
    },
    "message": "Cash advance approved successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/cash-advances/ca-uuid-1111/approve" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN",
      "approved_amount": 2400000,
      "notes": "Disetujui sebagian sesuai batas maksimal plafon grade 3"
    }'
  ```

---

### 14.5. Reject Cash Advance (`POST /api/v1/cash-advances/:id/reject`)

- **Method:** `POST`
- **Path:** `/api/v1/cash-advances/:id/reject`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak `403 Forbidden`)
- **Aturan State Machine & Validasi:**
  - Kasbon wajib berstatus `PENDING`. Ditolak `409 Conflict` jika tidak `PENDING`.
  - `notes`: Catatan/alasan penolakan (opsional namun sangat disarankan untuk audit trail).
  - Status bertransisi menjadi `REJECTED`. Mencatat `approved_by` dan `approved_at`.
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_ADMIN_TOKEN",
    "notes": "Masa kerja belum mencapai syarat minimal 1 tahun untuk pengajuan kasbon"
  }
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "ca-uuid-1111",
      "status": "REJECTED",
      "approved_by": "admin-user-uuid",
      "approved_at": "2026-11-20T14:20:00.000Z",
      "notes": "Masa kerja belum mencapai syarat minimal 1 tahun untuk pengajuan kasbon"
    },
    "message": "Cash advance rejected successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/cash-advances/ca-uuid-1111/reject" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN",
      "notes": "Masa kerja belum mencapai syarat minimal 1 tahun"
    }'
  ```

---

### 14.6. Disburse Cash Advance (`POST /api/v1/cash-advances/:id/disburse`)

- **Method:** `POST`
- **Path:** `/api/v1/cash-advances/:id/disburse`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak `403 Forbidden`)
- **Aturan State Machine & Validasi:**
  - Kasbon wajib berstatus `APPROVED`. Kasbon yang masih `PENDING` atau sudah `ACTIVE` ditolak `409 Conflict`.
  - `disbursement_date`: Format tanggal strict `YYYY-MM-DD` (opsional, default hari ini). Wajib $\ge$ `request_date`.
  - `notes`: Catatan pencairan (misal: nomor referensi transfer bank).
  - Status bertransisi menjadi `ACTIVE` dan mencatat `disbursement_date`.
  - Mengeksekusi event hook `onCashAdvanceDisbursed(record)` yang siap dihubungkan dengan Modul 13 (`cash_advance_installments`).
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_ADMIN_TOKEN",
    "disbursement_date": "2026-11-20",
    "notes": "Transfer via BCA No. Ref TRF-20261120-998"
  }
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "ca-uuid-1111",
      "status": "ACTIVE",
      "disbursement_date": "2026-11-20",
      "approved_amount": 2400000,
      "installment_amount": 800000,
      "notes": "Transfer via BCA No. Ref TRF-20261120-998"
    },
    "message": "Cash advance disbursed successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/cash-advances/ca-uuid-1111/disburse" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_ADMIN_TOKEN",
      "disbursement_date": "2026-11-20",
      "notes": "Transfer via BCA No. Ref TRF-20261120-998"
    }'
  ```

---

### 14.7. Cancel Cash Advance (`POST /api/v1/cash-advances/:id/cancel`)

- **Method:** `POST`
- **Path:** `/api/v1/cash-advances/:id/cancel`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE`
- **Aturan Otorisasi & State Machine:**
  - Jika kasbon berstatus `PENDING`:
    - Role `EMPLOYEE` pemilik kasbon atau `OWNER` / `ADMIN` dapat membatalkan.
    - Role `EMPLOYEE` karyawan lain ditolak `403 Forbidden`.
  - Jika kasbon berstatus `APPROVED`:
    - HANYA role `OWNER` / `ADMIN` yang dapat membatalkan.
    - Role `EMPLOYEE` ditolak `403 Forbidden` (`Only administrators can cancel an approved cash advance`).
  - Jika kasbon berstatus `ACTIVE`, `PAID_OFF`, `REJECTED`, atau `CANCELLED`:
    - Ditolak `409 Conflict` (`Disbursed or resolved cash advances cannot be cancelled`).
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_TOKEN",
    "notes": "Kebutuhan dana mendesak sudah terpenuhi dari sumber lain"
  }
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "ca-uuid-1111",
      "status": "CANCELLED",
      "notes": "Kebutuhan dana mendesak sudah terpenuhi dari sumber lain"
    },
    "message": "Cash advance cancelled successfully"
  }
  ```
- **Contoh curl:**
  ```bash
  curl -L -X POST "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/cash-advances/ca-uuid-1111/cancel" \
    -H "Content-Type: text/plain;charset=utf-8" \
    -d '{
      "auth_token": "YOUR_TOKEN",
      "notes": "Kebutuhan dana mendesak sudah terpenuhi dari sumber lain"
    }'
  ```

---

## 15. Modul 13: Cicilan & Jadwal Kasbon (`cash_advance_installments`)

Tabel `cash_advance_installments` mengelola jadwal amortisasi pelunasan pinjaman kasbon secara terstruktur dan terotomatisasi. Jadwal cicilan di-_generate_ secara atomik saat kasbon dicairkan (`disbursed`), dipotongkan secara otomatis melalui slip gaji berkala (Modul 11), atau dilunasi langsung di luar siklus penggajian (_ad-hoc payment_ & _early payoff_).

### Skema & Struktur Data (Tepat 12 Kolom)

| Kolom                | Tipe Data     | Deskripsi                                                                             |
| -------------------- | ------------- | ------------------------------------------------------------------------------------- |
| `id`                 | UUID PK       | Pengidentifikasi unik termin cicilan (RFC 4122 v4)                                    |
| `cash_advance_id`    | UUID FK       | Relasi ke pinjaman induk (`cash_advances.id`)                                         |
| `employee_id`        | UUID FK       | Relasi ke penerima pinjaman (`employees.id`)                                          |
| `payroll_period_id`  | UUID NULL FK  | Terisi jika cicilan ini ditautkan/dipotong melalui slip gaji periode tertentu         |
| `installment_number` | INTEGER       | Urutan termin cicilan (`1` s/d `installment_count`, unik per pinjaman)                |
| `amount_due`         | DECIMAL       | Kewajiban nominal yang harus dibayar pada termin ini (`> 0`)                          |
| `amount_paid`        | DECIMAL       | Akumulasi nominal yang sudah disetorkan pada termin ini (`>= 0`)                      |
| `due_date`           | DATE          | Tanggal jatuh tempo kalender (`YYYY-MM-DD`, aman dari pergeseran tanggal akhir bulan) |
| `status`             | ENUM          | Status termin: `PENDING`, `PARTIALLY_PAID`, `PAID`, `OVERDUE`, `WAIVED`               |
| `paid_at`            | DATETIME NULL | Timestamp pelunasan penuh dalam format ISO 8601 UTC                                   |
| `created_at`         | DATETIME      | Timestamp pembuatan termin cicilan (ISO 8601 UTC)                                     |
| `updated_at`         | DATETIME      | Timestamp pembaruan data termin cicilan (ISO 8601 UTC)                                |

---

### 15.1. List Cash Advance Installments (`GET /api/v1/cash-advance-installments`)

- **Method:** `GET`
- **Path:** `/api/v1/cash-advance-installments`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE`
- **Aturan Otorisasi & Filter Data:**
  - Role `OWNER` dan `ADMIN` dapat melihat seluruh termin cicilan lintas karyawan.
  - Role `EMPLOYEE` **hanya dapat melihat termin miliknya sendiri** (`employee_id` otomatis di-_override_ oleh server).
  - Parameter filter:
    - `cash_advance_id` (opsional): Memfilter termin untuk satu pinjaman kasbon tertentu.
    - `employee_id` (opsional, khusus Admin/Owner): Memfilter termin untuk karyawan tertentu.
    - `status` (opsional): Memfilter berdasarkan status (`PENDING`, `PARTIALLY_PAID`, `PAID`, `OVERDUE`, `WAIVED`).
- **Contoh Request:**
  ```bash
  curl -L "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/cash-advance-installments&cash_advance_id=ca-uuid-1111&auth_token=YOUR_TOKEN"
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": [
      {
        "id": "inst-uuid-0001",
        "cash_advance_id": "ca-uuid-1111",
        "employee_id": "emp-uuid-8888",
        "payroll_period_id": null,
        "installment_number": 1,
        "amount_due": 333333.33,
        "amount_paid": 0,
        "remaining_amount": 333333.33,
        "due_date": "2026-12-20",
        "status": "PENDING",
        "paid_at": null,
        "created_at": "2026-11-20T10:00:00.000Z",
        "updated_at": "2026-11-20T10:00:00.000Z"
      },
      {
        "id": "inst-uuid-0002",
        "cash_advance_id": "ca-uuid-1111",
        "employee_id": "emp-uuid-8888",
        "payroll_period_id": null,
        "installment_number": 2,
        "amount_due": 333333.33,
        "amount_paid": 0,
        "remaining_amount": 333333.33,
        "due_date": "2027-01-20",
        "status": "PENDING",
        "paid_at": null,
        "created_at": "2026-11-20T10:00:00.000Z",
        "updated_at": "2026-11-20T10:00:00.000Z"
      },
      {
        "id": "inst-uuid-0003",
        "cash_advance_id": "ca-uuid-1111",
        "employee_id": "emp-uuid-8888",
        "payroll_period_id": null,
        "installment_number": 3,
        "amount_due": 333333.34,
        "amount_paid": 0,
        "remaining_amount": 333333.34,
        "due_date": "2027-02-20",
        "status": "PENDING",
        "paid_at": null,
        "created_at": "2026-11-20T10:00:00.000Z",
        "updated_at": "2026-11-20T10:00:00.000Z"
      }
    ],
    "meta": {
      "total": 3,
      "limit": 50,
      "offset": 0
    }
  }
  ```

---

### 15.2. Get Cash Advance Installment by ID (`GET /api/v1/cash-advance-installments/:id`)

- **Method:** `GET`
- **Path:** `/api/v1/cash-advance-installments/:id`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE` (Khusus termin miliknya)
- **Aturan Otorisasi:**
  - Jika pengguna adalah role `EMPLOYEE` dan termin tersebut milik karyawan lain, permintaan ditolak dengan `403 Forbidden`.
- **Contoh Request:**
  ```bash
  curl -L "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/cash-advance-installments/inst-uuid-0001&auth_token=YOUR_TOKEN"
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "inst-uuid-0001",
      "cash_advance_id": "ca-uuid-1111",
      "employee_id": "emp-uuid-8888",
      "payroll_period_id": null,
      "installment_number": 1,
      "amount_due": 333333.33,
      "amount_paid": 0,
      "remaining_amount": 333333.33,
      "due_date": "2026-12-20",
      "status": "PENDING",
      "paid_at": null,
      "created_at": "2026-11-20T10:00:00.000Z",
      "updated_at": "2026-11-20T10:00:00.000Z"
    }
  }
  ```

---

### 15.3. Record Installment Payment (`POST /api/v1/cash-advance-installments/:id/pay`)

- **Method:** `POST`
- **Path:** `/api/v1/cash-advance-installments/:id/pay`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak `403 Forbidden`)
- **Aturan Bisnis & Validasi:**
  - `amount`: Nominal pembayaran (`> 0`). Jika tidak dikirim, otomatis melunasi sisa tagihan termin (`amount_due - amount_paid`).
  - Nominal pembayaran tidak boleh melebihi sisa tagihan (`remaining_amount`). Jika melebihi, ditolak `400 Bad Request`.
  - Jika status sudah `PAID` atau `WAIVED`, ditolak `409 Conflict`.
  - Transisi Status Termin:
    - Jika `new_paid < amount_due`: Status menjadi `PARTIALLY_PAID`.
    - Jika `new_paid === amount_due`: Status menjadi `PAID` dan `paid_at` diisi timestamp server.
  - **Auto PAID_OFF Hook:** Jika seluruh termin pada kasbon induk telah berstatus `PAID` atau `WAIVED`, status kasbon induk pada `cash_advances` otomatis diperbarui menjadi `PAID_OFF`.
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_ADMIN_TOKEN",
    "amount": 333333.33,
    "paid_at": "2026-12-20T08:30:00.000Z",
    "notes": "Pembayaran manual via transfer bank"
  }
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "inst-uuid-0001",
      "cash_advance_id": "ca-uuid-1111",
      "installment_number": 1,
      "amount_due": 333333.33,
      "amount_paid": 333333.33,
      "status": "PAID",
      "paid_at": "2026-12-20T08:30:00.000Z",
      "cash_advance_status": "ACTIVE"
    },
    "message": "Installment payment recorded successfully"
  }
  ```

---

### 15.4. Waive Installment (`POST /api/v1/cash-advance-installments/:id/waive`)

- **Method:** `POST`
- **Path:** `/api/v1/cash-advance-installments/:id/waive`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak `403 Forbidden`)
- **Aturan Bisnis & Validasi:**
  - Pemutihan/penghapusan termin cicilan oleh manajemen perusahaan (misalnya bantuan/kebijakan khusus).
  - Termin yang sudah berstatus `PAID` atau `WAIVED` tidak dapat diputihkan kembali (`409 Conflict`).
  - `reason` (opsional): Alasan justifikasi pemutihan termin.
  - Status termin berubah menjadi `WAIVED`.
  - **Auto PAID_OFF Hook:** Jika pemutihan ini menyebabkan seluruh termin cicilan pada pinjaman berstatus `PAID` atau `WAIVED`, status kasbon induk otomatis beralih menjadi `PAID_OFF`.
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_ADMIN_TOKEN",
    "reason": "Kebijakan kompensasi prestasi khusus direksi"
  }
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "inst-uuid-0002",
      "cash_advance_id": "ca-uuid-1111",
      "status": "WAIVED",
      "cash_advance_status": "ACTIVE"
    },
    "message": "Installment waived successfully"
  }
  ```

---

### 15.5. Early Payoff Cash Advance (`POST /api/v1/cash-advances/:id/early-payoff`)

- **Method:** `POST`
- **Path:** `/api/v1/cash-advances/:id/early-payoff`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak `403 Forbidden`)
- **Aturan Bisnis & Validasi:**
  - Pelunasan pinjaman kasbon secara dipercepat (sekaligus).
  - Kasbon induk wajib berstatus `ACTIVE`. Jika berstatus selain `ACTIVE`, ditolak `409 Conflict`.
  - Menemukan seluruh termin cicilan yang masih berstatus terbuka (`PENDING`, `PARTIALLY_PAID`, `OVERDUE`).
  - Menandai seluruh termin terbuka tersebut menjadi `PAID` dengan `amount_paid = amount_due` dan `paid_at = serverTime`.
  - Mengubah status kasbon induk pada `cash_advances` menjadi `PAID_OFF`.
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_ADMIN_TOKEN",
    "notes": "Pelunasan sekaligus tunai sebelum jatuh tempo"
  }
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "cash_advance_id": "ca-uuid-1111",
      "settled_count": 2,
      "total_settled_amount": 666666.67,
      "cash_advance_status": "PAID_OFF"
    },
    "message": "Cash advance paid off early successfully"
  }
  ```

---

### 15.6. Cross-Module Payroll Integration (Modul 10, 11 & 13)

Sistem mengintegrasikan jadwal cicilan kasbon secara transparan dan atomik dengan siklus penggajian:

1. **Auto-Deduction pada `generatePayslips` (Modul 11):**
   - Saat Admin menjalankan `generatePayslips` untuk periode penggajian berstatus `DRAFT`:
   - Sistem mencari termin kasbon yang jatuh tempo:
     - Karyawan berstatus aktif (`employment_status === 'ACTIVE'`)
     - Kasbon induk berstatus `ACTIVE`
     - Termin berstatus `PENDING`, `PARTIALLY_PAID`, atau `OVERDUE`
     - `due_date <= payroll_period.end_date`
     - Belum ditautkan ke periode lain (`payroll_period_id === null` atau `payroll_period_id === period.id`)
   - Sistem menautkan termin tersebut (`payroll_period_id = period.id`) dan mengakumulasikan nominalnya ke dalam kolom `cash_advance_deduction` pada tabel `payslips`.
   - **Idempotensi Aman:** Pembuatan ulang slip gaji (_re-generate_) mengevaluasi termin yang sama secara idempotent tanpa menduplikasi potongan atau merusak penautan.
   - **Proteksi Karyawan Resign:** Jika karyawan berstatus tidak aktif/telah keluar (`RESIGNED`/`TERMINATED`), sisa cicilan masa depan **TIDAK** dipercepat secara agresif ke dalam satu slip gaji terakhir untuk mencegah nilai take-home-pay menjadi negatif atau tidak wajar. Sisa cicilan tetap tercatat di buku piutang kasbon.

2. **Auto-Settlement pada Pelunasan Gaji (`payPayslip` & `payPayrollPeriod`):**
   - Saat slip gaji ditandai `PAID` (secara individual via `POST /api/v1/payslips/:id/pay` atau secara massal melalui penutupan periode `POST /api/v1/payroll-periods/:id/pay`):
   - Seluruh termin cicilan yang tertaut pada periode penggajian tersebut secara otomatis diselesaikan menjadi `PAID` (`amount_paid = amount_due`, `paid_at = serverTime`).
   - Jika termin terakhir suatu pinjaman terbayar, pinjaman kasbon tersebut otomatis beralih menjadi `PAID_OFF`.

---

## 16. Modul 14: Buku Besar Transaksi Kasbon (`cash_advance_transactions`)

Tabel `cash_advance_transactions` adalah buku besar keuangan (_financial ledger_) yang bersifat kekal (_immutable append-only_). Tabel ini mencatat setiap mutasi pergerakan uang aktual kasbon: pencairan dana (`DISBURSEMENT`), pengembalian/pelunasan cicilan (`REPAYMENT`), serta pemutihan atau penyesuaian administratif (`ADJUSTMENT`).

### A. Karakteristik & Skema Data (Tepat 10 Kolom)

Buku besar transaksi kasbon tidak memiliki kolom pembaruan (`updated_at`) maupun penghapusan (`deleted_at`). Sekali transaksi dicatat, data tidak dapat diubah maupun dihapus. Percobaan pemanggilan metode `PUT` atau `DELETE` pada endpoint transaksi akan ditolak secara permanen dengan `404 Not Found`.

| Kolom              | Tipe Data    | Nullable | Deskripsi                                                                                       |
| ------------------ | ------------ | -------- | ----------------------------------------------------------------------------------------------- |
| `id`               | UUID PK      | NO       | Pengidentifikasi unik transaksi (RFC 4122 v4)                                                   |
| `cash_advance_id`  | UUID FK      | NO       | Relasi ke pinjaman induk (`cash_advances.id`)                                                   |
| `installment_id`   | UUID NULL FK | YES      | `null` untuk `DISBURSEMENT` / penyesuaian induk; terisi ID termin untuk `REPAYMENT` & pemutihan |
| `transaction_type` | ENUM         | NO       | Tipe transaksi: `DISBURSEMENT`, `REPAYMENT`, `ADJUSTMENT`                                       |
| `amount`           | DECIMAL      | NO       | Nominal mutasi uang, bernilai positif (`> 0`)                                                   |
| `transaction_date` | DATETIME     | NO       | Waktu transaksi aktual dalam format ISO 8601 UTC                                                |
| `reference_id`     | UUID NULL    | YES      | Referensi dokumen sumber (misal `payslip.id` atau `cash_advance.id`) untuk pencegahan duplikasi |
| `notes`            | TEXT NULL    | YES      | Keterangan/catatan audit pergerakan dana                                                        |
| `created_by`       | UUID FK      | NO       | ID pengguna pembuat transaksi (`users.id`)                                                      |
| `created_at`       | DATETIME     | NO       | Timestamp pencatatan ke dalam sistem (ISO 8601 UTC)                                             |

---

### B. Otomatisasi Transaksi & Reference Uniqueness Guard

Sistem menjamin integritas buku besar secara otomatis pada seluruh alur kasbon:

1. **Pencairan Kasbon (`POST /api/v1/cash-advances/:id/disburse`):** Otomatis mencatat 1 transaksi `DISBURSEMENT` sebesar `approved_amount` dengan `reference_id = cash_advance.id`.
2. **Pembayaran Cicilan Individual (`POST /api/v1/cash-advance-installments/:id/pay`):** Otomatis mencatat 1 transaksi `REPAYMENT` sebesar nominal yang disetorkan dengan `installment_id = installment.id`.
3. **Pelunasan Slip Gaji & Periode Gaji (`payPayslip` & `payPayrollPeriod`):** Otomatis mencatat transaksi `REPAYMENT` untuk setiap termin yang dilunasi lewat slip gaji dalam **satu kali Batch Write** dengan `reference_id = payslip.id`.
4. **Pemutihan Termin (`POST /api/v1/cash-advance-installments/:id/waive`):** Otomatis mencatat 1 transaksi `ADJUSTMENT` sebesar sisa kewajiban yang diputihkan dengan `installment_id = installment.id`.
5. **Pelunasan Dipercepat (`POST /api/v1/cash-advances/:id/early-payoff`):** Otomatis mencatat transaksi `REPAYMENT` untuk setiap termin yang dilunasi dalam **satu kali Batch Write**.
6. **Reference Uniqueness Guard:** Jika `installment_id` dan `reference_id` diisi, kombinasi `(installment_id, reference_id, transaction_type)` diproteksi sehingga transaksi yang sama tidak pernah dicatat ganda saat pemanggilan berulang (_idempotent protection_).

---

### 16.1. List Cash Advance Transactions (`GET /api/v1/cash-advance-transactions`)

- **Method:** `GET`
- **Path:** `/api/v1/cash-advance-transactions`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE`
- **Aturan Otorisasi & Filter Data:**
  - Role `OWNER` dan `ADMIN` dapat melihat seluruh mutasi transaksi lintas karyawan.
  - Role `EMPLOYEE` **hanya dapat melihat transaksi untuk kasbon miliknya sendiri** (`self-boundary` lock). Jika mencoba memfilter `cash_advance_id` milik orang lain, ditolak `403 Forbidden`.
  - Parameter filter yang didukung:
    - `cash_advance_id` (opsional): Memfilter transaksi untuk satu kasbon tertentu.
    - `installment_id` (opsional): Memfilter transaksi untuk satu termin tertentu.
    - `transaction_type` (opsional): Memfilter berdasarkan tipe (`DISBURSEMENT`, `REPAYMENT`, `ADJUSTMENT`).
    - `reference_id` (opsional): Memfilter berdasarkan ID referensi sumber.
    - `start_date` / `end_date` (opsional): Format `YYYY-MM-DD`.
    - `limit` (default 50, max 200) & `offset` (default 0).
- **Contoh Request:**
  ```bash
  curl -L "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/cash-advance-transactions&cash_advance_id=ca-uuid-1111&auth_token=YOUR_TOKEN"
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": [
      {
        "id": "tx-uuid-0001",
        "cash_advance_id": "ca-uuid-1111",
        "installment_id": null,
        "transaction_type": "DISBURSEMENT",
        "amount": 1200000,
        "transaction_date": "2026-11-05T00:00:00.000Z",
        "reference_id": "ca-uuid-1111",
        "notes": "Pencairan kasbon via transfer BCA",
        "created_by": "user-uuid-admin",
        "created_at": "2026-11-05T08:30:00.000Z",
        "employee_id": "emp-uuid-8888",
        "employee_name": "Budi Santoso",
        "employee_nik": "1234567890123456",
        "installment_number": null,
        "creator_email": "admin@company.com"
      },
      {
        "id": "tx-uuid-0002",
        "cash_advance_id": "ca-uuid-1111",
        "installment_id": "inst-uuid-0001",
        "transaction_type": "REPAYMENT",
        "amount": 150000,
        "transaction_date": "2026-11-15T10:00:00.000Z",
        "reference_id": null,
        "notes": "Bayar tunai sebagian",
        "created_by": "user-uuid-admin",
        "created_at": "2026-11-15T10:00:00.000Z",
        "employee_id": "emp-uuid-8888",
        "employee_name": "Budi Santoso",
        "employee_nik": "1234567890123456",
        "installment_number": 1,
        "creator_email": "admin@company.com"
      }
    ],
    "meta": {
      "total": 2,
      "limit": 50,
      "offset": 0
    }
  }
  ```

---

### 16.2. Get Cash Advance Transaction by ID (`GET /api/v1/cash-advance-transactions/:id`)

- **Method:** `GET`
- **Path:** `/api/v1/cash-advance-transactions/:id`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE` (Khusus transaksi kasbon miliknya)
- **Aturan Otorisasi:**
  - Jika pengguna adalah role `EMPLOYEE` dan transaksi tersebut milik karyawan lain, permintaan ditolak dengan `403 Forbidden`.
- **Contoh Request:**
  ```bash
  curl -L "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/cash-advance-transactions/tx-uuid-0001&auth_token=YOUR_TOKEN"
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "tx-uuid-0001",
      "cash_advance_id": "ca-uuid-1111",
      "installment_id": null,
      "transaction_type": "DISBURSEMENT",
      "amount": 1200000,
      "transaction_date": "2026-11-05T00:00:00.000Z",
      "reference_id": "ca-uuid-1111",
      "notes": "Pencairan kasbon via transfer BCA",
      "created_by": "user-uuid-admin",
      "created_at": "2026-11-05T08:30:00.000Z",
      "employee_id": "emp-uuid-8888",
      "employee_name": "Budi Santoso",
      "employee_nik": "1234567890123456",
      "installment_number": null,
      "creator_email": "admin@company.com"
    }
  }
  ```

---

### 16.3. Create Controlled Manual Adjustment (`POST /api/v1/cash-advance-transactions/adjust`)

- **Method:** `POST`
- **Path:** `/api/v1/cash-advance-transactions/adjust`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak `403 Forbidden`)
- **Aturan Validasi:**
  - `cash_advance_id`: UUID wajib valid dan harus terdaftar di `cash_advances`.
  - `installment_id`: UUID opsional. Jika diisi, wajib terdaftar dan berelasi ke `cash_advance_id` tersebut.
  - `amount`: Angka positif bernilai `> 0` (pembulatan 2 tempat desimal).
  - `notes`: Wajib diisi minimal 3 karakter untuk akuntabilitas jejak audit.
- **Request Payload:**
  ```json
  {
    "auth_token": "YOUR_ADMIN_TOKEN",
    "cash_advance_id": "ca-uuid-1111",
    "installment_id": "inst-uuid-0002",
    "amount": 50000,
    "notes": "Koreksi penyesuaian biaya administrasi atas arahan keuangan"
  }
  ```
- **Contoh Response Berhasil (`201 Created`):**
  ```json
  {
    "success": true,
    "status": 201,
    "data": {
      "id": "tx-uuid-adj-999",
      "cash_advance_id": "ca-uuid-1111",
      "installment_id": "inst-uuid-0002",
      "transaction_type": "ADJUSTMENT",
      "amount": 50000,
      "transaction_date": "2026-11-20T10:00:00.000Z",
      "reference_id": null,
      "notes": "Koreksi penyesuaian biaya administrasi atas arahan keuangan",
      "created_by": "user-uuid-admin",
      "created_at": "2026-11-20T10:00:00.000Z",
      "employee_id": "emp-uuid-8888",
      "employee_name": "Budi Santoso",
      "employee_nik": "1234567890123456"
    },
    "message": "Cash advance adjustment recorded successfully"
  }
  ```

---

### 16.4. Financial Reconciliation Summary (`GET /api/v1/cash-advances/:id/reconciliation`)

- **Method:** `GET`
- **Path:** `/api/v1/cash-advances/:id/reconciliation`
- **Role:** `OWNER`, `ADMIN`, `EMPLOYEE` (Khusus kasbon miliknya sendiri)
- **Karakteristik & Formula Rekonsiliasi:**
  - Menghitung seluruh transaksi pada buku besar:
    - `total_disbursed` = $\sum \text{amount (DISBURSEMENT)}$
    - `total_repaid` = $\sum \text{amount (REPAYMENT)}$
    - `total_adjusted` = $\sum \text{amount (ADJUSTMENT)}$
    - `outstanding_balance` = $\text{total\_disbursed} - \text{total\_repaid} - \text{total\_adjusted}$
  - Menghitung sisa kewajiban pada jadwal cicilan (`cash_advance_installments`):
    - `installments_outstanding` = $\sum (\text{amount\_due} - \text{amount\_paid})$ untuk termin non-`WAIVED`.
  - Pembuktian Integritas:
    - `is_balanced` bernilai `true` jika dan hanya jika `outstanding_balance === installments_outstanding`.
- **Contoh Request:**
  ```bash
  curl -L "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/cash-advances/ca-uuid-1111/reconciliation&auth_token=YOUR_TOKEN"
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "cash_advance_id": "ca-uuid-1111",
      "employee_id": "emp-uuid-8888",
      "employee_name": "Budi Santoso",
      "employee_nik": "1234567890123456",
      "cash_advance_status": "ACTIVE",
      "approved_amount": 1200000,
      "total_disbursed": 1200000,
      "total_repaid": 550000,
      "total_adjusted": 400000,
      "outstanding_balance": 250000,
      "installments_outstanding": 250000,
      "is_balanced": true,
      "transactions_count": 4,
      "installments_count": 3
    }
  }
  ```

---

## 17. Modul 15: Jejak Forensik & Rekam Mutasi (`audit_logs`)

Modul 15 merupakan modul tabel ke-15 sekaligus modul penutup dari arsitektur 15 tabel HRIS Backend. Berfungsi sebagai jejak audit forensik permanen (_immutable append-only ledger_) yang mencatat setiap peristiwa mutasi (`CREATE`, `UPDATE`, `DELETE`) di seluruh entitas bisnis sistem.

### 17.0. Prinsip Desain & Zero-Trust Security

1. **Immutable Append-Only:** Tidak ada endpoint `POST`, `PUT`, atau `DELETE` publik yang diekspos untuk tabel ini. Record audit ditulis secara atomik oleh internal hooks service. Setiap percobaan mutasi HTTP menghasilkan `404 Not Found`.
2. **Redaksi Otomatis Kredensial Sensitif (Credential Redaction Guard):** Seluruh data pada `old_value` dan `new_value` yang memuat kunci kredensial (`password`, `password_hash`, `old_password`, `new_password`, `auth_token`, `token`, `secret`, `pin`) disanitasi secara rekursif menjadi `"[REDACTED]"`.
3. **Zero-Trust RBAC:** Hanya role `OWNER` dan `ADMIN` yang memiliki izin untuk membaca audit logs. Role `EMPLOYEE` ditolak secara tegas dengan `403 Forbidden`.
4. **Enrichment Aktor & Parsed Diff:** Setiap log diperkaya dengan informasi email dan role pelaku (`actor_email`, `actor_role`), serta `old_value` dan `new_value` di-deserialize menjadi JSON object siap inspeksi.

---

### 17.1. List Audit Logs (`GET /api/v1/audit-logs`)

- **Method:** `GET`
- **Path:** `/api/v1/audit-logs`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak dengan `403 Forbidden`)
- **Query Parameters:**
  - `entity` (string, opsional): Nama entitas/tabel (contoh: `"employees"`, `"users"`, `"shifts"`, `"payroll_periods"`, dll).
  - `actor_user_id` (UUID, opsional): Filter berdasarkan ID user pelaku mutasi.
  - `entity_id` (UUID, opsional): Filter berdasarkan ID record entitas spesifik.
  - `action` (string ENUM, opsional): `"CREATE"`, `"UPDATE"`, `"DELETE"`.
  - `start_date` (date `YYYY-MM-DD`, opsional): Batas awal tanggal UTC log dibuat.
  - `end_date` (date `YYYY-MM-DD`, opsional): Batas akhir tanggal UTC log dibuat.
  - `limit` (integer, opsional, default `50`, max `200`): Ukuran halaman.
  - `offset` (integer, opsional, default `0`): Posisi index mulai.
- **Contoh Request:**
  ```bash
  curl -L "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/audit-logs&entity=users&action=UPDATE&auth_token=YOUR_ADMIN_TOKEN"
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": [
      {
        "id": "aud-uuid-0001",
        "actor_user_id": "usr-uuid-1111",
        "actor_email": "admin@company.com",
        "actor_role": "ADMIN",
        "entity": "users",
        "entity_id": "usr-uuid-2222",
        "action": "UPDATE",
        "old_value": {
          "email": "budi@company.com",
          "role": "EMPLOYEE",
          "password_hash": "[REDACTED]"
        },
        "new_value": {
          "email": "budi@company.com",
          "role": "ADMIN",
          "password_hash": "[REDACTED]"
        },
        "created_at": "2026-11-20T14:30:00.000Z"
      }
    ],
    "meta": {
      "total": 1,
      "limit": 50,
      "offset": 0
    }
  }
  ```

---

### 17.2. Get Audit Log Detail by ID (`GET /api/v1/audit-logs/:id`)

- **Method:** `GET`
- **Path:** `/api/v1/audit-logs/:id`
- **Role:** `OWNER`, `ADMIN` (Role `EMPLOYEE` ditolak dengan `403 Forbidden`)
- **Contoh Request:**
  ```bash
  curl -L "https://script.google.com/macros/s/<SCRIPT_ID>/exec?path=api/v1/audit-logs/aud-uuid-0001&auth_token=YOUR_ADMIN_TOKEN"
  ```
- **Contoh Response Berhasil (`200 OK`):**
  ```json
  {
    "success": true,
    "status": 200,
    "data": {
      "id": "aud-uuid-0001",
      "actor_user_id": "usr-uuid-1111",
      "actor_email": "admin@company.com",
      "actor_role": "ADMIN",
      "entity": "users",
      "entity_id": "usr-uuid-2222",
      "action": "UPDATE",
      "old_value": {
        "email": "budi@company.com",
        "role": "EMPLOYEE",
        "password_hash": "[REDACTED]"
      },
      "new_value": {
        "email": "budi@company.com",
        "role": "ADMIN",
        "password_hash": "[REDACTED]"
      },
      "created_at": "2026-11-20T14:30:00.000Z"
    }
  }
  ```
- **Respons Error Umum:**
  - `401 Unauthorized`: Token otentikasi tidak disediakan atau tidak valid.
  - `403 Forbidden`: Pengguna memiliki role `EMPLOYEE`.
  - `404 Not Found`: ID audit log tidak ditemukan di sheet `audit_logs`.
