import pathlib
import sys


MODULE_PATH = pathlib.Path(__file__).resolve().parents[1] / "src" / "function_app" / "HttpExample"
sys.path.insert(0, str(MODULE_PATH))

import __init__ as http_example  # noqa: E402


class DummyRequest:
    def __init__(self, params=None, body=None, body_raises=False):
        self.params = params or {}
        self._body = body or {}
        self._body_raises = body_raises

    def get_json(self):
        if self._body_raises:
            raise ValueError("invalid json")
        return self._body


def test_main_returns_named_greeting_from_query():
    req = DummyRequest(params={"name": "CI"})
    res = http_example.main(req)
    assert res.get_body().decode() == "Hello, CI."


def test_main_returns_named_greeting_from_body():
    req = DummyRequest(body={"name": "BodyName"})
    res = http_example.main(req)
    assert res.get_body().decode() == "Hello, BodyName."


def test_main_returns_default_message_when_name_missing():
    req = DummyRequest(body_raises=True)
    res = http_example.main(req)
    body = res.get_body().decode()
    assert "HTTP-triggered function executed successfully" in body
