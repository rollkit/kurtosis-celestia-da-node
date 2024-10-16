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
    # TODO: this storage path should be configurable as the node store
    # da_node_service_name = "celestia-{0}-{1}".format(node_type, p2p_network)
    da_node_service_name = "node"
    node_store = "/home/celestia/{0}".format(da_node_service_name)
    plan.store_service_files(
        service_name=da_node_service_name,
        src=node_store,
        name="persisted-data",
    )
