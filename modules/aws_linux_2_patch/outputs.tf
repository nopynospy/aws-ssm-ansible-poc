output "patch_group_id" {
  description = "EC2 patch group ID, to be used in EC2 tag key, 'Patch Group'"
  value       = aws_ssm_patch_group.this.id
}