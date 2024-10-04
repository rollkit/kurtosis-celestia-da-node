NETWORK = "arabica"
DEFAULT_CONFIG = {
    "arabica": {
        # "da_image": "ghcr.io/celestiaorg/celestia-node:v0.18.1-arabica",
        "da_image": "celestia-node:v0.18.1-arabica-fix",  # custom local image until PR is merged
        "core_ip": "validator-1.celestia-arabica-11.com",
    },
    "mocha": {
        "da_image": "ghcr.io/celestiaorg/celestia-node:v0.18.1-mocha",
        "core_ip": "full.consensus.mocha-4.celestia-mocha.com",
    },
}


def run(
    plan,
    node_type="light",
    da_image=DEFAULT_CONFIG[NETWORK]["da_image"],
    core_ip=DEFAULT_CONFIG[NETWORK]["core_ip"],
    p2p_network=NETWORK,
):
    # Add celestia da node from docker image
    da_node_service_name = "celestia-{0}-{1}".format(node_type, p2p_network)
    da_node = plan.add_service(
        name=da_node_service_name,
        config=ServiceConfig(
            image=da_image,
            # Expose the RPC port
            ports={
                "rpc": PortSpec(
                    number=26658,
                    transport_protocol="TCP",
                    application_protocol="http",
                ),
            },
            public_ports={
                "rpc": PortSpec(
                    number=26658,
                    transport_protocol="TCP",
                    application_protocol="http",
                ),
            },
            # Set environment variables used by the docker image
            env_vars={
                "NODE_TYPE": node_type,
                "P2P_NETWORK": p2p_network,
            },
            # Set the command to start the node
            cmd=[
                "celestia",
                node_type,
                "start",
                "--core.ip",
                core_ip,
                "--p2p.network",
                p2p_network,
            ],
        ),
    )

    # Get the node's address
    get_address_result = plan.exec(
        service_name=da_node_service_name,
        recipe=ExecRecipe(
            command=[
                "sh",
                "-c",
                "celestia state account-address | jq .result",
            ],
        ),
        acceptable_codes=[0],
        description="Getting address of node",
    )
    address = get_address_result["output"]

    # Get the node's auth token
    get_auth_token_result = plan.exec(
        service_name=da_node_service_name,
        recipe=ExecRecipe(
            command=[
                "sh",
                "-c",
                "celestia {0} auth write --p2p.network {1}".format(
                    node_type, p2p_network
                ),
            ],
        ),
        acceptable_codes=[0],
        description="Getting auth token of node",
    )
    auth_token = get_auth_token_result["output"]

    # Get the node's current network height
    get_height_result = plan.exec(
        service_name=da_node_service_name,
        recipe=ExecRecipe(
            command=[
                "sh",
                "-c",
                "celestia header network-head | jq .result.header.height",
            ],
        ),
        acceptable_codes=[0],
        description="Getting network head height of node",
    )
    height = get_height_result["output"]
    return (
        "http://{0}:{1}".format(da_node.ip_address, da_node.ports["rpc"].number),
        auth_token,
        address,
        height,
    )
