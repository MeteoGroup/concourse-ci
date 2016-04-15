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
cd "$CONCOURSE"

for arg in "$@"; do
  case "$arg" in
  --tsa-host=*) CONCOURSE_TSA_HOST="${arg#*=}" ;;
  --tsa-port=*) CONCOURSE_TSA_PORT="${arg#*=}" ;;
  --tsa-pubkey=*) CONCOURSE_TSA_PUBKEY="${arg#*=}" ;;
  --worker-key=*) CONCOURSE_WORKER_KEY="${arg#*=}" ;;
  esac
done

if [ ! -f "$CONCOURSE/tsa_key.pub" ]; then
  if [ ${CONCOURSE_TSA_PUBKEY:+set} ]; then
    echo 'Using public TSA key from environment.'
    cat <<<"$CONCOURSE_TSA_PUBKEY" >"$CONCOURSE/tsa_key.pub"
  elif [ -f "$CONCOURSE_KEYS/tsa_key.pub" ]; then
    echo 'Using public TSA key from `'"$CONCOURSE_KEYS/tsa_key.pub"'`.'
    cp "$CONCOURSE_KEYS/tsa_key.pub" "$CONCOURSE/tsa_key.pub"
  else
    echo 'Fetching public TSA key from host.'
    ssh-keyscan -p "${CONCOURSE_TSA_PORT:-2222}" -- "${CONCOURSE_TSA_HOST:-0.0.0.0}" | awk '{print $2" "$3" tsa"}' >"$CONCOURSE/tsa_key.pub" || exit 1
  fi
  chown root:root "$CONCOURSE/tsa_key.pub"
  chmod 0600 "$CONCOURSE/tsa_key.pub"
fi

if [ ! -f "$CONCOURSE/worker_key" ]; then
  if [ ${CONCOURSE_WORKER_KEY:+set} ]; then
    echo 'Using private worker key from environment.'
    cat <<<"$CONCOURSE_WORKER_KEY" >"$CONCOURSE/worker_key"
  elif [ -f "$CONCOURSE_KEYS/worker_key" ]; then
    echo 'Using private worker key from `'"$CONCOURSE_KEYS/worker_key"'`.'
    cp "$CONCOURSE_KEYS/worker_key" "$CONCOURSE/worker_key"
  else
    echo 'Generating worker key pair.'
    ssh-keygen -t ecdsa -b 521 -N '' -f "$CONCOURSE/worker_key"
    echo "Public ssh key for worker: "
    cat "$CONCOURSE/worker_key.pub"
  fi
  chmod 0600 "$CONCOURSE/worker_key"
  chown root:root "$CONCOURSE/worker_key"
  { ssh-keygen -y -f ~/.ssh/id_ecdsa "$CONCOURSE/worker_key" >> "$CONCOURSE_KEYS/authorized_worker_keys"; } 2>&- || true
fi

exec concourse worker --work-dir="$CONCOURSE_WORK" \
  --tsa-host="${CONCOURSE_TSA_HOST:-0.0.0.0}" --tsa-port "${CONCOURSE_TSA_PORT:-2222}" \
  --tsa-public-key="$CONCOURSE/tsa_key.pub" --tsa-worker-private-key="$CONCOURSE/worker_key"
