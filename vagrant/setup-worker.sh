#!/bin/bash -ex
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

sudo apt-get -y update
sudo apt-get -y upgrade
sudo curl -# -L https://github.com/concourse/concourse/releases/download/v1.0.0/concourse_linux_amd64 -o /usr/local/bin/concourse
sudo chmod 755 /usr/local/bin/concourse
sudo mkdir -p /var/lib/concourse/work
sudo install -m0644 /vagrant/tsa_key.pub /var/lib/concourse/
sudo install -m0600 /vagrant/worker_key /var/lib/concourse/

ls -lR /var/lib/concourse
