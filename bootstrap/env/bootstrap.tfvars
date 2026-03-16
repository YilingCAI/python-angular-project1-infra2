aws_region          = "us-east-1"
project_name        = "mypythonproject1"
<<<<<<< HEAD
expected_account_id = "891377039642"
=======
expected_account_id = "769254791061"
>>>>>>> feature/init

environments = ["dev", "staging", "prod"]

# Keep names stable to match existing landing-zone resources.
state_bucket_names = {
  dev     = "mypythonproject1-tfstate-eks-dev"
  staging = "mypythonproject1-tfstate-eks-staging"
  prod    = "mypythonproject1-tfstate-eks-prod"
}

github_actions_role_name = "GitHubActionsRole"

github_oidc_subjects = [
<<<<<<< HEAD
  "repo:YilingCAI/python-angular-project1-infra1:environment:dev",
  "repo:YilingCAI/python-angular-project1-infra1:environment:staging",
  "repo:YilingCAI/python-angular-project1-infra1:environment:prod",
  "repo:yilingcai/python-angular-project1-infra1:environment:dev",
  "repo:yilingcai/python-angular-project1-infra1:environment:staging",
  "repo:yilingcai/python-angular-project1-infra1:environment:prod",
  "repo:YilingCAI/python-angular-project1-infra1:ref:refs/heads/main",
  "repo:yilingcai/python-angular-project1-infra1:ref:refs/heads/main",
  "repo:YilingCAI/python-angular-project1-infra1:pull_request",
  "repo:yilingcai/python-angular-project1-infra1:pull_request"
=======
  "repo:YilingCAI/python-angular-project1-infra2:environment:dev",
  "repo:YilingCAI/python-angular-project1-infra2:environment:staging",
  "repo:YilingCAI/python-angular-project1-infra2:environment:prod",
  "repo:yilingcai/python-angular-project1-infra2:environment:dev",
  "repo:yilingcai/python-angular-project1-infra2:environment:staging",
  "repo:yilingcai/python-angular-project1-infra2:environment:prod",
  "repo:YilingCAI/python-angular-project1-infra2:ref:refs/heads/main",
  "repo:yilingcai/python-angular-project1-infra2:ref:refs/heads/main",
  "repo:YilingCAI/python-angular-project1-infra2:pull_request",
  "repo:yilingcai/python-angular-project1-infra2:pull_request"
>>>>>>> feature/init
]

oidc_thumbprints = [
  "6938fd4d98bab03faadb97b34396831e3780aea1"
]
