locals {
  # Merged tags applied uniformly to all taggable resources.
  common_tags = merge(var.tags, {
    Name = var.peering_name
  })
}
