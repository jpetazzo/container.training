# Managing configuration

- Some applications need to be configured (obviously!)

- There are many ways for our code to pick up configuration:

  - command-line arguments

  - environment variables

  - configuration files

  - configuration servers (getting configuration from a database, an API...)

  - ... and more (because programmers can be very creative!)

- How can we do these things with containers and Kubernetes?

---

## Passing configuration to containers

- There are many ways to pass configuration to code running in a container:

  - baking it into a custom image

  - command-line arguments

  - environment variables

  - injecting configuration files

  - exposing it over the Kubernetes API

  - configuration servers

- Let's review these different strategies!

---

## Baking custom images

- Put the configuration in the image

  (it can be in a configuration file, but also `ENV` or `CMD` actions)

- It's easy! It's simple!

- Unfortunately, it also has downsides:

  - multiplication of images

  - different images for dev, staging, prod ...

  - minor reconfigurations require a whole build/push/pull cycle

- Avoid doing it unless you don't have the time to figure out other options

---

## Command-line arguments

- Pass options to `args` array in the container specification

- Example ([source](https://github.com/coreos/pods/blob/master/kubernetes.yaml#L29)): 
  ```yaml
      args: 
        - "--data-dir=/var/lib/etcd"
        - "--advertise-client-urls=http://127.0.0.1:2379"
        - "--listen-client-urls=http://127.0.0.1:2379"
        - "--listen-peer-urls=http://127.0.0.1:2380"
        - "--name=etcd"
  ```

- The options can be passed directly to the program that we run ...

  ... or to a wrapper script that will use them to e.g. generate a config file

---

## Command-line arguments, pros & cons

- Works great when options are passed directly to the running program

  (otherwise, a wrapper script can work around the issue)

- Works great when there aren't too many parameters

  (to avoid a 20-lines `args` array)

- Requires documentation and/or understanding of the underlying program

  ("which parameters and flags do I need, again?")

- Well-suited for mandatory parameters (without default values)

- Not ideal when we need to pass a real configuration file anyway

---

## Environment variables

- Pass options through the `env` map in the container specification

- Example:
  ```yaml
      env:
      - name: ADMIN_PORT
        value: "8080"
      - name: ADMIN_AUTH
        value: Basic
      - name: ADMIN_CRED
        value: "admin:0pensesame!"
  ```

.warning[`value` must be a string! Make sure that numbers and fancy strings are quoted.]

🤔 Why this weird `{name: xxx, value: yyy}` scheme? It will be revealed soon!

---

## The downward API

- In the previous example, environment variables have fixed values

- We can also use a mechanism called the *downward API*

- The downward API allows exposing pod or container information

  - either through special files (we won't show that for now)

  - or through environment variables

- The value of these environment variables is computed when the container is started

- Remember: environment variables won't (can't) change after container start

- Let's see a few concrete examples!

---

## Exposing the pod's namespace

```yaml
    - name: MY_POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
```

- Useful to generate FQDN of services

  (in some contexts, a short name is not enough)

- For instance, the two commands should be equivalent:
  ```
  curl api-backend
  curl api-backend.$MY_POD_NAMESPACE.svc.cluster.local
  ```

---

## Exposing the pod's IP address

```yaml
    - name: MY_POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
```

- Useful if we need to know our IP address

  (we could also read it from `eth0`, but this is more solid)

---

## Exposing the container's resource limits

```yaml
    - name: MY_MEM_LIMIT
      valueFrom:
        resourceFieldRef:
          containerName: test-container
          resource: limits.memory
```

- Useful for runtimes where memory is garbage collected

- Example: the JVM

  (the memory available to the JVM should be set with the `-Xmx ` flag)

- Best practice: set a memory limit, and pass it to the runtime

- Note: recent versions of the JVM can do this automatically

  (see [JDK-8146115](https://bugs.java.com/bugdatabase/view_bug.do?bug_id=JDK-8146115))
  and
  [this blog post](https://very-serio.us/2017/12/05/running-jvms-in-kubernetes/)
  for detailed examples)

---

## More about the downward API

- [This documentation page](https://kubernetes.io/docs/tasks/inject-data-application/environment-variable-expose-pod-information/) tells more about these environment variables

- And [this one](https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/) explains the other way to use the downward API

  (through files that get created in the container filesystem)

---

## Environment variables, pros and cons

- Works great when the running program expects these variables

- Works great for optional parameters with reasonable defaults

  (since the container image can provide these defaults)

- Sort of auto-documented

  (we can see which environment variables are defined in the image, and their values)

- Can be (ab)used with longer values ...

- ... You *can* put an entire Tomcat configuration file in an environment ...

- ... But *should* you?

(Do it if you really need to, we're not judging! But we'll see better ways.)

---

## Injecting configuration files

- Sometimes, there is no way around it: we need to inject a full config file

- Kubernetes provides a mechanism for that purpose: `configmaps`

- A configmap is a Kubernetes resource that exists in a namespace

- Conceptually, it's a key/value map

  (values are arbitrary strings)

- We can think about them in (at least) two different ways:

  - as holding entire configuration file(s)

  - as holding individual configuration parameters

*Note: to hold sensitive information, we can use "Secrets", which
are another type of resource behaving very much like configmaps.
We'll cover them just after!*

---

## Configmaps storing entire files

- In this case, each key/value pair corresponds to a configuration file

- Key = name of the file

- Value = content of the file

- There can be one key/value pair, or as many as necessary

  (for complex apps with multiple configuration files)

- Examples:
  ```
  # Create a configmap with a single key, "app.conf"
  kubectl create configmap my-app-config --from-file=app.conf
  # Create a configmap with a single key, "app.conf" but another file
  kubectl create configmap my-app-config --from-file=app.conf=app-prod.conf
  # Create a configmap with multiple keys (one per file in the config.d directory)
  kubectl create configmap my-app-config --from-file=config.d/
  ```

---

## Configmaps storing individual parameters

- In this case, each key/value pair corresponds to a parameter

- Key = name of the parameter

- Value = value of the parameter

- Examples:
  ```
  # Create a configmap with two keys
  kubectl create cm my-app-config \
      --from-literal=foreground=red \
      --from-literal=background=blue
  
  # Create a configmap from a file containing key=val pairs
  kubectl create cm my-app-config \
      --from-env-file=app.conf
  ```

---

## Exposing configmaps to containers

- Configmaps can be exposed as plain files in the filesystem of a container

  - this is achieved by declaring a volume and mounting it in the container

  - this is particularly effective for configmaps containing whole files

- Configmaps can be exposed as environment variables in the container

  - this is achieved with the downward API

  - this is particularly effective for configmaps containing individual parameters

- Let's see how to do both!

---

## Passing a configuration file with a configmap

- We will start a load balancer powered by HAProxy

- We will use the [official `haproxy` image](https://hub.docker.com/_/haproxy/)

- It expects to find its configuration in `/usr/local/etc/haproxy/haproxy.cfg`

- We will provide a simple HAproxy configuration, `k8s/haproxy.cfg`

- It listens on port 80, and load balances connections between IBM and Google

---

## Creating the configmap

.exercise[

- Go to the `k8s` directory in the repository:
  ```bash
  cd ~/container.training/k8s
  ```

- Create a configmap named `haproxy` and holding the configuration file:
  ```bash
  kubectl create configmap haproxy --from-file=haproxy.cfg
  ```

- Check what our configmap looks like:
  ```bash
  kubectl get configmap haproxy -o yaml
  ```

]

---

## Using the configmap

We are going to use the following pod definition:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: haproxy
spec:
  volumes:
  - name: config
    configMap:
      name: haproxy
  containers:
  - name: haproxy
    image: haproxy
    volumeMounts:
    - name: config
      mountPath: /usr/local/etc/haproxy/
```

---

## Using the configmap

- The resource definition from the previous slide is in `k8s/haproxy.yaml`

.exercise[

- Create the HAProxy pod:
  ```bash
  kubectl apply -f ~/container.training/k8s/haproxy.yaml
  ```

<!-- ```hide kubectl wait pod haproxy --for condition=ready``` -->

- Check the IP address allocated to the pod:
  ```bash
  kubectl get pod haproxy -o wide
  IP=$(kubectl get pod haproxy -o json | jq -r .status.podIP)
  ```

]

---

## Testing our load balancer

- The load balancer will send:

  - half of the connections to Google

  - the other half to IBM

.exercise[

- Access the load balancer a few times:
  ```bash
  curl $IP
  curl $IP
  curl $IP
  ```

]

We should see connections served by Google, and others served by IBM.
<br/>
(Each server sends us a redirect page. Look at the URL that they send us to!)

---

## Exposing configmaps with the downward API

- We are going to run a Docker registry on a custom port

- By default, the registry listens on port 5000

- This can be changed by setting environment variable `REGISTRY_HTTP_ADDR`

- We are going to store the port number in a configmap

- Then we will expose that configmap as a container environment variable

---

## Creating the configmap

.exercise[

- Our configmap will have a single key, `http.addr`:
  ```bash
  kubectl create configmap registry --from-literal=http.addr=0.0.0.0:80
  ```

- Check our configmap:
  ```bash
  kubectl get configmap registry -o yaml
  ```

]

---

## Using the configmap

We are going to use the following pod definition:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: registry
spec:
  containers:
  - name: registry
    image: registry
    env:
    - name: REGISTRY_HTTP_ADDR
      valueFrom:
        configMapKeyRef:
          name: registry
          key: http.addr
```

---

## Using the configmap

- The resource definition from the previous slide is in `k8s/registry.yaml`

.exercise[

- Create the registry pod:
  ```bash
  kubectl apply -f ~/container.training/k8s/registry.yaml
  ```

<!-- ```hide kubectl wait pod registry --for condition=ready``` -->

- Check the IP address allocated to the pod:
  ```bash
  kubectl get pod registry -o wide
  IP=$(kubectl get pod registry -o json | jq -r .status.podIP)
  ```

- Confirm that the registry is available on port 80:
  ```bash
  curl $IP/v2/_catalog
  ```

]

---

## Passwords, tokens, sensitive information

- For sensitive information, there is another special resource: *Secrets*

- Secrets and Configmaps work almost the same way

  (we'll expose the differences on the next slide)

- The *intent* is different, though:

  *"You should use secrets for things which are actually secret like API keys, 
  credentials, etc., and use config map for not-secret configuration data."*

  *"In the future there will likely be some differentiators for secrets like rotation or support for backing the secret API w/ HSMs, etc."*

  (Source: [the author of both features](https://stackoverflow.com/a/36925553/580281
))

---

## Differences between configmaps and secrets
 
- Secrets are base64-encoded when shown with `kubectl get secrets -o yaml`

  - keep in mind that this is just *encoding*, not *encryption*

  - it is very easy to [automatically extract and decode secrets](https://medium.com/@mveritym/decoding-kubernetes-secrets-60deed7a96a3)

- [Secrets can be encrypted at rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)

- With RBAC, we can authorize a user to access configmaps, but not secrets

  (since they are two different kinds of resources)
