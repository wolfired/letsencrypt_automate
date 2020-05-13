#!/bin/env bash

DOMAIN=${1:?}
EMAIL=${email+"--email ${email}"}
EMAIL=${EMAIL:-'--register-unsafely-without-email'}
DRY_RUN=${dry_run+'--dry-run'}
TEST_CERT=${test_cert+'--test-cert'}

DIR_CONFIG=${dir_config:-".dir_config/$DOMAIN"}
DIR_LOGS=${dir_logs:-".dir_logs/$DOMAIN"}
DIR_WORK=${dir_work:-".dir_work/$DOMAIN"}

rm -rf {$DIR_CONFIG,$DIR_LOGS,$DIR_WORK}
mkdir -p {$DIR_CONFIG,$DIR_LOGS,$DIR_WORK}

certbot \
certonly \
--manual \
--preferred-challenges dns \
--server https://acme-v02.api.letsencrypt.org/directory \
$EMAIL \
$DRY_RUN \
$TEST_CERT \
--config-dir ./$DIR_CONFIG \
--logs-dir ./$DIR_LOGS \
--work-dir ./$DIR_WORK \
--non-interactive \
--agree-tos \
--manual-public-ip-logging-ok \
--manual-auth-hook ./manual_auth_hook.sh \
--manual-cleanup-hook ./manual_cleanup_hook.sh \
-d \*.$DOMAIN
