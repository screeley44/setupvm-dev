oc adm groups new myclusteradmingroup admin
oc adm groups new mystorageadmingroup screeley

# add policy roles to groups
oc adm policy add-cluster-role-to-group cluster-admin myclusteradmingroup
oc adm policy add-cluster-role-to-group storage-admin mystorageadmingroup
oc adm policy add-role-to-user basic-user jdoe -n default
oc adm policy add-role-to-user view jdoe -n default
oc adm policy add-role-to-user edit jdoe -n default

# add some scc policy as well
oc adm policy add-scc-to-group privileged myclusteradmingroup

# Add default service account to privileged  
oc adm policy add-scc-to-user privileged -n default -z default
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:default:default
oc adm policy add-scc-to-user privileged -z router
oc adm policy add-scc-to-user privileged -z default
