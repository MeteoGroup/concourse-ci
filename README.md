Concourse CI docker image [![travis build](https://travis-ci.org/MeteoGroup/concourse-ci.svg)](https://travis-ci.org/MeteoGroup/concourse-ci)
=========================

A docker image for [concourse](https://concourse.ci/introduction.html) using
the [standalone distribution](https://concourse.ci/binaries.html).

It provides entry points for _concourse web_ as well as for _concourse worker_.


Table of content
----------------

- **[Links](links)**
- **[Building](#building)**
- **[Running](#runnning)**
  + [Run _concourse web_](#run-concourse-web)
  + [Run _concourse worker_](#run-concourse-worker)
  + [Run single node _concourse web/worker_](#run-single-node-concourse-webworker)
- **[Test](#test)**
- **[License](#license)**


Links
-----

- [Concourse home page](https://concourse.ci/introduction.html)
- [Image on docker hub](https://hub.docker.com/r/meteogroup/concourse-ci/)
- [Travis-CI build](https://travis-ci.org/MeteoGroup/concourse-ci)
- [Source code repository](https://github.com/meteogroup/concourse-ci)


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
`/var/lib/concourse/keys`. The following files are looked up there:

  - `tsa_key` will be used as private TSA host key
  - `authorized_worker_keys` will be used to verify
    workers. It will be reread each time a worker connects to the TSA.

```bash
docker run --entrypoint concourse-web.sh \
  -v /path/to/dir/containing/keys:/var/lib/concourse/keys \
  meteogroup/concourse-ci
```

To allow sharing `/var/lib/concourse/keys` between _concourse web_ and
_concourse worker_, private keys may be accessible by root only. They are
copied and made accessible to _concourse web_ which will be run as non-root
user.

A single public key can be passed in the `CONCOURSE_WORKER_PUBKEY` environment
variable. If `/var/lib/concourse/keys` is writable by the container
`authorized_worker_keys` will be created from that key and used instead.
Otherwise the key in `CONCOURSE_WORKER_PUBKEY` is used as sole key to verify
workers.

If _concourse web_ is firewalled or run behind a proxy the external visible URL
can be configured by setting the `CONCOURSE_URL` environment variable.

```bash
docker run --entrypoint concourse-web.sh \
  --env CONCOURSE_URL=http://192.168.99.100:8080 \
  meteogroup/concourse-ci
```

The default login is `concourse` with password `ci` . This can be changed by
setting the `CONCOURSE_LOGIN` and `CONCOURSE_PASSWORD` environment variables.

```bash
docker run --entrypoint concourse-web.sh \
  --env CONCOURSE_LOGIN=ci-user \
  --env CONCOURSE_PASSWORD=rumpelstiltskin \
  meteogroup/concourse-ci
```

Alternatively, you can configure GitHub OAuth authenticaion by setting the `CONCOURSE_GITHUB_AUTH_CLIENT_ID` and `CONCOURSE_GITHUB_AUTH_CLIENT_SECRET` environment variables, along with one or more of the `CONCOURSE_GITHUB_AUTH_ORGANIZATION`, `CONCOURSE_GITHUB_AUTH_TEAM`, and `CONCOURSE_GITHUB_AUTH_USER` variables. Setting these variables will cause the container to ignore the `CONCOURSE_LOGIN` and `CONCOURSE_PASSWORD` variables.

```bash
docker run --entrypoint concourse-web.sh \
  --env CONCOURSE_GITHUB_AUTH_CLIENT_ID=b9c1a7f3895bd045b945 \
  --env CONCOURSE_GITHUB_AUTH_CLIENT_SECRET=1d9c379fcdfa6e1010293ed955274da27c3904c2 \
  --env CONCOURSE_GITHUB_AUTH_ORGANIZATION=my-org \
  meteogroup/concourse-ci
```

If you want to expose a safe view of your pipelines to unauthenticated users, set the `CONCOURSE_PUBLICLY_VIEWABLE` environment variable. This is convenient for open source projects.

```bash
docker run --entrypoint concourse-web.sh \
  --env CONCOURSE_PUBLICLY_VIEWABLE=true \
  meteogroup/concourse-ci
```

The image comes with an internal postgres database (which will be lost when the
container is removed). To use an external postgres database set the
`CONCOURSE_DATA_SOURCE` environment variable.

```bash
docker run --entrypoint concourse-web.sh \
  --env CONCOURSE_DATA_SOURCE=postgres://pg-user:pg-password@192.168.99.100 \
  meteogroup/concourse-ci
```


### Run a _concourse worker_

To run a worker use

```bash
docker run --entrypoint concourse-worker.sh --privileged \
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
into `/var/lib/concourse/keys`. The following files are looked up there:

  - `tsa_key.pub` will be used as public TSA host key
  - `worker_key` will be used as the workers private
    host key.

If `/var/lib/concourse/keys` is writable by the container the workers public
key is appended `authorized_worker_keys` (which will be created if it not
exists). After keys are setup `/var/lib/concourse/keys` will be unmounted from
the container to protect private keys.

```bash
docker run --entrypoint concourse-worker.sh \
  --privileged --v /var/lib/concourse/work \
  -v /path/to/dir/containing/keys:/var/lib/concourse/keys \
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


### Run single node _concourse web/worker_

For your convenience there is a `docker-compose.yml` file to stand up a ready
to use _concourse web/worker_ deployment, no key management involved. Just run

```bash
docker-compose up
```

If _concourse web_ is firewalled or run behind a proxy the external visible URL
can be configured by setting the `CONCOURSE_URL` environment variable.

```bash
CONCOURSE_URL=http://192.168.99.100:8080 docker-compose up
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

If _concourse web_ running behind a proxy and is not reachable at the hosts
root path you have to set the `CONCOURSE_URL` environment variable to the
externally reachable URL of _concourse web_. In that case username and password
have to be repeated in the authority part of that URL, otherwise the
test script will not be able to download the `fly` binary.

Connecting to custom host/port:
```bash
CONCOURSE_HOST=192.168.99.100 CONCOURSE_PORT=8080 test.sh
```

Using custom username/password:
```bash
CONCOURSE_LOGIN=ci-user CONCOURSE_PASSWORD=rumpelstiltskin test.sh
```

Connecting to concourse behind a proxy:
```bash
CONCOURSE_URL=https://ci-user:rumpelstiltskin@my-ci/concourse \
  CONCOURSE_LOGIN=ci-user CONCOURSE_PASSWORD=rumpelstiltskin test.sh
```


License
-------

Concourse – Copyright © 2014-2016 Alex Suraci & Chris Brown, licensed under
[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)

Copyright © 2016 MeteoGroup Deutschland GmbH

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
any file from this repository except in compliance with the License. You may
obtain a copy of the License at

  <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
