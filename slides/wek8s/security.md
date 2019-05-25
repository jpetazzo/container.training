## Security in the context of wek8s

- The wek8s dev clusters have permissive policies

  (so that we can easily experiment and try things)

- This means that we need to be particularly careful about unknown sources

- Check the provenance of images, YAML bundles, Helm Charts, etc.:

  - does it come from the website / documentation / repository of a trusted vendor?

  - is it maintained; how often does it get updates?

- For images:

  - is the source (Dockerfile or otherwise) available?

  - are they checked by an automated vulnerability scanner?
