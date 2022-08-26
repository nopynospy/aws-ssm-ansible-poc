# AWS SSM + ansible + session manager POC

This is a fork from an achieved project 4 years ago, that served as a proof of concept. It was chosen in this demo because of its brevity.

While SSM allows EC2 admins to not use SSH, there are two reasons not to use it with ansible:

1. It violates the agentless aspect of ansible.
  - In typical use cases, ansible is only installed from the master node once and as long as authorized and given an inventory of hosts, the hosts do not need to have ansible installed.
  - The problem is using SSM with ansible will install ansible on all the hosts. Several demonstrations online showcase this aspect.
  - On top of that, installation of ansible on target host is seen in the .sh file of the original repo, runit.sh
  ```
  # # install ansible on machine
  COMMAND_ID=$(aws ssm send-command --instance-ids $INSTANCE_ID --document-name "AWS-RunShellScript" --parameters "commands=sudo amazon-linux-extras install -y ansible2" --output text --query "Command.CommandId")
  ```
  - At the time of writing, [the recommended AWS CLI command] (https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-state-manager-ansible.html) was used in this repo. Even so, it still leads to installation of ansible on host machines.
  ```
  aws ssm create-association --name "AWS-ApplyAnsiblePlaybooks" \
    --association-name test-ansible \
    --targets Key=tag:SSM,Values=Ansible \
    --color on \
    --region us-east-1 \
    --parameters '{"SourceType":["S3"],"SourceInfo":["{\"path\": \"https://s3.amazonaws.com/MY-S3-BUCKET-NAME/playbook.yml\"}"],"InstallDependencies":["True"],"PlaybookFile":["playbook.yml"],"ExtraVariables":["myregion=us-east-1"],"Check":["True"],"Verbose":["-v"]}'
  ```

2. The create-association CLI command does not return the ansible output logs to the CLI terminal, hence not suitable for gitops
  - While in the original repo, the author was able to get the output logs of the ansible playbook in CLI terminal, [the 'get-command'] (https://docs.aws.amazon.com/cli/latest/reference/ssm/get-command-invocation.html) was used, which can only run on one target instance id at a time.
  - This is not the typical usecase of ansible, especially when it is used to manage hundreds of hosts.
  - Thus, in this forked repo, the [create-association command] (https://docs.aws.amazon.com/cli/latest/reference/ssm/create-association.html) is used instead, because it can use EC2 tags.
  - The create-association command does not return the output logs to CLI terminal. To see the logs, they are available in the SSM > Run command > Command history.
  - This makes it not as suitable as terraform in gitops, because terraform will display the output logs in terminal. Ideally, both terraform and ansible logs should appear in the same terminal, assuming that they share the same CICD pipeline.
