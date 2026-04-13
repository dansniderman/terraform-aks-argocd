---
name: "Bootstrap Argo CD GitOps"
description: "Add or update AKS and Argo CD bootstrap work in this repository using the Microsoft GitOps with Argo CD guidance"
argument-hint: "Describe the GitOps or Argo CD bootstrap change you want"
agent: "agent"
model: "GPT-5 (copilot)"
---
Implement the requested bootstrap or GitOps change for this repository.

Requirements:

1. Use the Microsoft tutorial pattern for GitOps with Argo CD on AKS as the default reference model.
2. Keep the environment suitable for learning and lowest practical cost.
3. Assume the AKS cluster must use managed identity.
4. Prefer the Azure `Microsoft.ArgoCD` extension path unless the user explicitly asks for a different Argo CD installation method.
5. Use workload identity and Microsoft Entra-based Argo CD auth settings by default unless the user explicitly asks for a simpler non-SSO mode.
6. For a single-node learning cluster, keep `redis-ha.enabled=false` unless the user requests a multi-node or higher-availability topology.
7. Update any Terraform, prompts, and README guidance that becomes stale because of the change.
8. Call out prerequisites such as Azure provider registration, Azure CLI extensions, networking, Entra IDs, or federated credential setup when they matter to the requested change.
