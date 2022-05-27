# Deploying to GitHub Container Registry
This sample shows how to build and publish an image to GitHub Container Registry (GHCR). It uses the same sample Python application as the [ACR sample](https://github.com/kenmuse/gh-actions-and-acr). The image contains a minimal, Flash-based web application. The base image is pulled from DockerHub. 

*Release* versions will include the version tag, and the the most recent release will be tagged with `latest`. The most recent manually built images will be tagged with the branch name (`main`). All builds will have the SHA256 identifier. These display in GitHub as 'untagged". The images are signed, so an additional .sig is uploaded with each image.

> **Note**  
> The workflow uses Actions that are not certified by GitHub. They are provided by third-parties and are governed by
> separate terms of service, privacy policy, and support documentation.

## Packages and Pulling
The image is pushed to the repository packages and visible there. It is also stored at the organization level. The images can have fine-grained permissions applied at the organization level. This allows image permissions to be assigned to teams and individuals (in addition to repo-based permissions).

The default `pull` command shown by GitHub is incorrect and will pull the container's signature metadata (.sig). To pull an image, use the appropriate tag instead. This will be `main` (latest manual build), `latest` (latest release build), or a specific release version.

## Local Testing
To pull an image and use it in a local environment, you will need to make sure you have installed Docker (or Docker Desktop).

The steps to use the built image on a local machine:

1. Fork the repository.
2. Run the [workflow](.github/workflows/publish-image.yml) to publish the image. To do this, [create a new release](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository#creating-a-release). Typically releases use the format `v#.#` or `v#.#.#` and will have a matching tag. Alternatively, you can manually invoke the workflow to create a SHA-versioned image.
3. On the machine that will need to use the image, run the command `docker login ghcr.io` to authenticate with the registry.
   - Provide your GitHub user name 
   - For the password, create a [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with *read:packages* permissions.
4. Start the container with the following command `docker run -it -p 80:80 --name ghcr-demo --rm ghcr.io/{owner}/{repo}:latest`. Remember to replace `{owner}` and `{repo}` with appropriate values. For example. `ghcr.io/kenmuse/gh-actions-and-ghcr:latest`

## Dev Containers
This repository supports [GitHub Codespaces](https://github.com/features/codespaces) and VS Code development containers. This creates a standalone environment for viewing and editing the files.

## Application
The application used for this sample is a basic Python 3 Flask web application that displays a 'Hello world' message. The Dockerfile will create an image that serves the web pages on Port 80, making this image compatible with most standalone container services.

## Labels
The build process automatically extracts a number of labels:

```
org.opencontainers.image.title=gh-actions-and-ghcr
org.opencontainers.image.description=Sample code to demonstrate integrating GitHub Actions and GitHub ContainerRegistry
org.opencontainers.image.url=https://github.com/kenmuse/gh-actions-and-ghcr
org.opencontainers.image.source=https://github.com/kenmuse/gh-actions-and-ghcr
org.opencontainers.image.version=main
org.opencontainers.image.created=2022-05-26T20:27:30.525Z
org.opencontainers.image.revision=ebf49487225be8867bebe8d102ad6e7588ed7368
org.opencontainers.image.licenses=MIT
```

These can be overridden in the Dockerfile, as shown [on lines 11-12](Dockerfile#3).

## Cleanup
While not shown in this workflow, it is possible to create a job that will also cleanup older images automatically using a third-party action.
For this to work correctly, you will need the *unprefixed* image name (i.e., no owner). This is available from the event context as `github.event.repository.name`. This can be especially important if you're continuously building since GHCR does not have a retention policy for images. To cleanup all but the latest unversioned images (anything without a "v" prefix), you can use a job like the one below.

> **Note**  
> The `GITHUB_TOKEN` does not have permission to delete images. You must provide a personal access token with
> `read:packages` and `delete:packages` permissions to be able to list the images and delete them.
> See https://github.com/snok/container-retention-policy for more details about this action.

```yaml
clean-ghcr:
  name: Delete older images
  runs-on: ubuntu-latest
  steps:
    - name: Delete unversioned images
      uses: snok/container-retention-policy@v1
      with:
        image-names: ${{ github.event.repository.name }}
        cut-off: Two weeks ago UTC
        keep-at-least: 1
        account-type: personal
        skip-tags: v*
        token: ${{ secrets.DELETE_TOKEN }}
```
