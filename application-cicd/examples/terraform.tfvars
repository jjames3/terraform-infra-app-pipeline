project_name       = "tf-application"
environment        = "dev"
source_repo_name   = "terraform-application-repo"
source_repo_branch = "master"
create_new_repo    = true
repo_approvers_arn = "arn:aws:sts::397748281750:assumed-role/CodeCommitReview/*" #Update ARN (IAM Role/User/Group) of Approval Members
create_new_role    = true


stage_input = [
  { name = "plan", category = "Test", owner = "AWS", provider = "CodeBuild", input_artifacts = "SourceOutput", output_artifacts = "PlanOutput" },
  { name = "apply", category = "Build", owner = "AWS", provider = "CodeBuild", input_artifacts = "PlanOutput", output_artifacts = "ApplyOutput" }
]

build_projects = ["plan", "apply"]
