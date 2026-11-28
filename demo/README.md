# Showcase GIF

This folder contains the VHS demo for `scratchpad`.

## Files

- `demo.tape` - VHS tape that records the demo
- `demo.gif` - generated output
- `Dockerfile` - minimal image with VHS dependencies (`nano`, `jq`)

## Generate the GIF

Build the image from the repo root:

```powershell
docker build -t scratchpad-vhs demo
```

Run the container with the repo mounted at `/vhs`:

```powershell
docker run --rm -it -v ${PWD}:/vhs scratchpad-vhs
```

From inside the container:

```bash
vhs demo/demo.tape
```

The tape writes `demo.gif` as configured by `Output` in `demo.tape`.
