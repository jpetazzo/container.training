# Installing Traefik

- Traefik is going to be our Ingress Controller

- Let's install it with a Helm chart, in its own namespace

- First, let's add the Traefik chart repository:
  ```bash
  helm repo add traefik https://helm.traefik.io/traefik
  ```

- Then, install the chart:
  ```bash
    helm upgrade --install treafik trafik/traefik \
        --create-namespace --namespace traefik \
        --set "ports.websecure.tls.enabled=true"
  ```

  (that option that we added enables HTTPS, it will be useful later!)

---

## Testing Traefik

- Let's create an Ingress resource!

- If we're using Kubernetes 1.20 or later, we can simply do this:
  ```bash
  kubectl create ingress web \
      --rule=`ingress-is-fun.cloudnative.party`/*=web:80
  ```

  (make sure to update and use your own domain)

- Check that the Ingress was correctly created:
  ```bash
  kubectl get ingress
  kubectl describe ingress
  ```

- If we're using Kubernetes 1.19 or earlier, we'll need some YAML

---

## Creating an Ingress with YAML

- This is how we do it with YAML:
  ```bash
    kubectl apply -f- <<EOF
    apiVersion: networking.k8s.io/v1beta1
    kind: Ingress
    metadata:
      name: web
    spec:
      rules:
      - host: `ingress-is-fun.cloudnative.party`
        http:
          paths:
          - path: /
            backend:
              serviceName: web
              servicePort: 80
    EOF
  ```

---

## Ingress versions...

- Note how we used the `v1beta1` Ingress version on the previous YAML

  (to be compatible with older Kubernetes versions)

- This YAML will give you deprecation warnings on recent version of Kubernetes

  (since the Ingress spec is now at version `v1`)

- Don't worry too much about the deprecation warnings

  (on Kubernetes, deprecation happens over a long time window, typically 1 year)

- You will have time to revisit and worry later! 😅

---

## Does it work?

- Try to connect to the Ingress host name

  (in my example, http://ingress-is-fun.cloudnative.party/)

- *Normally,* it doesn't work (yet) 🤔

- Let's look at `kubectl get ingress` again

- ExternalDNS is trying to create records mapping HOSTS to ADDRESS

- But the ADDRESS field is currently empty!

- We need to tell Traefik to fill that ADDRESS field

---

## Reconfiguring Traefik

- There is a "magic" flag to tell Traefik to update the address status field

- Let's update our Traefik install:
  ```bash
    helm upgrade --install treafik trafik/traefik \
        --create-namespace --namespace traefik \
        --set "ports.websecure.tls.enabled=true" \
        --set "providers.kubernetesIngress.publishedService.enabled=true"
  ```

---

## Checking what we did

- Check the output of `kubectl get ingress`

  (there should be an address now)

- Check the logs of ExternalDNS

  (there should be a mention of the new DNS record)

- Try again to connect to the HTTP address

  (now it should work)

- Note that some of these operations might take a minute or two

  (be patient!)

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
