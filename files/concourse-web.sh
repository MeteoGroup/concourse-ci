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

${CONTAINER_DELAY:+sleep "$CONTAINER_DELAY"}
cd "$CONCOURSE_WEB"

for arg in "$@"; do
  case "$arg" in
  --login=*) CONCOURSE_LOGIN="${arg#*=}" ;;
  --password=*) CONCOURSE_PASSWORD="${arg#*=}" ;;
  --github-auth-client-id=*) CONCOURSE_GITHUB_AUTH_CLIENT_ID="${arg#*=}" ;;
  --github-auth-client-secret=*) CONCOURSE_GITHUB_AUTH_CLIENT_SECRET="${arg#*=}" ;;
  --github-auth-organization=*) CONCOURSE_GITHUB_AUTH_ORGANIZATION="${arg#*=}" ;;
  --github-auth-team=*) CONCOURSE_GITHUB_AUTH_TEAM="${arg#*=}" ;;
  --github-auth-user=*) CONCOURSE_GITHUB_AUTH_USER="${arg#*=}" ;;
  --publicly-viewable=*) CONCOURSE_PUBLICLY_VIEWABLE="${arg#*=}" ;;
  --data-source=*) CONCOURSE_DATA_SOURCE="${arg#*=}" ;;
  --worker-pubkey=*) CONCOURSE_WORKER_PUBKEY="${arg#*=}" ;;
  --url=*) CONCOURSE_URL="${arg#*=}" ;;
  esac
done

pg_ctlcluster 9.5 main start

if [ ! -f "$CONCOURSE_WEB/tsa_key" ]; then
  if [ -f "$CONCOURSE_KEYS/tsa_key" ]; then
    echo '--- Using private TSA key from `'"$CONCOURSE_KEYS/tsa_key"'`.'
    cp "$CONCOURSE_KEYS/tsa_key" "$CONCOURSE_WEB/tsa_key"
  else
    echo '--- Generating TSA key pair.'
    ssh-keygen -t ecdsa -b 521 -N '' -f "$CONCOURSE_WEB/tsa_key"
    echo '--- Public TSA key:'
    cat "$CONCOURSE_WEB/tsa_key.pub"
    cp "$CONCOURSE_WEB/tsa_key.pub" "$CONCOURSE_KEYS/tsa_key.pub" 1>&- 2>&- || true
  fi
  chmod 0600 "$CONCOURSE_WEB/tsa_key"
  chown concourse-web "$CONCOURSE_WEB/tsa_key"
fi

if [ ! -f "$CONCOURSE_WEB/session_signing_key" ]; then
  echo '--- Generating session signing key pair.'
  ssh-keygen -t rsa -b 4096 -N '' -f "$CONCOURSE_WEB/session_signing_key"
  chmod 0600 "$CONCOURSE_WEB/session_signing_key"
  chown concourse-web "$CONCOURSE_WEB/session_signing_key"
fi

if [ ! -f "$CONCOURSE_WEB/authorized_worker_keys" ]; then
  if [ ${CONCOURSE_WORKER_PUBKEY:+set} ]; then
    echo '--- Using public worker key from environment.'
    cat <<<"$CONCOURSE_WORKER_PUBKEY" >"$CONCOURSE_WEB/authorized_worker_keys"
    if mv "$CONCOURSE_WEB/authorized_worker_keys" "$CONCOURSE_KEYS/authorized_worker_keys" 1>&- 2>&-; then
      ln -s "$CONCOURSE_KEYS/authorized_worker_keys" "$CONCOURSE_WEB/authorized_worker_keys"
    fi
  elif [ -f "$CONCOURSE_KEYS/authorized_worker_keys" ]; then
    echo '--- Using authorized worker keys from `'"$CONCOURSE_KEYS/authorized_worker_keys"'`.'
    ln -s "$CONCOURSE_KEYS/authorized_worker_keys" "$CONCOURSE_WEB/authorized_worker_keys"
  else
    echo '--- Generating worker key pair.'
    ssh-keygen -t ecdsa -b 521 -N '' -f "$CONCOURSE_WEB/worker_key"
    if ! mv "$CONCOURSE_WEB/worker_key" "$CONCOURSE_KEYS/worker_key" 1>&- 2>&-; then
      echo "--- Private ssh key for worker: "
      cat "$CONCOURSE_WEB/worker_key"
    fi
    if mv "$CONCOURSE_WEB/worker_key.pub" "$CONCOURSE_KEYS/authorized_worker_keys" 1>&- 2>&-; then
      ln -s "$CONCOURSE_KEYS/authorized_worker_keys" "$CONCOURSE_WEB/authorized_worker_keys"
    else
      mv "$CONCOURSE_WEB/worker_key.pub" "$CONCOURSE_WEB/authorized_worker_keys"
    fi
  fi
fi

auth_args=()
if [ ! -z ${CONCOURSE_GITHUB_AUTH_CLIENT_ID:+x} ]; then
  echo '--- Using GitHub authentication.'
  auth_args+=(--github-auth-client-id "${CONCOURSE_GITHUB_AUTH_CLIENT_ID}")
  auth_args+=(--github-auth-client-secret "${CONCOURSE_GITHUB_AUTH_CLIENT_SECRET}")

  if [ ! -z ${CONCOURSE_GITHUB_AUTH_ORGANIZATION:+x} ]; then
    auth_args+=(--github-auth-organization "${CONCOURSE_GITHUB_AUTH_ORGANIZATION}")
  fi
  if [ ! -z ${CONCOURSE_GITHUB_AUTH_TEAM:+x} ]; then
    auth_args+=(--github-auth-team "${CONCOURSE_GITHUB_AUTH_TEAM}")
  fi
  if [ ! -z ${CONCOURSE_GITHUB_AUTH_USER:+x} ]; then
    auth_args+=(--github-auth-user "${CONCOURSE_GITHUB_AUTH_USER}")
  fi
else
  echo '--- Using HTTP basic authentication.'
  auth_args+=(--basic-auth-username "${CONCOURSE_LOGIN:-concourse}")
  auth_args+=(--basic-auth-password "${CONCOURSE_PASSWORD:-ci}")
fi

if [ ! -z ${CONCOURSE_PUBLICLY_VIEWABLE:+x} ]; then
  echo '--- Enabling public viewing of pipelines.'
  auth_args+=(--publicly-viewable)
fi

exec su concourse-web -s /usr/local/bin/concourse -- web \
    "${auth_args[@]}" \
    --session-signing-key "$CONCOURSE_WEB/session_signing_key" \
    --tsa-host-key "$CONCOURSE_WEB/tsa_key" \
    --tsa-authorized-keys "$CONCOURSE_WEB/authorized_worker_keys" \
    --postgres-data-source "${CONCOURSE_DATA_SOURCE:-postgres://concourse:ci@localhost/concourse}" \
    ${CONCOURSE_URL:+--external-url "${CONCOURSE_URL}"}
