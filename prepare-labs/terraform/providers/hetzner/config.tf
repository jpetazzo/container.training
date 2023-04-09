/*
Okay, the following is pretty gross - it uses the first token found in the hcloud CLI
configuration file. We don't use Hetzner much anyway, and when we do, we only have one
profile ever, and we want this thing to Just Work; so this should do for now, but might
need to be improved if others actively use Hetzner to provision training labs.
*/
provider "hcloud" {
  token = regex("token = \"([A-Za-z0-9]+)\"", file("~/.config/hcloud/cli.toml"))[0]
}
