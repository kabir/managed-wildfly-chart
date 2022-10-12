# Managed WildFly Helm Chart

Proof of concept for Helm chart to create a managed WildFly instance from a deployment. 
It is not deployed anywhere yet so you need to build it yourself by running

# Build and install the Helm Chart
````shell
# Go to the checkout directory
cd managed-wildfly-chart
helm package .
````
Then we install the helm chart choosing a name (in this case `kabir-test`) for the application:
```shell
helm install kabir-test ./managed-wildfly-chart-0.1.0.tgz
```
This will create a bunch of ImageStreams and  BuildConfigs prefixed with `kabir-test-`, as well as a Service, Route 
and Deployment all called `kabir-test`. The namespace of the resources become that of the currently active OpenShift
project.

You can also pass in `--set builder.mode=populated` when running the above command which results in better performance
when creating a new application.
```shell
helm install kabir-test ./managed-wildfly-chart-0.1.0.tgz --set builder.mode=populated
```

# Create a new application
Now we can deploy a war containing a `META-INF/server-config.xml` such as this [test application](https://github.com/kabir/managed-wildfly-deployments/tree/main/simple).
(You need to clone that repository and build it).

Now we start a build which takes the uploaded war as input.
````shell
oc start-build kabir-test-deployment-build  --from-file=/path/to/managed-server-builder/target/ROOT.war
````
This will:
1) Grab the uploaded war
2) Use the managed server builder image to provision a server based on the contents of `META-INF/server-config.xml`
   - If  `--set builder.mode=populated` was **not** specified, this step will spend quite some time downloading all the maven dependencies.
   - If `--set builder.mode=populated` **was** specified, a different builder image will be used, which has a pre-populated maven repository for a given server version. Some time is saved by not having to download all the dependencies. The managed server team would make this image available.
4) Copy the server into an image based on the WildFly runtime image
5) Create another image with the war copied into the deployments/ directory of the prior image
6) Create an OpenShift Deployment running from the above image, as well as a Service and Route to connect to the image

# Update the application
To update the application, you can run the following command:
````shell
oc start-build kabir-test-update-build  --from-file=../managed-server-builder/target/ROOT.war
````
This is much faster than creating the application from scratch. It essentially takes the uploaded war, and performs 
step 4 above, so the application pods in 5 above are respawned.

**Note this does not do any checks of the war** - the onus is on the user to make sure that this is just a change to code.
If they are making any changes to the server, whether that is the provisioned Galleon layers (`server-config.xml`), or
configuration changes (`server-init.cli` or `server-init.yml`) the will ned to run the `kabir-test-deployment-build` command
again from the previous step.
