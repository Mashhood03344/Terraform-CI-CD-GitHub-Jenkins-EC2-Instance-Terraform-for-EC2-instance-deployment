# Jenkins Pipeline Tutorial

This tutorial will create a simple CI/CD pipeline using GitHub,Jenkins, the EC2 instance

## Table of Contents

- [Jenkins Pipeline Tutorial](#jenkins-pipeline-tutorial)
    - [Table of Contents](#table-of-contents)
    - [Prerequisites](#prerequisites)
    - [Cloning the Repository](#cloning-the-repository)
    - [Preparing the Deployment Environment](#preparing-the-deployment-environment)
    	- [Variables](#variables)
    	- [Usage](#usage)
    - [Preparing Jenkins](#preparing-jenkins)
        - [Create an IAM Role for Jenkins](#create-an-iam-role-for-jenkins)
        - [Create an EC2 Instance](#create-an-ec2-instance)
        - [Install Jenkins, Git and Docker on the Jenkins Instance](#install-jenkins,-git-and-docker-on-the-jenkins-instance)
        - [Run the Jenkins Setup Wizard](#run-the-jenkins-setup-wizard)
    - [Creating the Pipeline](#creating-the-pipeline)
    - [Creating Github Webhook](#creating-Github-Webhook)
    - [Configuring the Pipeline](#configuring-the-pipeline)
        - [Looking at the Sample Pipeline](#looking-at-the-sample-pipeline)
        - [Running the Pipeline](#running-the-pipeline)
        - [Adding a CI Stage](#adding-a-ci-stage)
        - [Adding a CD Stage](#adding-a-cd-stage)
    - [Testing the Pipeline](#testing-the-pipeline)
    - [Cleaning Up](#cleaning-up)

## Prerequisites

You will need the following to complete this tutorial:

- An AWS account
- [AWS CLI][3] installed and configured for your AWS account
- [Git][8]
- Terraform

## Cloning the Repository

Use the following command to clone the repository

	git clone <GitHub-repo-url>

- Extract the files from the Source Code directory and push those files into your created git repository.

## Preparing the Deployment Environment

The Terraform configuration folder named **Terraform CI-CD-GitHub-Jenkins-EC2 Instance** is used to set up a Virtual Private Cloud (VPC) with public subnets, an Internet Gateway, and security groups. This configuration also provisions an EC2 instance that serves as a Jenkins server and is preconfigured with necessary tools like Docker and the AWS CLI. The instance also has access to the AWS Elastic Container Registry (ECR) and Systems Manager (SSM) through an attached IAM role.

###Variables

- vpc_cidr_block: CIDR block for the Virtual Private Cloud (VPC) that defines the IP range.
- public_subnet_cidr_1: CIDR block for the first public subnet in the VPC.
- public_subnet_cidr_2: CIDR block for the second public subnet in the VPC.
- ami_id: Amazon Machine Image (AMI) ID for launching the EC2 instance (e.g., an Ubuntu image).
- instance_type: The type of EC2 instance to be launched (e.g., t2.micro).
- key_name: The name of the SSH key used to access the EC2 instance.
- region: AWS region where the resources will be provisioned.

###Usage

- Clone the repository and **Terraform CI-CD-GitHub-Jenkins-EC2 Instance** navigate to the directory.
- Initialize Terraform:
	
	```bash
	terraform init
	```
	
- Review the plan:

	```bash
	terraform plan -out=tfplan
	```
	
- Apply the configuration:

	```bash
	terraform apply "tfplan"
	```
	
## Preparing Jenkins

You will need a Jenkins instance for this tutorial. Perform the following steps to deploy Jenkins
inside your AWS account:

### Create an IAM Role for Jenkins

1. In the [IAM roles view][6] click **Create role**.
2. Choose **EC2** and click **Next: Permissions**.
3. Check the **AmazonECS_FullAccess**, the **AmazonEC2ContainerRegistryPowerUser**, the **AmazonS3FullAccess**, and the **AmazonSSMManagedInstanceCore** , ensure that the following IAM policy is attached to your role:

	```json
	{
	    "Version": "2012-10-17",
	    "Statement": [
		{
		    "Effect": "Allow",
		    "Action": [
		        "ssm:SendCommand",
		        "ssm:ListCommands",
		        "ssm:ListCommandInvocations",
		        "ssm:GetCommandInvocation"
		    ],
		    "Resource": "*"
		}
	    ]
	}
	```
	
Also, make sure to set up the trust relationship with the following policy:

	```json
	{
	    "Version": "2012-10-17",
	    "Statement": [
		{
		    "Effect": "Allow",
		    "Principal": {
		        "Service": "ec2.amazonaws.com"
		    },
		    "Action": "sts:AssumeRole"
		}
	    ]
	}
	```
	
policies and after configuring these policies
click **Next: Review**.
4. Under **Role name** type "Jenkins" and click **Create role**.

### Create an EC2 Instance

1. In the [EC2 console][7] click **Launch Instance**.
2. Select an **Ubuntu** AMI.
3. Leave **t2.micro** selected and click **Next: Configure Instance Details**.
4. Under **Network**, choose any VPC with a public subnet. The **default VPC** will work fine here,
too.
5. Under **Subnet**, choose any public subnet.
6. Under **Auto-assign Public IP** choose **Enabled**.
7. Under **IAM role** choose the **Jenkins** role you created before.
8. Click **Next: Add Storage**.
9. Click **Next: Add Tags**.
10. Create a tag with the key "Name" and the value "Jenkins" and click **Next: Configure Security Group**.
11. Name the security group "Jenkins" and allow **SSH access** as well as access to **TCP port
8080** from your WAN IP address, make sure that the inbound rules for the **SSH** and **HTTP** and and **Custom TCP access for Port 8080** .
12. Click **Review and Launch**.
13. Click **Launch**.
14. Choose an existing SSH key or create a new one, then click **Launch Instances**.

### Install Jenkins, Git and Docker on the Jenkins Instance

SSH into the EC2 instance using Instance connect, Select the EC2 instance you want to SSH into then click on the connect button and then click on connect button in the bottom of the next web page

**Note:** You will be able to SSH into the instance only if there is an in bound rule for the **SSH access** in the inbound rules of the security group.

### Run the Jenkins Setup Wizard

1. Browse `http://<instance_ip>:8080`.
2. Under **Administrator password** enter the output of `sudo cat /var/lib/jenkins/secrets/initialAdminPassword` on the Jenkins instance.
3. Click **Continue**.
4. Click **Install suggested plugins** and let the installation finish.
5. Click **Continue as admin**.
6. Click **Start using Jenkins**.

**Note:** In the **Dashboard -> Manage Jenkins -> System** in the Jenkins Url field ensure that the Jenkins url is the same as the ec2 instance ip plus port 8080 for example like this **http://ec2-instance-	ip.compute-1.amazonaws.com:8080/**

Secondly, ensure that in the **Dashboard -> Manage Jenkins -> Security** in the under CSRF Protection checkbox the Enable proxy compatibility option


## Creating the Pipeline

We will now create the Jenkins pipeline. Perform the following steps on the Jenkins UI:

1. Click **New Item** to create a new Jenkins job.
2. Under **Enter an item name** type "sample-pipeline".
3. Choose **Pipeline** as the job type and click **OK**.
4. In the **Build Triggers section**, check **GitHub hook trigger for GITScm polling**.
5. Under **Pipeline -> Definition** choose **Pipeline script from SCM**.
6. Under **SCM** choose **Git**.
7. Under **Repository URL** paste the [HTTPS URL][9] of your repository.

> **NOTE:** It is generally recommended to use Git **over SSH** rather than HTTPS, especially in
> automated processes. However, to simplify things and since the repository is public, we can
> simply use the HTTPS URL instead of dealing with SSH keys.

7. Leave the rest at the default and click **Save**.

You should now have a pipeline configured. When executing the pipeline, Jenkins will clone the Git
repository, look for a file named `Jenkinsfile` at its root and execute the instructions in it.

## Creating Github Webhook

### Create a webhook in your GitHub repository:

- Go to your repository on GitHub.
- Navigate to Settings → Webhooks → Add webhook.

### Configure the webhook settings:

- Payload URL: This is the URL where GitHub will send the webhook events. In your case, it should point to your Jenkins instance on the EC2 server. The format is:

	```bash
	http://<your-jenkins-ec2-instance>:8080/github-webhook/
	```
	
Make sure your Jenkins instance is publicly accessible or you are using something like a reverse proxy (e.g., NGINX) or tunneling service (e.g., serveo.net, ngrok) to expose Jenkins to the internet if it's not.

**Content type:** Choose application/json.

Which events would you like to trigger this webhook?: Select **Just the push event** (if you only want the build to trigger on pushes) or customize based on your needs.

## Configuring the Pipeline

The Jenkins Pipeline plugin supports two types of piplines: **declarative pipelines** and
**scripted pipelines**. Declarative pipelines are simpler and have a nice, clean syntax. Scripted
pipelines, on the other hand, offer unlimited flexibility by exposing the full power of the
[Groovy][11] programming language in the pipeline.

In this tutorial we will use the **declarative syntax**, which is more than enough for what we are
trying to accomplish.

### Looking at the Sample Pipeline

Let's take a look at the sample pipeline that is already in the repository. Open the file called
`Jenkinsfile` file in a text editor (preferably one [which][12] [supports][13] the Jenkinsfile
syntax).

We can see that the entire pipeline is inside a top-level directive called `pipeline`.

Then we have a line saying `agent any` - this is required for declarative pipelines, but we are not
going to touch it in this tutorial. If you are still curious about what the agent directive does,
you can read about it [here][15].

Next we have the `environment` directive. This section allows us to configure global variables
which will be available (for both reading and writing) in any of the pipeline's stages. This is
useful for configuring global settings.

Lastly, we have a `stage`. You can have as many stages as you want in a pipeline. A stage is a
major section of the pipeline and it contains the actual "work" which the pipeline does. This work
is defined in `steps`. A step can execute a shell script, push an artifact somewhere, send an email
or a Slack message to someone and do lots of other stuff. We can see that at the moment our
pipeline doesn't do much, just prints something to the console using an `echo` step.

> **NOTE:** There is [an entire list][16] of step types which can be used in Jenknis pipelines,
> however in this tutorial we will keep things simple and use mostly the `sh` step, which executes
> a shell script.

So, now that we understand the structure of our pipeline, let's run it.

### Running the Pipeline

1. From the top-level view on the Jenkins UI, click on the pipeline's name ("sample-pipeline").
2. On the menu to the left, click **Build Now**.

This will trigger a run. You should see a new run (or "build") under the **Build History** view on
on the left side. To see the logs from the build, click the build number (`#1` if this is your
first build) and the click **Console Output**.

If all went well, after some Git-related output you should see that the pipeline ran the only stage
we currently have, which should simply display `Hello World!`.

Great. Now let's make the pipeline do some real stuff.

### Adding a CI Stage

Let's add a simple CI step to our pipeline. We want to build a Docker image from our app and push
it to ECR so that we can later deploy containers from it.

Let's populate the `docker_repo_uri` environment variable with the full URI of the ECR repository
you created previously. It shall be similar to the following:

   pipeline {
    	...

	    environment {
		region = "us-east-1"
		docker_repo_uri = "xxxxxxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/simple-html-app"
		ec2_instance_id = "i-07bc8cba9d91653d9" //replace this with the id of your ec2 instance
	    }

        ...
    }

Now add the Build and the Pre-Build stages

    stage('Pre-Build') {
            steps {
                script {
                    // Build Docker image
                    sh 'docker build -t sample-app .'
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    // Tag the Docker image with 'latest'
                    sh "docker tag sample-app:latest ${docker_repo_uri}:latest"
                    
                    // Push the Docker image with the 'latest' tag
                    sh "docker push ${docker_repo_uri}:latest"
                }
            }
        }

Notice that we have two types of steps here: `script` and `sh`. `script` steps allow us to run a
Groovy code snippet inside our declarative pipeline. We need this because we want to capture the
SHA1 of the current commit and assign it to a variable, which we can then use to uniquely tag the
Docker image we are building. `sh` steps are simply shell commands.

So now our pipeline should build a Docker image, push it to ECR.

In order to update the pipeline, we must commit and push our changes to Github. So, when you are
done editing, do the following:

1. Commit your changes by running `git commit -am "Add CI step to pipeline"`.
2. Push your changes to Github by running `git push origin main`.

Now, re-run the pipeline on Jenkins and examine its output. If all goes well, the pipeline will
build a Docker image, push it to ECR. Verify this by
looking at the [Repositories][14] section of the ECS console. Your repository should now have an
image in it.

### Adding a CD Stage

Now that we have a pipeline which automatically generates Docker images for us, let's add another
stage that will deploy new images to our deployment environment (EC2 instance).

So now for the CD stage, add the following deploy stage right after the existing "Build" stage:

	    stage('Deploy to EC2') {
	    steps {
		script {
		    // Authenticate EC2 instance to ECR before pulling the image
		    def ssmCommand = sh(script: """
		        aws ssm send-command \
		            --region ${region} \
		            --instance-ids ${ec2_instance_id} \
		            --document-name "AWS-RunShellScript" \
		            --comment "Authenticate and Deploy Docker container" \
		            --parameters 'commands=["aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${docker_repo_uri}", "docker pull ${docker_repo_uri}:latest", "docker stop sample-app || true", "docker rm sample-app || true", "docker run -d -p 80:80 --name sample-app ${docker_repo_uri}:latest"]' \
		            --query "Command.CommandId" --output text
		    """, returnStdout: true).trim()

		    // Poll the SSM command until it's finished
		    def status = "InProgress"
		    while (status == "InProgress") {
		        sleep(time: 10, unit: 'SECONDS')
		        status = sh(script: """
		            aws ssm get-command-invocation \
		                --command-id ${ssmCommand} \
		                --instance-id ${ec2_instance_id} \
		                --region ${region} \
		                --query "Status" --output text
		        """, returnStdout: true).trim()
		        echo "SSM command status: ${status}"
		    }

		    // Check final status
		    if (status != "Success") {
		        error "SSM command failed with status: ${status}"
		    }
		}
	    }
	}

This stage will perform the following actions:

1. **Authenticate EC2 to ECR:** The aws ssm send-command sends a command to the EC2 instance to log in to ECR using the provided credentials.
2. **Pull the Docker Image:** It pulls the latest Docker image from the ECR repository.
3. **Stop and Remove Existing Container:** Stops and removes any existing container named sample-app to ensure there’s no conflict.
4. **Run New Container:** Launches a new container from the pulled image, exposing port 80.

The script also includes polling logic to check the status of the SSM command until it completes. If the command fails, the pipeline will be marked as failed.

So, we should now be ready to test our CD stage. Commit your changes, push them to Github and run
the pipeline. If all goes well, an update should be triggered on ec2 instance, which will deploy our
app.

## Testing the Pipeline

Up to now, all we did was set up a CI/CD pipeline which will build and deploy code changes
automatically. Now, we will verify it actually does so by making a very simple code change.

Open `index.html` in your editor and change `<h1>Hello World!</h1>` to `<h1>Hello World 2!</h1>`. Push
the change to Github and run the pipeline. If all goes well, after a short time you should see the
change when refreshing your browser.

> **Note:** Deploying a new change could take a few minutes, mainly because the default
> [Deregistration Delay][20] is 5 minutes. You may reduce this timer to speed up deployments, or
> manually kill the old tasks.

## Cleaning Up

When you are done experimenting and would like to delete the environment, perform the following:

1. Terminate the Jenkins instance and delete its IAM role, security group and SSH key.
2. For the terraform configuration clean up run the command.


	```bash
	terraform destroy -auto-approve
	```



[1]: https://jenkins.io/doc/book/pipeline/
[2]: https://aws.amazon.com/fargate/
[3]: https://aws.amazon.com/cli/
[4]: https://console.aws.amazon.com/ecs/home?region=us-east-1
[5]: https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#LoadBalancers:sort=loadBalancerName
[6]: https://console.aws.amazon.com/iam/home?region=us-east-1#/roles
[7]: https://console.aws.amazon.com/ec2/v2/home?region=us-east-1
[8]: https://git-scm.com/
[9]: https://help.github.com/articles/which-remote-url-should-i-use/
[10]: https://guides.github.com/activities/forking/
[11]: http://groovy-lang.org/
[12]: https://code.visualstudio.com/
[13]: https://atom.io/
[14]: https://console.aws.amazon.com/ecs/home?region=us-east-1#/repositories
[15]: https://jenkins.io/doc/book/pipeline/syntax/#agent
[16]: https://jenkins.io/doc/pipeline/steps/
[17]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
[18]: https://console.aws.amazon.com/ecs/home?region=us-east-1#/taskDefinitions
[19]: https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/default/services/sample-app-service/deployments
[20]: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html#deregistration-delay
[21]: https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters
