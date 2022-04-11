# (1) Setting up a registry, and telling Tilt to use it.

# Tilt needs a registry to store images.

# The following manifest defines a Deployment to run a basic Docker registry,
# and a NodePort Service to access it. Using a NodePort means that we don't
# need to obtain a TLS certificate, because we will be accessing the registry
# through localhost.
k8s_yaml('../k8s/tilt-registry.yaml')

# Tell Tilt to use the registry that we just deployed instead of whatever
# is defined in our Kubernetes resources. Tilt will patch image names to
# use our registry.
default_registry('localhost:30555')

# Create a port forward so that we can access the registry from our local
# environment, too. Note that if you run Tilt directly from a Kubernetes node
# (which is not typical, but might happen in some lab/training environments)
# the following might cause an error because port 30555 is already taken.
k8s_resource(workload='tilt-registry', port_forwards='30555:5000')

# (2) Telling Tilt how to build and run our app.

# The following two lines will use the kubectl-build plugin
# to leverage buildkit and build the images in our Kubernetes
# cluster. This is not enabled by default, because it requires
# the plugin to be installed.
# See https://github.com/vmware-tanzu/buildkit-cli-for-kubectl
# for more information about this plugin.
#load('ext://kubectl_build', 'kubectl_build')
#docker_build = kubectl_build

# Our Kubernetes manifests use images 'dockercoins/...' so we tell Tilt
# how each of these images should be built. The first argument is the name
# of the image, the second argument is the directory containing the build
# context (i.e. the Dockerfile to build the image).
docker_build('dockercoins/hasher', 'hasher')
docker_build('dockercoins/rng', 'rng')
docker_build('dockercoins/webui', 'webui')
docker_build('dockercoins/worker', 'worker')

# The following manifests defines five Deployments and four Services for
# our application.
k8s_yaml('../k8s/dockercoins.yaml')

# (3) Finishing touches.

# The following line lets Tilt run with the default kubeadm cluster-admin context.
allow_k8s_contexts('kubernetes-admin@kubernetes')

# Note: the whole section below (to set up ngrok tunnels) is disabled,
# because ngrok now requires to set up an account to serve HTML
# content. So we can still use ngrok for e.g. webhooks and "raw" APIs,
# but not to serve web pages like the Tilt UI.

# # This will run an ngrok tunnel to expose Tilt to the outside world.
# # This is intended to be used when Tilt runs on a remote machine.
# local_resource(name='ngrok:tunnel', serve_cmd='ngrok http 10350')

# # This will wait until the ngrok tunnel is up, and show its URL to the user.
# # We send the output to /dev/tty so that it doesn't get intercepted by
# # Tilt, and gets displayed to the user's terminal instead.
# # Note: this assumes that the ngrok instance will be running on port 4040.
# # If you have other ngrok instances running on the machine, this might not work.
# local_resource(name='ngrok:showurl', cmd='''
#   while sleep 1; do
#     TUNNELS=$(curl -fsSL http://localhost:4040/api/tunnels | jq -r .tunnels[].public_url)
#     [ "$TUNNELS" ] && break
#   done
#   printf "\nYou should be able to connect to the Tilt UI with the following URL(s): %s\n" "$TUNNELS" >/dev/tty
#   '''
# )
