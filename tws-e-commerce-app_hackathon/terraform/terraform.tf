terraform {
  backend "s3" {
    bucket       = "remote-state-venkatesh-dev"
    key          = "backend-locking"
    region       = "us-east-1"
    use_lockfile = true
  }
}
