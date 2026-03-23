aws_region          = "us-east-1"
project_name        = "mypythonproject1"
expected_account_id = "128977215002"

environments = ["dev", "staging", "prod"]

# Keep names stable to match existing landing-zone resources.
state_bucket_names = {
  dev     = "mypythonproject1-tfstate-eks-dev"
  staging = "mypythonproject1-tfstate-eks-staging"
  prod    = "mypythonproject1-tfstate-eks-prod"
}

github_actions_role_name = "GitHubActionsRole"

github_oidc_subjects = [
  # infra2 repo — Terraform CI/CD
  "repo:YilingCAI/python-angular-project1-infra2:environment:dev",
  "repo:YilingCAI/python-angular-project1-infra2:environment:staging",
  "repo:YilingCAI/python-angular-project1-infra2:environment:prod",
  "repo:YilingCAI/python-angular-project1-infra2:ref:refs/heads/main",
  "repo:YilingCAI/python-angular-project1-infra2:pull_request",

  # app repo — CD workflow (ECR push + EKS deploy)
  "repo:YilingCAI/python-devops-aws-project1:environment:dev",
  "repo:YilingCAI/python-devops-aws-project1:environment:staging",
  "repo:YilingCAI/python-devops-aws-project1:environment:prod",
  "repo:YilingCAI/python-devops-aws-project1:ref:refs/heads/main",
  "repo:YilingCAI/python-devops-aws-project1:ref:refs/heads/developer",
  "repo:YilingCAI/python-devops-aws-project1:ref:refs/heads/feature/*"
]

oidc_thumbprints = [
  "6938fd4d98bab03faadb97b34396831e3780aea1"
]
