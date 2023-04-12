# Cert Authority, Artifactory, OCP, ACS
Scripts for creating a local Certificate Authority (CA) and derived certs for JFrog Container Registry (JCR), deploying to OpenShift Container Platform, and more

Tested executing in order listed, on an ARM64 Mac, running Colima w/ docker runtime

_Disclaimer: For experimentation / local testing only_

## Pre-reqs

- `helm`
- `oc`
- `kubectl`
- `openssl`
- `sed`
- `grep`


## Scripts

Script | Comment
--- | ---
`01-create-CA-cert.sh`      | Creates local CA root key/cert, **remember passphrase**, only one attribute (ie: Country Name) needed for cert
`02-install-JCR-OCP.sh`     | Installs JCR on OCP using `helm`, temporary to get Load Balancer service IPs
`03-create-JCR-certs.sh`    | Creates certs derived from CA Root with SANs that includes JCR IPs
`04-reinstall-JCR-OCP.sh`   | Re-installs JCR with TLS certs created in previous step
`05-add-CA-OCP.sh`          | Adds CA Root cert to OCP platform trust store (requires JCR IPs)
`06-add-CA-colima.sh`       | Adds CA Root cert to Colima docker trust store (will not work with other runtimes)
`07-open-JCR.sh`            | Opens JCR UI, perform initial setup, change default pass, etc.
`08-add-pull-secret-OCP.sh` | Adds a Pull Secret in current k8s context namespace for JCR external IP (prompts for JCR creds)
`09-add-CA-ACS.sh`          | Adds CA Root Cert to RH ACS (Central, Scanner)

## Example
Example runs of the scripts mentioned

`./01-create-CA-cert.sh`
```sh
==== Generating CA ROOT KEY at /Users/dcaravel/.certs/myCA.key ====

Generating RSA private key, 2048 bit long modulus
...
Enter pass phrase for /Users/dcaravel/.certs/myCA.key:
Verifying - Enter pass phrase for /Users/dcaravel/.certs/myCA.key:

==== Generating CA ROOT CERT at /Users/dcaravel/.certs/myCA.pem ====

Enter pass phrase for /Users/dcaravel/.certs/myCA.key:
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) []:US
State or Province Name (full name) []:
Locality Name (eg, city) []:
Organization Name (eg, company) []:
Organizational Unit Name (eg, section) []:
Common Name (eg, fully qualified host name) []:
Email Address []:

==== Certs List from /Users/dcaravel/.certs ====

total 16
-rw-r--r--  1 dcaravel  staff  1751 Apr 12 16:43 myCA.key
-rw-r--r--  1 dcaravel  staff   956 Apr 12 16:43 myCA.pem
```

`02-install-JCR-OCP.sh`
```sh
==== Creating namespace artifactory-jcr if needed ====

namespace/artifactory-jcr created

==== Adding anyuid SCC to default SA ====

clusterrole.rbac.authorization.k8s.io/system:openshift:scc:anyuid added: "default"

==== Adding helm jfrog repo ====

"jfrog" already exists with the same configuration, skipping

==== Updating helm jfrog repo ====

Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "jfrog" chart repository
Update Complete. ⎈Happy Helming!⎈

==== Installing JFrog Container Registry (Artifactory) w/ persistence disabled ====

Release "jfrog-container-registry" does not exist. Installing it now.
NAME: jfrog-container-registry
LAST DEPLOYED: Wed Apr 12 16:45:07 2023
NAMESPACE: artifactory-jcr
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Congratulations. You have just deployed JFrog Container Registry!

==== Waiting for Load Balancer External IP to be provisioned ====

...............................
External JCR IP: 34.75.235.1
```

`03-create-JCR-certs.sh`
```sh
==== Generating Artifactory key ====

Generating RSA private key, 2048 bit long modulus
...

==== Generating Artifactory csr ====

You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) []:US
State or Province Name (full name) []:
Locality Name (eg, city) []:
Organization Name (eg, company) []:
Organizational Unit Name (eg, section) []:
Common Name (eg, fully qualified host name) []:
Email Address []:

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:

==== Generating Artifactory cert ====

Signature ok
subject=/C=US
Getting CA Private Key
Enter pass phrase for /Users/dcaravel/.certs/myCA.key:

==== Generated cert with following Subject Alternative Names (SANs) ====

DNS.1  = artifactory.artifactory-jcr
DNS.2  = artifactory.artifactory-jcr.svc
DNS.3  = arti.local
DNS.4  = *.arti.local
IP.1   = 172...
IP.2   = 34...

==== Certs List ====

total 40
-rw-r--r--  1 dcaravel  staff  1212 Apr 12 16:46 arti.local.crt
-rw-r--r--  1 dcaravel  staff   883 Apr 12 16:46 arti.local.csr
-rw-r--r--  1 dcaravel  staff  1679 Apr 12 16:46 arti.local.key
-rw-r--r--  1 dcaravel  staff  1751 Apr 12 16:43 myCA.key
-rw-r--r--  1 dcaravel  staff   956 Apr 12 16:43 myCA.pem
```

`./04-reinstall-JCR-OCP.sh`
```sh
==== Creating nginx-tls secret w/ JCR certs ====

secret/nginx-tls created

==== Installing JFrog Container Registry (Artifactory) w/ persistence ENABLED ====

Release "jfrog-container-registry" has been upgraded. Happy Helming!
NAME: jfrog-container-registry
LAST DEPLOYED: Wed Apr 12 16:48:00 2023
NAMESPACE: artifactory-jcr
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
Congratulations. You have just deployed JFrog Container Registry!
```

`./05-add-CA-OCP.sh`
```sh
==== Creating Registry CAs ConfigMap ====

configmap/registry-cas created

==== Patching OpenShift Image Config ====

image.config.openshift.io/cluster patched
```

`./06-add-CA-colima.sh`
```sh
==== Transfering /Users/dcaravel/.certs/myCA.pem to colima ====

myCA.pem                       100%  956     1.4MB/s   00:00    

==== Loading Root Cert into Trust Store (docker) ====

 * Stopping cri-dockerd ... [ ok ]
 * Stopping Docker Daemon ... [ ok ]
 * Starting Docker Daemon ... [ ok ]
 * Starting cri-dockerd ... [ ok ]
```

`./07-open-JCR.sh`
```sh
==== Opening external_ip - default creds admin/password ====
```
With UI open, setup wizard will appear, must accept EULA, change admin password, and recommended to create default `docker` repositories (rest of settings can be skipped)


`./08-add-pull-secret-OCP.sh`
```sh
==== Prompting for registry credentials ====

Username: read
Password: 

==== Prompting for registry creds ====


==== Creating secret jcr-ext-pull-secret in current context ====

secret/jcr-ext-pull-secret created

==== Creating secret jcr-int-pull-secret in current context ====

secret/jcr-int-pull-secret created

==== Adding secret jcr-ext-pull-secret and jcr-int-pull-secret to default SA in current context ====

serviceaccount/default patched
```

`./09-add-CA-ACS.sh`
```
==== Downloading ca-setup.sh ====

  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  2425  100  2425    0     0   8376      0 --:--:-- --:--:-- --:--:--  8479

==== Executing ca-setup.sh ====

W0412 16:58:35.184910   14860 helpers.go:663] --dry-run is deprecated and can be replaced with --dry-run=client.
secret/additional-ca created
secret/additional-ca labeled

==== Restarting Central ====

pod "central-55ddc5d68d-9r7th" deleted

==== Restarting Scanner ====

pod "scanner-77469bc4d5-w2cj4" deleted
```

## Usage / Outcome

Pushing an image to JCR via docker (colima) using external svc IP

```sh
$ EXTERNAL_IP=$(kubectl get svc jfrog-container-registry-artifactory-nginx -o json -n artifactory-jcr | jq -r '.status.loadBalancer.ingress[0] | .ip')

$ docker login $EXTERNAL_IP
Username: admin
Password: 
Login Succeeded

$ docker pull --platform=linux/amd64 nginx
Using default tag: latest
latest: Pulling from library/nginx
26c5c85e47da: Pull complete 
4f3256bdf66b: Pull complete 
2019c71d5655: Pull complete 
8c767bdbc9ae: Pull complete 
78e14bb05fd3: Pull complete 
75576236abf5: Pull complete 
Digest: sha256:63b44e8ddb83d5dd8020327c1f40436e37a6fffd3ef2498a6204df23be6e7e94
Status: Downloaded newer image for nginx:latest
docker.io/library/nginx:latest

$ docker tag nginx:latest $EXTERNAL_IP/docker/nginx

$ docker push $EXTERNAL_IP/docker/nginx
Using default tag: latest
The push refers to repository [$EXTERNAL_IP/docker/nginx]
9d907f11dc74: Pushed 
79974a1a12aa: Pushed 
f12d4345b7f3: Pushed 
935b5bd454e1: Pushed 
fb6d57d46ad5: Pushed 
ed7b0ef3bf5b: Pushed 
latest: digest: sha256:f2fee5c7194cbbfb9d2711fa5de094c797a42a51aa42b0c8ee8ca31547c872b1 size: 1570
```

Creating a pod with image from JCR

```sh
$ EXTERNAL_IP=$(kubectl get svc jfrog-container-registry-artifactory-nginx -o json -n artifactory-jcr | jq -r '.status.loadBalancer.ingress[0] | .ip')
$ INTERNAL_IP=$(kubectl get svc jfrog-container-registry-artifactory-nginx -o json -n artifactory-jcr | jq '.spec.clusterIP' -r)

$ oc run nginx --image $EXTERNAL_IP/docker/nginx
pod/nginx created

$ oc get pods
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          12s

$ oc get pods nginx -o json | jq .spec.containers[0].image
"$EXTERNAL_IP/docker/nginx"

$ oc delete pod nginx
pod "nginx" deleted

$ oc run nginx --image $INTERNAL_IP/docker/nginx
pod/nginx created

$ oc get pods
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          6s

$ oc get pods nginx -o json | jq .spec.containers[0].image
"$INTERNAL_IP/docker/nginx"

$ oc port-forward pod/nginx 8080:80 &

$ curl 127.0.0.1:8080
...
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>
...
```