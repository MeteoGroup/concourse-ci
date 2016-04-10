#!/bin/sh
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

CONCOURSE_USER="${CONCOURSE_USER:-concourse}"
CONCOURSE_PASSWORD="${CONCOURSE_PASSWORD:-ci}"
CONCOURSE_HOST="${CONCOURSE_HOST:-0.0.0.0}"
CONCOURSE_PORT="${CONCOURSE_PORT:-8080}"
CONCOURSE_URL="${CONCOURSE_URL:-http://$CONCOURSE_USER:$CONCOURSE_PASSWORD@$CONCOURSE_HOST:$CONCOURSE_PORT}"
export CONCOURSE_USER CONCOURSE_PASSWORD CONCOURSE_HOST CONCOURSE_PORT CONCOURSE_URL

echo '+++ Install `fly`'
wget "$CONCOURSE_URL/api/v1/cli?arch=amd64&platform=linux" -O /bin/fly || exit
chmod 0755 /bin/fly || exit
echo '*** Ok.'

echo '+++ Add user for tests:'
adduser -D test || exit
echo '*** Ok.'

echo '+++ Run test:'
if su test -- /test-files/test.sh; then
  echo "*** Test successfully finished."
  echo
  exit 0
else
  echo "!!! Test failed."
  echo
  exit 1
fi
