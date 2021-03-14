# Quick Kubernetes review

FIXME


:T: Warming up with a quick Kubernetes review

:Q: In Kubernetes, what is a Pod?
:A: ✔️A basic unit of scaling that can contain one or more containers
:A: An abstraction for an application and its dependencies
:A: It's just a fancy name for "container" but they're the same
:A: A group of cluster nodes used for scheduling purposes

:Q: In Kubernetes, what is a Replica Set?
:A: ✔️A controller used to create one or multiple identical Pods
:A: A numeric parameter in a Pod specification, used to scale that Pod
:A: A group of containers running on the same node
:A: A group of containers running on different nodes

:Q: In Kubernetes, what is a Deployment?
:A: ✔️A controller that can manage Replica Sets corresponding to different configurations
:A: A manifest telling Kubernetes how to deploy an app and its dependencies
:A: A list of instructions executed in a container to configure that container
:A: A basic unit of work for the Kubernetes scheduler
