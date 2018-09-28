infra_start() {
	COUNT=$1

	cp terraform/*.tf tags/$TAG
	(
		cd tags/$TAG
		terraform init
		echo prefix = \"$TAG\" >> terraform.tfvars
		echo count = \"$COUNT\" >> terraform.tfvars
		terraform apply -auto-approve
		terraform output ip_addresses > ips.txt
	)
}

infra_stop() {
	(
		cd tags/$TAG
		terraform destroy -auto-approve
	)
}