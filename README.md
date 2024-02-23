## Install Azure DevBox extension

```bash
az extension add --name devcenter
```

### Create a Resource Group 📦

As every Azure resource, the first thing you need to do is to create a resource group.

```bash
RESOURCE_GROUP="DevBoxDemos"
LOCATION="westeurope"

az group create --name $RESOURCE_GROUP --location $LOCATION
```

### Create a virtual network

In a enterprise environment, you will probably want to create a virtual network to connect your dev boxes to your corporate network.

```bash
VNET_NAME="devbox-vnet"
SUBNET_NAME="devboxes-subnet"

az network vnet create \
--name $VNET_NAME \
--resource-group $RESOURCE_GROUP \
--location $LOCATION \
--address-prefixes 192.168.0.0/16 \
--subnet-name $SUBNET_NAME \
--subnet-prefix 192.168.1.0/24
```

### Create a Gallery

A gallery is a place where you can store your custom images. You can create a gallery in the Azure portal, but you can also create it using the Azure CLI.

```bash
GALLERY_NAME="returngis_gallery"

az sig create \
--resource-group $RESOURCE_GROUP \
--gallery-name $GALLERY_NAME \
--location $LOCATION
```
<!-- az image builder create --image-source $imagesource -n myTemplate -g myGroup \
    --scripts $scripts --managed-image-destinations image_1=westus \
    --shared-image-destinations my_shared_gallery/linux_image_def=westus,brazilsouth \
   --identity myIdentity --staging-resource-group myStagingResourceGroup -->

### Create the image definition

```bash
az sig image-definition create \
--resource-group $RESOURCE_GROUP \
--gallery-name $GALLERY_NAME \
--gallery-image-definition "vscodeImageDef" \
--os-type "Windows" \
--os-state "Generalized" \
--publisher "returngis" \
--offer "vscodebox" \
--sku "1-0-0" \
--hyper-v-generation "V2" \
--features "SecurityType=TrustedLaunch"
```

### Create the custom image

```bash
mkdir -p tmp
cp custom-images/win11-with-vscode.json /tmp/win11-with-vscode.json

sed -i -e "s%<subscriptionID>%$SUBSCRIPTION_ID%g" tmp-image-builder/win11-with-vscode.json
sed -i -e "s%<rgName>%$RESOURCE_GROUP%g" tmp-image-builder/win11-with-vscode.json
sed -i -e "s%<region1>%$LOCATION%g" tmp-image-builder/win11-with-vscode.json
# sed -i -e "s%<region2>%$ADITIONAL_LOCATION%g" tmp-image-builder/win11-with-vscode.json
sed -i -e "s%<imageName>%$IMAGE_NAME%g" tmp-image-builder/win11-with-vscode.json
sed -i -e "s%<runOutputName>%$RUN_OUTPUT_NAME%g" tmp-image-builder/win11-with-vscode.json
sed -i -e "s%<sharedImageGalName>%$GALLERY_NAME%g" tmp-image-builder/win11-with-vscode.json
sed -i -e "s%<imgBuilderId>%$IDENTITY_ID%g" tmp-image-builder/win11-with-vscode.json
sed -i -e "s%<imageDefName>%$IMAGE_NAME%g" tmp-image-builder/win11-with-vscode.json


# Create parameters file

cat <<EOF > /tmp/win11-with-vscode-parameters.json
{
  "imageTemplateName": {
    "value": "vscodeWinTemplate"
  },
  "api-version": {
    "value": "2020-02-14"
  },
  "svclocation": {
    "value": "$LOCATION"
  }
}

```

```bash
az group deployment create \
--resource-group $RESOURCE_GROUP \
--template-file /tmp/win11-with-vscode.json \
--parameters "{ \"location\": { \"value\": \"westus\" } }"
```


### Create a Dev Center 🏢

The first thing you need to do is to create a Dev Center. This is the place where you will manage your projects.

```bash
DEV_CENTER_NAME=returngis-dev-center

DEV_CENTER_ID=$(az devcenter admin devcenter create \
--name $DEV_CENTER_NAME \
--resource-group $RESOURCE_GROUP \
--identity-type "SystemAssigned" \
--query id -o tsv)
```


### Create a Project 📝

Projects in Dev Box should represent a team or a group of people that will use the same dev boxes. For example, you can create a project for your backend team, another for your frontend team, and so on.

```bash
DEV_CENTER_PROJECT="tour-of-heroes-project"

az devcenter admin project create \
--name $DEV_CENTER_PROJECT \
--resource-group $RESOURCE_GROUP \
--dev-center-id $DEV_CENTER_ID \
--max-dev-boxes-per-user 2
```

### Create a Dev Box Definition 📦

#### Get image reference id

```bash
az devcenter admin image list \
--resource-group $RESOURCE_GROUP \
--dev-center $DEV_CENTER_NAME \
-o table
```

For this example, we'll use Visual Studio 2022 Enterprise on Windows 11 Enterprise + Microsoft 365 Apps 23H2

```bash
IMAGE_NAME="microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2"

IMAGE_REFERENCE_ID=$(az devcenter admin image show \
--resource-group $RESOURCE_GROUP \
--dev-center $DEV_CENTER_NAME \
--gallery-name "Default" \
--name $IMAGE_NAME \
--query id -o tsv)
```

Custom image:

```bash
IMAGE_NAME="vscodeImageDef"

IMAGE_REFERENCE_ID=$(az devcenter admin image show \
--resource-group $RESOURCE_GROUP \
--dev-center $DEV_CENTER_NAME \
--gallery-name "devboxGallery" \
--name $IMAGE_NAME \
--query id -o tsv)
```

As you can see I use the `--gallery-name "Default"` parameter. This is because the image is in the default gallery. If you want to use a custom gallery, you need to specify the gallery name.

You can check all the available galleries with the following command:

```bash
az devcenter admin gallery list \
--resource-group $RESOURCE_GROUP \
--dev-center $DEV_CENTER_NAME \
-o table
```

#### How to get the available SKUs

```bash
az devcenter admin sku list -o table

SKU_NAME="general_i_8c32gb256ssd_v2"
```

And now, we can create the Dev Box Definition

#### Create a dev box definition with a image reference

```bash
DEV_BOX_DEFINITION_NAME="vs2022-box"

az devcenter admin devbox-definition create \
--name $DEV_BOX_DEFINITION_NAME \
--dev-center $DEV_CENTER_NAME \
--resource-group $RESOURCE_GROUP \
--image-reference id=$IMAGE_REFERENCE_ID \
--os-storage-type "ssd_256gb" \
--sku name="$SKU_NAME" \
--hibernate-support Enabled
```

#### Create a dev box definition with a custom image

```bash
DEV_BOX_DEFINITION_NAME="vscode-box"

az devcenter admin devbox-definition create \
--name $DEV_BOX_DEFINITION_NAME \
--dev-center $DEV_CENTER_NAME \
--resource-group $RESOURCE_GROUP \
--image-reference id=$IMAGE_REFERENCE_ID \
--os-storage-type "ssd_256gb" \
--sku name="$SKU_NAME" \
--hibernate-support Enabled
```

### Create a network connections

```bash
az devcenter admin network-connection create \
--name "$LOCATION-connection" \
--resource-group $RESOURCE_GROUP \
--location $LOCATION \
--domain-join-type "AzureAdJoin" \
--networking-resource-group-name $RESOURCE_GROUP \
--subnet-id $(az network vnet subnet show --name $SUBNET_NAME --vnet-name $VNET_NAME --resource-group $RESOURCE_GROUP --query id -o tsv)
```

### Create a dev box pool

Now that you have a dev box definition, you can create a dev box pool in your project. A dev box pool is a set of dev boxes that are created from the same dev box definition. 

<!-- ```bash
DEV_BOX_POOL_NAME="backend-team-pool"

az devcenter admin pool create \
--name $DEV_BOX_POOL_NAME \
--project-name $DEV_CENTER_PROJECT \
--resource-group $RESOURCE_GROUP \
--devbox-definition-name $DEV_BOX_DEFINITION_NAME \
--local-administrator Disabled \
--virtual-network-type Managed \
--managed-virtual-network-regions "westeurope"
``` -->

```bash
DEV_BOX_POOL_NAME="backend-team-pool"

az devcenter admin pool create \
--name $DEV_BOX_POOL_NAME \
--project-name $DEV_CENTER_PROJECT \
--resource-group $RESOURCE_GROUP \
--devbox-definition-name $DEV_BOX_DEFINITION_NAME \
--local-administrator Disabled \
--virtual-network-type Unmanaged \
--network-connection-name "$LOCATION-connection"
```

##### Provide access to a dev project

##### Assign DevCenter Dev Box User role to a user

```bash
USER_EMAIL="<your-email>"

az role assignment create \
--role "DevCenter Dev Box User" \
--assignee $USER_EMAIL \
--scope $(az devcenter admin project show --name $DEV_CENTER_PROJECT --resource-group $RESOURCE_GROUP --query id -o tsv)
```

#### Got to the developer portal and create a dev box

The URL for the developer portal is https://devportal.microsoft.com

You should see something like this:

<img src="images/Dev Box portal.png" />

And once you launch the dev box you can configure `In Session Settings`:

<img src="images/In Session Settings.png" />

### Check the usage

```bash
az devcenter admin usage list -l $LOCATION \
--query "[].{name:name.value, currentValue:currentValue}" \
-o table
```

You'll get something like this:

```bash
Name                CurrentValue
------------------  --------------
devBoxDefinitions   2
devCenters          2
general_i_v2        8
networkConnections  0
general_a_v1        0
general_a_v2        0
pools               0
projects            0
```

#### Create your own images

You can create your own images and upload them to your Dev Center. You have several options: you can use Azure Image Builder, Packer, or any other tool that you like.

##### Azure Image Builder

Let's create an image with Azure Image Builder.

But first let's create a managed identity for the image builder.

```bash
IMAGE_BUILDER_IDENTITY="image-builder-identity"

IDENTITY_CLIENT_ID=$(az identity create \
--name $IMAGE_BUILDER_IDENTITY \
--resource-group $RESOURCE_GROUP \
--query clientId -o tsv)
```

Now let's create a custom role for the image builder.

```bash
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

az role definition create --role-definition @- <<EOF
{
    "Name": "Azure Image Builder Service Image Creation Role",
    "IsCustom": true,
    "Description": "Image Builder access to create resources for the image build, you should delete or split out as appropriate",
    "Actions": [
        "Microsoft.Compute/galleries/read",
        "Microsoft.Compute/galleries/images/read",
        "Microsoft.Compute/galleries/images/versions/read",
        "Microsoft.Compute/galleries/images/versions/write",

        "Microsoft.Compute/images/write",
        "Microsoft.Compute/images/read",
        "Microsoft.Compute/images/delete"
    ],
    "NotActions": [
  
    ],
    "AssignableScopes": [
      "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
    ]
  }
EOF
```

Check the custom role was created successfully

```bash
az role definition list --custom-role-only -o table
```

Assign the custom role to the managed identity

```bash
az role assignment create \
--role "Azure Image Builder Service Image Creation Role" \
--assignee $IDENTITY_CLIENT_ID \
--scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP
```

Check the role was assigned successfully

```bash
az role assignment list --assignee $IDENTITY_CLIENT_ID --all -o table
```

Now let's replace the values in the template

```bash
mkdir -p tmp-image-builder
cp custom-images/helloImageTemplateWin.json tmp-image-builder/helloImageTemplateWin.json

IMAGE_NAME="helloImageWin"
RUN_OUTPUT_NAME="helloImageWinRunOutput"
IDENTITY_ID=$(az identity show --name $IMAGE_BUILDER_IDENTITY --resource-group $RESOURCE_GROUP --query id -o tsv)

sed -i -e "s%<subscriptionID>%$SUBSCRIPTION_ID%g" tmp-image-builder/helloImageTemplateWin.json
sed -i -e "s%<rgName>%$RESOURCE_GROUP%g" tmp-image-builder/helloImageTemplateWin.json
sed -i -e "s%<region>%$LOCATION%g" tmp-image-builder/helloImageTemplateWin.json
sed -i -e "s%<imageName>%$IMAGE_NAME%g" tmp-image-builder/helloImageTemplateWin.json
sed -i -e "s%<runOutputName>%$RUN_OUTPUT_NAME%g" tmp-image-builder/helloImageTemplateWin.json
sed -i -e "s%<imgBuilderId>%$IDENTITY_ID%g" tmp-image-builder/helloImageTemplateWin.json
```

Now let's create the image

```bash
az resource create \
--resource-group $RESOURCE_GROUP \
--is-full-object \
--properties @tmp-image-builder/helloImageTemplateWin.json \
--resource-type Microsoft.VirtualMachineImages/imageTemplates \
--name helloImageTemplateWin01
```

#### Create a gallery

First of all you need to create a Gallery on Azure

```bash
GALLERY_NAME="returngis_gallery"
az sig create \
--gallery-name $GALLERY_NAME \
--resource-group $RESOURCE_GROUP
```

Then you can associate the gallery with the Dev Center:

First you have to give the Dev Center permissions to the gallery using the `az role assignment create` command.

```bash
DEV_CENTER_CLIENT_ID=$(az devcenter admin devcenter show \
--name $DEV_CENTER_NAME \
--resource-group $RESOURCE_GROUP \
--query identity.principalId -o tsv)
```

Let's assign the `Contributor` role to the Dev Center:

```bash
az role assignment create \
--role "Contributor" \
--assignee $DEV_CENTER_CLIENT_ID \
--scope $(az sig show --gallery-name $GALLERY_NAME --resource-group $RESOURCE_GROUP --query id -o tsv)
```
Then you can associate the gallery with the Dev Center:

```bash
az devcenter admin gallery create \
--name $GALLERY_NAME \
--gallery-resource-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Compute/galleries/$GALLERY_NAME" \
--dev-center $DEV_CENTER_NAME \
--resource-group $RESOURCE_GROUP
```

Para la creada por powershell

```bash
az role assignment create \
--role "Contributor" \
--assignee $DEV_CENTER_CLIENT_ID \
--scope $(az sig show --gallery-name devboxGallery --resource-group $RESOURCE_GROUP --query id -o tsv)

az devcenter admin gallery create \
--name devboxGallery \
--gallery-resource-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Compute/galleries/devboxGallery" \
--dev-center $DEV_CENTER_NAME \
--resource-group $RESOURCE_GROUP
```



#### Create the image for the gallery

```bash
IMAGE_NAME="vscodeImageWin"
IMAGE_TEMPLATE_NAME="vscodeImageTemplateWin"
ADITIONAL_LOCATION="northeurope"

cp custom-images/win11-with-vscode-new.json tmp-image-builder/win11-with-vscode.json

sed -i -e "s%<subscriptionID>%$SUBSCRIPTION_ID%g" tmp-image-builder/win11-with-vscode.json
sed -i -e "s%<rgName>%$RESOURCE_GROUP%g" tmp-image-builder/win11-with-vscode.json
sed -i -e "s%<region1>%$LOCATION%g" tmp-image-builder/win11-with-vscode.json
sed -i -e "s%<region2>%$ADITIONAL_LOCATION%g" tmp-image-builder/win11-with-vscode.json
sed -i -e "s%<imageName>%$IMAGE_NAME%g" tmp-image-builder/win11-with-vscode.json
sed -i -e "s%<runOutputName>%$RUN_OUTPUT_NAME%g" tmp-image-builder/win11-with-vscode.json
sed -i -e "s%<sharedImageGalName>%$GALLERY_NAME%g" tmp-image-builder/win11-with-vscode.json
sed -i -e "s%<imgBuilderId>%$IDENTITY_ID%g" tmp-image-builder/win11-with-vscode.json
sed -i -e "s%<imageDefName>%$IMAGE_NAME%g" tmp-image-builder/win11-with-vscode.json
```

Now let's create the image in the gallery

```bash
az resource create \
--resource-group $RESOURCE_GROUP \
--is-full-object \
--properties @tmp-image-builder/win11-with-vscode.json \
--resource-type Microsoft.VirtualMachineImages/imageTemplates \
--name win11-with-vscode
```

#### Create images with Packer



### Clean up

```bash
az group delete --name $RESOURCE_GROUP --yes --no-wait
```