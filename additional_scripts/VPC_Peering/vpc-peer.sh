#!/bin/bash

set -e

# Fill in Array of openshift contexts
declare -a CONTEXTS
CONTEXTS=($(oc config get-contexts -o name))
# Check for three clusters
if [ ${#CONTEXTS[@]} != 3 ]
then
    echo "Need three clusters in kubeconfig to continue"
    exit 1
fi
echo "+---+-----------------------+-----------+---------------+----------------------+"
echo "+ I +          VPC          +   REGION  +      CIDR     +    Security Group    +"
echo "+---+-----------------------+-----------+---------------+----------------------+"
for i in 0 1 2
do
    OC="oc --context=${CONTEXTS[i]}"
    # Gather nodes from context
    NODES=($(${OC} get nodes -l 'node-role.kubernetes.io/worker' -o name))
    # Read AWS region for first node
    REGIONS[$i]=$(${OC} get ${NODES[0]} -L 'failure-domain.beta.kubernetes.io/region' | tail -n 1 | awk '{print $6}')
    AWS="aws --region ${REGIONS[i]}"
    # Get AWS id of first node
    providerid=$(${OC} get ${NODES[0]} -o jsonpath='{.spec.providerID}')
    ID=$(basename ${providerid})
    # Read AWS VPC id for this cluster (and strip quotes)
    VPCS[$i]=$(${AWS} ec2 describe-instances --instance-id $ID --query 'Reservations[0].Instances[0].VpcId' --output text)
    # Need CIDR for routing rules
    CIDRS[$i]=$(${AWS} ec2 describe-vpcs --vpc-id ${VPCS[i]} --query 'Vpcs[0].CidrBlock' --output text)
    # Need SG for worker nodes
    # Filter created in JSON because csv implies OR while JSON implies AND (seems a bug)
    FILTER='[{"Name": "vpc-id", "Values": ["'${VPCS[i]}'"]},{"Name": "tag:Name","Values": ["*worker*"]}]'
    SGS[$i]=$(${AWS} ec2 describe-security-groups --filters "${FILTER}" --query 'SecurityGroups[0].GroupId' --output text)

    echo "+ ${i} + ${VPCS[i]} + ${REGIONS[i]} + ${CIDRS[i]} + ${SGS[i]} +"
    echo "+---+-----------------------+-----------+---------------+----------------------+"
done

# create_sg_rules(index_from, index_to)
# Adds rules for VPN connections to provided sg from provided peering
create_sg_rules() {
    from=$1
    to=$2
    echo -n "Security group rules from $from to $to: "
    EXISTS=$(aws ec2 --region ${REGIONS[from]} describe-security-groups  \
        --group-id ${SGS[from]} \
        --filter "Name=ip-permission.to-port,Values=4500,Name=ip-permission.cidr,Values=[${CIDRS[to]}]" \
        --query "SecurityGroups[0].GroupId" \
        --output text)
    if [ $EXISTS == "None" ]
    then
        aws ec2 --region ${REGIONS[from]} authorize-security-group-ingress \
            --group-id ${SGS[from]} \
            --ip-permissions \
            IpProtocol=udp,FromPort=500,ToPort=500,IpRanges="[{CidrIp=${CIDRS[to]}}]" \
            IpProtocol=udp,FromPort=4500,ToPort=4500,IpRanges="[{CidrIp=${CIDRS[to]}}]" \
            IpProtocol=50,IpRanges="[{CidrIp=${CIDRS[to]}}]" \
            IpProtocol=51,IpRanges="[{CidrIp=${CIDRS[to]}}]"
        echo "Created"
    else
        echo "Exists"
    fi
}

# create_routes(index_from, index_to, vpc_peering_connection)
# Creates route entries in all the zones' route tables
create_routes() {
    from=$1
    to=$2
    # Enumerate route tables in FROM sg
    RTS=$(aws ec2 --region ${REGIONS[from]} describe-route-tables --filter "Name=vpc-id,Values=${VPCS[from]}" --query 'RouteTables[*].RouteTableId' --output text)
    for rt in $RTS
    do
        echo -n "Route ${REGIONS[from]} to ${CIDRS[to]}: "
        # Check for existence (idempotency)
        EXISTS=$(aws ec2 --region ${REGIONS[from]} describe-route-tables \
            --route-table-id ${rt} \
            --filter Name=route.destination-cidr-block,Values=${CIDRS[to]} \
            --query 'RouteTables[0].RouteTableId' --output text)
        if [ $EXISTS == "None" ]
        then
            aws ec2 --region ${REGIONS[from]} create-route \
                --route-table-id ${rt} \
                --destination-cidr-block ${CIDRS[to]} \
                --vpc-peering-connection-id $3
            echo "Created"
        else
            echo "Exists"
        fi
    done
}

# create_and_accept_peer (index_from, index_to)
create_and_accept_peer() {
    from=$1
    to=$2
    VPCPEER=$(aws ec2 --region ${REGIONS[from]} create-vpc-peering-connection \
        --vpc-id ${VPCS[from]} \
        --peer-vpc-id ${VPCS[to]} \
        --peer-region ${REGIONS[to]} \
        --query  'VpcPeeringConnection.VpcPeeringConnectionId' \
        --output text)
    echo $VPCPEER

    # Give connection time to create TODO: Add check not just sleep
    sleep 5

    aws ec2 --region ${REGIONS[to]} accept-vpc-peering-connection \
        --vpc-peering-connection-id ${VPCPEER} >& /dev/null

    create_routes $from $to $VPCPEER
    create_routes $to $from $VPCPEER

    create_sg_rules $from $to
    create_sg_rules $to $from
}


create_and_accept_peer 0 1
create_and_accept_peer 0 2
create_and_accept_peer 1 2
