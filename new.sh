aws s3 cp playbook.yml \
    s3://BUCKET-NAME/playbook.yml \
    --region REGION-ID

aws ssm create-association --name "AWS-ApplyAnsiblePlaybooks" \
    --association-name test-ansible \
    --targets Key=tag:SSM,Values=Ansible \
    --color on \
    --region REGION-ID \
    --parameters '{"SourceType":["S3"],"SourceInfo":["{\"path\": \"https://s3.amazonaws.com/BUCKET-NAME/playbook.yml\"}"],"InstallDependencies":["True"],"PlaybookFile":["playbook.yml"],"ExtraVariables":["myregion=REGION-ID"],"Check":["True"],"Verbose":["-v"]}'

aws s3 rm s3://BUCKET-NAME --recursive