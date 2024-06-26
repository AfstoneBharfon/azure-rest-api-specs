import "@typespec/http";
import "@typespec/openapi";
import "@typespec/rest";
import "@azure-tools/typespec-azure-core";
import "@azure-tools/typespec-azure-resource-manager";

using TypeSpec.Http;
using TypeSpec.OpenAPI;
using TypeSpec.Rest;
using TypeSpec.Versioning;
using Azure.Core;
using Azure.ResourceManager;

@armProviderNamespace
@service({
  title: "Managed DevOps Infrastructure",
})
@versioned(Versions)
namespace Microsoft.DevOpsInfrastructure;

/** Api versions */
enum Versions {
  /** 2024-03-26-preview preview version */
  @useDependency(Azure.ResourceManager.Versions.v1_0_Preview_1)
  `2024-03-26-preview`,
}

model Pool is TrackedResource<PoolProperties> {
  @key("poolName")
  @pattern("^[a-zA-Z0-9][a-zA-Z0-9-.]*$")
  @path
  @segment("pools")
  @doc("Name of the pool. It needs to be globally unique.")
  name: string;

  ...ManagedServiceIdentity;
}

@doc("Pool properties")
model PoolProperties {
  #suppress "@azure-tools/typespec-azure-resource-manager/arm-resource-provisioning-state" "Existing SDK"
  @doc("The status of the current operation.")
  provisioningState?: ProvisioningState;

  @minValue(1)
  @maxValue(10000)
  @doc("Defines how many resources can there be created at any given time.")
  maximumConcurrency: int32;

  @doc("Defines the organization in which the pool will be used.")
  organizationProfile: OrganizationProfile;

  @doc("Defines how the machine will be handled once it executed a job.")
  agentProfile: AgentProfile;

  @doc("Defines the type of fabric the agent will run on.")
  fabricProfile: FabricProfile;

  @doc("The resource id of the DevCenter Project the pool belongs to.")
  devCenterProjectResourceId: string;
}

@doc("Defines the organization in which the pool will be used.")
@discriminator("kind")
model OrganizationProfile {}

@doc("GitHub organization profile")
model GitHubOrganizationProfile extends OrganizationProfile {
  @doc("GitHub organization profile")
  kind: "GitHub";

  @doc("The list of GitHub organizations/repositories the pool should be present in.")
  @extension("x-ms-identifiers", [])
  organizations: GitHubOrganization[];
}
@doc("Defines a GitHub organization")
model GitHubOrganization {
  @doc("The GitHub organization URL in which the pool should be created.")
  url: string;

  @doc("Optional list of repositories in which the pool should be created.")
  repositories?: string[];
}

@doc("Azure DevOps organization profile")
model AzureDevOpsOrganizationProfile extends OrganizationProfile {
  @doc("Azure DevOps organization profile")
  kind: "AzureDevOps";

  @doc("The list of Azure DevOps organizations the pool should be present in.")
  @extension("x-ms-identifiers", [])
  organizations: Organization[];

  @doc("The type of permission which determines which accounts are admins on the Azure DevOps pool.")
  permissionProfile?: AzureDevOpsPermissionProfile;
}
@doc("Defines an Azure DevOps organization.")
model Organization {
  @doc("The Azure DevOps organization URL in which the pool should be created.")
  url: string;

  @doc("Optional list of projects in which the pool should be created.")
  projects?: string[];

  @doc("How many machines can be created at maximum in this organization out of the maximumConcurrency of the pool.")
  parallelism?: int32;
}
@doc("Defines the type of Azure DevOps pool permission.")
model AzureDevOpsPermissionProfile {
  @doc("Determines who has admin permissions to the Azure DevOps pool.")
  kind: AzureDevOpsPermissionType;

  @doc("User email addresses")
  users?: string[];

  @doc("Group email addresses")
  groups?: string[];
}
@doc("Determines who has admin permissions to the Azure DevOps pool.")
union AzureDevOpsPermissionType {
  string,

  @doc("Pool will inherit permissions from the project or organization.")
  "Inherit",

  @doc("Only the pool creator will be an admin of the pool.")
  "CreatorOnly",

  @doc("Only the specified accounts will be admins of the pool.")
  "SpecificAccounts",
}

@doc("Defines the type of fabric the agent will run on.")
@discriminator("kind")
model FabricProfile {}
@doc("The agents will run on Virtual Machine Scale Sets.")
model VmssFabricProfile extends FabricProfile {
  @doc("Virtual Machine Scale Sets")
  kind: "Vmss";

  @doc("The Azure SKU of the machines in the pool.")
  sku: DevOpsAzureSku;

  @doc("The VM images of the machines in the pool.")
  @extension("x-ms-identifiers", [])
  images: PoolImage[];

  @doc("The OS profile of the machines in the pool.")
  osProfile?: OsProfile;

  @doc("The storage profile of the machines in the pool.")
  storageProfile?: StorageProfile;

  @doc("The network profile of the machines in the pool.")
  networkProfile?: NetworkProfile;
}

@doc("The Azure SKU of the machines in the pool.")
model DevOpsAzureSku {
  @doc("The Azure SKU name of the machines in the pool.")
  name: string;
}

@doc("The storage profile of the VMSS.")
model StorageProfile {
  @doc("The Azure SKU name of the machines in the pool.")
  osDiskStorageAccountType?: OsDiskStorageAccountType;

  @doc("A list of empty data disks to attach.")
  @extension("x-ms-identifiers", [])
  dataDisks?: DataDisk[];
}

@doc("The data disk of the VMSS.")
model DataDisk {
  @doc("The type of caching to be enabled for the data disks. The default value for caching is readwrite. For information about the caching options see: https://blogs.msdn.microsoft.com/windowsazurestorage/2012/06/27/exploring-windows-azure-drives-disks-and-images/.")
  caching?: CachingType;

  @doc("The initial disk size in gigabytes.")
  diskSizeGiB?: int32;

  @doc("The storage Account type to be used for the data disk. If omitted, the default is \"standard_lrs\".")
  storageAccountType?: StorageAccountType;

  @doc("The drive letter for the empty data disk. If not specified, it will be the first available letter.")
  driveLetter?: string;
}

@doc("The type of caching in a data disk.")
union CachingType {
  string,

  @doc("Don't use host caching.")
  "None",

  @doc("For workloads that only do read operations.")
  "ReadOnly",

  @doc("For workloads that do a balance of read and write operations.")
  "ReadWrite",
}

@doc("StorageAccountType enums")
union StorageAccountType {
  string,

  @doc("The data disk should use standard locally redundant storage.")
  StandardLRS: "standard_lrs",

  @doc("The data disk should use premium locally redundant storage.")
  PremiumLRS: "premium_lrs",

  @doc("The data disk should use standard SSD locally redundant storage.")
  StandardSSDLRS: "standardssd_lrs",

  @doc("The data disk should use premium SSD zonal redundant storage.")
  PremiumZRS: "premium_zrs",

  @doc("The data disk should use standard SSD zonal redundant storage.")
  StandardSSDZRS: "standardssd_zrs",
}

@doc("The storage account type of the OS disk.")
union OsDiskStorageAccountType {
  string,

  @doc("Standard OS disk type.")
  "Standard",

  @doc("Premium OS disk type.")
  "Premium",

  @doc("Standard SSD OS disk type.")
  "StandardSSD",
}

@doc("The VM image of the machines in the pool.")
model PoolImage {
  @doc("The resource id of the image.")
  resourceId?: string;

  @doc("The image to use from a well-known set of images made available to customers.")
  wellKnownImageName?: string;

  @doc("List of aliases to reference the image by.")
  aliases?: string[];

  @doc("The percentage of the buffer to be allocated to this image.")
  buffer?: string = "*";
}

@doc("The OS profile of the machines in the pool.")
model OsProfile {
  @doc("The secret management settings of the machines in the pool.")
  secretsManagementSettings?: SecretsManagementSettings;

  @doc("Determines how the service should be run. By default, this will be set to Service.")
  logonType?: LogonType;
}
@doc("The secret management settings of the machines in the pool.")
model SecretsManagementSettings {
  @doc("Where to store certificates on the machine.")
  certificateStoreLocation?: string;

  @doc("The list of certificates to install on all machines in the pool.")
  observedCertificates: url[];

  @doc("Defines if the key of the certificates should be exportable.")
  keyExportable: boolean;
}
@doc("Determines how the service should be run.")
union LogonType {
  string,

  @doc("Run as a service.")
  "Service",

  @doc("Run in interactive mode.")
  "Interactive",
}

@doc("The network profile of the machines in the pool.")
model NetworkProfile {
  @doc("The subnet id on which to put all machines created in the pool.")
  subnetId: string;
}

@doc("The agent profile of the machines in the pool.")
@discriminator("kind")
model AgentProfile {
  @doc("Defines pool buffer.")
  resourcePredictions?: ResourcePredictions;
}
@doc("Stateless profile meaning that the machines will be cleaned up after running a job.")
model StatelessAgentProfile extends AgentProfile {
  @doc("Stateless profile meaning that the machines will be cleaned up after running a job.")
  kind: "Stateless";
}
@doc("Stateful profile meaning that the machines will be returned to the pool after running a job.")
model Stateful extends AgentProfile {
  @doc("Stateful profile meaning that the machines will be returned to the pool after running a job.")
  kind: "Stateful";

  @doc("How long should stateful machines be kept around. The maximum is one week.")
  maxAgentLifetime: string;
}
@doc("Defines pool buffer.")
model ResourcePredictions {}

@doc("The status of the current operation.")
union ProvisioningState {
  string,

  /** Represents a succeeded operation. */
  Succeeded: "Succeeded",

  /** Represents a failed operation. */
  Failed: "Failed",

  /** Represents a canceled operation. */
  Canceled: "Canceled",

  /** Represents a pending operation. */
  Provisioning: "Provisioning",

  /** Represents a pending operation. */
  Updating: "Updating",

  /** Represents an operation under deletion. */
  Deleting: "Deleting",

  /** Represents an accepted operation. */
  Accepted: "Accepted",
}

interface Operations extends Azure.ResourceManager.Operations {}

@armResourceOperations
interface Pools {
  get is ArmResourceRead<Pool>;
  createOrUpdate is ArmResourceCreateOrUpdateAsync<Pool>;
  update is ArmResourcePatchAsync<Pool, PoolProperties>;
  delete is ArmResourceDeleteWithoutOkAsync<Pool>;
  listByResourceGroup is ArmResourceListByParent<Pool>;
  listBySubscription is ArmListBySubscription<Pool>;
}

@parentResource(Pool)
@doc("A ResourceDetailsObject")
model ResourceDetailsObject is ProxyResource<ResourceDetailsObjectProperties> {
  @doc("The name of the resource.")
  @key("resourceName")
  @segment("resources")
  @visibility("read")
  @path
  name: string;
}

#suppress "@azure-tools/typespec-azure-resource-manager/arm-resource-provisioning-state" "No ProvisioningState"
@doc("Details of the ResourceDetailsObject.")
model ResourceDetailsObjectProperties {
  @doc("The status of the resource.")
  status: ResourceStatus;

  @doc("The image name of the resource.")
  image: string;

  @doc("The version of the image running on the resource.")
  imageVersion: string;
}

@doc("The status of the machine resource.")
union ResourceStatus {
  string,

  /** Represents a machine resource that is ready. */
  Ready: "Ready",

  /** Represents a machine resource that is not ready. */
  NotReady: "NotReady",

  /** Represents a machine resource that is allocated. */
  Allocated: "Allocated",

  /** Represents a machine resource that is pending return. */
  PendingReturn: "PendingReturn",

  /** Represents a machine resource that is returned. */
  Returned: "Returned",

  /** Represents a machine resource that is leased. */
  Leased: "Leased",

  /** Represents a machine resource that is provisioning. */
  Provisioning: "Provisioning",

  /** Represents a machine resource that is updating. */
  Updating: "Updating",

  /** Represents a machine resource that is starting. */
  Starting: "Starting",

  /** Represents a machine resource that is pending reimage. */
  PendingReimage: "PendingReimage",

  /** Represents a machine resource that is reimaging. */
  Reimaging: "Reimaging",
}

@armResourceOperations
interface ResourceDetails {
  listByPool is ArmResourceListByParent<ResourceDetailsObject>;
}

union ResourceSkuCapacityScaleType {
  string,
  "Automatic",
  "Manual",
  "None",
}

@doc("Describes scaling information of a SKU.")
model ResourceSkuCapacity {
  @doc("The minimum capacity of the SKU.")
  minimum?: int32;

  @doc("The maximum capacity of the SKU.")
  maximum?: int32;

  @doc("The default capacity of the SKU.")
  default?: int32;

  @doc("The scale type of the SKU.")
  scaleType: ResourceSkuCapacityScaleType;
}

@doc("Describes The SKU capabilities object.")
model ResourceSkuCapabilities {
  @doc("The name of the SKU capability.")
  name: string;

  @doc("The value of the SKU capability.")
  value: string;
}

@doc("The restrictions of the SKU.")
model ResourceSkuRestrictions {
  @doc("the type of restrictions.")
  type?: ResourceSkuRestrictionsType;

  @doc("The value of restrictions. If the restriction type is set to location. This would be different locations where the SKU is restricted.")
  values: string[];

  @doc("The information about the restriction where the SKU cannot be used.")
  restrictionInfo: ResourceSkuRestrictionInfo;

  @doc("the reason for restriction.")
  reasonCode?: ResourceSkuRestrictionsReasonCode;
}

union ResourceSkuRestrictionsType {
  string,
  "Location",
  "Zone",
}

@doc("Describes an available Compute SKU Restriction Information.")
model ResourceSkuRestrictionInfo {
  @doc("Locations where the SKU is restricted")
  locations?: string[];

  @doc("List of availability zones where the SKU is restricted.")
  zones?: string[];
}

union ResourceSkuRestrictionsReasonCode {
  string,
  "QuotaId",
  "NotAvailableForSubscription",
}

@doc("Describes an available Compute SKU Location Information.")
model ResourceSkuLocationInfo {
  @doc("Location of the SKU")
  location: string;

  @doc("List of availability zones where the SKU is supported.")
  zones: string[];

  @doc("Gets details of capabilities available to a SKU in specific zones.")
  @extension("x-ms-identifiers", [])
  zoneDetails: ResourceSkuZoneDetails[];
}

@doc("Describes The zonal capabilities of a SKU.")
model ResourceSkuZoneDetails {
  @doc("Gets the set of zones that the SKU is available in with the specified capabilities.")
  name: string[];

  @doc("A list of capabilities that are available for the SKU in the specified list of zones.")
  @extension("x-ms-identifiers", [])
  capabilities: ResourceSkuCapabilities[];
}

@doc("A ResourceSku")
@parentResource(Location)
model ResourceSku is ProxyResource<ResourceSkuProperties> {
  @doc("The name of the SKU.")
  @key("skuName")
  @segment("skus")
  @visibility("read")
  @path
  name: string;
}

#suppress "@azure-tools/typespec-azure-resource-manager/arm-resource-provisioning-state" "No ProvisioningState"
@doc("Properties of a ResourceSku")
model ResourceSkuProperties {
  @doc("The type of resource the SKU applies to.")
  resourceType: string;

  @doc("The tier of virtual machines in a scale set")
  tier: string;

  @doc("The size of the SKU.")
  size: string;

  @doc("The family of the SKU.")
  family: string;

  @doc("The set of locations that the SKU is available.")
  locations: string[];

  @doc("A list of locations and availability zones in those locations where the SKU is available")
  @extension("x-ms-identifiers", [])
  locationInfo: ResourceSkuLocationInfo[];

  @doc("Name value pairs to describe the capability.")
  @extension("x-ms-identifiers", [])
  capabilities: ResourceSkuCapabilities[];

  @doc("The restrictions of the SKU.")
  @extension("x-ms-identifiers", [])
  restrictions: ResourceSkuRestrictions[];
}

#suppress "@azure-tools/typespec-azure-resource-manager/arm-resource-provisioning-state" "No ProvisioningState"
#suppress "@azure-tools/typespec-azure-resource-manager/missing-property" "No Identity"
@doc("An Azure location.")
model Location is ProxyResource<LocationProperties> {
  @key("locationName")
  @pattern("^[a-zA-Z0-9][a-zA-Z0-9-.]*$")
  @path
  @segment("locations")
  @doc("Name of the location.")
  @visibility("public")
  name: string;
}

#suppress "@azure-tools/typespec-azure-resource-manager/arm-resource-provisioning-state" "No ProvisioningState"
@doc("Properties of a location.")
model LocationProperties {}

@armResourceOperations
interface Sku {
  listByLocation is ArmListBySubscription<ResourceSku>;
}
