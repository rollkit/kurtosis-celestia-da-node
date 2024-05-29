
def run(
    plan,
    da_image="ghcr.io/celestiaorg/celestia-node:v0.13.6",
    core_grpc_port="9090",
    core_ip="full.consensus.mocha-4.celestia-mocha.com",
    core_rpc_port="26657",
    gateway=False,
    gateway_addr="localhost",
    gateway_port="26659",
    headers_trusted_hash="8932B706216780C2660A9343A7F2B40A549BFA141D6B1CCA1E676306C35B25EA",
    headers_trusted_peers="",
    daser_sample_from=1264456,
    keyring_accname="",
    keyring_backend="test",
    log_level="INFO",
    log_level_module="",
    metrics= False,
    metrics_endpoint="localhost:4318",
    metrics_tls=True,
    node_config="",
    p2p_metrics=False,
    p2p_mutual="",
    p2p_network="mocha",
    pprof=False,
    pyroscope=False,
    pyroscope_endpoint="http://localhost:4040",
    pyroscope_tracing=False,
    rpc_addr="0.0.0.0",
    rpc_port="26658",
    tracing=False,
    tracing_endpoint="localhost:4318",
    tracing_tls=True
    ):
    # create node store
    results = plan.run_sh(
        run="whoami && celestia light init --p2p.network {0} --node.store=/home/celestia/.celestia-light-node-4".format(p2p_network),
        image=da_image,
        store=[
            StoreSpec(name="keystore", src="/home/celestia/.celestia-light-node-4/keys/*"),
        ],
    )
    plan.print(results.files_artifacts)

    # create node config based on provided args
    config_file_template = read_file("./configs/config.toml.tmpl")
    da_node_config_file = plan.render_templates(
        name="light-node-configuration",
        config={
            "config.toml": struct(
                template=config_file_template,
                data={
                    "CORE_IP": core_ip,
                    "CORE_RPC_PORT": core_rpc_port,
                    "CORE_GRPC_PORT": core_grpc_port,
                    "RPC_ADDRESS": rpc_addr,
                    "RPC_PORT": rpc_port,
                    "TRUSTED_HASH": headers_trusted_hash,
                    "SAMPLE_FROM": daser_sample_from,
                }
            ),
        }
    )

    plan.add_service(
    name = "celestia-light",
    config = ServiceConfig(
        image=da_image,
        ports = {
            "rpc": PortSpec(
                    number = 26658, 
                    transport_protocol = "TCP",
                    application_protocol = "http",
            ),
        },
        # create public port so that 26658 is exposed on machine and available for peering
        public_ports = {
            "rpc": PortSpec(
                    number = 26658, 
                    transport_protocol = "TCP",
                    application_protocol = "http",
            ),
        },
        files={
            "/home/celestia/.celestia-light-mocha-4/": da_node_config_file,
            "/home/celestia/.celestia-light-mocha-4/keys": Directory(
                artifact_names=[results.files_artifacts[0]],
            ),
            "/home/celestia/.celestia-light-mocha-4/data": Directory(
                persistent_key="data-directory"
            ),
        },
        entrypoint=[
            "bash",
            "-c",
            "cat /home/celestia/.celestia-light-mocha-4/config.toml && celestia light start --p2p.network {0} --node.store=/home/celestia/.celestia-light-mocha-4".format(p2p_network),
        ],
        user = User(uid=0),
    ),
)

