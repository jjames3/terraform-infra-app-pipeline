# Introduction

This solution deploy two set of pipelines. One deploys Infrastructure which includes an EKS Cluster and the second pipeline deploys python-flask application into the EKS cluster which got created in the earlier pipeline.


├── README.md  
├── infrastructure-cicd/       --> Terraform code which creates CodePipeline which performs EKS cluster code validation and deploying  
├── eks-cluster/               --> Terraform code which creates EKS cluster and dependent resources  
├── application-cicd/          --> Terraform code which create CodePipeline which builds and deploys flask application into EKS cluster  
└── api-application/           --> Dockerfile and flask application to be built and deployed into EKS cluster

### Prerequisites
* Terraform installed in machine where this solution is going to be deployed
* AWSCLI installed and configured
* The solution is defaulted to be deployed into us-west-2 region
* git should be installed. Also git-remote-codecommit has to be installed for below steps to work. Follow below link to install git-remote-codecommit
   https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-git-remote-codecommit.html


### To deploy the solution:
#### Create Infrastructure Pipeline
This pipeline performs validation, plan and apply of terraform code which deploys EKS Cluster. Additionally, this pipeline creates a Code Commit repository and configures this repository as "Source" for the pipeline. Once this pipeline is provisioned, go ahead and place the EKS Terraform code inside this repository and the Code Pipeline will automatically pick up the change and pipeline execution get's triggered.

Run below command to move into directory which has infra-deploy code
```
cd infrastructure-cicd/
```
You can tweak parameters as per your requirement by modifying tfvars file at "examples/terraform.tfvars". Go into the file and pass in your AWS AccountID as below

cat examples/terraform.tfvars  
...  
repo_approvers_arn = "arn:aws:sts::<AccountID>:assumed-role/CodeCommitReview/*"  
...

The above configuration allows only the approved members who can assume the above IAM Role to have permission to merge PR requests for the created repository

Follow below steps to deploy the pipeline
```
terraform init  
terraform plan -var-file=./examples/terraform.tfvars  
terraform apply -var-file=./examples/terraform.tfvars
```
#### Placing EKS Cluster code in CodeCommit repository
The above step would have created CodeCommit repository "terraform-ekscluster-repo" in us-west-2 region. Clone the repository and push code from "eks-cluster" directory into it.
```
cd ..
git clone codecommit::us-west-2://terraform-ekscluster-repo
cd terraform-ekscluster-repo
cp -a ../eks-cluster/* .
git add .
git commit -m 'initial commit'
git push
cd ..
```
Once the code is pushed go back to AWS CodePipeline Console and you should see "tf-infrastructure-pipeline" in progress. Wait for the pipeline to finish execution and EKS cluster to be created.


#### Create Application Pipeline
This pipeline builds docker image of python flask application, pushes it into ECR Image repository, modifies Kubernetes deployment manifest file with the latest built image tag and deploys the deployment manifest which performs rolling update of pods.

Run below command to move into directory which has application deploy code
cd application-cicd/

Like in Infrastructure pipeline you need to edit parameters as per your requirement by modifying tfvars file at "examples/terraform.tfvars". Go into the file and pass in your AWS AccountID as below

cat examples/terraform.tfvars  
...  
repo_approvers_arn = "arn:aws:sts::<AccountID>:assumed-role/CodeCommitReview/*"  
...

The above configuration allows only the approved members who can assume the above IAM Role to have permission to merge PR requests for the created repository

Follow below steps to deploy the pipeline
```
terraform init
terraform plan -var-file=./examples/terraform.tfvars
terraform apply -var-file=./examples/terraform.tfvars
cd ..
```

#### Placing application code in CodeCommit repository
Applicaton pipeline would have created CodeCommit repository "terraform-application-repo". Like you did earlier, clone the repo, copy app code into it and push the changes.
```
git clone codecommit::us-west-2://terraform-application-repo
cd terraform-application-repo
cp -a ../api-application/* .
```
You need to additionally modify below files as well.  

cat templates/buildspec_plan.yml #should be entered with region and accountID  
...  
AWS_ACCOUNT_ID: <AccountID>  
...

cat templates/buildspec_apply.yml  
...  
ASSUME_ROLE_ARN: "arn:aws:iam::<AccountID>:role/custom-role"  
EKS_CLUSTER_NAME: <CLUSTER_NAME>  
...

```
git add .
git commit -m 'initial commit'
git push
cd ..
```
Once the code is pushed go back to AWS CodePipeline Console and you should see "tf-application-pipeline" in progress. Wait for the pipeline to finish execution and application would be deployed into EKS cluster.


### Testing
One the application is deployed, navigate into EC2 LoadBalancer Console and you would be able to find an ALB newly created there. You can use following curl command to test the application.

```
# GET
curl  -H 'Content-Type: application/json' <loadBalancerCNAME>

curl  -H 'Content-Type: application/json' k8s-default-flaskser-0cb9492d95-1173375781.us-west-2.elb.amazonaws.com

# POST
curl -X POST -d '{"key": "testvalue"}' -H 'Content-Type: application/json' <loadBalancerCNAME>/customuri

curl -X POST -d '{"key": "testvalue"}' -H 'Content-Type: application/json' k8s-default-flaskser-0cb9492d95-1173375781.us-west-2.elb.amazonaws.com/customuri
```

### Resources used:
https://github.com/aws-ia/terraform-aws-eks-blueprints/release
https://github.com/aws-samples/aws-codepipeline-terraform-cicd-samples
