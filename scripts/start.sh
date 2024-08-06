#!/bin/sh

# Check variables DUCKDNS_TOKEN, DUCKDNS_DOMAIN, KEY_TYPE, KEY_SIZE
if [ -z "$DUCKDNS_TOKEN" ] || [ "$DUCKDNS_TOKEN" = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" ]; then
    echo "ERROR: Variable DUCKDNS_TOKEN is unset"
    exit 1
fi

if [ -z "$DUCKDNS_DOMAIN" ]; then
    echo "ERROR: Variable DUCKDNS_DOMAIN is unset"
    exit 1
fi

if [ -z "$KEY_TYPE" ]; then
    echo "ERROR: Variable KEY_TYPE is unset"
    exit 1
fi

if [ -z "$KEY_SIZE" ]; then
    echo "ERROR: Variable KEY_SIZE is unset"
    exit 1
fi
# Print email notice if applicable
if [ -z "$LETSENCRYPT_EMAIL" ]; then
    echo "WARNING: You will not receive SSL certificate expiration notices"
fi

# Set LETSENCRYPT_DOMAIN to DUCKDNS_DOMAIN if not specified
if [ -z "$LETSENCRYPT_DOMAIN" ]; then
    echo "INFO: LETSENCRYPT_DOMAIN is unset, using DUCKDNS_DOMAIN"
    LETSENCRYPT_DOMAIN=$DUCKDNS_DOMAIN
fi

# Set certificate url based on LETSENCRYPT_WILDCARD value
if [ "$LETSENCRYPT_WILDCARD" = "true" ]; then
    echo "INFO: A wildcard SSL certificate will be created"
    LETSENCRYPT_DOMAIN="*.$LETSENCRYPT_DOMAIN"
else
    LETSENCRYPT_WILDCARD="false"
fi

# Set user and group ID's for files
if [ -z "$UID" ]; then
    echo "INFO: No UID specified, using root UID of 0"
    UID=0
fi

if [ -z "$GID" ]; then
    echo "INFO: No GID specified, using root GID of 0"
    GID=0
fi

# Print variables
echo "DUCKDNS_TOKEN: $DUCKDNS_TOKEN"
echo "DUCKDNS_DOMAIN: $DUCKDNS_DOMAIN"
echo "LETSENCRYPT_KEY_TYPE: $KEY_TYPE"
echo "LETSENCRYPT_KEY_SIZE: $KEY_SIZE"
echo "LETSENCRYPT_DOMAIN: $LETSENCRYPT_DOMAIN"
echo "LETSENCRYPT_EMAIL: $LETSENCRYPT_EMAIL"
echo "LETSENCRYPT_WILDCARD: $LETSENCRYPT_WILDCARD"
echo "TESTING: $TESTING"
echo "UID: $UID"
echo "GID: $GID"

if [ -z "$LETSENCRYPT_EMAIL" ]; then
    EMAIL_PARAM="" #"--register-unsafely-without-email"
else
    EMAIL_PARAM="--email $LETSENCRYPT_EMAIL" #"-m $LETSENCRYPT_EMAIL --no-eff-email"
fi

if [ "$TESTING" = "true" ]; then
    echo "INFO: Generating staging certificate"
    TEST_PARAM="--test-cert"
else
    unset TEST_PARAM
fi

# Create certificates
for DOMAIN in $(echo $LETSENCRYPT_DOMAIN | tr "," "\n"); do
    certbot certonly \
        --non-interactive \
        --agree-tos \
        --key-type ${KEY_TYPE} --rsa-key-size ${KEY_SIZE} \
        --preferred-challenges dns \
        --authenticator dns-duckdns \
        --dns-duckdns-token ${DUCKDNS_TOKEN} \
        --dns-duckdns-propagation-seconds 60 \
        --dns-duckdns-no-txt-restore \
        $EMAIL_PARAM \
        -d ${LETSENCRYPT_DOMAIN}

    chown -R $UID:$GID /etc/letsencrypt

    # Check for successful certificate generation
    if [ ! -d "/etc/letsencrypt/live/${DOMAIN#\*\.}" ] || \
        [ ! -f "/etc/letsencrypt/live/${DOMAIN#\*\.}/fullchain.pem" ] || \
        [ ! -f "/etc/letsencrypt/live/${DOMAIN#\*\.}/privkey.pem" ]; then
        echo "ERROR: Failed to create SSL certificates"
        exit 1
    fi

    ./deploy.sh
done

# Check if certificates require renewal twice a day
while :; do
    # Wait for a random period within the next 12 hours
    LETSENCRYPT_DELAY=$(shuf -i 1-720 -n 1)
    echo "Sleeping for $(($LETSENCRYPT_DELAY / 60)) hour(s) and $(($LETSENCRYPT_DELAY % 60)) minute(s)"
    sleep $((${LETSENCRYPT_DELAY} * 60)) # Convert to seconds

    echo "INFO: Attempting SSL certificate renewal"
    certbot renew --deploy-hook /scripts/deploy.sh
    chown -R $UID:$GID /etc/letsencrypt
done
