# Ingress and TLS certificates

- Most ingress controllers support TLS connections

  (in a way that is standard across controllers)

- The TLS key and certificate are stored in a Secret

- The Secret is then referenced in the Ingress resource:
  ```yaml
    spec:
      tls:
      - secretName: XXX
        hosts:
        - YYY
      rules:
      - ZZZ
  ```

---

## Obtaining a certificate

- In the next section, we will need a TLS key and certificate

- These usually come in [PEM](https://en.wikipedia.org/wiki/Privacy-Enhanced_Mail) format:
   ```
   -----BEGIN CERTIFICATE-----
   MIIDATCCAemg...
   ...
   -----END CERTIFICATE-----
   ```

- We will see how to generate a self-signed certificate

  (easy, fast, but won't be recognized by web browsers)

- We will also see how to obtain a certificate from [Let's Encrypt](https://letsencrypt.org/)

  (requires the cluster to be reachable through a domain name)

---

class: extra-details

## In production ...

- A very popular option is to use the [cert-manager](https://cert-manager.io/docs/) operator

- It's a flexible, modular approach to automated certificate management

- For simplicity, in this section, we will use [certbot](https://certbot.eff.org/)

- The method shown here works well for one-time certs, but lacks:

  - automation

  - renewal

---

## Which domain to use

- If you're doing this in a training:

  *the instructor will tell you what to use*

- If you're doing this on your own Kubernetes cluster:

  *you should use a domain that points to your cluster*

- More precisely:

  *you should use a domain that points to your ingress controller*

- If you don't have a domain name, you can use [nip.io](https://nip.io/)

  (if your ingress controller is on 1.2.3.4, you can use `whatever.1.2.3.4.nip.io`)

---

## Setting `$DOMAIN`

- We will use `$DOMAIN` in the following section

- Let's set it now

.lab[

- Set the `DOMAIN` environment variable:
  ```bash
  export DOMAIN=...
  ```

]

---

## Choose your adventure!

- We present 3 methods to obtain a certificate

- We suggest that we use method 1 (self-signed certificate)

  - it's the simplest and fastest method

  - it doesn't rely on other components

- You're welcome to try methods 2 and 3 (leveraging certbot)

  - they're great if you want to understand "how the sausage is made"

  - they require some hacks (make sure port 80 is available)

  - they won't be used in production (cert-manager is better)

---

## Method 1, self-signed certificate

- Thanks to `openssl`, generating a self-signed cert is just one command away!

.lab[

- Generate a key and certificate:
  ```bash
    openssl req \
      -newkey rsa -nodes -keyout privkey.pem \
      -x509 -days 30 -subj /CN=$DOMAIN/ -out cert.pem
  ```

]

This will create two files, `privkey.pem` and `cert.pem`.

---

## Method 2, Let's Encrypt with certbot

- `certbot` is an [ACME](https://tools.ietf.org/html/rfc8555) client

  (Automatic Certificate Management Environment)

- We can use it to obtain certificates from Let's Encrypt

- It needs to listen to port 80

  (to complete the [HTTP-01 challenge](https://letsencrypt.org/docs/challenge-types/))

- If port 80 is already taken by our ingress controller, see method 3

---

class: extra-details

## HTTP-01 challenge

- `certbot` contacts Let's Encrypt, asking for a cert for `$DOMAIN`

- Let's Encrypt gives a token to `certbot`

- Let's Encrypt then tries to access the following URL:

  `http://$DOMAIN/.well-known/acme-challenge/<token>`

- That URL needs to be routed to `certbot`

- Once Let's Encrypt gets the response from `certbot`, it issues the certificate

---

## Running certbot

- There is a very convenient container image, `certbot/certbot`

- Let's use a volume to get easy access to the generated key and certificate

.lab[

- Obtain a certificate from Let's Encrypt:
  ```bash
    EMAIL=your.address@example.com
    docker run --rm -p 80:80 -v $PWD/letsencrypt:/etc/letsencrypt \
      certbot/certbot certonly \
      -m $EMAIL \
      --standalone --agree-tos -n \
      --domain $DOMAIN \
      --test-cert
  ```

]

This will get us a "staging" certificate.
Remove `--test-cert` to obtain a *real* certificate.

---

## Copying the key and certificate

- If everything went fine:

  - the key and certificate files are in `letsencrypt/live/$DOMAIN`

  - they are owned by `root`

.lab[

- Grant ourselves permissions on these files:
  ```bash
  sudo chown -R $USER letsencrypt
  ```

- Copy the certificate and key to the current directory:
  ```bash
  cp letsencrypt/live/test/{cert,privkey}.pem .
  ```

]

---

## Method 3, certbot with Ingress

- Sometimes, we can't simply listen to port 80:

  - we might already have an ingress controller there
  - our nodes might be on an internal network

- But we can define an Ingress to route the HTTP-01 challenge to `certbot`!

- Our Ingress needs to route all requests to `/.well-known/acme-challenge` to `certbot`

- There are at least two ways to do that:

  - run `certbot` in a Pod (and extract the cert+key when it's done)
  - run `certbot` in a container on a node (and manually route traffic to it)

- We're going to use the second option

  (mostly because it will give us an excuse to tinker with Endpoints resources!)

---

## The plan

- We need the following resources:

  - an Endpoints¹ listing a hard-coded IP address and port
    <br/>(where our `certbot` container will be listening)

  - a Service corresponding to that Endpoints

  - an Ingress sending requests to `/.well-known/acme-challenge/*` to that Service
    <br/>(we don't even need to include a domain name in it)

- Then we need to start `certbot` so that it's listening on the right address+port

.footnote[¹Endpoints is always plural, because even a single resource is a list of endpoints.]

---

## Creating resources

- We prepared a YAML file to create the three resources

- However, the Endpoints needs to be adapted to put the current node's address

.lab[

- Edit `~/containers.training/k8s/certbot.yaml`

  (replace `A.B.C.D` with the current node's address)

- Create the resources:
  ```bash
  kubectl apply -f ~/containers.training/k8s/certbot.yaml
  ```

]

---

## Obtaining the certificate

- Now we can run `certbot`, listening on the port listed in the Endpoints

  (i.e. 8000)

.lab[

- Run `certbot`:
  ```bash
    EMAIL=your.address@example.com
    docker run --rm -p 8000:80 -v $PWD/letsencrypt:/etc/letsencrypt \
      certbot/certbot certonly \
      -m $EMAIL \
      --standalone --agree-tos -n \
      --domain $DOMAIN \
      --test-cert
  ```

]

This is using the staging environment.
Remove `--test-cert` to get a production certificate.

---

## Copying the certificate

- Just like in the previous method, the certificate is in `letsencrypt/live/$DOMAIN`

  (and owned by root)

.lab[

- Grand ourselves permissions on these files:
  ```bash
  sudo chown -R $USER letsencrypt
  ```

- Copy the certificate and key to the current directory:
  ```bash
  cp letsencrypt/live/$DOMAIN/{cert,privkey}.pem .
  ```

]

---

## Creating the Secret

- We now have two files:

  - `privkey.pem` (the private key)

  - `cert.pem` (the certificate)

- We can create a Secret to hold them

.lab[

- Create the Secret:
  ```bash
  kubectl create secret tls $DOMAIN --cert=cert.pem --key=privkey.pem 
  ```

]

---

## Ingress with TLS

- To enable TLS for an Ingress, we need to add a `tls` section to the Ingress:

  ```yaml
	spec:
	  tls:
	  - secretName: DOMAIN
	    hosts:
	    - DOMAIN
	  rules: ...
  ```

- The list of hosts will be used by the ingress controller

  (to know which certificate to use with [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication))

- Of course, the name of the secret can be different

  (here, for clarity and convenience, we set it to match the domain)

---

## `kubectl create ingress`

- We can also create an Ingress using TLS directly

- To do it, add `,tls=secret-name` to an Ingress rule

- Example:
  ```bash
  kubectl create ingress hello \
          --rule=hello.example.com/*=hello:80,tls=hello
  ```

- The domain will automatically be inferred from the rule

---

class: extra-details

## About the ingress controller

- Many ingress controllers can use different "stores" for keys and certificates

- Our ingress controller needs to be configured to use secrets

  (as opposed to, e.g., obtain certificates directly with Let's Encrypt)

---

## Using the certificate

.lab[

- Add the `tls` section to an existing Ingress

- If you need to see what the `tls` section should look like, you can:

  - `kubectl explain ingress.spec.tls`

  - `kubectl create ingress --dry-run=client -o yaml ...`

  - check `~/container.training/k8s/ingress.yaml` for inspiration

  - read the docs

- Check that the URL now works over `https`

  (it might take a minute to be picked up by the ingress controller)

]

---

## Discussion

*To repeat something mentioned earlier ...*

- The methods presented here are for *educational purpose only*

- In most production scenarios, the certificates will be obtained automatically

- A very popular option is to use the [cert-manager](https://cert-manager.io/docs/) operator

---

## Security

- Since TLS certificates are stored in Secrets...

- ...It means that our Ingress controller must be able to read Secrets

- A vulnerability in the Ingress controller can have dramatic consequences

- See [CVE-2021-25742](https://github.com/kubernetes/ingress-nginx/issues/7837) for an example

- This can be mitigated by limiting which Secrets the controller can access

  (RBAC rules can specify resource names)

- Downside: each TLS secret must explicitly be listed in RBAC

  (but that's better than a full cluster compromise, isn't it?)

???

:EN:- Ingress and TLS
:FR:- Certificats TLS et *ingress*
