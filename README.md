### archlinux-on-gitpod

So I found some people in Gitpod discord server asked how to use custom ISO on Gitpod, however Gitpod is running on k8s cluster, means it's not an ordinary cloud VM like AWS EC2 or anything else, but an container running inside Google Kubernetes Engine.

So I finally go to [Gitpod workspace image repository](https://github.com/gitpod-io/workspace-images) and see the Dockerfile of gitpod/workspace-base, set up .gitpod.Dockerfile for testing, and finally push my change and create another workspace to test it.