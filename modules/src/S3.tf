# ログ保存用S3バケット
resource "aws_s3_bucket" "elb_logs" {
  bucket = "s3-dev-i231-elbaccesslog"
  acl    = "private"

  lifecycle_rule {
    id      = "log"
    enabled = true

    transition {
      days          = 30
      storage_class = "STANDARD_IA" 
    }

    expiration {
      days = 60
    }
  }

  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"ELBLogDeliveryAclCheck",
      "Effect":"Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action":"s3:GetBucketAcl",
      "Resource":"arn:aws:s3:::s3-dev-i231-elbaccesslog"
    },
    {
      "Sid":" ELBLogDeliveryWrite",
      "Effect":"Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action":"s3:PutObject",
      "Resource":"arn:aws:s3:::s3-dev-i231-elbaccesslog/*",
      "Condition":{
        "StringEquals":{
          "s3:x-amz-acl":"bucket-owner-full-control"
        }
      }
    }
  ]
}
POLICY
}