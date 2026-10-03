# Coolify Deployment

## What this deploys

MoneyPrinterV2 is currently a Python CLI and background-job runner, not an HTTP web app. It does not listen on a port, so do not configure a Coolify domain or HTTP health check. The Compose service runs as a persistent worker; Coolify Scheduled Tasks can invoke the existing one-shot jobs in the running container.

## Configure

1. Create a `config.json` from `config.example.json` and store it on the Coolify host in a persistent location. Do not commit secrets to Git.
2. Set the Coolify Compose environment variable `MPV2_CONFIG_FILE` to that file's absolute host path. The file must be readable by UID/GID `1000` (for example, use mode `0644` on the host file).
3. In `config.json`, set `firefox_profile` to `/data/firefox-profile`, `headless` to `true`, and `imagemagick_path` to `/usr/bin/convert`.
4. Set `ollama_base_url` to an Ollama endpoint reachable from the container. `127.0.0.1` inside the container is the container itself; on the Docker host, `http://host.docker.internal:11434` may be used when Ollama is listening on the host and the host firewall allows it. Configure the required provider credentials as well.
5. Populate the persistent Firefox profile volume with a Linux Firefox profile already authenticated to the target sites. An empty volume does not contain account sessions; login/profile provisioning is not automated by this project.
6. Deploy as a Docker Compose resource. No port mapping is required. The first image build is large because it installs Python ML/TTS dependencies, Firefox, FFmpeg, ImageMagick, and Go.

The Compose file persists generated work under `.mp`, user-provided audio under `Songs`, the Firefox profile, and model caches. Back these volumes up as appropriate.

## Scheduled jobs

Create Coolify Scheduled Tasks that execute these commands in the `moneyprinter` service, replacing the account UUID and optionally the model name:

```sh
python -u src/cron.py youtube ACCOUNT_UUID [MODEL]
python -u src/cron.py twitter ACCOUNT_UUID [MODEL]
```

Each invocation runs one job and exits. The schedule configured interactively in `src/main.py` is an in-process CLI scheduler; it is not used by this worker service.

For an interactive local CLI session, run:

```sh
docker compose run --rm -it moneyprinter python -u src/main.py
```

That interactive menu is not exposed as a Coolify web interface. A web UI/API would need to be implemented separately before this can be deployed as a browser-facing app.
