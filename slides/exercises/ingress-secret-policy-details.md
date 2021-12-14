⚠️ BROKEN EXERCISE - DO NOT USE

# Exercise — Ingress Secret Policy

- Most ingress controllers have access to all Secrets

  (so that they can access TLS keys and certs, which are stored in Secrets)

- Ingress controller vulnerability can lead to full cluster compromise

  (by allowing attacker to access all secrets, including API tokens)

- See for instance [CVE-2021-25742](https://github.com/kubernetes/ingress-nginx/issues/7837)

- How can we prevent that?

---

## Step 1: Ingress Controller

- Deploy an Ingress Controller

  (e.g. Traefik or NGINX; you can use @@LINK[k8s/traefik-v2.yaml])

- Create a trivial web app (e.g. NGINX, `jpetazzo/color`...)

- Expose it with an Ingress

  (e.g. use `app.<ip-address>.nip.io`)

- Check that you can access it through `http://app.<ip-address>.nip.io`

---

## Step 2: cert-manager

- Deploy cert-manager

- Create a ClusterIssuer using Let's Encrypt staging environment

  (e.g. with @@LINK[k8s/cm-clusterissuer.yaml])

- Create an Ingress for the app, with TLS enabled

  (e.g. use `appsecure.<ip-address>.nip.io`)

- Tell cert-manager to obtain a certificate for that Ingress

  - option 1: manually create a Certificate (e.g. with @@LINK[k8s/cm-certificate.yaml])

  - option 2: use the `cert-manager.io/cluster-issuer` annotation

- Check that you get the Let's Encrypt certificate was issued

---

## Step 3: RBAC

- Remove the Ingress Controller's permission to read all Secrets

- Restart the Ingress Controller

- Check that https://appsecure doesn't serve the Let's Encrypt cert

- Grant permission to read the certificate's Secret

- Check that https://appsecure serve the Let's Encrypt cert again

---

## Step 4: Kyverno

- Install Kyverno

- Write a Kyverno policy to automatically grant permission to read Secrets

  (e.g. when a cert-manager Certificate is created)

- Check @@LINK[k8s/kyverno-namespace-setup.yaml] for inspiration

- Hint: you need to automatically create a Role and RoleBinding

- Create another app + another Ingress with TLS

- Check that the Certificate, Secret, Role, RoleBinding are created

- Check that the new app correctly serves the Let's Encrypt cert

---

## Step 5: double-check

- Check that the Ingress Controller can't access other secrets

  (e.g. by manually creating a Secret and checking with `kubectl exec`?)
