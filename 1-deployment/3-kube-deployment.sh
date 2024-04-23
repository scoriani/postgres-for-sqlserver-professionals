# follow this getting started: https://www.kubegres.io/doc/getting-started.html

# deploy kubergres
kubectl apply -f https://raw.githubusercontent.com/reactive-tech/kubegres/v1.17/kubegres.yaml

# check kubegres deployment
kubectl get all -n kubegres-system

# create a secret file
vi my-postgres-secret.yaml

# add the following content
apiVersion: v1
kind: Secret
metadata:
  name: mypostgres-secret
  namespace: default
type: Opaque
stringData:
  superUserPassword: <password>
  replicationUserPassword: <password>

kubectl apply -f my-postgres-secret.yaml

# explore kubegres logs
kubectl logs pod/kubegres-controller-manager-999786dd6-74tmb -c manager -n kubegres-system -f


# create a service definition file
vi my-postgres.yaml

# add the following content
apiVersion: kubegres.reactive-tech.io/v1
kind: Kubegres
metadata:
  name: mypostgres
  namespace: default

spec:

   replicas: 3
   image: postgres:16.2

   database:
      size: 200Mi

   env:
      - name: POSTGRES_PASSWORD
        valueFrom:
           secretKeyRef:
              name: mypostgres-secret
              key: superUserPassword

      - name: POSTGRES_REPLICATION_PASSWORD
        valueFrom:
           secretKeyRef:
              name: mypostgres-secret
              key: replicationUserPassword


# deploy my postgres cluster
kubectl apply -f my-postgres.yaml

kubectl get pod,statefulset,svc,configmap,pv,pvc -o wide

# connect to a client pod called "ubuntu"
kubectl exec -it ubuntu -- /bin/bash

# connect to postgres
psql -h mypostgres -U postgres

# create a table
CREATE TABLE my_table (id SERIAL PRIMARY KEY, name VARCHAR(100));

# insert some data
INSERT INTO my_table (name) VALUES ('John');

# check replication on primary
SELECT * FROM  pg_stat_subscription;

# connect to replica
psql -h mypostgres-replica -U postgres

# check replication on replica
SELECT * FROM pg_stat_wal_receiver;

SELECT * FROM my_table;

# check replication stats on primary
create table test (id int);
INSERT INTO test SELECT generate_series(1,100000000);

select * from pg_stat_replication;

# failover
kubectl delete pod mypostgres-0

# check the new master
kubectl get pods -l kubegres_cluster=mypostgres -o wide

# check the new replica
kubectl get pods -l kubegres_cluster=mypostgres-replica -o wide

# connect to new master
psql -h mypostgres -U postgres

# clean up
kubectl delete kubegres mypostgres
kubectl delete -f https://raw.githubusercontent.com/reactive-tech/kubegres/v1.17/kubegres.yaml
kubectl delete pvc --all