## EC2 vs ELB (ALB) Health Check --- Quick Difference

  --------------------------------------------------------------------------
  Item          EC2 Health Check          ELB (ALB) Health Check
  ------------- ------------------------- ----------------------------------
  Checks OS &   Yes                       No
  network                                 

  Checks        No                        Yes
  application                             

  Detects app   No                        Yes
  crash                                   

  Stops traffic No                        Yes
  to bad                                  
  instance                                

  ASG replaces  Yes (infra failure only)  Yes (app + infra failure)
  instance                                

  Recommended   No                        Yes
  for web apps                            
  --------------------------------------------------------------------------

**Used in this project:** ELB health checks are used so that only
healthy application instances receive traffic and unhealthy ones are
automatically replaced.

**One-line summary:**\
EC2 health checks verify only instance status, while ELB health checks
verify real application availability and are used for production
workloads behind a load balancer.

### ✅ EC2 Health Check (Simple)

Checks only:

- Is VM running?

- Is network reachable?

But if:

- Nginx stopped

- App crashed

EC2 still says:
👉 Healthy ❌ (but app is broken)

So users may get errors.

---


## ✅ ELB Health Check (What you are using)

Checks:

- Port is open

- App responds with HTTP 200

If app fails:

- ALB stops sending traffic

- ASG replaces instance

So:
👉 Users don’t hit broken servers ✅


### Interview Ready Summary (short)

I create S3 buckets with random suffix for global uniqueness, enable versioning for recovery, enforce ownership controls, block all public access, apply private ACLs, and enable server-side encryption by default. This follows AWS security best practices and prevents accidental data exposure.

---