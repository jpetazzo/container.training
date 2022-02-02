error_terraform_configuration() {
        error "When using the terraform infraclass, the TERRAFORM"
        error "environment variable must be set to one of the available"
        error "terraform configurations. These configurations are in"
        error "the prepare-vm/terraform subdirectory. You should probably"
        error "update your infra file and set the variable."
        error "(e.g. with TERRAFORM=openstack)"
}

if [ "$TERRAFORM" = "" ]; then
        error_terraform_configuration
        die "Aborting because TERRAFORM variable is not set."
fi

if [ ! -d terraform/$TERRAFORM ]; then
        error_terraform_configuration
        die "Aborting because no terraform configuration was found in 'terraform/$TERRAFORM'."
fi

infra_start() {
        COUNT=$1

        cp terraform/$TERRAFORM/*.tf tags/$TAG
        (
                cd tags/$TAG
                if ! terraform init; then
                        error "'terraform init' failed."
                        error "If it mentions the following error message:"
                        error "openpgp: signature made by unknown entity."
                        error "Then you need to upgrade Terraform to 0.11.15"
                        error "to upgrade its signing keys following the"
                        error "codecov breach."
                        die "Aborting."
                fi
                echo prefix = \"$TAG\" >> terraform.tfvars
                echo how_many_nodes = \"$COUNT\" >> terraform.tfvars
                terraform apply -auto-approve
                terraform output -raw ip_addresses > ips.txt
        )
}

infra_stop() {
        (
                cd tags/$TAG
                terraform destroy -auto-approve
        )
}
