# EpicChain All-in-One Deployment Guide

## Overview

Welcome to the **EpicChain All-in-One** deployment guide. This guide provides comprehensive instructions on deploying the full suite of EpicChain services on a single physical or virtual server. This single-node deployment is designed primarily for development and testing purposes. For production environments, a multi-node deployment with load balancing and fault tolerance is recommended.

The EpicChain All-in-One setup includes all essential components required for running EpicChain services, enabling you to get up and running quickly with a minimal setup. This guide will walk you through the server requirements, quick start instructions, system management with Systemd, image building, and a simple web application setup.

## Server Requirements

To successfully deploy the EpicChain All-in-One setup, ensure your server meets the following requirements:

- **Docker**: Make sure Docker and Docker Compose are installed on your server. Docker simplifies the deployment process by encapsulating the EpicChain components within containers.
- **Docker Compose**: Required for managing multi-container Docker applications.
- **jq**: A command-line JSON processor used for handling JSON data in shell scripts.
- **curl**: A tool for transferring data with URLs, useful for making HTTP requests to the deployed services.

## Quick Start Guide

### Running the Container

To deploy the EpicChain services, follow these steps:

1. **Clone the Repository**: Download the EpicChain All-in-One setup from the GitHub repository.

   ```sh
   $ git clone https://github.com/epicchainlabs/epicchain-aio.git /opt/epicchain
   ```

2. **Navigate to the Directory**: Move into the directory where the repository has been cloned.

   ```sh
   $ cd /opt/epicchain
   ```

3. **Start the Containers**: Use Docker Compose to bring up the containers.

   ```sh
   $ docker-compose up -d
   ```

4. **Managing Volumes**: Since the storage node container uses persistent storage, it is advisable to clear local volumes if you update the `aio` version. This ensures you’re working with the latest configuration.

   ```sh
   docker volume rm epicchain-aio_data
   docker volume rm epicchain-aio_cache
   ```

5. **Network Map**: Ensure the storage node is correctly registered in the network map. If the output is not as expected, you may need to wait for the new Epoch or manually force the Storage Node registration. Ensure `jq` is installed to process the JSON output.

   ```sh
   $ docker exec -ti aio epicchain-cli netmap snapshot -c /config/cli-cfg-sn.yaml --rpc-endpoint 127.0.0.1:8080
   ```

   Example output:

   ```sh
   Epoch: 45
   Node 1: 02ecaa220948f03171dedcb36f9c3de959be066c0bc289b1032c8702caa376fddb ONLINE /dns4/localhost/tcp/8080
       Continent: Europe
       Country: Germany
       CountryCode: DE
       Deployed: Private
       Location: Falkenstein
       Price: 10
       SubDiv: Sachsen
       SubDivCode: SN
       UN-LOCODE: DE FKS
   ```

6. **Updating Epoch**: If needed, update the EpicChain epoch to reflect changes.

   ```sh
   $ make tick.epoch
   ```

### Systemd Unit Setup

For easier management of your EpicChain Deployment, consider setting it up as a Systemd service. This allows you to control the service like any other system service.

1. **Copy the Unit File**: Place the provided Systemd unit file in the system directory.

   ```sh
   $ sudo cp systemd/epicchain-aio.service /etc/systemd/system/
   ```

2. **Reload Systemd Daemon**: Inform Systemd of the new service file.

   ```sh
   $ sudo systemctl daemon-reload
   ```

3. **Check the Service Status**: Verify that the service is running correctly.

   ```sh
   $ sudo systemctl status epicchain-aio
   ```

### Building Images

If you need to build the Docker image for EpicChain All-in-One, you can do so with the following command:

```sh
$ make image-aio
```

### Setting Up a Simple Web Application

This section outlines how to create a container, store objects, and interact with the EpicChain system using both command-line and REST API methods.

#### Creating a Container

1. **Create a Container**: Using `epicchain-cli`, create a container to store your objects. This operation may take 5-10 seconds as it requires on-chain interactions. For simplicity, use the pre-generated key for the REST Gateway.

   ```sh
   $ epicchain-cli -r localhost:8080 -w rest-gw/wallet.json \
                   --address XqCx9XDJtmWrUwmE7pUEh1iMKETpBD5AEk \
                   container create \
                   --policy "REP 1" --basic-acl public-read --await
   ```

   Example output:

   ```sh
   container ID: GfWw35kHds7gKWmSvW7Zi4U39K7NMLK8EfXBQ5FPJA46
   awaiting...
   container has been persisted on sidechain
   ```

#### Getting Container Information

Retrieve information about the created container using `curl`:

```sh
$ curl http://localhost:8090/v1/containers/GfWw35kHds7gKWmSvW7Zi4U39K7NMLK8EfXBQ5FPJA46 | jq
```

Example output:

```json
{
  "attributes": [
    {
      "key": "Timestamp",
      "value": "1661861767"
    }
  ],
  "basicAcl": "1fbf8cff",
  "cannedAcl": "public-read",
  "containerId": "iafCKZmWu1mahdxxcA6HRYdB5S9BrypYF1qNqpQezpA",
  "containerName": "",
  "ownerId": "XqCx9XDJtmWrUwmE7pUEh1iMKETpBD5AEk",
  "placementPolicy": "REP 1",
  "version": "v2.13"
}
```

#### Putting an Object with `epicchain-cli`

Store an object in the container:

```sh
$ epicchain-cli -r localhost:8080 -w rest-gw/wallet.json \
                --address NPFCqWHfi9ixCJRu7DABRbVfXRbkSEr9Vo \
                object put \
                --cid GfWw35kHds7gKWmSvW7Zi4U39K7NMLK8EfXBQ5FPJA46 \
                --file cat.jpg
```

Example output:

```sh
[cat.jpg] Object successfully stored
  ID: BYwj7QRxubaLSsXxKU2nbBu3ugcyjv1SsAT4zxPXvosB
  CID: GfWw35kHds7gKWmSvW7Zi4U39K7NMLK8EfXBQ5FPJA46
```

#### Putting an Object via REST API

Upload an object using the REST API:

```sh
$ curl -F 'file=@cat.jpg;filename=cat.jpg' \
       http://localhost:8090/v1/upload/ADsJLhJhLQRGMufFin56PCTtPK1BiSxbg6bDmdgSB1Mo
```

Example output:

```json
{
    "object_id": "B4J4L61X6zFcz5fcmZaCJJNZfFFTE6uT4pz7dqP87m6m",
    "container_id": "ADsJLhJhLQRGMufFin56PCTtPK1BiSxbg6bDmdgSB1Mo"
}
```

For detailed information on the REST API supported by EpicChain REST Gateway, refer to its OpenAPI specification available at [http://localhost:8090](http://localhost:8090). For more information, also check out the [epicchain-rest-gw repository](https://github.com/epicchainlabs/epicchain-rest-gw).

#### Getting an Object via Nginx

To retrieve an object through Nginx as a reverse proxy, use the following `curl` command:

```sh
$ curl --head http://localhost:8082/ADsJLhJhLQRGMufFin56PCTtPK1BiSxbg6bDmdgSB1Mo/cat.jpg
```

Example output:

```sh
HTTP/1.1 200 OK
Server: nginx/1.20.1
Date: Wed, 07 Jul 2021 17:10:32 GMT
Content-Type: image/jpeg
Content-Length: 187342
Connection: keep-alive
X-Attribute-FileName: cat.jpg
x-object-id: B4J4L61X6zFcz5fcmZaCJJNZfFFTE6uT4pz7dqP87m6m
x-owner-id: NPFCqWHfi9ixCJRu7DABRbVfXRbkSEr9Vo
x-container-id: ADsJLhJhLQRGMufFin56PCTtPK1BiSxbg6b

DmdgSB1Mo
```

This setup provides a simple yet powerful way to interact with EpicChain's services for development and testing. For a full production deployment, consider using multiple nodes and additional configurations for security, performance, and reliability.

