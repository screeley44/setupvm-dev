#! /bin/bash
# Some automation to setting up GlusterFS VMs
#

source setupvm.config



IFS=':' read -r -a gfs <<< "$GFS_LIST"
for index in "${!gfs[@]}"
do
  if [ "$index" == 0 ]
  then
    # do nothing - this is our main host
    echo " *** PEER PROBE INITIATED ***"
    echo " ****************************"
    echo ""
  else
    # peer probe our list
    echo " ... probing peer ${gfs[index]}"

                  echo "Adding brick to Existing Volume $VOLUME_BASE$volstart" >> $LOG_NAME
                  result=`eval gluster volume add-brick $VOLUME_BASE$volstart replica $REPLICA_COUNT $BASE_NAME-$peerstart.$SERVICE_NAME.$NAMESPACE.svc.cluster.local:$MOUNT_BASE$VOLUME_BASE$volstart/brick$volstart force || true`
                  wait

  fi
done

