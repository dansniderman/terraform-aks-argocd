---
name: "Implement Terraform AKS Change"
description: "Implement or update Terraform in this repository for an AKS-related change"
argument-hint: "Describe the Terraform or AKS change to implement"
agent: "agent"
model: "GPT-5 (copilot)"
---
Implement the requested Terraform change in this repository.

Requirements:

1. Follow the repository guidance in `.github/copilot-instructions.md`.
2. Reuse the existing file layout unless there is a strong reason to restructure.
3. Keep provider constraints, variables, outputs, and resource composition organized in the standard Terraform files.
4. Update `terraform.tfvars.example` and `README.md` when new user-facing inputs or setup steps are introduced.
5. Preserve the low-cost learning goal by preferring free or cheapest practical tiers unless the requested feature requires more.
6. Treat Argo CD as part of the target platform when the change affects cluster bootstrap or GitOps flow.
7. Stay compatible with the Microsoft tutorial approach for AKS plus the `Microsoft.ArgoCD` extension unless the user explicitly asks for a different installation model.
8. For single-node learning clusters, preserve the non-HA Argo CD setting unless the user asks for a larger topology.
9. Default to workload identity configuration for Argo CD and call out any required Entra IDs, federated credentials, or role assignments.
10. Call out any Azure prerequisites or assumptions that cannot be inferred from the repository.

