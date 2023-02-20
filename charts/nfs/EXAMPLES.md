# nfs-server

## PersistentVolume

````yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: shared-data
spec:
  capacity:
    storage: 1Mi
  accessModes:
    - ReadWriteMany
  nfs:
    server: nfs
    path: "/"
  mountOptions:
    - nfsvers=4.2
````

## PersistentVolumeClaim

````yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-data
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi
````
