# CNI internals

- Kubelet looks for a CNI configuration file

  (by default, in `/etc/cni/net.d`)

- Note: if we have multiple files, the first one will be used

  (in lexicographic order)

- If no configuration can be found, kubelet holds off on creating containers

  (except if they are using `hostNetwork`)

- Let's see how exactly plugins are invoked!

---

## General principle

- A plugin is an executable program

- It is invoked with by kubelet to set up / tear down networking for a container

- It doesn't take any command-line argument

- However, it uses environment variables to know what to do, which container, etc.

- It reads JSON on stdin, and writes back JSON on stdout

- There will generally be multiple plugins invoked in a row

  (at least IPAM + network setup; possibly more)

---

## Environment variables

- `CNI_COMMAND`: `ADD`, `DEL`, `CHECK`, or `VERSION`

- `CNI_CONTAINERID`: opaque identifier

  (container ID of the "sandbox", i.e. the container running the `pause` image)

- `CNI_NETNS`: path to network namespace pseudo-file

  (e.g. `/var/run/netns/cni-0376f625-29b5-7a21-6c45-6a973b3224e5`)

- `CNI_IFNAME`: interface name, usually `eth0`

- `CNI_PATH`: path(s) with plugin executables (e.g. `/opt/cni/bin`)

- `CNI_ARGS`: "extra arguments" (see next slide)

---

## `CNI_ARGS`

- Extra key/value pair arguments passed by "the user"

- "The user", here, is "kubelet" (or in an abstract way, "Kubernetes")

- This is used to pass the pod name and namespace to the CNI plugin

- Example:
  ```
  IgnoreUnknown=1
  K8S_POD_NAMESPACE=default
  K8S_POD_NAME=web-96d5df5c8-jcn72
  K8S_POD_INFRA_CONTAINER_ID=016493dbff152641d334d9828dab6136c1ff...
  ```

Note that technically, it's a `;`-separated list, so it really looks like this:
```
CNI_ARGS=IgnoreUnknown=1;K8S_POD_NAMESPACE=default;K8S_POD_NAME=web-96d...
```

---

## JSON in, JSON out

- The plugin reads its configuration on stdin

- It writes back results in JSON

  (e.g. allocated address, routes, DNS...)

⚠️ "Plugin configuration" is not always the same as "CNI configuration"!

---

## Conf vs Conflist

- The CNI configuration can be a single plugin configuration

  - it will then contain a `type` field in the top-most structure

  - it will be passed "as-is"

- It can also be a "conflist", containing a chain of plugins

  (it will then contain a `plugins` field in the top-most structure)

- Plugins are then invoked in order (reverse order for `DEL` action)

- In that case, the input of the plugin is not the whole configuration

  (see details on next slide)

---

## List of plugins

- When invoking a plugin in a list, the JSON input will be:

  - the configuration of the plugin

  - augmented with `name` (matching the conf list `name`)

  - augmented with `prevResult` (which will be the output of the previous plugin)

- Conceptually, a plugin (generally the first one) will do the "main setup"

- Other plugins can do tuning / refinement (firewalling, traffic shaping...)

---

## Analyzing plugins

- Let's see what goes in and out of our CNI plugins!

- We will create a fake plugin that:

  - saves its environment and input

  - executes the real plugin with the saved input

  - saves the plugin output

  - passes the saved output

---

## Our fake plugin

```bash
#!/bin/sh
PLUGIN=$(basename $0)
cat > /tmp/cni.$$.$PLUGIN.in
env | sort > /tmp/cni.$$.$PLUGIN.env
echo "PPID=$PPID, $(readlink /proc/$PPID/exe)" > /tmp/cni.$$.$PLUGIN.parent
$0.real < /tmp/cni.$$.$PLUGIN.in > /tmp/cni.$$.$PLUGIN.out
EXITSTATUS=$?
cat /tmp/cni.$$.$PLUGIN.out
exit $EXITSTATUS
```

Save this script as `/opt/cni/bin/debug` and make it executable.

---

## Substituting the fake plugin

- For each plugin that we want to instrument:

  - rename the plugin from e.g. `ptp` to `ptp.real`

  - symlink `ptp` to our `debug` plugin

- There is no need to change the CNI configuration or restart kubelet

---

## Create some pods and looks at the results

- Create a pod

- For each instrumented plugin, there will be files in `/tmp`:

  `cni.PID.pluginname.in` (JSON input)

  `cni.PID.pluginname.env` (environment variables)

  `cni.PID.pluginname.parent` (parent process information)

  `cni.PID.pluginname.out` (JSON output)

❓️ What is calling our plugins?

???

:EN:- Deep dive into CNI internals
:FR:- La Container Network Interface (CNI) en détails
