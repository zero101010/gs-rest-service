#!/bin/bash
set -euo pipefail

# ── Install Docker ────────────────────────────────────────────────────────────
dnf install -y docker
systemctl enable --now docker

# ── Create the deploy user (Docker management only, no sudo) ──────────────────
useradd -m -s /bin/bash deploy
usermod -aG docker deploy          # docker group = only privilege granted

# ── Authorise the GitHub Actions SSH key ─────────────────────────────────────
mkdir -p /home/deploy/.ssh
echo "${deploy_public_key}" > /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys

# ── Harden SSH: key-pair only, no passwords ───────────────────────────────────
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/'           /etc/ssh/sshd_config
sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/'               /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/'                         /etc/ssh/sshd_config

systemctl restart sshd

# ── Install Nginx ─────────────────────────────────────────────────────────────
dnf install -y nginx
systemctl enable nginx

# ── Install Certbot with Route53 DNS plugin ───────────────────────────────────
dnf install -y python3-pip augeas-libs
pip3 install certbot certbot-dns-route53

# ── Initial Nginx config (HTTP only — serves while cert is being issued) ──────
cat > /etc/nginx/conf.d/app.conf << 'EOF'
server {
    listen 80;
    server_name ${domain};

    location / {
        proxy_pass         http://localhost:777;
        proxy_http_version 1.1;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }
}
EOF

systemctl start nginx

# ── Obtain TLS certificate via Route53 DNS challenge ─────────────────────────
certbot certonly \
  --dns-route53 \
  --non-interactive \
  --agree-tos \
  --email "${certbot_email}" \
  -d "${domain}"

# ── Final Nginx config: HTTPS with redirect from HTTP ─────────────────────────
cat > /etc/nginx/conf.d/app.conf << 'EOF'
server {
    listen 80;
    server_name ${domain};
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name ${domain};

    ssl_certificate     /etc/letsencrypt/live/${domain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${domain}/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        proxy_pass         http://localhost:777;
        proxy_http_version 1.1;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }
}
EOF

nginx -s reload

# ── Auto-renew certificate (runs daily at noon) ───────────────────────────────
echo "0 12 * * * root certbot renew --quiet --dns-route53 && nginx -s reload" > /etc/cron.d/certbot-renew
