
# Python Project Template for Google Cloud Run

The goal of this project is to provide a template for new projects that can be easily deployed on Google Cloud Run. You only need to fill in some variables, run a few commands, and you will have an environment that allows for easy development and deployment of changes to production via commits/merges to a GitHub repository.

This project uses:
* Google Cloud Run, Google Container Registry
* GitHub Actions
* Terraform (state stored in Google Storage Bucket)
* FastAPI
* Pytest, Mypy, Flake8, Black, pre-commit
* Poetry
* Docker-compose (for local development)

## Getting Started

### Deploying to Google Cloud Run and Testing

1. **Fork** this repository: [https://github.com/cthtuf/cloud-run-template](https://github.com/cthtuf/cloud-run-template).
2. **Clone** the forked repository:
    ```bash
    git clone https://github.com/your_username/cloud-run-template.git
    cd cloud-run-template
    ```
3. **Install** Terraform: [installation guide](https://developer.hashicorp.com/terraform/install?product_intent=terraform).
4. **Create a project** in the Google Cloud Console, link it to a billing account, and get the Project ID.
5. **Update the variables**:
   - In `infrastructure/terraform.tfvars` and `pyproject.toml` files.
6. **Prepare the infrastructure**:  
   - This step can be challenging due to a race condition in the project's initialization logic. If you have any ideas on how to fix this, feel free to submit a PR.
    ```bash
    cd infrastructure
    terraform init
    terraform plan
    terraform apply
    ```
    The last command will raise an error because a docker image for the service does not exist yet. Don't worry, we will build and upload the image using the GitHub Actions pipeline later. At this point, required APIs are enabled, a Docker Registry repository is created, and a service account (SA) is set up. You need to obtain the SA credentials to use in GitHub Actions. Go to the [Service Accounts page](https://console.cloud.google.com/iam-admin/serviceaccounts), select "Manage Keys," and create a new JSON key.
7. **Set up GitHub Actions Secrets**:
   - `GCP_PROJECT_ID` (e.g., project-id-12345-a6)
   - `GCP_REGION` (e.g., europe-west4)
   - `GCP_REGISTRY_HOST` (e.g., europe-west4-docker.pkg.dev)
   - `GCP_REGISTRY_REPO` (e.g., cloudrunproject1)
   - `GCP_SERVICE_NAME` (e.g., cloudrunproject1)
   - `GCP_CREDENTIALS` (insert the JSON with SA credentials)

8. **Run** the GitHub Actions pipeline manually or commit changes to the main branch.  
   This process will build and push the Docker image to the Google Container Registry and start the CloudRun service.
9. **Check the Pipeline logs**: [https://github.com/{your_github_account}/cloud-run-template/actions](https://github.com/{your_github_account}/cloud-run-template/actions). It should build and push the Docker image to GCR and then deploy the service to CloudRun.
10. **Apply permissions** to make your app endpoint accessible to everyone:
    ```bash
    terraform apply
    ```
    Run the command again to redeploy the service with the latest image and create permissions for anonymous users.
11. **Check your CloudRun endpoint**. It should return `Hello world`.

## Running the Application Locally

To run the application locally, execute:

```bash
docker compose up
```

The `service/main.py` file contains a basic HTTP handler as an example.

## CI/CD Setup

CD is configured via the `.github/workflows/deploy.yml` file. On every merge to the default branch, a job is triggered that performs the following steps:

- Build the image and install requirements.
- Deploy a new version of the application to Google Cloud Run.

Tests are not included in this template. If you need CI with tests, you can modify the workflow to suit your needs. It is recommended to build a separate image for tests (by passing the build arg `--build-arg RUNTIME_ENV=tests`) and run `pytest` as a command for this image.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
