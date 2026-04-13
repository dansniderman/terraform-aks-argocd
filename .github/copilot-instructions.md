# Project Guidelines

## Scope

This repository provisions Azure Kubernetes Service infrastructure with Terraform.

This repository is for learning, so changes should prefer the cheapest practical Azure options unless a more expensive feature is explicitly required.

## Terraform Conventions

- Prefer small, composable Terraform changes.
- Keep variables, outputs, and provider constraints in their dedicated root files.
- Prefer explicit variable descriptions and sensible defaults only when safe.
- Avoid hardcoded names, locations, and CIDR ranges when they should be inputs.
- Keep comments brief and only where the intent is not obvious.

## Azure Conventions

- Default to AzureRM resources unless a specific Azure API gap requires another approach.
- Surface AKS settings such as Kubernetes version, node pool sizing, and network settings as variables.
- Favor managed identities and least-privilege role assignments.
- Prefer AKS `Free` tier and minimal node counts for learning environments.
- Avoid optional paid add-ons and premium SKUs unless the learning objective depends on them.
- Treat Argo CD as a required capability for this repository and keep its installation explicit in Terraform or the documented bootstrap flow.
- Prefer workload identity and Microsoft Entra-based auth for Argo CD where feasible, and avoid static credentials.

## Cost Guardrails

- Default to one node in the system pool for learning unless a component requires more.
- Prefer low-cost VM sizes that are broadly available in Azure regions used for demos.
- Call out any resource that materially increases ongoing monthly cost.

## Working Style

- Before adding resources, check whether the root module should stay flat or extract a reusable module.
- When changing Terraform, also update `terraform.tfvars.example` and `README.md` if inputs or setup steps change.
- Keep generated output aligned with existing file layout unless the task explicitly asks for restructuring.
- If a change affects Argo CD deployment or operating cost, document that tradeoff briefly.
