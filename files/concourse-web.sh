#!/bin/bash -e
#
# Copyright 2016 MeteoGroup Deutschland GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

pg_ctlcluster 9.5 main start
cd "$CONCOURSE_WEB"

if [ -f "$CONCOURSE_KEYS/tsa_key" ]; then
  echo '--- Using private TSA key from `'"$CONCOURSE_KEYS/tsa_key"'`.'
  cp "$CONCOURSE_KEYS/tsa_key" "$CONCOURSE_WEB/tsa_key"
else
  echo '--- Generating TSA key pair.'
  ssh-keygen -t ecdsa -b 521 -N '' -f "$CONCOURSE_WEB/tsa_key"
  echo '--- Public TSA key:'
  cat "$CONCOURSE_WEB/tsa_key.pub"
fi
chmod 0600 "$CONCOURSE_WEB/tsa_key"
chown concourse-web "$CONCOURSE_WEB/tsa_key"

if [ -f "$CONCOURSE_KEYS/session_signing_key" ]; then
  echo '--- Using session signing key from `'"$CONCOURSE_KEYS/session_signing_key"'`.'
  cp "$CONCOURSE_KEYS/session_signing_key" "$CONCOURSE_WEB/session_signing_key"
else
  echo '--- Generating session signing key pair.'
  ssh-keygen -t rsa -b 4096 -N '' -f "$CONCOURSE_WEB/session_signing_key"
fi
chmod 0600 "$CONCOURSE_WEB/session_signing_key"
chown concourse-web "$CONCOURSE_WEB/session_signing_key"

if [ ${CONCOURSE_WORKER_PUBKEY:+set} ]; then
  echo '--- Using public worker key from environment.'
  cat <<<"$CONCOURSE_WORKER_PUBKEY" >"$CONCOURSE_WEB/authorized_worker_keys"
elif [ -f "$CONCOURSE_KEYS/authorized_worker_keys" ]; then
  echo '--- Using authorized worker keys from `'"$CONCOURSE_KEYS/authorized_worker_keys"'`.'
  cp "$CONCOURSE_KEYS/authorized_worker_keys" "$CONCOURSE_WEB/authorized_worker_keys"
elif [ -f "$CONCOURSE_KEYS/worker_key.pub" ]; then
  echo '--- Using authorized worker keys from `'"$CONCOURSE_KEYS/worker_key.pub"'`.'
  cp "$CONCOURSE_KEYS/worker_key.pub" "$CONCOURSE_WEB/authorized_worker_keys"
else
  echo '--- Generating worker key pair.'
  ssh-keygen -t ecdsa -b 521 -N '' -f "$CONCOURSE_WEB/worker_key"
  echo "--- Private ssh key for worker: "
  cat $CONCOURSE_WEB/worker_key
  rm $CONCOURSE_WEB/worker_key
  mv worker_key.pub "$CONCOURSE_WEB/authorized_worker_keys"
fi
chmod 0600 "$CONCOURSE_WEB/authorized_worker_keys"
chown concourse-web "$CONCOURSE_WEB/authorized_worker_keys"

exec su concourse-web -s /usr/local/bin/concourse -- web \
    --basic-auth-username "${CONCOURSE_LOGIN:-concourse}" \
    --basic-auth-password "${CONCOURSE_PASSWORD:-ci}" \
    --session-signing-key "$CONCOURSE_WEB/session_signing_key" \
    --tsa-host-key "$CONCOURSE_WEB/tsa_key" \
    --tsa-authorized-keys "$CONCOURSE_WEB/authorized_worker_keys" \
    --postgres-data-source "${CONCOURSE_DATA_SOURCE:-postgres://concourse:ci@localhost/concourse}" \
    ${CONCOURSE_URL:+--external-url "${CONCOURSE_URL}"}
