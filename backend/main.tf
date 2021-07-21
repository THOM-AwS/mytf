module "backend" {
  source = "github.com/cmdlabs/cmd-tf-aws-backend?ref=0.9.0"

  resource_prefix             = local.workspace["resource_prefix"]
  prevent_unencrypted_uploads = false

  all_workspaces_details = []
  workspace_details      = {}

  tags = {
    repository = "hamer/backend"
    workspace  = terraform.workspace
  }
}
