# IAM role for EC2 instance — allows SSM Agent to communicate with AWS
resource "aws_iam_role" "ec2_ssm" {
  name = "gs-rest-service-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Purpose = "Allows SSM Agent on the EC2 instance to receive commands"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Allows Certbot on the instance to create DNS TXT records for Let's Encrypt challenge
resource "aws_iam_role_policy" "ec2_certbot_route53" {
  name = "certbot-route53-dns-challenge"
  role = aws_iam_role.ec2_ssm.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListZones"
        Effect   = "Allow"
        Action   = "route53:ListHostedZones"
        Resource = "*"
      },
      {
        Sid      = "GetChange"
        Effect   = "Allow"
        Action   = "route53:GetChange"
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Sid      = "UpdateDNSChallenge"
        Effect   = "Allow"
        Action   = "route53:ChangeResourceRecordSets"
        Resource = "arn:aws:route53:::hostedzone/${data.aws_route53_zone.main.zone_id}"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "gs-rest-service-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name
}

# IAM user for GitHub Actions — least-privilege, Docker management via SSH only
resource "aws_iam_user" "github_actions_deploy" {
  name = "github-actions-deploy"
  path = "/ci/"

  tags = {
    Purpose = "GitHub Actions deployment user"
  }
}

# Minimal policy: allows GHA to describe the EC2 instance (e.g. to get the
# public IP dynamically). No write permissions to any AWS resource.
# Docker operations are performed over SSH — no AWS API access is required.
data "aws_iam_policy_document" "deploy_policy" {
  statement {
    sid    = "DescribeInstanceOnly"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "SSMSendCommand"
    effect = "Allow"
    actions = [
      "ssm:SendCommand",
    ]
    resources = [
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ssm:*::document/AWS-RunShellScript",
    ]
  }

  statement {
    sid    = "SSMReadCommandResult"
    effect = "Allow"
    actions = [
      "ssm:GetCommandInvocation",
      "ssm:ListCommandInvocations",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "deploy_policy" {
  name        = "github-actions-deploy-policy"
  description = "Allows GitHub Actions to describe EC2 instances and run SSM commands"
  policy      = data.aws_iam_policy_document.deploy_policy.json
}

resource "aws_iam_user_policy_attachment" "deploy_attach" {
  user       = aws_iam_user.github_actions_deploy.name
  policy_arn = aws_iam_policy.deploy_policy.arn
}

