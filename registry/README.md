# Docker Registry with Swarm superpowers

To start your registry, just do:

```
docker-compose up -d
```

You can then refer to the registry as `localhost:5000`.

If you are running on Swarm, do the following:

```
docker-compose up -d
docker-compose scale frontend=N
```

... where `N` is the number of nodes in your cluster.

This will make sure that a `frontend` container runs on every node,
so that `localhost:5000` always refers to your registry.

If you scale up your cluster, make sure to re-run `docker-compose scale`
accordingly.

If you supply a too large value for `N`, you will see errors
(since Swarm tries to schedule more frontends than there are
available hosts) but everything will work fine, don't worry.

Note: this will bind port 5000 on the loopoback interface on
all your machines. That port will therefore be unavailable if
you try e.g. `docker run -p 5000:...`.

Note: the registry will only be available from your cluster,
through the loopback interface. If you want to make it available
from outside, remove `127.0.0.1:` from the Compose file.

