#-----------------------------------------------------------------------------------------------------
# Create new APP in FortiWEB Cloud
#-----------------------------------------------------------------------------------------------------
# Template command to create an APP on FortiWEB Cloud and export CNAME to file named "file_name"
data "template_file" "fwb_cloud_create_app" {
  template = file("./templates/fwb_cloud_new_app.tpl")
  vars = {
    token       = var.fwb_cloud_token
    region      = local.fortiweb_region["aws"]
    app_name    = "${local.app_name}"
    zone_name   = local.route53_zone_name
    server_ip   = local.fgt_values["aws"]["PUBLIC_IP"]
    server_port = local.app_nodeport
    template_id = local.fwb_cloud_template
    file_name   = "cname_record.txt"
    platform    = local.fortiweb_platform["aws"]
  }
}
# Launch command
resource "null_resource" "fwb_cloud_create_app" {
  provisioner "local-exec" {
    command = data.template_file.fwb_cloud_create_app.rendered
  }
}
#-----------------------------------------------------------------------------------------------------
# Create new Route53 record
#-----------------------------------------------------------------------------------------------------
# Read Route53 Zone info
data "aws_route53_zone" "route53_zone" {
  name         = "${local.route53_zone_name}."
  private_zone = false
}
# Read FortiWEB new APP CNAME file after FWB Cloud command be applied
data "local_file" "fwb_cloud_app_cname" {
  depends_on = [null_resource.fwb_cloud_create_app]
  filename   = "cname_record.txt"
}
# Create Route53 record entry with FWB APP CNAME
resource "aws_route53_record" "app_record_type_cname" {
  zone_id  = data.aws_route53_zone.route53_zone.zone_id
  name     = "${local.app_name}.${data.aws_route53_zone.route53_zone.name}"
  type     = "CNAME"
  ttl      = "30"
  records  = [data.local_file.fwb_cloud_app_cname.content]
}
