def launch(plan):
    # TODO: figure out how to run this faucet while hiding the master key, I could embed the address and master key into the docker image
    faucet_config = plan.upload_files(src="./faucet_config.yml", name="faucet-config")

    plan.add_service(
        name="faucet",
        config=ServiceConfig(
            image="tedim52/faucet:latest",
            ports={
                "api": PortSpec(
                    number=8080,
                    transport_protocol="TCP",
                    application_protocol="http",
                ),
                # "server": PortSpec(
                #     number=8080,
                #     transport_protocol="TCP",
                #     application_protocol="http",
                # )
            },
            files={
                "/config": faucet_config,
            },
            entrypoint=["sh", "-c", "/app/server --config-file /config/faucet_config.yml"],
        ),
    )


def allocate_funds(plan, address=""):
    # retrieve the faucet service
    faucet = plan.get_service(name="faucet")

    # request_body = "{\"address\":\"{0}\",\"chainId\": \"mocha-4\"}".format(address)
    request_body = "{\"address\":" + address + ",\"chainId\":\"mocha-4\"}"
    plan.print(request_body)

    result = plan.request(
        service_name="faucet",
        recipe=PostHttpRequestRecipe(
            port_id="api",
            endpoint="/api/v1/faucet/give_me",
            body=request_body,
            extract={
                "txhash": ".txHash"
            }
        ),
        acceptable_codes=[200],
    )
    # TODO: add verifications and checks for users requesting too many funds too many times etc.
    # 403, code 7 - user has already requested too many funds
    # 200 - everything went well

    plan.print(result)
    


