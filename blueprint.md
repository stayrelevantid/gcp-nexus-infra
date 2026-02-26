# Blueprint Final: Arsitektur "GCP Hybrid-Env Backbone"

Proyek ini kita namai secara internal: **GCP-Nexus-Infra**.

## 1. Spesifikasi Teknis

- **VPC Mode**: Custom (untuk kontrol penuh IP).
- **IP Planning**:
  - **Prod**: `10.1.0.0/24`
  - **Dev**: `10.2.0.0/24`
- **Keamanan**: Private-only (No Public IP), IAP for SSH, Cloud NAT for Egress.
- **OS/App**: Ubuntu 22.04 LTS + Nginx.
- **State Management**: GCS Bucket dengan state locking.

### Struktur Folder Definitif
```plaintext
gcp-nexus-infra/
├── .github/workflows/    # CI/CD: Pipeline Terraform (OIDC)
├── modules/
│   └── networking/       # Modul VPC, NAT, VM, Firewall, Labels
├── prod/                 # Env: Production
├── dev/                  # Env: Development
├── peering/              # Interconnect & Connectivity Tests
└── wif/                  # Workload Identity Federation (GitHub Actions)
```

## 2. Fase Eksekusi (The Execution Roadmap)

Agar aman dan sistematis, eksekusi dibagi menjadi 4 fase utama:

### Fase 1: Persiapan Dasar (Foundational)
Fase ini memastikan "rumah" untuk Terraform sudah siap.

- **GCP Project Setup**: Buat atau pilih project di GCP.
- **State Storage**: Buat GCS Bucket (misal: `gs://nexus-tf-state-123`). Aktifkan fitur versioning pada bucket ini agar file state lama bisa dipulihkan jika ada kesalahan.
- **Service Account**: Buat Service Account dengan role Compute Admin, Network Admin, dan Storage Admin. Download JSON key-nya.
- **API Activation**: Pastikan API `compute.googleapis.com` dan `networkmanagement.googleapis.com` sudah aktif.

### Fase 2: Pembangunan Modul & Environment (Core Construction)
Fase ini adalah saat Anda mulai menulis dan mengetes kode.

- **Drafting Modules**: Buat modul networking agar konfigurasi Prod dan Dev konsisten. Masukkan variabel labels untuk Cost Management.
- **Deploy Dev**: Jalankan `terraform apply` pada folder `dev/`.
- **Deploy Prod**: Jalankan `terraform apply` pada folder `prod/`.
- **Verifikasi Nginx**: Masuk via IAP SSH dan pastikan Nginx sudah berjalan di IP internal masing-masing (`systemctl status nginx`).

### Fase 3: Interkoneksi & Validasi (Connectivity)
Fase untuk menyambungkan dua dunia yang terpisah.

- **VPC Peering**: Jalankan folder `peering/`. Pastikan kedua VPC saling "melihat" satu sama lain.
- **Connectivity Test**: Jalankan simulasi paket data dari Google Cloud Console.
  - **Test 1**: VM-Prod ke VM-Dev (Port 80).
  - **Test 2**: VM ke Google API (Private Google Access).
- **Manual Curl**: Pastikan VM Prod bisa menarik halaman HTML dari VM Dev menggunakan `curl`.

### Fase 4: Otomatisasi & Tata Kelola (Governance)
Fase untuk menyerahkan kontrol ke sistem CI/CD secara temporer atau _review_ lokal.

- **Git Integration**: Push kode ke GitHub.
- **Labeling Audit**: Cek di Billing Report GCP apakah label `environment:prod` dan `environment:dev` sudah muncul untuk memantau biaya.

### Fase 5: CI/CD Security (Workload Identity Federation)
Fase tambahan (Best Practice) untuk mengamankan integrasi GitHub Actions ke GCP tanpa menggunakan JSON Key yang rentan bocor.

- **WIF Setup**: Jalankan Terraform di folder `wif/` untuk membuat Identity Pool dan Provider.
- **Keyless CI/CD**: Konfigurasi GitHub Actions (`.github/workflows/terraform.yml`) menggunakan nilai `workload_identity_provider_name` dari output fase ini.
- **PR Policy**: Tetapkan aturan bahwa setiap perubahan ke `main` (Prod) wajib melalui Review dan pipeline Terraform otomatis _run_.

### Fase 6: Cleanup (Opsional)
Jika infrastruktur ini hanya dibangun untuk simulasi/latihan, pastikan semua *resource* dihapus agar tidak memakan biaya GCP.

- Menghancurkan _resources_ harus dilakukan secara berurutan *(Reverse Order)* dari yang terakhir dibuat menuju yang pertama:
  1. `cd peering && terraform destroy -auto-approve`
  2. `cd prod && terraform destroy -auto-approve`
  3. `cd dev && terraform destroy -auto-approve`
  4. `cd wif && terraform destroy -auto-approve`

## 3. Penutup Brainstorming

Blueprint GCP-Nexus-Infra ini sudah siap untuk diimplementasikan. Anda memulai dari infrastruktur yang "kecil" (single region), namun dengan fondasi modular yang sangat mudah jika ingin diekspansi menjadi multi-region atau multi-project di masa depan.

**Langkah kecil pertama Anda:** Buatlah GCS Bucket untuk remote state. Begitu bucket itu ada, kode Terraform pertama Anda sudah punya tempat tinggal yang aman.