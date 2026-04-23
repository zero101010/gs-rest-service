# Security Overview

This deployment exposes a single public EC2 instance running Nginx on ports 80 and 443, with the Spring Boot application listening only on localhost port 777 inside a container. The externally reachable attack surface is the public DNS name, the public IP on HTTP/HTTPS, and SSH on port 22 from one explicitly allowed operator IP. The instance also has AWS Systems Manager access and limited Route53 permissions so Certbot can complete DNS challenges.

## Controls And Threats Mitigated

| Control | Threat Mitigated |
| --- | --- |
| Security group allows HTTP/HTTPS from anywhere but restricts SSH to `local_ip_cidr` | Reduces unauthorized administrative access and limits brute-force SSH exposure to a known source IP |
| No security group rule exposes application port 777 directly | Prevents bypassing Nginx and reduces direct attack surface against the Java service |
| Nginx redirects HTTP to HTTPS and serves TLS with certificates from Let's Encrypt | Reduces credential or session exposure from plaintext transport and downgrade to unsecured HTTP |
| EC2 metadata service requires IMDSv2 with hop limit 1 | Reduces risk of SSRF-based theft of instance metadata and temporary credentials |
| Root EBS volume is encrypted | Reduces exposure of data at rest if underlying storage is accessed outside the instance lifecycle |
| SSH is hardened to disable password auth, challenge-response auth, empty passwords, and root login | Reduces brute-force and credential-stuffing risk and blocks direct root login |
| Deploy user is non-root and only added to the Docker group | Limits routine deployment access compared with full sudo-based administration, although Docker access is still powerful |
| Distroless Java runtime image removes shell and package manager tooling from the container | Reduces post-compromise tooling available inside the container and shrinks the container attack surface |
| EC2 instance role is scoped to SSM core plus Route53 DNS challenge permissions for the hosted zone | Reduces blast radius versus broad AWS permissions on the instance |
| GitHub Actions IAM user is limited to describing EC2 instances and sending/reading SSM commands | Reduces CI credential abuse compared with broad deployment credentials |


## CI/CD Workflow Security

The GitHub Actions workflow adds a separate attack surface: changes pushed to the `main` branch or manual `workflow_dispatch` runs can trigger deployment logic; GitHub-hosted runners receive Docker Hub, AWS, and Slack secrets; third-party marketplace actions run in the pipeline; the workflow publishes a container image to Docker Hub; and the final stage sends SSM commands to a specific EC2 instance to stop containers and start the new image.

## CI/CD Controls And Threats Mitigated

| Control | Threat Mitigated |
| --- | --- |
| Workflow triggers are limited to `main`, manual dispatch, and changes under `.github/workflows/**` or `complete/**` | Reduces accidental deployments from unrelated file changes and narrows what code paths can initiate a release |
| Build and test run before image publication or deployment | Reduces the chance of deploying an obviously broken artifact |
| The JAR is passed as a short-lived GitHub artifact with `retention-days: 1` | Limits persistence of intermediate build outputs in GitHub storage |
| The container image is built from `Dockerfile.deploy`, which uses a distroless Java 17 runtime | Reduces the runtime attack surface of the shipped container compared with a fuller base image |
| Docker Scout blocks the pipeline on critical CVEs in the built image | Reduces the chance of publishing images with known critical vulnerabilities |
| AWS credentials used by the workflow are limited in Terraform to EC2 describe and SSM command operations | Reduces cloud-side blast radius compared with broad deployment credentials |
| Deployment is performed through SSM instead of exposing a wider remote management interface from GitHub Actions | Avoids adding another internet-exposed administration endpoint to the EC2 instance |
| Slack notifications are outbound only and report pipeline state rather than granting control back into the workflow | Limits notification integration to observability instead of remote administration |


## Residual Risk

One important residual risk is that the deployment still relies on a public EC2 host and CI-controlled remote execution against a fixed instance. If the deploy path or its credentials are compromised, an attacker could replace the running container or execute arbitrary commands on that host.

For a production system, the preferred mitigation would be to remove SSH-based deployment entirely, use short-lived federated credentials for CI, and place the workload behind a managed entry point such as an ALB in a hardened VPC design with private application subnets. That would reduce standing administrative access and narrow the path from internet exposure to host compromise.
