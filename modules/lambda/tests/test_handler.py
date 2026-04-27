import json
import unittest
from unittest.mock import MagicMock, patch
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

class TestHandler(unittest.TestCase):

    def _make_context(self):
        ctx = MagicMock()
        ctx.aws_request_id = "test-request-id"
        ctx.function_name = "secop2-dev-integrations"
        return ctx

    def _make_event(self, body):
        return {"body": json.dumps(body)}

    @patch.dict(os.environ, {"S3_BUCKET": "test-bucket"})
    @patch("boto3.client")
    def test_post_exitoso(self, mock_boto):
        mock_s3 = MagicMock()
        mock_boto.return_value = mock_s3

        import index
        event = self._make_event({
            "entidad": "Ministerio de Hacienda",
            "modalidad": "licitacion_publica",
            "objeto": "Adquisicion de equipos",
            "valor": 500000000
        })

        response = index.handler(event, self._make_context())
        self.assertEqual(response["statusCode"], 201)

    @patch.dict(os.environ, {"S3_BUCKET": "test-bucket"})
    @patch("boto3.client")
    def test_campos_faltantes(self, mock_boto):
        import index
        event = self._make_event({
            "entidad": "Ministerio de Hacienda"
            # faltan modalidad y objeto
        })

        response = index.handler(event, self._make_context())
        self.assertEqual(response["statusCode"], 400)
        body = json.loads(response["body"])
        self.assertIn("campos", body)

    @patch.dict(os.environ, {"S3_BUCKET": "test-bucket"})
    @patch("boto3.client")
    def test_body_invalido(self, mock_boto):
        import index
        event = {"body": "esto no es json"}

        response = index.handler(event, self._make_context())
        self.assertEqual(response["statusCode"], 400)

    @patch.dict(os.environ, {"S3_BUCKET": "test-bucket"})
    @patch("boto3.client")
    def test_idempotencia_proceso_id(self, mock_boto):
        mock_s3 = MagicMock()
        mock_boto.return_value = mock_s3

        import index
        event = self._make_event({
            "proceso_id": "PROCESO-TEST-001",
            "entidad": "Contraloria General",
            "modalidad": "minima_cuantia",
            "objeto": "Servicios de mantenimiento",
            "valor": 10000000
        })

        response = index.handler(event, self._make_context())
        body = json.loads(response["body"])
        self.assertEqual(body["proceso_id"], "PROCESO-TEST-001")

if __name__ == "__main__":
    unittest.main()