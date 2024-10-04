faucet = import_module("./lib/faucet/faucet.star")
pyro = import_module("./lib/pyro/pyro.star")

NETWORK = "arabica"

DEFAULT_CONFIG = {
    "arabica": {
        # "da_image": "ghcr.io/celestiaorg/celestia-node:v0.18.1-arabica",
        "da_image": "celestia-node:v0.18.1-arabica-fix",  # custom image until PR is merged
        "core_ip": "validator-1.celestia-arabica-11.com",
    },
    "mocha": {
        "da_image": "ghcr.io/celestiaorg/celestia-node:v0.18.1-mocha",
        "core_ip": "full.consensus.mocha-4.celestia-mocha.com",
    },
}


# NOTE:
# - Commneted out inputs are arguments for the node that could be added later as needed
# - This is a simple implementation for use with testnets. Additional features and testing might be required to use on mainnet.
def run(
    plan,
    node_type="light",
    da_image=DEFAULT_CONFIG[NETWORK]["da_image"],
    # core_grpc_port="9090",
    core_ip=DEFAULT_CONFIG[NETWORK]["core_ip"],
    # core_rpc_port="26657",
    # gateway=False,
    # gateway_addr="0.0.0.0",
    # gateway_port="26659",
    # headers_trusted_hash="8932B706216780C2660A9343A7F2B40A549BFA141D6B1CCA1E676306C35B25EA",
    # headers_trusted_peers="",
    # daser_sample_from=1264456,
    # keyring_accname="",
    # keyring_backend="test",
    # log_level="INFO",
    # log_level_module="",
    # metrics=False,
    # metrics_endpoint="0.0.0.0:4318",
    # metrics_tls=True,
    # node_config="",
    # p2p_metrics=False,
    # p2p_mutual="",
    p2p_network=NETWORK,
    # pprof=False,
    # enable_pyroscope=True,
    # pyroscope_tracing=True,
    # rpc_addr="0.0.0.0",
    # rpc_port="26658",
    # tracing=False,
    # tracing_endpoint="0.0.0.0:4318",
    # tracing_tls=True,
):
    # pyroscope_endpoint = "http://0.0.0.0:4040"  # set this as default endpoint
    # if enable_pyroscope:
    #     # TODO: configure pyro with DA node, grafana maybe?
    #     pyro_service = pyro.launch(plan)
    #     pyroscope_endpoint = "http://{0}:{1}".format(
    #         pyro_service.ip_address, pyro_service.ports["pyroscope"].number
    #     )

    # # create node store
    # results = plan.run_sh(
    #     # run="whoami && celestia light init --p2p.network {0} --node.store=/home/celestia/.celestia-light-node-4 --pyroscope {1} --pyroscope.endpoint {2} --tracing {3}".format(p2p_network, enable_pyroscope, pyroscope_endpoint, tracing),
    #     run="whoami && celestia light init --p2p.network {0} --node.store=/home/celestia/.celestia-light-node-4".format(
    #         p2p_network, enable_pyroscope, pyroscope_endpoint, tracing
    #     ),
    #     image=da_image,
    #     store=[
    #         StoreSpec(
    #             name="keystore", src="/home/celestia/.celestia-light-node-4/keys/*"
    #         ),
    #     ],
    #     description="Generate keystore for DA node",
    # )
    # keystore_artifact = results.files_artifacts[0]
    # plan.print(results.output)

    # node_store = "/Users/matt/Code/MSevey/celestia-da-node-package/node_store"

    # Add celestia da node from docker image
    da_node_service_name = "celestia-{0}-{1}".format(node_type, p2p_network)
    da_node = plan.add_service(
        name=da_node_service_name,
        config=ServiceConfig(
            image=da_image,
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
            env_vars={
                "NODE_TYPE": node_type,
                "P2P_NETWORK": p2p_network,
            },
            cmd=[
                "celestia",
                node_type,
                "start",
                "--core.ip",
                core_ip,
                "--p2p.network",
                p2p_network,
            ],
            # files={
            #     #     # "/home/celestia/config.toml": "config.toml",
            #     "/Users/matt/Code/MSevey/celestia-da-node-package": Directory(
            #         persistent_key="keys-directory"
            #     ),
            #     #     "/home/celestia/data": Directory(persistent_key="data-directory"),
            # }
            # files={
            #     "/home/celestia/.celestia-light-mocha-4/": da_node_config_file,
            #     "/home/celestia/.celestia-light-mocha-4/keys": Directory(
            #         artifact_names=[keystore_artifact],
            #     ),
            #     "/home/celestia/.celestia-light-mocha-4/data": Directory(
            #         persistent_key="data-directory"
            #     ),
            # },
            # entrypoint=[
            #     "bash",
            #     "-c",
            #     # "cat /home/celestia/.celestia-light-mocha-4/config.toml && celestia light start --core.ip {0} --p2p.network {1} --node.store=/home/celestia/.celestia-light-mocha-4 --rpc.skip-auth".format(p2p_network),
            #     # "celestia light start --p2p.network {0} --node.store=/home/celestia/.celestia-light-mocha-4 --node.config=/home/celestia/.celestia-light-mocha-4 --rpc.skip-auth".format(p2p_network),
            #     "cat /home/celestia/.celestia-light-mocha-4/config.toml && celestia light start --p2p.network {0} --node.config=/home/celestia/.celestia-light-mocha-4/config.toml --node.store=/home/celestia/.celestia-light-mocha-4 --rpc.skip-auth".format(
            #         p2p_network
            #     ),
            # ],
            # user=User(uid=0),
        ),
    )

    # Get node values to return
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

    return (
        "http://{0}:{1}".format(da_node.ip_address, da_node.ports["rpc"].number),
        auth_token,
        address,
    )
