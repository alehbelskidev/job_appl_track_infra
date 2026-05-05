#!/bin/bash
set -e

CLUSTER="job-tracker"
NAMESPACE="job-tracker"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔨 Building API..."
docker build -f "$SCRIPT_DIR/../../job_appl_track/Dockerfile.prod" \
	-t job-tracker-api:latest \
	"$SCRIPT_DIR/../../job_appl_track"

echo "🔨 Building Web..."
docker build -f "$SCRIPT_DIR/../../job_appl_track_web/Dockerfile.prod" \
	-t job-tracker-web:latest \
	"$SCRIPT_DIR/../../job_appl_track_web"

echo "📦 Importing images into k3d..."
k3d image import job-tracker-api:latest -c $CLUSTER
k3d image import job-tracker-web:latest -c $CLUSTER

echo "🔄 Restarting deployments..."
kubectl rollout restart deployment/api -n $NAMESPACE
kubectl rollout restart deployment/web -n $NAMESPACE

echo "⏳ Waiting for rollout..."
kubectl rollout status deployment/api -n $NAMESPACE
kubectl rollout status deployment/web -n $NAMESPACE

echo "✅ Done"
