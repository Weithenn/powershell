﻿﻿# ==================================================================================
# Author:         Weithenn Wang (weithenn at weithenn.org)
# Version:        v0.1 - July 2, 2024
# IT event:       Cloud Summit Taiwan 2024
# Workshop Name:  實戰演練 - 打造超大型規模 Azure Stack HCI 和 AKS 基礎架構
# Description:    Step-by-step to build up Cluster Set with Azure Stack HCI
# ==================================================================================



# Create a Cluster Set (Scaleout Master)
New-ClusterSet -name "CS-Master" -NamespaceRoot "SOFS-ClusterSet" -CimSession "MGMT-Cluster" -StaticAddress "10.10.75.40"



# To add cluster members to the Cluster Set (Scaleout Worker)