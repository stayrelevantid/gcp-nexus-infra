# GCP-Nexus-Infra 🚀

Repository ini berisi infrastruktur berbasis **Terraform** untuk mendeploy arsitektur Hybrid-Env GCP yang terdiri dari environment `Dev` dan `Prod`, serta VPC Peering di antara keduanya.

---

## 🚦 Langkah-Langkah Eksekusi

### 1. Fase 1: Persiapan Dasar (Eksekusi Lokal di Laptop Anda)
Jalankan script `fase1-setup.sh` untuk membuat Service Account, mengaktifkan API GCP, dan membuat GCS Bucket untuk menyimpan State Terraform.
```bash
# Pastikan Anda sudah login ke GCP
gcloud auth login
gcloud config set project [PROJECT_ID_ANDA]

# Jalankan script
chmod +x fase1-setup.sh
./fase1-setup.sh
```

**Penting:**
1. Catat nama GCS Bucket yang muncul (misal: `nexus-tf-state-12345`).
2. Script akan menghasilkan file `credentials.json` (Jangan di-commit ke Git).

---

### 2. Fase 2: Update Variabel Terraform
Buka file-file berikut dan gantilah `YOUR_PROJECT_ID` dengan Project ID GCP Anda sesungguhnya:
- `dev/terraform.tfvars`
- `prod/terraform.tfvars`
- `peering/terraform.tfvars`

**Mengaktifkan Remote State:**
Buka file `dev/main.tf`, `prod/main.tf`, dan `peering/main.tf`. Uncomment bagian `backend "gcs"` dan masukkan nama GCS Bucket Anda:
```hcl
  backend "gcs" {
    bucket = "nexus-tf-state-PROJECT_ID" # Ganti ini!
    prefix = "env/dev" # (atau prod/peering)
  }
```

---

### 3. Fase 3: Deploy Environment Secara Berurutan
Karena eksekusi saat ini bersifat lokal, kita bisa menggunakan Application Default Credentials (ADC) agar tidak bergantung pada JSON Key (Best Practice keamanan).

Jalankan perintah ini sekali saja di terminal Anda sebelum mengeksekusi Terraform:
```bash
gcloud auth application-default login
```

**A. Deploy Dev**
```bash
cd dev
terraform init
terraform apply
cd ..
```

**B. Deploy Prod**
```bash
cd prod
terraform init
terraform apply
cd ..
```

**C. Deploy Peering (Penghubung Dev & Prod)**
```bash
cd peering
terraform init
terraform apply
cd ..
```

---

### 4. Fase 4: Validasi Manual & Eksekusi IAP
1. Cek VM Instances di Google Cloud Console. Anda tidak akan melihat Public IP (karena kita menggunakan Private VM).
2. SSH ke VM menggunakan **IAP** (Identity-Aware Proxy):
   ```bash
   gcloud compute ssh vm-dev --zone=asia-southeast2-a --tunnel-through-iap --project=[PROJECT_ID]
   ```
3. Lakukan **Ping/Curl** ke internal IP VM Prod dari VM Dev untuk membuktikan VPC Peering berhasil.

---

### 5. Fase 5: CI/CD Keyless dengan Workload Identity Federation (WIF)
Karena penggunaan JSON Key telah diblokir secara organisasi (untuk keamanan), kita menggunakan **WIF** agar GitHub Actions bisa masuk ke Google Cloud API tanpa password.

1. Buka folder `wif/` dan ubah variabel `github_repo` di file `wif/terraform.tfvars` dengan repository GitHub Anda (contoh: `octocat/my-repo`).
2. Jalankan eksekusi Terraform untuk membuat infrastruktur WIF:
   ```bash
   cd wif
   terraform init
   terraform apply
   cd ..
   ```
3. **Penting:** Catat output `workload_identity_provider_name` di bagian akhir proses _apply_.
4. Buka file `.github/workflows/terraform.yml` dan paste Output tersebut ke bagian `workload_identity_provider` di dua tempat (untuk Dev dan Prod).
5. Lakukan Commit dan Push ke GitHub. Pipeline Terraform akan otomatis berjalan tanpa memerlukan secret tambahan!

---

### 6. Fase Tambahan: Membersihkan Lingkungan (Cleanup)
Jika proyek ini ditujukan untuk evaluasi atau simulasi Terraform saja (agar tidak ditagih biaya oleh Google Cloud secara terus-menerus), pastikan Anda menghancurkan semua resource.

**Aturan Emas:** _Penghapusan objek harus dilakukan dari yang terakhir kali dibuat ke awal!_
Jalankan perintah ini berurutan di terminal lokal Anda:

1. Modul Peering:
   ```bash
   cd peering && terraform destroy -auto-approve
   ```
2. Modul Prod:
   ```bash
   cd ../prod && terraform destroy -auto-approve
   ```
3. Modul Dev:
   ```bash
   cd ../dev && terraform destroy -auto-approve
   ```
4. Modul Security (WIF):
   ```bash
   cd ../wif && terraform destroy -auto-approve
   ```
> ⚠️ **Peringatan**: Setelah ini dijalankan, seluruh VM, Jaringan, Router, dan Koneksi GitHub-GCP akan dicabut.
