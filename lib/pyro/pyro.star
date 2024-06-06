
def launch(plan):
    return plan.add_service(
        name="pyroscope",
        config=ServiceConfig(
            image="grafana/pyroscope:latest",
            ports={
                "pyroscope": PortSpec(
                    number=4040,
                    transport_protocol="TCP",
                    application_protocol="http",
                )
            },
        )
    )