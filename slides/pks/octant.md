# Octant

Octant is an open source tool from VMWare which is designed to be a Kubernetes workload visualization tool that runs locally and uses your Kubeconfig to connect to the Kubernetes cluster.

Octant only ever performs list and read style requests and does not create/modify/delete resources. This makes it a much safer tool to use than the Kubernetes Dashboard.

.exercise[

- Run octant and browse through your resources:
  ```bash
  octant
  ```

]