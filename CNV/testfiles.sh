#! /bin/bash

echo "apiVersion: v1" > $KUBEPATH/dev-configs/cinder/ceph-secret.yaml
echo "kind: Secret" >> $KUBEPATH/dev-configs/cinder/ceph-secret.yaml
echo "metadata:" >> $KUBEPATH/dev-configs/cinder/ceph-secret.yaml
echo "  name: standalone-cinder-cephx-secret" >> $KUBEPATH/dev-configs/cinder/ceph-secret.yaml
echo "type: "kubernetes.io/rbd"" >> $KUBEPATH/dev-configs/cinder/ceph-secret.yaml
echo "data:" >> $KUBEPATH/dev-configs/cinder/ceph-secret.yaml
echo "  key: <your key here from ceph auth get-key client.admin | base64>" >> $KUBEPATH/dev-configs/cinder/ceph-secret.yaml

echo "kind: StorageClass" > $KUBEPATH/dev-configs/cinder/cinder-storageclass.yaml
echo "apiVersion: storage.k8s.io/v1" >> $KUBEPATH/dev-configs/cinder/cinder-storageclass.yaml
echo "metadata:" >> $KUBEPATH/dev-configs/cinder/cinder-storageclass.yaml
echo "  name: standalone-cinder" >> $KUBEPATH/dev-configs/cinder/cinder-storageclass.yaml
echo "provisioner: openstack.org/standalone-cinder" >> $KUBEPATH/dev-configs/cinder/cinder-storageclass.yaml
echo "parameters:" >> $KUBEPATH/dev-configs/cinder/cinder-storageclass.yaml
echo "  smartclone: \"true\"" >> $KUBEPATH/dev-configs/cinder/cinder-storageclass.yaml

echo "apiVersion: extensions/v1beta1" > $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "kind: Deployment" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "metadata:" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "  name: standalone-cinder-provisioner" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "spec:" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "  replicas: 1" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "  strategy:" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "    type: Recreate" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "  template:" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "    metadata:" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "      labels:" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "        app: standalone-cinder-provisioner" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "    spec:" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "      containers:" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "      - name: standalone-cinder-provisioner" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "#        image: \"quay.io/external_storage/standalone-cinder-provisioner:latest\"" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "        image: "quay.io/aglitke/standalone-cinder-provisioner:latest"" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "        imagePullPolicy: IfNotPresent" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "        env:" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "        - name: OS_AUTH_URL" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "          value: http://172.18.8.229:5000/v2.0 # obtained from /root/keystonerc_admin file but replace v3 with v2.0" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "        - name: OS_USERNAME" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "          value: admin" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "        - name: OS_PASSWORD" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "          value: 4241004c69d34c9f             # obtained from /root/keystonerc_admin file" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "        - name: OS_TENANT_ID" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "          value: 4965a4662eba4356851d05e64edaaf65 # obtained from command openstack project list and take id for admin project" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "        - name: OS_REGION_NAME" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml
echo "          value: RegionOne" >> $KUBEPATH/dev-configs/cinder/provisioner.yaml

echo "kind: PersistentVolumeClaim" > $KUBEPATH/dev-configs/cinder/cinder-storageclass-pvc.yaml
echo "apiVersion: v1" >> $KUBEPATH/dev-configs/cinder/cinder-storageclass-pvc.yaml
echo "metadata:" >> $KUBEPATH/dev-configs/cinder/cinder-storageclass-pvc.yaml
echo "  name: test-clone" >> $KUBEPATH/dev-configs/cinder/cinder-storageclass-pvc.yaml
echo "  annotations:" >> $KUBEPATH/dev-configs/cinder/cinder-storageclass-pvc.yaml
echo "spec:" >> $KUBEPATH/dev-configs/cinder/cinder-storageclass-pvc.yaml
echo "  storageClassName: standalone-cinder" >> $KUBEPATH/dev-configs/cinder/cinder-storageclass-pvc.yaml
echo "  accessModes:" >> $KUBEPATH/dev-configs/cinder/cinder-storageclass-pvc.yaml
echo "    - ReadWriteOnce" >> $KUBEPATH/dev-configs/cinder/cinder-storageclass-pvc.yaml
echo "  resources:" >> $KUBEPATH/dev-configs/cinder/cinder-storageclass-pvc.yaml
echo "    requests:" >> $KUBEPATH/dev-configs/cinder/cinder-storageclass-pvc.yaml
echo "      storage: 2Gi" >> $KUBEPATH/dev-configs/cinder/cinder-storageclass-pvc.yaml
