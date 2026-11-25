# HRIS API Conventions & Specifications

**Target Audience:** Mobile Flutter Developers & Backend Maintainers  
**Platform Infrastructure:** Cloudflare Workers (V8 Edge Runtime) & Hono Framework  
**Database Storage:** Turso Database (libSQL / SQLite)  
**Document Version:** 2.0.0 (Migrated from Legacy)

---

## 1. Overview & Cloudflare Workers Edge Runtime

Backend HRIS berjalan di atas jaringan global **Cloudflare Workers** menggunakan framework **Hono**. Seluruh permintaan diproses di server edge terdekat dengan latensi minimal dan mendukung protokol RESTful modern secara penuh.

Berbeda dengan arsitektur serverless generasi lama, backend ini mendukung:

1. **HTTP Headers Penuh:** Mendukung header HTTP standar seperti `Authorization: Bearer <TOKEN>`, `Content-Type: application/json`, `X-Idempotency-Key`, dll.
2. **REST Verbs Native:** Mendukung metode HTTP standar murni (`GET`, `POST`, `PUT`, `DELETE`).
3. **Backward Compatibility Layer:** Tetap mendukung fallback pengiriman token via query parameter `?auth_token=...` atau body payload `auth_token`, serta tunneling method via `_method: "PUT"` / `_method: "DELETE"` untuk kompatibilitas klien Flutter.

---

## 2. Base URL & Routing

### Base URL

```text
https://hris-backend-worker.<subdomain>.workers.dev
```

### Mekanisme Routing REST

Seluruh routing menggunakan path URL RESTful standar:

```text
GET  https://hris-backend-worker.<subdomain>.workers.dev/api/v1/health
POST https://hris-backend-worker.<subdomain>.workers.dev/api/v1/auth/login
GET  https://hris-backend-worker.<subdomain>.workers.dev/api/v1/employees
```

---

## 3. Standar Autentikasi & Pengiriman Metadata

### A. Autentikasi Standar (Direkomendasikan)

Gunakan header HTTP standar:

```http
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

### B. Backward Compatibility (Legacy Fallback)

Untuk klien mobile dengan konfigurasi lama:

1. **Pada Permintaan GET:** Token dapat dikirimkan melalui query parameter:
   ```text
   GET /api/v1/employees?auth_token=<JWT_TOKEN>&limit=20&offset=0
   ```
2. **Pada Permintaan POST / PUT / DELETE:** Token dapat disertakan dalam JSON body envelope:
   ```json
   {
     "auth_token": "<JWT_TOKEN>",
     "_method": "PUT",
     "name": "Budi Santoso",
     "phone": "081234567890",
     "department": "Engineering"
   }
   ```

---

## 4. HTTP Method Override Support

Backend mendukung metode HTTP standar murni (`GET`, `POST`, `PUT`, `DELETE`). Namun jika terdapat jaringan atau klien dengan firewall yang membatasi selain `GET` dan `POST`, backend mendukung simulasi method override:

| Operasi Target      | Method HTTP Aktual   | Lokasi `_method`                                          |
| ------------------- | -------------------- | --------------------------------------------------------- |
| Read / Query        | `GET`                | —                                                         |
| Create Data         | `POST`               | (Tanpa `_method`)                                         |
| Update Seluruh Data | `PUT` atau `POST`    | Body: `"_method": "PUT"` atau Query: `?_method=PUT`       |
| Update Sebagian     | `PATCH` atau `POST`  | Body: `"_method": "PATCH"` atau Query: `?_method=PATCH`   |
| Delete Data         | `DELETE` atau `POST` | Body: `"_method": "DELETE"` atau Query: `?_method=DELETE` |

---

## 5. Format Response API

Format response bersifat **100% konsisten** di seluruh 15 modul:

### A. Response Sukses (200 OK / 201 Created)

```json
{
  "success": true,
  "status": 200,
  "data": {
    "id": "c85025a1-7785-45d2-a7d0-7ec837136005",
    "nik": "3201012304900001",
    "name": "Budi Santoso",
    "email": "budi@company.com",
    "department": "Engineering"
  },
  "meta": {
    "message": "Success",
    "timestamp": "2026-11-23T10:14:41.000Z"
  }
}
```

### B. Response Sukses dengan Pagination

```json
{
  "success": true,
  "status": 200,
  "data": [ ... ],
  "meta": {
    "message": "Success",
    "timestamp": "2026-11-23T10:14:41.000Z",
    "total": 128,
    "limit": 20,
    "offset": 0
  }
}
```

### C. Response Error (400, 401, 403, 404, 409, 500)

```json
{
  "success": false,
  "status": 400,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed for employee data",
    "details": [
      { "field": "nik", "message": "nik must be exactly 16 numeric digits" }
    ]
  },
  "meta": {
    "timestamp": "2026-11-23T10:14:41.000Z"
  }
}
```

---

## 6. Standar Kode Error HTTP

| Kode HTTP          | Error Code                          | Deskripsi                                                                                                          |
| ------------------ | ----------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `400 Bad Request`  | `VALIDATION_ERROR`                  | Format body JSON tidak valid, field wajib hilang, atau aturan domain dilanggar                                     |
| `401 Unauthorized` | `UNAUTHORIZED` / `INVALID_TOKEN`    | Token JWT tidak ada, kadaluarsa, salah tanda tangan, atau akun dinonaktifkan                                       |
| `403 Forbidden`    | `FORBIDDEN`                         | Akun aktif tetapi tidak memiliki role yang diizinkan (RBAC) atau mencoba mengakses data milik karyawan lain (IDOR) |
| `404 Not Found`    | `NOT_FOUND`                         | Record dengan ID target tidak ditemukan di database                                                                |
| `409 Conflict`     | `DUPLICATE_ENTRY` / `INVALID_STATE` | Pelanggaran unique constraint (NIK duplikat, check-in ganda, atau status transisi tidak valid)                     |
| `500 Server Error` | `INTERNAL_SERVER_ERROR`             | Kesalahan internal server yang tidak tertangani                                                                    |
