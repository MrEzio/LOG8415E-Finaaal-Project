import boto3
import os

def create_security_group(ec2, sg_name, vpc_id):
    """
    Function that creates security group and assigns inbound rules
    :param ec2: The ec2 client that creates the security group
    :param sg_name: The name of the security group
    :param vpc_id: id of the vpc need to create security group
    :returns: the created security group
    """

    # verifying if it already exists
    exists = ec2.describe_security_groups(
        Filters=[
            dict(Name='group-name', Values=[sg_name])
        ]
    )
    if exists['SecurityGroups']:
        print("Security group 'mysql_stand-alone-security-group' already exists!")
        group = exists['SecurityGroups'][0]
    else:
        group = ec2.create_security_group(
            Description=sg_name,
            GroupName=sg_name,
            VpcId=vpc_id
        )
        add_inbound_rules(ec2, group['GroupId'])
        print(f"{sg_name} was created!")
    
    return group


def add_inbound_rules(ec2, sg_id):
    """
    Function that assigns inbound rules to the security group
    :param ec2: The ec2 client that will assign rules
    :param sg_id: Security group's id
    """

    inbound_rules = [
        {
            'IpProtocol': 'tcp', 'FromPort': 22, 'ToPort': 22,
            'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
        },
        {
            'IpProtocol': 'tcp', 'FromPort': 80, 'ToPort': 80,
            'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
        },
        {
            'IpProtocol': 'tcp', 'FromPort': 443, 'ToPort': 443,
            'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
        }
        ]
    ec2.authorize_security_group_ingress(GroupId=sg_id, IpPermissions=inbound_rules)


def create_ec2_instance(ec2, groupId, keyPair):
    
    response = ec2.run_instances(
        ImageId='ami-0574da719dca65348',
        InstanceType='t2.micro',
        KeyName=keyPair,
        UserData=open("mysql_stand-alone.sh").read(),
        SecurityGroupIds=[
            groupId
        ],
        MinCount=1,
        MaxCount=1, 
        TagSpecifications=[
            {
                'ResourceType': 'instance',
                'Tags': [
                    {
                        'Key': 'Name',
                        'Value': 'MySQL_stand-alone'
                    },
                ]
            },
        ],
    )
    print("Instance t2.micro for 'mysql_stand-alone' was created!")    
    return response


def main():
    EC2 = boto3.client (
        'ec2',
        region_name="us-east-1"
    )
    # get vpc_id
    vpc_id = EC2.describe_vpcs().get('Vpcs', [{}])[0].get('VpcId', '')

    #Keypair for access and security group that needs to be assigned when instance is made
    keyPairName = 'final'
    securityGroupName = 'mysql_stand-alone-security-group'
    ######################

    # CREATE SECURITY GROUP #
    try:
        print(f"####Creating Security group '{securityGroupName}'####")
        group = create_security_group(EC2, securityGroupName, vpc_id)
    except Exception as err:
        print(f"Error occured when creating security group: {err}")
    print("------------------")
    #########################

    # CREATE & LAUNCH EC2 INSTANCE #
    try:
        print(f"####Creating 1 instance of t2.micro for mysql_stand-alone####")
        instance = create_ec2_instance(EC2, group['GroupId'], keyPairName)
    except Exception as err:
        print(f"Error occured when creating ec2 instance: {err}")
    print("------------------")
    ################################

    # Instance info to OK
    wait = EC2.get_waiter('instance_status_ok')
    wait.wait(InstanceIds=[instance["Instances"][0]["InstanceId"]])
    print("Results are now available in the file results.txt!")

if __name__ == "__main__":
    main()