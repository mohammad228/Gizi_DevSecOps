# DevSecOps Project

This project is designed to run automated security scans for code, configurations, containers, and infrastructure using various security tools like **Gosec**, **Semgrep**, and **Trivy**. The scan results are uploaded to **DefectDojo** for vulnerability tracking and management.

## Tools Included
- **Gosec**: Static code analysis for Go code.
- **Semgrep**: Static analysis for a wide variety of languages.
- **Trivy**: Vulnerability scanner for container images, file systems, and Infrastructure as Code (IaC).
- **DefectDojo**: Platform for managing security vulnerabilities and findings.

## Project Setup

### Prerequisites
Ensure you have the following installed on your system:
- Docker
- Git

### Build Docker Image
To build the Docker image for this project, clone the repository and navigate to the project directory. Then run the following command:
```bash
docker build -t security-scan-image .
```

### Running the Container
Once the image is built, you can run the Docker container:
```bash
docker run --env CI_PROJECT_NAME=<project_name> \
           --env CI_COMMIT_BRANCH=<commit_branch> \
           --env CI_PROJECT_DIR=<project_directory> \
           --env FULL_IMAGE_NAME=<full_image_name> \
           --env CI_COMMIT_SHORT_SHA=<commit_short_sha> \
           --env ENG_ID=<engagement_id> \
           --env GOLANG=<true|false> \
           --env SERVICE=<service_name> \
           security-scan-image
```

### Environment Variables

The container uses the following environment variables to configure the scans:
- `CI_PROJECT_NAME`: Name of the project being scanned.
- `CI_COMMIT_BRANCH`: Branch name of the commit.
- `CI_PROJECT_DIR`: Directory path where the project resides.
- `FULL_IMAGE_NAME`: The full name of the container image to be scanned.
- `CI_COMMIT_SHORT_SHA`: Short SHA of the commit for labeling purposes.
- `ENG_ID`: Engagement ID for DefectDojo uploads.
- `GOLANG`: If `true`, runs Gosec scan for Go code. Otherwise, runs Semgrep scan.
- `SERVICE`: Specify the service name if scanning a particular subdirectory (e.g., `deposit`, `withdrawals`).

### Available Scans
The following security scans are performed by the container:
- **Gosec**: Scans for security issues in Go code.
- **Semgrep**: Static code analysis for multi-language projects.
- **Trivy Filesystem (FS)**: Scans the project's file system for vulnerabilities.
- **Trivy Container (Image)**: Scans container images for vulnerabilities.
- **Trivy IaC**: Scans Infrastructure as Code files for misconfigurations.

### DefectDojo Integration
The scan reports are automatically uploaded to DefectDojo. You must provide the following environment variables to upload reports:
- `DEFECTDOJO_API_KEY`: API key for DefectDojo.
- `DEFECTDOJO_URL`: Base URL of your DefectDojo instance.
- `DEFECTDOJO_PRODUCT_ID`: Product ID for the engagement where the reports will be uploaded.

### Example Usage

#### Scanning a Go Project
```bash
docker run --env CI_PROJECT_NAME="My Go Project" \
           --env CI_COMMIT_BRANCH="main" \
           --env CI_PROJECT_DIR="/path/to/project" \
           --env FULL_IMAGE_NAME="myrepo/myimage:latest" \
           --env CI_COMMIT_SHORT_SHA="abc123" \
           --env ENG_ID="1234" \
           --env GOLANG="true" \
           --env SERVICE="deposit" \
           security-scan-image
```

#### Scanning a Container Image and Uploading to DefectDojo
```bash
docker run --env CI_PROJECT_NAME="Container Project" \
           --env CI_COMMIT_BRANCH="main" \
           --env CI_PROJECT_DIR="/path/to/project" \
           --env FULL_IMAGE_NAME="myrepo/myimage:latest" \
           --env CI_COMMIT_SHORT_SHA="abc123" \
           --env ENG_ID="1234" \
           security-scan-image
```

## Scan Output
- **Gosec/Trivy/Semgrep**: Each scan generates a JSON report (`FS_report.json`, `CON_report.json`, `IAC_report.json`, `results.json`, `semgrep.json`).
- The reports are uploaded to DefectDojo automatically.

## Troubleshooting
If the scans fail or the reports are not uploaded to DefectDojo, check the following:
- Verify the environment variables, particularly `DEFECTDOJO_API_KEY`, `DEFECTDOJO_URL`, and `DEFECTDOJO_PRODUCT_ID`.
- Ensure Trivy, Semgrep, and Gosec are properly installed and configured within the Docker container.
- For debugging, you can inspect the scan results and error messages from the output of the container run.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
