# https-reverse-proxy-over-ssh

Expose your local HTTP service to a public HTTPS service using Caddy and an SSH tunnel.

## Introduction

This is a simple implementation of an HTTPS reverse proxy for a web service running on your local system.
It functions similar to popular services like
[ngrok](https://ngrok.com/) or
[localhost.run](http://localhost.run/)

The difference with these services:
- this proxy runs on a server of your own, adding privacy and control over domain names and port numbers.
- ...
 
HTTPS server certificates are generated automatically using Let's Encrypt.

In a nutshell, all this script does is

1. terminate HTTPS connections from the Internet using Let's Encrypt certificates generated on-the-fly,
2. reverse proxy those connections to a local service,
3. which is routed over an SSH tunnel back to the SSH client

Similar to:

    ssh proxy.example.org -l ubuntu -R 1234:localhost:8080 caddy reverse-proxy --from https://proxy.aai.surfn0www0:4443 --to localhost:1234


# Install

This reverse proxy can be deployed on any server, assuming ubuntu:

Install [jq](https://stedolan.github.io/jq/):

      apt install jq

Install [Caddy](https://caddyserver.com/docs/download):

    echo "deb [trusted=yes] https://apt.fury.io/caddy/ /" | sudo tee -a /etc/apt/sources.list.d/caddy-fury.list
    sudo apt update
    sudo apt install caddy

Install Caddy config file:

    sudo cp Caddyfile.example /etc/caddy/Caddyfile

Replace the first line in that file with the fully qualified domain name of your reverse proxy.

Create the reverse proxy config file:

    cp config.example config

Replace the HOST variable in that file with the fully qualified domain name of your reverse proxy.

## Install using ansible

Create an ansible `inventory` file with the name of your proxy.
Then run the ansible playbook using:

    ansible-playbook -i inventory ansible/playbook.yml

If needed, you can specify the SSH key t ouse with  something like `--key-file "~/.ssh/rsa_id.pem"`

Add user `ubuntu` to group `caddy`:

    adduser ubuntu caddy

# Use

Start a local web service, for instance using Caddy on your local system:

    caddy file-server -browse -listen :8004

Or using PHP's builtin web server:

    echo '<?php phpinfo();' > /tmp/index.php
    php -S 0:8001 /tmp/index.php 

Then, open a tunnel to the proxy with the necessary plumbing:

    ssh proxy.example.org -l ubuntu -i ~/.ssh/id_rsa.pem -R 8001:localhost:8001 -t ./reverse-proxy.sh 1

# Implementation

Upon a succesful SSH connection, a Caddy configuration is generated and loaded, similar to:

```
https://proxy.example.org {
    reverse_proxy :8001
    log {
	output file /tmp/access.log
	format single_field common_log
    }
}
```

The local service on port 8001 is forwarded over the SSH tunnel to the SSH client.

# Security

Note that when connecting to your proxy, anyone on the Internet can connect to your local web service.
Use a firewall on your proxy to limit web clients.

Also make sure you don't accidentally expose a service by proxying a port on which another service is already listening.

# Troubleshooting

See Caddy logs:

    journalctl --no-pager -u caddy

Reset Caddy to default config:

    systemctl reload caddy

#  TO DO

- replace homepage in /var/www/html with user instructions
- add instructions with SSH certificates
- use virtual hosts insteead of port numbers

