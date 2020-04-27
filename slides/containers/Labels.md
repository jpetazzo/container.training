# Labels

* Labels allow to attach arbitrary metadata to containers.

* Labels are key/value pairs.

* They are specified at container creation.

* You can query them with `docker inspect`.

* They can also be used as filters with some commands (e.g. `docker ps`).

---

## Using labels

Let's create a few containers with a label `owner`.

```bash
docker run -d -l owner=alice nginx
docker run -d -l owner=bob nginx
docker run -d -l owner nginx
```

We didn't specify a value for the `owner` label in the last example.

This is equivalent to setting the value to be an empty string.

---

## Querying labels

We can view the labels with `docker inspect`.

```bash
$ docker inspect $(docker ps -lq) | grep -A3 Labels
            "Labels": {
                "maintainer": "NGINX Docker Maintainers <docker-maint@nginx.com>",
                "owner": ""
            },
```

We can use the `--format` flag to list the value of a label.

```bash
$ docker inspect $(docker ps -q) --format 'OWNER={{.Config.Labels.owner}}'
```

---

## Using labels to select containers

We can list containers having a specific label.

```bash
$ docker ps --filter label=owner
```

Or we can list containers having a specific label with a specific value.

```bash
$ docker ps --filter label=owner=alice
```

---

## Use-cases for labels


* HTTP vhost of a web app or web service.

  (The label is used to generate the configuration for NGINX, HAProxy, etc.)

* Backup schedule for a stateful service.

  (The label is used by a cron job to determine if/when to backup container data.)

* Service ownership.

  (To determine internal cross-billing, or who to page in case of outage.)

* etc.

???

:EN:- Using labels to identify containers
:FR:- Étiqueter ses conteneurs avec des méta-données
