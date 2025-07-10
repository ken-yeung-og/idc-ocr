output "s3_bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.document_bucket.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.document_bucket.arn
}

output "dynamodb_table_name" {
  description = "Name of the created DynamoDB table"
  value       = aws_dynamodb_table.document_table.name
}

output "dynamodb_table_arn" {
  description = "ARN of the created DynamoDB table"
  value       = aws_dynamodb_table.document_table.arn
}

output "lambda_function_name" {
  description = "Name of the created Lambda function"
  value       = aws_lambda_function.document_processor.function_name
}

output "lambda_function_arn" {
  description = "ARN of the created Lambda function"
  value       = aws_lambda_function.document_processor.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}

output "upload_instructions" {
  description = "Instructions for uploading documents"
  value       = "Upload documents to S3 bucket: ${aws_s3_bucket.document_bucket.bucket}"
} 