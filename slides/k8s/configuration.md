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

- Indicate what should run in the container

- Pass `command` and/or `args` in the container options in a Pod's template

- Both `command` and `args` are arrays

- Example ([source](https://github.com/jpetazzo/container.training/blob/main/k8s/consul-1.yaml#L70)):
  ```yaml
    args:
    - "agent"
    - "-bootstrap-expect=3"
    - "-retry-join=provider=k8s label_selector=\"app=consul\" namespace=\"$(NS)\""
    - "-client=0.0.0.0"
    - "-data-dir=/consul/data"
    - "-server"
    - "-ui"
  ```

---

## `args` or `command`?

- Use `command` to override the `ENTRYPOINT` defined in the image

- Use `args` to keep the `ENTRYPOINT` defined in the image

  (the parameters specified in `args` are added to the `ENTRYPOINT`)

- In doubt, use `command`

- It is also possible to use *both* `command` and `args`

  (they will be strung together, just like `ENTRYPOINT` and `CMD`)

- See the [docs](https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#notes) to see how they interact together

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

- That second link also includes a list of all the fields that can be used with the downward API

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

## Example: HAProxy configuration

- We are going to deploy HAProxy, a popular load balancer

- It expects to find its configuration in a specific place:

  `/usr/local/etc/haproxy/haproxy.cfg`

- We will create a ConfigMap holding the configuration file

- Then we will mount that ConfigMap in a Pod running HAProxy

---

## Blue/green load balancing

- In this example, we will deploy two versions of our app:

  - the "blue" version in the `blue` namespace

  - the "green" version in the `green` namespace

- In both namespaces, we will have a Deployment and a Service

  (both named `color`)

- We want to load balance traffic between both namespaces

  (we can't do that with a simple service selector: these don't cross namespaces)

---

## Deploying the app

- We're going to use the image `jpetazzo/color`

  (it is a simple "HTTP echo" server showing which pod served the request)

- We can create each Namespace, Deployment, and Service by hand, or...

.lab[

- We can deploy the app with a YAML manifest:
  ```bash
  kubectl apply -f ~/container.training/k8s/rainbow.yaml
  ```

]

---

## Testing the app

- Reminder: Service `x` in Namespace `y` is available through:

  `x.y`, `x.y.svc`, `x.y.svc.cluster.local`

- Since the `cluster.local` suffix can change, we'll use `x.y.svc`

.lab[

- Check that the app is up and running:
  ```bash
    kubectl run --rm -it --restart=Never --image=nixery.dev/curl my-test-pod \
            curl color.blue.svc
  ```

]

---

## Creating the HAProxy configuration

Here is the file that we will use, @@LINK[k8s/haproxy.cfg]:

```
@@INCLUDE[k8s/haproxy.cfg]
```

---

## Creating the ConfigMap

.lab[

- Create a ConfigMap named `haproxy` and holding the configuration file:
  ```bash
  kubectl create configmap haproxy --from-file=~/container.training/k8s/haproxy.cfg
  ```

- Check what our configmap looks like:
  ```bash
  kubectl get configmap haproxy -o yaml
  ```

]

---

## Using the ConfigMap

Here is @@LINK[k8s/haproxy.yaml], a Pod manifest using that ConfigMap:

```yaml
@@INCLUDE[k8s/haproxy.yaml]
```

---

## Creating the Pod

.lab[

- Create the HAProxy Pod:
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

- If everything went well, when we should see a perfect round robin

  (one request to `blue`, one request to `green`, one request to `blue`, etc.)

.lab[

- Send a few requests:
  ```bash
  for i in $(seq 10); do
  curl $IP
  done
  ```

]

---

## Exposing configmaps with the downward API

- We are going to run a Docker registry on a custom port

- By default, the registry listens on port 5000

- This can be changed by setting environment variable `REGISTRY_HTTP_ADDR`

- We are going to store the port number in a configmap

- Then we will expose that configmap as a container environment variable

---

## Creating the configmap

.lab[

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
@@INCLUDE[k8s/registry.yaml]
```

---

## Using the configmap

- The resource definition from the previous slide is in @@LINK[k8s/registry.yaml]

.lab[

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

???

:EN:- Managing application configuration
:EN:- Exposing configuration with the downward API
:EN:- Exposing configuration with Config Maps

:FR:- Gérer la configuration des applications
:FR:- Configuration au travers de la *downward API*
:FR:- Configurer les applications avec des *Config Maps*