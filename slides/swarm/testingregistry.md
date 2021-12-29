## Testing our local registry

- We can retag a small image, and push it to the registry

.lab[

- Make sure we have the busybox image, and retag it:
  ```bash
  docker pull busybox
  docker tag busybox 127.0.0.1:5000/busybox
  ```

- Push it:
  ```bash
  docker push 127.0.0.1:5000/busybox
  ```

]

---

## Checking what's on our local registry

- The registry API has endpoints to query what's there

.lab[

- Ensure that our busybox image is now in the local registry:
  ```bash
  curl http://127.0.0.1:5000/v2/_catalog
  ```

]

The curl command should now output:
```json
{"repositories":["busybox"]}
```
