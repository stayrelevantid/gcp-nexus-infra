#!/bin/bash

# Script Eksekusi Fase 1: Persiapan Dasar (Foundational) GCP

set -e

# Mengambil Project ID yang saat ini aktif di gcloud
PROJECT_ID=$(gcloud config get-value project)
echo "🚀 Menggunakan GCP Project: $PROJECT_ID"

BUCKET_NAME="nexus-tf-state-${PROJECT_ID}"
SA_NAME="terraform-nexus"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "------------------------------------------------------"
echo "✅ 1. Mengaktifkan APIs (Compute & Network Management)..."
gcloud services enable compute.googleapis.com networkmanagement.googleapis.com cloudresourcemanager.googleapis.com

echo "------------------------------------------------------"
echo "✅ 2. Membuat GCS Bucket untuk State Terraform: gs://$BUCKET_NAME"
gcloud storage buckets create gs://$BUCKET_NAME \
    --location=asia-southeast2 \
    --uniform-bucket-level-access || echo "Bucket mungkin sudah ada, melanjutkkan..."

# Mengaktifkan Object Versioning (supaya aman bila state rusak)
gcloud storage buckets update gs://$BUCKET_NAME --versioning

echo "------------------------------------------------------"
echo "✅ 3. Membuat Service Account: $SA_NAME"
gcloud iam service-accounts create $SA_NAME \
    --display-name="Terraform Nexus Admin" || echo "Service account mungkin sudah ada, melanjutkan..."

echo "------------------------------------------------------"
echo "✅ 4. Memberikan Role IAM ke Service Account..."
ROLES=(
    "roles/compute.admin" 
    "roles/compute.networkAdmin" 
    "roles/storage.admin"
)

for ROLE in "${ROLES[@]}"; do
  echo "Menambahkan role $ROLE..."
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="${ROLE}" \
    --condition=None
done

echo "------------------------------------------------------"
echo "✅ 5. Membuat JSON Key Credentials..."
if [ -f "credentials.json" ]; then
    echo "File credentials.json sudah ada, tidak akan menimpa."
else
    if gcloud iam service-accounts keys create ./credentials.json --iam-account=$SA_EMAIL; then
        echo "🔑 Kunci Service Account berhasil disimpan di ./credentials.json (JANGAN DI-COMMIT KE GIT!)"
    else
        echo "⚠️  Pembuatan JSON Key diblokir oleh Organization Policy (Best Practice)." 
        echo "💡 Tidak masalah! Untuk eksekusi lokal kita akan menggunakan Application Default Credentials (ADC)."
    fi
fi

echo "------------------------------------------------------"
echo "🎉 Fase 1 SELESAI!"
echo "Bucket name yang harus Anda taruh di file backend terraform: $BUCKET_NAME"
