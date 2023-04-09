provider "exoscale" {
  key    = regex("\n  key *= *\"([^\"]+)\"\n", file("~/.config/exoscale/exoscale.toml"))[0]
  secret = regex("\n  secret *= *\"([^\"]+)\"\n", file("~/.config/exoscale/exoscale.toml"))[0]
}
