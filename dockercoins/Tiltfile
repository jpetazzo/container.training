k8s_yaml('../k8s/tilt-registry.yaml')
default_registry('localhost:30555')
docker_build('dockercoins/hasher', 'hasher')
docker_build('dockercoins/rng', 'rng')
docker_build('dockercoins/webui', 'webui')
docker_build('dockercoins/worker', 'worker')
k8s_yaml('../k8s/dockercoins.yaml')

# Uncomment the following line to let tilt run with the default kubeadm cluster-admin context.
#allow_k8s_contexts('kubernetes-admin@kubernetes')

# While we're here: if you're controlling a remote cluster, uncomment that line.
# It will create a port forward so that you can access the remote registry.
#k8s_resource(workload='registry', port_forwards='30555:5000')
