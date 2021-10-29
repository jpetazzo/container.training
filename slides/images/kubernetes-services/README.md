All the diagrams in this directory have been made with draw.io.

The source diagram (the `.drawio` file) should be kept in this directory.

To regenerate a diagram:

- open the source diagram
- menu File / Export As / Advanced...
- change DPI to "200dpi"
- change "Border Width" to 50
- export, download the resulting PNG image

After exporting all PNG images, move them to this directory, and run:

```bash
for F in kubernetes-services-*.png; do
  NEWF=$(echo "${F#kubernetes-services-}" | tr " " "-")
  mv "$F" "$NEWF"
done
```
