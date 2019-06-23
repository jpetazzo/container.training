# Application Configuration

There are many ways to provide configuration to containerized applications.

There is no "best way" — it depends on factors like:

* configuration size,

* mandatory and optional parameters,

* scope of configuration (per container, per app, per customer, per site, etc),

* frequency of changes in the configuration.

---

## Command-line parameters

```bash
docker run jpetazzo/hamba 80 www1:80 www2:80
```

* Configuration is provided through command-line parameters.

* In the above example, the `ENTRYPOINT` is a script that will:

  - parse the parameters,

  - generate a configuration file,

  - start the actual service.

---

## Command-line parameters pros and cons

* Appropriate for mandatory parameters (without which the service cannot start).

* Convenient for "toolbelt" services instantiated many times.

  (Because there is no extra step: just run it!)

* Not great for dynamic configurations or bigger configurations.

  (These things are still possible, but more cumbersome.)

---

## Environment variables

```bash
docker run -e ELASTICSEARCH_URL=http://es42:9201/ kibana
```

* Configuration is provided through environment variables.

* The environment variable can be used straight by the program,
  <br/>or by a script generating a configuration file.

---

## Environment variables pros and cons

* Appropriate for optional parameters (since the image can provide default values).

* Also convenient for services instantiated many times.

  (It's as easy as command-line parameters.)

* Great for services with lots of parameters, but you only want to specify a few.

  (And use default values for everything else.)

* Ability to introspect possible parameters and their default values.

* Not great for dynamic configurations.

---

## Baked-in configuration

```
FROM prometheus
COPY prometheus.conf /etc
```

* The configuration is added to the image.

* The image may have a default configuration; the new configuration can:

  - replace the default configuration,

  - extend it (if the code can read multiple configuration files).

---

## Baked-in configuration pros and cons

* Allows arbitrary customization and complex configuration files.

* Requires writing a configuration file. (Obviously!)

* Requires building an image to start the service.

* Requires rebuilding the image to reconfigure the service.

* Requires rebuilding the image to upgrade the service.

* Configured images can be stored in registries.

  (Which is great, but requires a registry.)

---

## Configuration volume

```bash
docker run -v appconfig:/etc/appconfig myapp
```

* The configuration is stored in a volume.

* The volume is attached to the container.

* The image may have a default configuration.

  (But this results in a less "obvious" setup, that needs more documentation.)

---

## Configuration volume pros and cons

* Allows arbitrary customization and complex configuration files.

* Requires creating a volume for each different configuration.

* Services with identical configurations can use the same volume.

* Doesn't require building / rebuilding an image when upgrading / reconfiguring.

* Configuration can be generated or edited through another container.

---

## Dynamic configuration volume

* This is a powerful pattern for dynamic, complex configurations.

* The configuration is stored in a volume.

* The configuration is generated / updated by a special container.

* The application container detects when the configuration is changed.

  (And automatically reloads the configuration when necessary.)

* The configuration can be shared between multiple services if needed.

---

## Dynamic configuration volume example

In a first terminal, start a load balancer with an initial configuration:

```bash
$ docker run --name loadbalancer jpetazzo/hamba \
  80 goo.gl:80
```

In another terminal, reconfigure that load balancer:

```bash
$ docker run --rm --volumes-from loadbalancer jpetazzo/hamba reconfigure \
  80 google.com:80
```

The configuration could also be updated through e.g. a REST API.

(The REST API being itself served from another container.)

---

## Keeping secrets

.warning[Ideally, you should not put secrets (passwords, tokens...) in:]

* command-line or environment variables (anyone with Docker API access can get them),

* images, especially stored in a registry.

Secrets management is better handled with an orchestrator (like Swarm or Kubernetes).

Orchestrators will allow to pass secrets in a "one-way" manner.

Managing secrets securely without an orchestrator can be contrived.

E.g.:

- read the secret on stdin when the service starts,

- pass the secret using an API endpoint.
