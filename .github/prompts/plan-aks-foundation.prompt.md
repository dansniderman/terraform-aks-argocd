---
name: "Plan AKS Foundation"
description: "Plan Terraform structure and inputs for a new AKS implementation in this repository"
argument-hint: "Describe the target AKS environment, constraints, and required features"
agent: "agent"
model: "GPT-5 (copilot)"
---
You are planning the initial Terraform design for this repository.

Priorities:

1. Keep the solution suitable for a low-cost learning environment.
2. Assume Argo CD must be included in the target design.
3. Stay aligned with the Microsoft tutorial for GitOps with Argo CD on AKS, including managed identity prerequisites, workload identity integration, and the single-node Argo CD learning pattern.

Use the user input as the target environment and produce:

1. A recommended repository structure for the requested AKS scope.
2. The Terraform files or modules that should be created or updated.
3. The input variables that should exist, with a short purpose for each.
4. The Azure resources that are required.
5. The Microsoft tutorial prerequisites or bootstrap steps that must be preserved, including workload identity prerequisites.
6. Any expected cost drivers and how to keep them low.
7. Any risks, missing assumptions, or sequencing concerns.

Keep the plan concise and tailored to this repository layout.
