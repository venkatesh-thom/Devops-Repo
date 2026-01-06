# Kubernetes Pod Anti-Affinity for Multi-AZ Deployments

## Overview

This document explains how to use **Kubernetes Pod Anti-Affinity** to deploy workloads (such as MySQL StatefulSets) across **multiple Availability Zones (AZs)** for high availability, and how to safely handle **single-AZ clusters**.

Using the wrong anti-affinity configuration can cause pods to remain in a `Pending` state, especially in clusters that do not span multiple AZs.

---

## What Is Pod Anti-Affinity?

Pod anti-affinity instructs the Kubernetes scheduler:

> “Avoid placing this pod close to other pods that match specific labels.”

It is commonly used to:

* Improve high availability
* Avoid single points of failure
* Spread replicas across AZs or nodes

---

## Hard Anti-Affinity Across Availability Zones

```yaml
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app: mysql
        topologyKey: topology.kubernetes.io/zone
```

### Explanation

* Pods with label `app=mysql` **must not** be scheduled in the same AZ
* `requiredDuringSchedulingIgnoredDuringExecution` is a **hard rule**
* The scheduler will refuse to schedule a pod if the rule cannot be met

### ❗ Issue in Single-AZ Clusters

If the cluster has **only one AZ**:

* The first pod schedules successfully
* Additional replicas cannot find a different AZ
* Pods remain in **`Pending`** state indefinitely

---

## Recommended Solution: Preferred Anti-Affinity (Safe Option)
## To allow scheduling of the extra pod(s) even if anti-affinity cannot be perfectly satisfied, use a soft rule instead:

```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100  # Preference weight (1–100). Higher means stronger preference.
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app: mysql
          topologyKey: topology.kubernetes.io/zone
```

### Benefits

* Spreads pods across AZs when multiple AZs are available
* Still schedules pods in single-AZ clusters
* Prevents pods from getting stuck in `Pending`
* Recommended for most environments (dev, staging, production)

---

## Alternative: Node-Level Spreading (Single-AZ Friendly)
## Single AZ Scenario:
```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app: mysql
          topologyKey: kubernetes.io/hostname
```

### Use Case

* Ensures pods do not run on the same node
* Works even when only one AZ is available
* Provides basic fault tolerance at the node level

---

## When to Use Hard (`required`) Anti-Affinity

Use `requiredDuringSchedulingIgnoredDuringExecution` **only if**:

* The cluster always spans **multiple AZs**
* You want strict enforcement
* You accept that pods may not schedule if constraints are unmet

This is typically suitable for tightly controlled production environments.

---

## Summary Table

| Scenario               | Recommended Setting       |
| ---------------------- | ------------------------- |
| Multi-AZ cluster       | `preferred` or `required` |
| Single-AZ cluster      | `preferred` only          |
| Development / Staging  | `preferred`               |
| Production (strict HA) | `required` (with caution) |

---

## Final Recommendation

For MySQL StatefulSets and most stateful workloads:

> **Use `preferredDuringSchedulingIgnoredDuringExecution` with `topology.kubernetes.io/zone`.**

This approach provides high availability **without risking unschedulable pods**.

---

## Single AZ Scenario:
```bash 
If you're in a single AZ environment, replace:

  topologyKey: topology.kubernetes.io/zone

with:

   topologyKey: kubernetes.io/hostname
```

---


# 1️⃣ What happens if a node is deleted after creating a Pod, PVC, and PV

## Scenario:

   * You have a StatefulSet or Pod using a PVC that is bound to a PV (backed by AWS EBS, for example).

   * You delete the node where the pod was running.

## Kubernetes Behavior:

* Pod

   * The pod will go into Pending if no other node can satisfy the scheduling requirements (e.g., anti-affinity, resources, zones).

   * If the pod can be scheduled elsewhere (another node in the cluster, in the same AZ if using EBS), it will be recreated automatically.

* PVC

  * PVC remains Bound to the PV.

  * PVC is not deleted, because it is independent of the node.


* PV (EBS volume in AWS)

  * EBS is still attached to the deleted node temporarily.

  * Kubernetes (via the cloud provider) will try to detach it from the deleted node and attach it to a new node where the pod is scheduled.

  * This may take a few seconds to a few minutes.


* Pod Scheduling Considerations

  * EBS volumes can only be attached to one AZ. If the pod is scheduled to a node in a different AZ, the pod will stay in Pending, because the volume cannot be attached there.

  * This is why AZ-aware scheduling (topologyKey: topology.kubernetes.io/zone) is important for StatefulSets with EBS.

# 2️⃣ Key Notes

  * Stateful workloads are resilient to node failures, but cloud volumes like EBS are AZ-bound.

  * If you delete a node, the pod will eventually come back on a healthy node in  the same AZ as the EBS volume.

  * If you use multi-AZ clusters, your StatefulSet can spread pods across zones, but each PV must stay in its original AZ.

  * Soft anti-affinity is helpful to avoid scheduling issues if nodes are deleted.





# If a node hosting your pods is deleted:

* Pods

    * Kubernetes recreates pods automatically if possible.

    * Pod may go Pending if AZ constraints or anti-affinity rules prevent scheduling.


* PVC

   * PVC remains Bound; data is safe.

*  PV (AWS EBS)

   * Volume detaches from the deleted node.

   * Volume re-attaches to a new node in the same AZ.

   * Pod becomes Ready once the volume is attached.

## Important:

   * EBS volumes cannot move across AZs.

   * Use kubectl describe pod <pod> to troubleshoot Pending pods.  


