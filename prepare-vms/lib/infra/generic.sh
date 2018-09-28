infra_start() {
	COUNT=$1
	info "You should now run your provisioning commands for $COUNT machines."
	info "Note: no machines have been automatically created!"
	info "Once done, put the list of IP addresses in tags/$TAG/ips.txt"
	info "(one IP address per line, without any comments or extra lines)."
	touch tags/$TAG/ips.txt
}
