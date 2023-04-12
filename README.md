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
==== Opening 34.75.235.1 - default creds admin/password ====
```

`./08-add-pull-secret-OCP.sh`
```sh
==== Prompting for registry credentials ====

Username: read
Password: 

==== Creating secret jcr-pull-secret in current context ====

secret/jcr-pull-secret created

==== Adding secret jcr-pull-secret to default SA in current context ====

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