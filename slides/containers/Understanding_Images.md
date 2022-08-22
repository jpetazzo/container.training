

```bash
$ docker run -it debian
root@ef22f9437171:/# apt-get update

root@ef22f9437171:/# apt-get install skopeo

root@ef22f9437171:/# apt-get wget curl jq

root@ef22f9437171:/# skopeo login docker.io -u containertraining -p testaccount

$ docker commit $(docker ps -lq) skop
```

```bash
root@0ab665194c4f:~# skopeo copy docker://docker.io/containertraining/test-image-0 dir:/root/test-image-0
root@0ab665194c4f:~# cd /root/test-image-0
root@0ab665194c4f:~# jq <manifest.json .layers[].digest
```


Stuff in Exploring-images
    image-test-0/1/2 + jpg



