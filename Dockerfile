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

FROM ubuntu:16.04

RUN apt-get update -y \
 && apt-get upgrade -y \
 && apt-get install -y curl iptables iproute2 postgresql openssh-client \
 && apt-get clean -y
RUN curl -L https://github.com/concourse/concourse/releases/download/v1.3.1/concourse_linux_amd64 -o /usr/local/bin/concourse \
 && chmod 755 /usr/local/bin/concourse

ENV CONCOURSE=/var/lib/concourse
ENV CONCOURSE_WEB="$CONCOURSE/web" \
    CONCOURSE_WORK="$CONCOURSE/work" \
    CONCOURSE_KEYS="$CONCOURSE/keys"

RUN pg_ctlcluster 9.5 main start \
 && su postgres -s /usr/bin/psql -c "CREATE ROLE concourse WITH LOGIN PASSWORD 'ci';" \
 && su postgres -s /usr/bin/psql -c "CREATE DATABASE concourse WITH OWNER concourse;" \
 && pg_ctlcluster 9.5 main stop

RUN mkdir -p "$CONCOURSE" "$CONCOURSE_WORK" \
 && useradd -d "$CONCOURSE_WEB" -s /bin/false -m -U concourse-web

VOLUME "$CONCOURSE_WORK"

COPY files/ /
