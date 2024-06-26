# MTProxy Docker Builds

This is a fork of the official [TelegramMessenger/MTProxy](https://github.com/TelegramMessenger/MTProxy) that only adds Docker builds and scripts for operating the proxy. Source files stay **untouched**, only changing compilation flags or environment variables if required for the build.

Check the differences with the original repository [here](https://github.com/TelegramMessenger/MTProxy/compare/master..sirikon:master).

Builds are automated on the `master` branch using GitHub Actions.

Check the latest builds [here](https://github.com/sirikon/MTProxy/pkgs/container/mtproxy).

> [!IMPORTANT]  
> A functioning MTProxy instance requires to have an up-to-date configuration file that is downloaded at start from Telegram servers. This file changes **regularly**, maybe multiple times per day, and MTProxy doesn't reload this file automatically.
>
> This means that you'll need to **regularly restart the container** to ensure that it keeps working smoothly over time. Maybe configure a cronjob to do that 😬.

## Usage

```bash
# Customize as needed. This is just an example.
docker run \
    -p 443:443 \
    -v ./mtproxy_data:/data \
    ghcr.io/sirikon/mtproxy:latest
```

Available environment variables to configure the proxy when executed (pass these using `-e ENV=val` arguments in `docker run`):

- `SECRET`: The proxy secret can be explicitly configured with this environment variable. If omitted, the container will generate one automatically and store it in the `/data` directory to re-use it after restarts.
- `EXTERNAL_IP_PROVIDER` (default: `https://checkip.amazonaws.com`): An HTTP address that returns the external IP address of the client connecting to it in plain text. Some common alternatives:
    - `https://digitalresistance.dog/myIp`
- `PROXY_PORT` (default: `443`): The internal proxy port to listen to inside the Docker container. You don't need to change this setting to expose the proxy with a different port. Just change the port mapping in the `docker run` command. (Example: `-p 4343:443`).
- `WORKERS` (default: `2`): Number of workers to spawn on start.
- `MAX_CONNECTIONS` (default: `60000`): The maximum number of connections a single worker will be able to accept.
- `STATS_PORT` (default: `8888`): The internal stats port to listen to inside the Docker container. Stats can be accessed by calling to the HTTP server from inside the Docker container: `curl http://127.0.0.1:8888/stats`.

### `mtproxy-cli`

The container includes the utility `mtproxy-cli` to have more possibilities while operating the proxy:

```
mtproxy-cli -- Manage the MTProxy container
  Usage: mtproxy-cli <command>

  Available commands:
    start           -  Starts the proxy server
    refresh-config  -  Refreshes the configuration stored in /cache
```

- `start`: Starts the proxy server. This is the containers default command when calling `docker run` without any explicit command at the end.
- `refresh-config`: Will refresh the proxy configuration file stored in the `/cache` directory.

### Optimization: Refresh config files while the proxy is running

The `refresh-config` command enables the possibility of downloading the new version of configuration files while the server is still running, and then restarting it afterwards, increasing the time the server is up and serving requests.

```bash
# You'll need to mount the cache directory too
# for this optimization to work
docker run \
    -p 443:443 \
    -v ./mtproxy_data:/data \
    -v ./mtproxy_cache:/cache \
    ghcr.io/sirikon/mtproxy:latest

# Now, whenever you want to restart the proxy...
docker exec -t "$container_id_here" mtproxy-cli refresh-config
docker restart "$container_id_here"
```

---

<br>
<br>
<br>
<br>
<br>

_original README.md starts after this line_

---

# MTProxy
Simple MT-Proto proxy

## Building
Install dependencies, you would need common set of tools for building from source, and development packages for `openssl` and `zlib`.

On Debian/Ubuntu:
```bash
apt install git curl build-essential libssl-dev zlib1g-dev
```
On CentOS/RHEL:
```bash
yum install openssl-devel zlib-devel
yum groupinstall "Development Tools"
```

Clone the repo:
```bash
git clone https://github.com/TelegramMessenger/MTProxy
cd MTProxy
```

To build, simply run `make`, the binary will be in `objs/bin/mtproto-proxy`:

```bash
make && cd objs/bin
```

If the build has failed, you should run `make clean` before building it again.

## Running
1. Obtain a secret, used to connect to telegram servers.
```bash
curl -s https://core.telegram.org/getProxySecret -o proxy-secret
```
2. Obtain current telegram configuration. It can change (occasionally), so we encourage you to update it once per day.
```bash
curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf
```
3. Generate a secret to be used by users to connect to your proxy.
```bash
head -c 16 /dev/urandom | xxd -ps
```
4. Run `mtproto-proxy`:
```bash
./mtproto-proxy -u nobody -p 8888 -H 443 -S <secret> --aes-pwd proxy-secret proxy-multi.conf -M 1
```
... where:
- `nobody` is the username. `mtproto-proxy` calls `setuid()` to drop privilegies.
- `443` is the port, used by clients to connect to the proxy.
- `8888` is the local port. You can use it to get statistics from `mtproto-proxy`. Like `wget localhost:8888/stats`. You can only get this stat via loopback.
- `<secret>` is the secret generated at step 3. Also you can set multiple secrets: `-S <secret1> -S <secret2>`.
- `proxy-secret` and `proxy-multi.conf` are obtained at steps 1 and 2.
- `1` is the number of workers. You can increase the number of workers, if you have a powerful server.

Also feel free to check out other options using `mtproto-proxy --help`.

5. Generate the link with following schema: `tg://proxy?server=SERVER_NAME&port=PORT&secret=SECRET` (or let the official bot generate it for you).
6. Register your proxy with [@MTProxybot](https://t.me/MTProxybot) on Telegram.
7. Set received tag with arguments: `-P <proxy tag>`
8. Enjoy.

## Random padding
Due to some ISPs detecting MTProxy by packet sizes, random padding is
added to packets if such mode is enabled.

It's only enabled for clients which request it.

Add `dd` prefix to secret (`cafe...babe` => `ddcafe...babe`) to enable
this mode on client side.

## Systemd example configuration
1. Create systemd service file (it's standard path for the most Linux distros, but you should check it before):
```bash
nano /etc/systemd/system/MTProxy.service
```
2. Edit this basic service (especially paths and params):
```bash
[Unit]
Description=MTProxy
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/MTProxy
ExecStart=/opt/MTProxy/mtproto-proxy -u nobody -p 8888 -H 443 -S <secret> -P <proxy tag> <other params>
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
3. Reload daemons:
```bash
systemctl daemon-reload
```
4. Test fresh MTProxy service:
```bash
systemctl restart MTProxy.service
# Check status, it should be active
systemctl status MTProxy.service
```
5. Enable it, to autostart service after reboot:
```bash
systemctl enable MTProxy.service
```

## Docker image
Telegram is also providing [official Docker image](https://hub.docker.com/r/telegrammessenger/proxy/).
Note: the image is outdated.
