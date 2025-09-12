#!/bin/sh
# runit service to start standalone gRPC server
set -eu
cd /home/app/webapp || exit 1
export BUNDLE_GEMFILE=/home/app/webapp/Gemfile
# Respect production defaults; allow insecure channel by default unless overridden
: "${GRPC_ALLOW_INSECURE:=true}"
# Don't attempt to start integrated server inside Rails web process
export GRPC_ENABLE_INTEGRATED=false

# Loop until the instance setting enables gRPC to avoid runit restart flapping
while :; do
    enabled=$(chpst -u app:app bundle exec rails runner 'begin; puts(LibreverseInstance::Application.grpc_enabled? ? "1" : "0"); rescue => e; warn e.message; puts "1"; end') || true
    if [ "$enabled" = "1" ]; then
        # If insecure is disabled, ensure SSL cert/key are present to avoid immediate exit
        if [ "${GRPC_ALLOW_INSECURE:-}" != "true" ]; then
            if [ ! -f "${GRPC_SSL_CERT_PATH:-}" ] || [ ! -f "${GRPC_SSL_KEY_PATH:-}" ]; then
                echo "[runit/grpc] SSL required but GRPC_SSL_CERT_PATH/GRPC_SSL_KEY_PATH missing; sleeping"
                sleep 30
                continue
            fi
        fi
    # Require the gRPC server file explicitly since app/grpc is excluded from autoload paths
    exec chpst -u app:app bundle exec rails runner 'require Rails.root.join("app/grpc/grpc_server"); Libreverse::GrpcServer.new.start'
    fi
    echo "[runit/grpc] gRPC disabled by instance setting; sleeping before retry"
    sleep 30
done
