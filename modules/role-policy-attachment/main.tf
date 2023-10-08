data "aws_iam_policy" "policy" {
  name = var.policy_name
}

resource "aws_iam_role_policy_attachment" "attached_policy" {
  role       = var.role_name
  policy_arn = data.aws_iam_policy.policy.arn
}
