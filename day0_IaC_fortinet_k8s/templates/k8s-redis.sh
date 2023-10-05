#!/bin/bash
# -------------------------------------------------------------------------------------------------------------
# User-data script to configure a Redis DB
#
# jvigueras@fortinet.com
# -------------------------------------------------------------------------------------------------------------
# Install Redis
apt update -y
apt-get install -y redis

# Allow access from anywhere and set password
sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
sh -c "echo 'requirepass ${db_pass}' >> /etc/redis/redis.conf"
systemctl restart redis-server

# Export Redis to AWS SSM
cat << EOF > export-redis-to-ssm.py
${script}
EOF

# Add crontab job
crontab -l | { cat; echo "*/2 * * * * /usr/bin/python3 ./export-redis-to-ssm.py"; }