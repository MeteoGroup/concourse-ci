Concourse CI docker image
=========================

A docker image for [concourse](https://concourse.ci/introduction.html) using
the [standalone distribution](https://concourse.ci/binaries.html).

It provides entry points for _concourse web_ as well as for _concourse worker_.


Building
--------

Just run

```bash
docker build -t <image tag> .
```


Running
-------

### Run _concourse web_

For the default configuration just run

```bash
docker run --entrypoint concourse-web.sh meteogroup/concourse-ci
```

By default all keys are generated. The public key for TSA is printed to
`stdout` as well as the **private key** workers may use to register with TSA!

It is possible to mount a directory containing required keys for TSA into
`/var/lib/concourse/keys`. The following files are looked up:

  - `/var/lib/concourse/keys/tsa_key` will be used as private TSA host key
  - `/var/lib/concourse/keys/authorized_worker_keys` will be used to verify
    workers
  - `/var/lib/concourse/keys/worker_key.pub` will be used to verify workers if
    `/var/lib/concourse/keys/authorized_worker_keys` does not exists.
  - `/var/lib/concourse/keys/session_signing_key` will be used as private key
    for session signing. _Concourse requires RSA keys for session signing._

```bash
docker run --entrypoint concourse-web.sh \
  -v /path/to/dir/containing/keys:/var/lib/concourse/keys:ro \
  meteogroup/concourse-ci
```

A single public key can be passed in the `CONCOURSE_WORKER_PUBKEY` environment
variable. In that case `/var/lib/concourse/keys/authorized_worker_keys` and
`/var/lib/concourse/keys/worker_key.pub` are ignored and the key in
`CONCOURSE_WORKER_PUBKEY` is used as sole key to verify workers.

If _concourse web_ is firewalled or run behind a proxy the external visible URL
can be configured by setting the `CONCOURSE_URL` environment variable.

```bash
docker run --entrypoint concourse-web.sh \
  --env CONCOURSE_URL=http://192.168.99.100:8080 \
  meteogroup/concourse-ci
```

By default the login `concourse` with password `ci` is used as credentials to
access _concourse web_. This can be changed by setting the `CONCOURSE_LOGIN`
and `CONCOURSE_PASSWORD` environment variables.

```bash
docker run --entrypoint concourse-web.sh \
  --env CONCOURSE_LOGIN=ci-user \
  --env CONCOURSE_PASSWD=rumpelstiltskin \
  meteogroup/concourse-ci
```

An connection to a external postgres database can be configured by setting the
`CONCOURSE_DATA_SOURCE` environment variable.

```bash
docker run --entrypoint concourse-web.sh \
  --env CONCOURSE_DATA_SOURCE=postgres://pg-user:pg-password@192.168.99.100 \
  meteogroup/concourse-ci
```


### Run a _concourse worker_

To run a worker use

```bash
docker run --entrypoint concourse-worker.sh \
  --privileged --v /var/lib/concourse/work \
  meteogroup/concourse-ci
```

As concourse worker is running containers for builds it is essential to run it
in _privileged_ mode and have a none layering filesystem mounted to
`/var/lib/concourse/work`. _Your builds will break and/or hang indefinitely
otherwise._

By default the TSA public key will be fetched from the TSA server during
startup and a key pair is generated for the worker. The public worker key is
then printed to `stdout` and has to be added to the authorized worker keys for
TSA.

The TSA host and port can be configured by setting the `CONCOURSE_TSA_HOST` and
`CONCOURSE_TSA_PORT` environment variables. By default the worker tries to
register at `0.0.0.0:2222`.

```bash
docker run --entrypoint concourse-worker.sh \
  --privileged --v /var/lib/concourse/work \
  --env CONCOURSE_TSA_HOST=192.168.99.100 \
  --env CONCOURSE_TSA_PORT=2222 \
  meteogroup/concourse-ci
```

It is possible to mount a directory containing required keys for the worker
into `/var/lib/concourse/keys`. The following files are looked up:

  - `/var/lib/concourse/keys/tsa_key.pub` will be used as public TSA host key
  - `/var/lib/concourse/keys/worker_key` will be used as the workers private
    host key.

```bash
docker run --entrypoint concourse-worker.sh \
  --privileged --v /var/lib/concourse/work \
  -v /path/to/dir/containing/keys:/var/lib/concourse/keys:ro \
  meteogroup/concourse-ci
```

The workers private key may be passed in the `CONCOURSE_WORKER_KEY` environment
variable. In that case `/var/lib/concourse/keys/worker_key` is ignored.

The public TSA host key can be passed in the `CONCOURSE_TSA_PUBKEY` environment
variable. In that case `/var/lib/concourse/keys/tsa_key.pub` is ignored.

```bash
docker run --entrypoint concourse-worker.sh \
  --privileged --v /var/lib/concourse/work \
  --env CONCOURSE_WORKER_KEY="<worker's private key>" \
  --env CONCOURSE_TSA_PUBKEY="<public TSA key>" \
  meteogroup/concourse-ci
```


Test
----

To test worker and CI server just run

```bash
./test.sh
```

This will start a busybox docker container, download `fly` and goes through the
following steps:

  - create a pipeline using a slightly modified version of the
    [_Hello, world!_ example](https://concourse.ci/hello-world.html).
  - Unpause the pipeline.
  - Trigger the job.
  - Wait for the job to complete.
  - Delete the pipeline.
  - Check the job output against the expected _Hello, world!_ output.

By default the script tries to connect to `http://0.0.0.0:8080` using
`concourse`/`ci` as username/password. That can be changed by setting the
`CONCOURSE_HOST`, `CONCOURSE_PORT`, `CONCOURSE_LOGIN` and `CONCOURSE_PASSWORD`
environment variables for the `test.sh` script.

**Be aware that username and password will be echoed in the script output!**

If _concourse web_ running behind a proxy and not reachable at the hosts root
path you have to set the `CONCOURSE_URL` environment variable to the externally
reachable URL of _concourse web_. In that case username and password have to be
repeated in the authority part of that URL, otherwise the script will not be
able to download the `fly` binary.


License
-------

Concourse – Copyright © 2014-2016 Alex Suraci & Chris Brown, licensed under
[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)

Copyright © 2016 MeteoGroup Deutschland GmbH

Licensed under the Apache License, Version 2.0 (the "License"); you may not
file from this repository except in compliance with the License. You may obtain
a copy of the License at

  <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
