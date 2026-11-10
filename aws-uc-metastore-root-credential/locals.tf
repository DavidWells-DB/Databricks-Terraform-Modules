locals {
  # Unity Catalog's IAM ARN for the trust policy. Partition-dependent:
  # aws -> arn:aws:iam::414351592139848:role/unity-catalog-prod-1;
  # aws-us-gov -> the GovCloud UC role. Verified against the provider data source.
  unity_catalog_iam_arn = (
    var.aws_partition == "aws-us-gov"
    ? "arn:aws-us-gov:iam::414351592139848:role/unity-catalog-prod-1"
    : "arn:aws:iam::414351592139848:role/unity-catalog-prod-1"
  )
}
