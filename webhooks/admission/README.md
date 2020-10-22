# Validating Webhook Demo

This webhook applies to pods. If a pod has a label `color`, then
that label must be `blue`, `green`, or `red`. If it is anything
else, the pod will be rejected. Furthermore, once the `color` label
has been set, it cannot be changed or removed.


## Cheatsheet

Generating a key pair and a self-signed certificate:
```bash
NAMESPACE=webhooks
SERVICE=admission
CN=$SERVICE.$NAMESPACE.svc
openssl req -x509 -newkey rsa:4096 -nodes -keyout key.pem -out cert.pem \
	-days 30 -subj /CN=$CN -addext subjectAltName=DNS:$CN
```
(The API server *requires* that the certificate uses a `subjectAltName`.)

Loading up the key and certificate in a secret:
```bash
kubectl create secret tls $SERVICE \
	--namespace=$NAMESPACE --cert=cert.pem --key=key.pem
```

After loading the webhook configuration, patch up the `caBundle`:
```bash
CA=$(base64 -w0 < cert.pem)
PATCH='[{"op": "replace",
         "path": "/webhooks/0/clientConfig/caBundle",
         "value":"'$CA'"}]'
kubectl patch validatingwebhookconfiguration \
        admission.webhook.container.training \
	--type='json' -p="$PATCH"
```

Remember to always look at the logs of the API server while troubleshooting this!
