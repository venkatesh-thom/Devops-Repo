# -----------------------------
# IAM Groups
# -----------------------------

resource "aws_iam_group" "education" {
  name = "Education"
  path = "/groups/"
}

resource "aws_iam_group" "managers" {
  name = "Managers"
  path = "/groups/"
}

resource "aws_iam_group" "engineers" {
  name = "Engineers"
  path = "/groups/"
}

# -----------------------------
# Group Membership
# -----------------------------

# Add users to the Education group
resource "aws_iam_group_membership" "education_members" {
  name  = "education-group-membership"
  group = aws_iam_group.education.name

  users = [
    for user in aws_iam_user.users : user.name if user.tags.Department == "Education"
  ]
}

# Add users to the Managers group
resource "aws_iam_group_membership" "managers_members" {
  name  = "managers-group-membership"
  group = aws_iam_group.managers.name

  users = [
    for user in aws_iam_user.users : user.name if contains(keys(user.tags), "JobTitle") && can(regex("Manager|CEO", user.tags.JobTitle))
  ]
}

# Add users to the Engineers group
resource "aws_iam_group_membership" "engineers_members" {
  name  = "engineers-group-membership"
  group = aws_iam_group.engineers.name

  users = [
    for user in aws_iam_user.users : user.name if user.tags.Department == "Engineering"
  ]
}




# -----------------------------
# Policies
# -----------------------------

## Creates a managed IAM policy
resource "aws_iam_policy" "managers_policy" {
  name        = "ManagersPolicy"
  description = "Permissions for Managers group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "s3:ListAllMyBuckets"
        ]
        Resource = "*"
      }
    ]
  })
}


# Attaches the policy to the Managers group
resource "aws_iam_group_policy_attachment" "managers_attach" {
  group      = aws_iam_group.managers.name
  policy_arn = aws_iam_policy.managers_policy.arn
}

## Create a managed policy for Engineers

resource "aws_iam_policy" "engineers_policy" {
  name        = "EngineersPolicy"
  description = "Permissions for Engineers group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}

## Attach the policy to the Engineers group
resource "aws_iam_group_policy_attachment" "engineers_attach" {
  group      = aws_iam_group.engineers.name
  policy_arn = aws_iam_policy.engineers_policy.arn
}


