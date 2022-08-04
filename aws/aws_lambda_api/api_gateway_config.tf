resource "aws_api_gateway_rest_api" "this" {
  name        = "${local.prefix_with_domain}"
  description = "${var.comment_prefix}${var.api_domain}"
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = "${aws_api_gateway_rest_api.this.id}"

  depends_on = [
    "aws_api_gateway_integration.proxy_root",
    "aws_api_gateway_integration.proxy_other",
  ]
}

resource "aws_api_gateway_stage" "this" {
  # oak9: MethodSettings.HttpMethod is not configured
  stage_name    = "${var.stage_name}"
  description   = "${var.comment_prefix}${var.api_domain}"
  rest_api_id   = "${aws_api_gateway_rest_api.this.id}"
  deployment_id = "${aws_api_gateway_deployment.this.id}"
  tags          = "${var.tags}"
}

resource "aws_api_gateway_method_settings" "this" {
  # oak9: aws_api_gateway_method.authorization is not configured
  # oak9: aws_api_gateway_method.authorizer_id is not configured
  # oak9: aws_api_gateway_method.resource_id is not configured
  # oak9: aws_api_gateway_method.http_method is not configured
  rest_api_id = "${aws_api_gateway_rest_api.this.id}"
  stage_name  = "${aws_api_gateway_stage.this.stage_name}"
  method_path = "*/*"

  settings {
    metrics_enabled        = "${var.api_gateway_cloudwatch_metrics}"
    logging_level          = "${var.api_gateway_logging_level}"
    data_trace_enabled     = "${var.api_gateway_logging_level == "OFF" ? false : true}"
    throttling_rate_limit  = "${var.throttling_rate_limit}"
    throttling_burst_limit = "${var.throttling_burst_limit}"
  }
}

resource "aws_api_gateway_domain_name" "this" {
  # oak9: aws_api_gateway_domain_name.mutual_tls_authentication.truststore_uri is not configured
  # oak9: aws_api_gateway_domain_name.certificate_arn is not configured
  security_policy = "TLS_1_2"
  domain_name              = "${var.api_domain}"
  regional_certificate_arn = "${aws_acm_certificate_validation.this.certificate_arn}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "this" {
  api_id      = "${aws_api_gateway_rest_api.this.id}"
  stage_name  = "${aws_api_gateway_stage.this.stage_name}"
  domain_name = "${aws_api_gateway_domain_name.this.domain_name}"
}
