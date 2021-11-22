resource "aws_iam_role" "example" {
  name = "MY-codebuild-role-for-${var.app_name}-${var.env}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "example" {
  role = aws_iam_role.example.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "ec2:*",
        "logs:*",
        "iam:*",
        "ecs:*",
        "ecr:*",
        "s3:*",
        "dynamodb:*",
        "elasticloadbalancing:*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "ecs_full_access" {
  role = aws_iam_role.example.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}