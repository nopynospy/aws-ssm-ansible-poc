resource "aws_ssm_patch_baseline" "this" {
  name             = var.patch_baseline_name
  operating_system = "AMAZON_LINUX_2"
  approval_rule {
    approve_after_days = 3

    patch_filter {
      key    = "CLASSIFICATION"
      values = ["Security", "Recommended", "Bugfix"]
    }

    patch_filter {
      key    = "SEVERITY"
      values = ["Critical", "Important"]
    }
  }
}

resource "aws_ssm_patch_group" "this" {
  baseline_id = aws_ssm_patch_baseline.this.id
  patch_group = var.patch_group_name
}