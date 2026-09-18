# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Infrastructure-as-code for a personal "utility cluster" in AWS (`us-east-2`, VPC tagged
`sb-utility-us-east-2`): Prometheus + Grafana + AlertManager + nginx on one node, a Consul
server cluster across three AZs, and (currently commented out) Kafka/ZooKeeper/app nodes.

There is no application code, no build, and no test suite. Everything is OpenTofu/Terraform
HCL plus Ansible roles.

## The core loop: Terraform writes Ansible's inputs

This is the single most important thing to understand. Terraform does not just create
instances — it generates the Ansible inventory, SSH config, and group_vars via `local_file`
resources and `templatefile()`. Nothing in `infra/` is hand-maintained (all of it is
gitignored), so **you must apply Terraform before running any playbook**, and any change to
what Ansible consumes starts in `aws-resources/templates/*.tpl`, not in `infra/`.

Generated artifacts:

| Terraform resource | Output | Template |
|---|---|---|
| `main.tf` `host_file` | `infra/all_hosts` (inventory) | `templates/hosts.cfg` |
| `main.tf` `ssh_config` | `infra/ssh.cfg` (bastion ProxyCommand) | `templates/ssh.cfg` |
| `main.tf` `prom_group_file` | `infra/group_vars/prom_servers` | `templates/prom_groups_vars.tpl` |
| `consul_servers.tf` `null_resource.consul_groups_vars` | `infra/group_vars/consul_servers` | module output |
| `keys.tf`, `prom.tf`, `consul_servers.tf` | `secrets/` (SSH key, TLS certs, gossip key) | — |

The Prometheus node doubles as the SSH bastion: `ssh.cfg` proxies every `10.20.*.*` host
through its public IP, which is why the generated `ssh.cfg` changes whenever that instance is
recreated. Consul servers are private-only (`private_host: true` skips their apt upgrade in
the `common` role).

## Commands

Terraform/OpenTofu (JetBrains config points at `/opt/homebrew/bin/tofu`; `terraform` works too):

```bash
cd aws-resources        # or azure-resources
tofu init
tofu plan
tofu apply
```

State is local (`aws-resources/terraform.tfstate`, gitignored) — there is no remote backend,
so the state file on this machine is the only copy.

Ansible (always from `infra/`, which is where `ansible.cfg` and the relative paths resolve):

```bash
cd infra
source env/bin/activate            # venv committed-in-place; pip install -r requirements.txt to rebuild
ansible-playbook servers.yaml                        # full cluster config
ansible-playbook servers.yaml --limit prom_servers   # one group
ansible-playbook servers.yaml --check --diff        # no tags are defined anywhere; use --limit to scope
ansible-playbook start_servers.yaml                  # EC2 start + rewrite all_hosts with new IPs
ansible-playbook stop_servers.yaml                   # EC2 stop
```

`start_servers.yaml`/`stop_servers.yaml` run on `localhost` and shell out to the `aws` CLI
over a `instance_ids` dict (instance-id → inventory name) that must be supplied, e.g.
`-e '{"instance_ids": {"i-abc": "prometheus"}}'`. `start` rewrites the `ansible_host` lines in
`all_hosts` in place.

Playbook entry points: `servers.yaml` (everything), `kafka.yaml`, `zk.yaml`,
`post_consul.yaml` (Consul ACL policies/tokens, run after servers are up), `test.yaml`
(scratch).

## Conventions

- **Roles are composed, not monolithic.** `common` + `node_exporter` run on all hosts;
  service roles layer on top. Every daemon role starts by `include_role: service_account`
  with `account_name` to create its unprivileged user/group — follow that when adding one.
- **Versions live in `roles/*/defaults/main.yaml`** (`prometheus_version`, `consul_version`,
  `node_exporter_version`, …) and drive the download URL and unpack directory name. Upgrading
  a component usually means editing only the default.
- **Commented-out blocks are the toggle mechanism.** Kafka, ZooKeeper, and the app node are
  wired up but disabled by comments in `kafka.tf`, `main.tf`'s `host_file` locals, and
  `servers.yaml`. Re-enabling means uncommenting the module, its `local_file` group_vars
  resource, *and* the corresponding `*_host_group` in `main.tf`. `app.tf.d` is a
  deliberately-disabled `.tf` file (rename to `app.tf` to activate).
- **`consul_enabled`** (derived in Terraform from whether any Consul servers exist) switches
  the nginx site config between `roles/prom_nginx_config/files/consul` and `non_consul`.
- Bare (unquoted) resource/provider/module names are the house HCL style throughout.

## External dependencies

- **Sibling repo at `../../vpcs`** (i.e. outside this repo) supplies the CA material read by
  `file("../../vpcs/secrets/podspace_ca_{cert,key}.pem")` and `internal_ca_*.pem` in `prom.tf`,
  `consul_servers.tf`, `azure-resources/main.tf`, and `roles/common/tasks/main.yaml`. Without
  it, plan and the `common` role both fail.
- **Private Terraform modules**: `github.com/smuggy/tf-services` (consul, prometheus) — the
  Consul source uses `git::ssh://`, so an SSH agent with GitHub access is required for
  `tofu init`; `github.com/smuggy/terraform-base` (key pair, entity certificates); and
  `app.terraform.io/podspace/base/aws` (compute/instance, route53 records) — needs a Terraform
  Cloud login.
- **AMI**: `data aws_ami ubuntu` filters on `owners = ["self"]` and name `ubuntu-aws-base-*`,
  a custom image that must already exist in the account.
- The VPC, subnets (tagged `use = public`), Route53 zones (`podspace.internal`, `podspace.net`,
  reverse `20.10.in-addr.arpa`), and the `promsa` IAM user are assumed pre-existing.

## Secrets

`secrets/` and `infra/group_vars/` are gitignored and contain live material — the SSH private
key, Consul TLS keys, the gossip key, and (in `group_vars/prom_servers`) a real AWS access
key/secret pair generated by `aws_iam_access_key.prom_access`. These are regenerated by
`tofu apply`; don't move them into tracked files.

## Azure

`azure-resources/` is a parallel, much smaller Prometheus-only deployment with its own local
state. It is not kept in sync with `aws-resources/` — treat AWS as the primary.
