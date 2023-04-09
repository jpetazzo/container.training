provider "linode" {
  token = regex("\ntoken *= *([0-9a-f]+)\n", file("~/.config/linode-cli"))[0]
}
