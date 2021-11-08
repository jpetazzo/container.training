infra_start() {
        COUNT=$1

        cp terraform/*.tf tags/$TAG
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
