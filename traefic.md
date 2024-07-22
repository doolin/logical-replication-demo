
# Traefik HTTPS Setup on Docker

This guide details setting up Traefik as a load balancer with HTTPS support on Docker.

## Step 1: Generate Self-Signed Certificates
Generate self-signed SSL certificates using `openssl`. Run the script:
```
./generate_certs.sh
```

## Step 2: Update Traefik Configuration
Update the Traefik configuration to include HTTPS settings. See `traefik.yml`.

## Step 3: Run Traefik with HTTPS Configurations
Use the Docker command provided in `run_traefik.sh` to start Traefik.

## Step 4: Update Application Labels for HTTPS
Ensure your application is configured for HTTPS in the Docker run command.

## Step 5: Test HTTPS Configuration
Access your application using HTTPS to verify the SSL setup.
```
https://whoami.local
```

## Adding Let’s Encrypt Support (Production)
For Let's Encrypt SSL handling, update the `traefik.yml` with the ACME configuration.

### Files
- `traefik.yml`: Traefik configuration file.
- `scripts/docker/rum/traefik.sh`: Script to run Traefik in Docker.
- `generate_certs.sh`: Script to generate self-signed certificates.
