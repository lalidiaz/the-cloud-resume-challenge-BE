# Cloud Resume Challenge

## Overview
This project implements the [Cloud Resume Challenge](https://cloudresumechallenge.dev/), a hands-on project that demonstrates cloud skills through building and deploying a personal resume website with a visitor counter using cloud services.

## Architecture
![Blank diagram (4)](https://github.com/user-attachments/assets/1a9bfceb-2c5b-4588-9592-4d4fa9474498)


The solution uses the following components:
- **Backend**: Serverless API **API GATEWAY**
- **Database**: NoSQL database to store visitor count **DynamoDB**
- **Infrastructure as Code**: All resources deployed using IaC **Terraform**
- **CI/CD Pipeline**: Automated deployments **Github Acions**

## Features
- Responsive resume website
- Visitor counter implemented using JavaScript
- Serverless API to retrieve and update visitor count
- Infrastructure defined as code
- Automated deployments through CI/CD

## Technical Stack
- **Cloud Provider**: AWS
- **Database**: DynamoDB
- **IaC**: Terraform
- **CI/CD**: GitHub Actions

## Future Improvements
- Implementing comprehensive testing (planned for second iteration)
- Enhanced security features
- Performance optimizations
- Analytics integration

## Project Status
This is the first iteration of the Cloud Resume Challenge implementation. Testing will be added in the second iteration to ensure code quality and reliability.

## Deployment
The live version of this resume can be found at: https://lauradiazcloudengineer.com/


## Repository Structure
```
/
├──/         # Lambda code
├── terraform/  # IaC templates
├── .github/         # CI/CD workflows
└── README.md        # This file
```

## Acknowledgements
- [Cloud Resume Challenge](https://cloudresumechallenge.dev/) for the project idea
