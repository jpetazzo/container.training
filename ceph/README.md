# CEPH on Docker

Note: this doesn't quite work yet.

The OSD containers need to be started twice (the first time, they fail
initializing; second time is a champ).

Also, it looks like you need at least two OSD containers (or the OSD
container should have two disks/directories, whatever).

RadosGw is listening on port 8080.

The `admin` container will create a `docker` user using `radosgw-admin`.
If you run it multiple times, that's OK: further invocations are idempotent.

Last but not least: it looks like AWS CLI uses a new signature format
that doesn't work with RadosGW. After almost two hours trying to figure
out what was wrong, I tried the S3 credentials directly with boto and
it worked immediately (I was able to create a bucket).
