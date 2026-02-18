import azure.functions as func


def main(req: func.HttpRequest) -> func.HttpResponse:
    name = req.params.get("name")
    if not name:
        try:
            body = req.get_json()
        except ValueError:
            body = {}
        name = body.get("name")

    if name:
        return func.HttpResponse(f"Hello, {name}.")

    return func.HttpResponse(
        "This HTTP-triggered function executed successfully. Pass a name in the query string or request body.",
        status_code=200,
    )
