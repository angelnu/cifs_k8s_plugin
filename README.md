# cifs pluging for kubernetes
[![Downloads](https://img.shields.io/docker/pulls/angelnu/cifs_k8s_plugin.svg)](https://hub.docker.com/r/angelnu/cifs_k8s_plugin/)
[![Build Status](https://travis-ci.org/angelnu/docker-cifs_k8s_plugin.svg?branch=master)](https://travis-ci.org/angelnu/docker-cifs_k8s_plugin)

Provide a Kubernetes cifs for Kubernetes on [mutiple archs](https://hub.docker.com/r/angelnu/keepalived/tags):
- arm
- arm64
- amd64

Tested and working on kubernetes 1.10.x on arm and amd64

- Forked from https://github.com/fvigotti/cifs_k8s_plugin in order to add multi arch support

### Delivering plugin to a docker host:

Kubernetes:

```bash
docker run -it --rm -v /etc/kubernetes/volumeplugins/fvigotti~cifs:/target fvigotti/cifs_k8s_plugin /target
```

Openshift:

```bash
docker run -it --rm -v /usr/libexec/kubernetes/kubelet-plugins/volume/exec/fvigotti~cifs:/target fvigotti/cifs_k8s_plugin /target
```

After installing the plugin, restart the kubelet or the origin-node service so that the plugin is detected.

### important notes:
 - generated from a fork of -> https://github.com/sigma/cifs_k8s_plugin
 - getvolumename is not implemented because there is a bug in kube 1.6.x https://github.com/kubernetes/kubernetes/issues/44737
 - kubelet flags :
    - "--volume-plugin-dir=/etc/kubernetes/volumeplugins"
    - "--enable-controller-attach-detach=false"
 - controller manager flags:
    - "--flex-volume-plugin-dir=/etc/kubernetes/volumeplugins"

- not sure if it's really true but seems that after the creation of the plugin directory (/etc/kubernetes/volumeplugins/fvigotti)
  kubelet needed a restart, hot-changes to plugin source can be done in place without further restarts


### Sample usage


Assuming a `//192.168.56.101/TEST` cifs share, accessible by a `TESTER` user with a `SECRET` password.

1. create secret to access the cifs share

```sh
kubectl create secret generic cifscreds --from-literal username=TESTER --from-literal password=SECRET
```

2. create the cifs-enabled pod

```sh
cat <<EOF | tee pod.yml
apiVersion: v1
kind: Pod
metadata:
  name: cc
spec:
  containers:
  - name: cc
    image: nginx
    volumeMounts:
    - name: test
      mountPath: /data
    ports:
    - containerPort: 80
  volumes:
  - name: test
    flexVolume:
      driver: "fvigotti/cifs"
      secretRef:
        name: cifscreds
      readOnly: true
      options:
        source: "//192.168.56.101/TEST"
        mountOptions: "dir_mode=0700,file_mode=0600"
EOF
```

generate the secret file, nb: the `type` is mandatory   
```sh
cat <<EOF | tee secret.yml
apiVersion: v1
data:
  password: bas64pwd
  username: bas64user
kind: Secret
metadata:
  name: cifscreds
  namespace: default
type: "fvigotti/cifs"
EOF
```


Feel free to edit the flexVolume specification to match your needs.


3. run the pod

```sh
kubectl create -f pod.yml
```

4. verify the pod

```sh
kubectl get pod cc
kubectl exec cc -- df ; ls -l /data
```

5. don't panic  
if something goes wrong ,
look at the kubelet log of host where the pod has been deployed,
 the cifs plugin is a bash script that can be modified in-place on that host ( add affinity to reschedule on same node )



### Docker building dockers - keeping them small

docker build process split into a 'builder' docker and a 'runtime'
docker to keep final docker image as small as possible.

To build the runtime docker image, clone this project and then
run the following command:

```bash
$ make container
$ make push
```

### References:

- https://github.com/coreos/coreos-overlay/issues/595
- https://github.com/jamiemccrindle/dockerception
- https://github.com/sigma/cifs_k8s_plugin

*NOTE*: this repository cannot be built automatically by docker hub.
