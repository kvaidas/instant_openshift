# Instant OpenShift on AWS

#### Requirements:

 * Terraform binary (can be acquired from terraform.io)
 * AWS account (you need the access key id and the secret access key)
 * Opt-in for using the CentOS AMI (can be done here: https://aws.amazon.com/marketplace/pp?sku=aw0evgkw8e5c1q413zgy5pjce)

#### Usage:

* meet all the requirements
* have the AWS credentials configured as per https://www.terraform.io/docs/providers/aws/
* edit the file called `terraform.tfvars` (WARNING: do not use the colon symbol ":" in your username)
* run `terraform apply` in the directory containing openshift.tf and terraform.tfvars
* note the public IP
* wait for the provisioning script to complete
* log into your OpenShift at `https://<public_ip>:8443` (you will have complete access over the cluster)

#### Cleanup:
Just run `terraform destroy -force` and all created AWS resources will be deleted.

#### Notes
By default TCP ports 22, 80, 443 and 8443 are allowed into the machine. Modify the Security Group "openshift" if you need something different.

Easy SSH'ing into the box from the directory with terraform state file:

`ssh -t -o StrictHostKeyChecking=no centos@$(terraform output public_ip) sudo bash`
