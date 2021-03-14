# Installing Traefik

FIXME

???

:T: Installing the Traefik Ingress Controller

:Q: What's the job of an Ingress Controller?
:A: Prevent unauthorized access to Kubernetes services
:A: Firewall inbound traffic on the Kubernetes API
:A: ✔️Handle inbound HTTP traffic for Kubernetes services
:A: Keep track of the location of Kubernetes operators

:Q: What happens when we create an "Ingress resource"?
:A: A web service is automatically deployed and scaled on our cluster
:A: Kubernetes starts tracking the location of our users
:A: Traffic coming from the specified addresses will be allowed
:A: ✔️A load balancer is configured with HTTP traffic rules
