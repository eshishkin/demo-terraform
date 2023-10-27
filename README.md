# Demo Project with Terraform

This is a demo project to test main features of Terraform along with Yandex Cloud.

## Cloud Architecture

These scripts install following infrastructure

- A serverless container (aka Google's Cloud Run) as an entrypoint. It handles HTTP requests with pictures
- S3 bucket where pictures are stored
- A set of cloud functions (aka Lambda) that organize processing pipeline for pictures
- Yandex Vision
- Cloud Queues

## Project Structure

This project is divided to several modules

- vpc - creates VPC
- queue - creates a cloud queue
- s3_storage - creates S3 storage and a bucket inside it
- s3_handler - creates cloud function with trigger that listens events from the bucket and calls Vision service
- ydb_storage - creates YDB storage
- stats_handler - creates cloud function that listens cloud queues and writes data to Yandex Database