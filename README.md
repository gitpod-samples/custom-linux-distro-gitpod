# custom-gitpod-image

So I found some people in Gitpod discord server asked how to use custom ISO on Gitpod, however Gitpod is running on k8s cluster, means it's not an ordinary cloud VM like AWS EC2 or anything else, but an container running inside Google Kubernetes Engine.

So I finally go to [Gitpod workspace image repository](https://github.com/gitpod-io/workspace-images) and see the Dockerfile of gitpod/workspace-base, set up .gitpod.Dockerfile for testing, and finally push my change and create another workspace to test it. And finally I've sucessfully run Arch Linux and Debian inside Gitpod.

### Well, is there's anything that's missing or doesn't work?
Yeah of course, and even worse
1. All of those images doesn't have really functioning SSH Server, mean you can't SSH into your workspace or use remote feature in your editor/IDE
2. Lack of version manager (for Node.js and Ruby (maybe?))
3. Docker might not working as expected

### Ok how to use it?
1. [Fork this repo](https://github.com/sprucecellodev125/custom-gitpod-image)
2. Edit .gitpod.yml and change the path of the dockerfile (for example if you want debian-based workspace, in line 2 change .gitpod.Dockerfile to .gitpod.debian.Dockerfile)
PS: If you don't want to build the image you can use prebuilt, auto-updated image in this repository (for example use ghcr.io/sprucecellodev125/custom-gitpod-image:latest for Arch Linux image)
3. Create a new workspace with the following configuration:
  - Use your own fork as context url
  - Only use VSCode in browser as desktop version of VSCode and any IDE doesn't work
  - You can use ay workspace class
4. After creating a workspace it should be automatically start the build process (if you prefer to use .gitpod*.Dockerfile) otherwise it should be started automatically
5. Enjoy (if you use arch linux image run `pacman -Syu neofetch` and now you use arch btw)
