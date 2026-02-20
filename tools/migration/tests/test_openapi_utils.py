"""
test_openapi_utils.py

Unit tests for openapi_utils.py

Run with:
    python3 -m pytest tools/migration/tests/test_openapi_utils.py -v

Or:
    cd tools/migration && python3 -m pytest tests/ -v
"""

import sys
import os
import json
import tempfile
import unittest

# Allow importing openapi_utils from the parent directory
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import openapi_utils as utils


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def make_swagger2_spec(**overrides) -> dict:
    """Return a minimal valid Swagger 2.0 specification."""
    spec = {
        "swagger": "2.0",
        "info": {"title": "Test API", "version": "1.0.0"},
        "host": "api.example.com",
        "basePath": "/v1",
        "schemes": ["https"],
        "paths": {},
    }
    spec.update(overrides)
    return spec


def make_oas3_spec(**overrides) -> dict:
    """Return a minimal valid OpenAPI 3.0 specification."""
    spec = {
        "openapi": "3.0.0",
        "info": {"title": "Test API", "version": "1.0.0"},
        "servers": [{"url": "https://api.example.com/v1"}],
        "paths": {},
    }
    spec.update(overrides)
    return spec


# ---------------------------------------------------------------------------
# Tests: Swagger 2.0 → OpenAPI 3.0 conversion
# ---------------------------------------------------------------------------

class TestConvertSwaggerToOpenapi3(unittest.TestCase):

    def test_version_field_updated(self):
        """Converted spec must have openapi: 3.0.0 and no swagger field."""
        spec = make_swagger2_spec()
        result = utils.convert_swagger_to_openapi3(spec)
        self.assertEqual(result["openapi"], "3.0.0")
        self.assertNotIn("swagger", result)

    def test_info_preserved(self):
        """info block must be carried over unchanged."""
        spec = make_swagger2_spec()
        spec["info"]["description"] = "My API description"
        result = utils.convert_swagger_to_openapi3(spec)
        self.assertEqual(result["info"]["title"], "Test API")
        self.assertEqual(result["info"]["version"], "1.0.0")
        self.assertEqual(result["info"]["description"], "My API description")

    def test_servers_built_from_host_basepath_schemes(self):
        """servers[] URL should be built from host + basePath + scheme."""
        spec = make_swagger2_spec(
            host="api.example.com",
            basePath="/v2",
            schemes=["https", "http"],
        )
        result = utils.convert_swagger_to_openapi3(spec)
        urls = [s["url"] for s in result["servers"]]
        self.assertIn("https://api.example.com/v2", urls)
        self.assertIn("http://api.example.com/v2", urls)

    def test_servers_fallback_basepath_only(self):
        """When no host is present but basePath is, create a relative server."""
        spec = make_swagger2_spec(basePath="/api", schemes=["https"])
        del spec["host"]
        result = utils.convert_swagger_to_openapi3(spec)
        self.assertEqual(result["servers"][0]["url"], "/api")

    def test_definitions_moved_to_components_schemas(self):
        """definitions should become components/schemas."""
        spec = make_swagger2_spec()
        spec["definitions"] = {
            "User": {"type": "object", "properties": {"id": {"type": "integer"}}}
        }
        result = utils.convert_swagger_to_openapi3(spec)
        self.assertIn("schemas", result["components"])
        self.assertIn("User", result["components"]["schemas"])

    def test_security_definitions_converted(self):
        """securityDefinitions should become components/securitySchemes."""
        spec = make_swagger2_spec()
        spec["securityDefinitions"] = {
            "ApiKeyAuth": {"type": "apiKey", "in": "header", "name": "X-API-Key"},
            "BasicAuth": {"type": "basic"},
            "OAuth2": {
                "type": "oauth2",
                "flow": "implicit",
                "authorizationUrl": "https://auth.example.com/oauth/authorize",
                "scopes": {"read:api": "Read access"},
            },
        }
        result = utils.convert_swagger_to_openapi3(spec)
        schemes = result["components"]["securitySchemes"]

        self.assertEqual(schemes["ApiKeyAuth"]["type"], "apiKey")
        self.assertEqual(schemes["ApiKeyAuth"]["in"], "header")

        self.assertEqual(schemes["BasicAuth"]["type"], "http")
        self.assertEqual(schemes["BasicAuth"]["scheme"], "basic")

        self.assertEqual(schemes["OAuth2"]["type"], "oauth2")
        self.assertIn("implicit", schemes["OAuth2"]["flows"])
        self.assertIn("read:api", schemes["OAuth2"]["flows"]["implicit"]["scopes"])

    def test_ref_paths_rewritten_in_paths(self):
        """$ref paths pointing to #/definitions/ must be rewritten."""
        spec = make_swagger2_spec()
        spec["definitions"] = {
            "User": {"type": "object", "properties": {"id": {"type": "integer"}}}
        }
        spec["paths"]["/users"] = {
            "get": {
                "operationId": "getUsers",
                "summary": "List users",
                "responses": {
                    "200": {
                        "description": "OK",
                        "schema": {"$ref": "#/definitions/User"},
                    }
                },
            }
        }
        result = utils.convert_swagger_to_openapi3(spec)
        response_content = result["paths"]["/users"]["get"]["responses"]["200"]["content"]
        schema_ref = list(response_content.values())[0]["schema"]["$ref"]
        self.assertEqual(schema_ref, "#/components/schemas/User")

    def test_body_parameter_becomes_request_body(self):
        """A body parameter should be converted to requestBody."""
        spec = make_swagger2_spec()
        spec["paths"]["/users"] = {
            "post": {
                "operationId": "createUser",
                "summary": "Create user",
                "consumes": ["application/json"],
                "parameters": [
                    {
                        "in": "body",
                        "name": "body",
                        "required": True,
                        "schema": {"$ref": "#/definitions/User"},
                    }
                ],
                "responses": {"201": {"description": "Created"}},
            }
        }
        result = utils.convert_swagger_to_openapi3(spec)
        op = result["paths"]["/users"]["post"]
        self.assertIn("requestBody", op)
        self.assertNotIn("body", [p.get("in") for p in op.get("parameters", [])])
        self.assertIn("application/json", op["requestBody"]["content"])

    def test_form_data_parameters_become_request_body(self):
        """formData parameters should become a requestBody with object schema."""
        spec = make_swagger2_spec()
        spec["paths"]["/upload"] = {
            "post": {
                "operationId": "uploadFile",
                "summary": "Upload",
                "parameters": [
                    {"in": "formData", "name": "name", "type": "string", "required": True},
                    {"in": "formData", "name": "file", "type": "file"},
                ],
                "responses": {"200": {"description": "OK"}},
            }
        }
        result = utils.convert_swagger_to_openapi3(spec)
        op = result["paths"]["/upload"]["post"]
        self.assertIn("requestBody", op)
        content_type = list(op["requestBody"]["content"].keys())[0]
        self.assertEqual(content_type, "multipart/form-data")
        schema = op["requestBody"]["content"]["multipart/form-data"]["schema"]
        self.assertIn("name", schema["properties"])

    def test_already_oas3_passthrough(self):
        """A spec already at OpenAPI 3.x should be returned without modification."""
        spec = make_oas3_spec()
        spec["paths"]["/users"] = {
            "get": {
                "operationId": "listUsers",
                "summary": "List",
                "responses": {"200": {"description": "OK"}},
            }
        }
        result = utils.convert_swagger_to_openapi3(spec)
        self.assertEqual(result["openapi"], "3.0.0")
        self.assertIn("/users", result["paths"])

    def test_unsupported_version_raises(self):
        """A spec with an unrecognised version should raise ValueError."""
        spec = {"info": {"title": "Bad", "version": "1"}, "paths": {}}
        with self.assertRaises(ValueError):
            utils.convert_swagger_to_openapi3(spec)

    def test_oauth2_flow_mapping(self):
        """OAuth2 flow names must be mapped to their OpenAPI 3.0 equivalents."""
        flow_tests = [
            ("implicit", "implicit"),
            ("password", "password"),
            ("application", "clientCredentials"),
            ("accessCode", "authorizationCode"),
        ]
        for swagger_flow, expected_flow in flow_tests:
            with self.subTest(swagger_flow=swagger_flow):
                spec = make_swagger2_spec()
                spec["securityDefinitions"] = {
                    "MyOAuth": {
                        "type": "oauth2",
                        "flow": swagger_flow,
                        "authorizationUrl": "https://auth.example.com/auth",
                        "tokenUrl": "https://auth.example.com/token",
                        "scopes": {},
                    }
                }
                result = utils.convert_swagger_to_openapi3(spec)
                flows = result["components"]["securitySchemes"]["MyOAuth"]["flows"]
                self.assertIn(expected_flow, flows)


# ---------------------------------------------------------------------------
# Tests: operationId generation
# ---------------------------------------------------------------------------

class TestGenerateOperationId(unittest.TestCase):

    def test_simple_get(self):
        self.assertEqual(utils.generate_operation_id("get", "/users"), "getUsers")

    def test_simple_post(self):
        self.assertEqual(utils.generate_operation_id("post", "/users"), "postUsers")

    def test_path_with_id_parameter(self):
        self.assertEqual(
            utils.generate_operation_id("get", "/users/{userId}"),
            "getUsersByUserId",
        )

    def test_nested_path(self):
        self.assertEqual(
            utils.generate_operation_id("get", "/users/{userId}/orders"),
            "getUsersByUserIdOrders",
        )

    def test_delete_with_parameter(self):
        self.assertEqual(
            utils.generate_operation_id("delete", "/users/{id}"),
            "deleteUsersById",
        )

    def test_root_path(self):
        self.assertEqual(utils.generate_operation_id("get", "/"), "getRoot")

    def test_kebab_case_segment(self):
        self.assertEqual(
            utils.generate_operation_id("get", "/api-keys"),
            "getApiKeys",
        )

    def test_uppercase_method(self):
        """Method is normalised to lowercase."""
        self.assertEqual(
            utils.generate_operation_id("GET", "/pets"),
            "getPets",
        )


class TestEnsureOperationIds(unittest.TestCase):

    def test_missing_ids_are_generated(self):
        """Operations without operationId should have one added."""
        spec = make_oas3_spec()
        spec["paths"]["/users"] = {
            "get": {"summary": "List users", "responses": {"200": {"description": "OK"}}}
        }
        result = utils.ensure_operation_ids(spec)
        self.assertEqual(result["paths"]["/users"]["get"]["operationId"], "getUsers")

    def test_existing_ids_are_preserved(self):
        """Existing operationIds must not be changed."""
        spec = make_oas3_spec()
        spec["paths"]["/users"] = {
            "get": {
                "operationId": "myCustomId",
                "summary": "List users",
                "responses": {"200": {"description": "OK"}},
            }
        }
        result = utils.ensure_operation_ids(spec)
        self.assertEqual(result["paths"]["/users"]["get"]["operationId"], "myCustomId")

    def test_duplicate_generated_ids_are_disambiguated(self):
        """If two paths generate the same base ID, add a numeric suffix."""
        spec = make_oas3_spec()
        # Both /users and /users (different methods won't clash here, but
        # same method on paths that happen to collide would)
        # Create a contrived case by using identical-resolving paths
        spec["paths"]["/user-s"] = {
            "get": {"summary": "A", "responses": {"200": {"description": "OK"}}}
        }
        spec["paths"]["/userS"] = {
            "get": {"summary": "B", "responses": {"200": {"description": "OK"}}}
        }
        result = utils.ensure_operation_ids(spec)
        ids = [
            result["paths"]["/user-s"]["get"]["operationId"],
            result["paths"]["/userS"]["get"]["operationId"],
        ]
        # Both should have operationIds, and they must be unique
        self.assertEqual(len(set(ids)), 2)

    def test_multiple_methods_on_same_path(self):
        """Each method on the same path should get a distinct operationId."""
        spec = make_oas3_spec()
        spec["paths"]["/items"] = {
            "get": {"summary": "List", "responses": {"200": {"description": "OK"}}},
            "post": {"summary": "Create", "responses": {"201": {"description": "Created"}}},
        }
        result = utils.ensure_operation_ids(spec)
        get_id = result["paths"]["/items"]["get"]["operationId"]
        post_id = result["paths"]["/items"]["post"]["operationId"]
        self.assertEqual(get_id, "getItems")
        self.assertEqual(post_id, "postItems")
        self.assertNotEqual(get_id, post_id)

    def test_empty_paths_no_error(self):
        """Spec with no paths should not raise."""
        spec = make_oas3_spec()
        result = utils.ensure_operation_ids(spec)
        self.assertEqual(result["paths"], {})


# ---------------------------------------------------------------------------
# Tests: APIM requirement validation
# ---------------------------------------------------------------------------

class TestValidateApimRequirements(unittest.TestCase):

    def test_valid_oas3_spec_has_no_errors(self):
        """A well-formed OAS3 spec should produce no validation errors."""
        spec = make_oas3_spec()
        errors = utils.validate_apim_requirements(spec)
        self.assertEqual(errors, [])

    def test_missing_title_is_an_error(self):
        spec = make_oas3_spec()
        del spec["info"]["title"]
        errors = utils.validate_apim_requirements(spec)
        self.assertTrue(any("title" in e for e in errors))

    def test_missing_version_is_an_error(self):
        spec = make_oas3_spec()
        del spec["info"]["version"]
        errors = utils.validate_apim_requirements(spec)
        self.assertTrue(any("version" in e for e in errors))

    def test_missing_servers_is_a_warning(self):
        spec = make_oas3_spec()
        del spec["servers"]
        errors = utils.validate_apim_requirements(spec)
        self.assertTrue(any("servers" in e or "server" in e.lower() for e in errors))

    def test_server_without_url_is_an_error(self):
        spec = make_oas3_spec()
        spec["servers"] = [{"description": "No URL here"}]
        errors = utils.validate_apim_requirements(spec)
        self.assertTrue(any("url" in e for e in errors))

    def test_unsupported_security_scheme_type(self):
        spec = make_oas3_spec()
        spec["components"] = {
            "securitySchemes": {
                "weirdAuth": {"type": "mutualTLS"}  # not yet in APIM
            }
        }
        errors = utils.validate_apim_requirements(spec)
        self.assertTrue(any("weirdAuth" in e for e in errors))

    def test_supported_security_schemes_no_warning(self):
        spec = make_oas3_spec()
        spec["components"] = {
            "securitySchemes": {
                "ApiKey": {"type": "apiKey", "in": "header", "name": "X-API-Key"},
                "OAuth2": {
                    "type": "oauth2",
                    "flows": {
                        "clientCredentials": {
                            "tokenUrl": "https://auth.example.com/token",
                            "scopes": {},
                        }
                    },
                },
            }
        }
        errors = utils.validate_apim_requirements(spec)
        self.assertEqual(errors, [])

    def test_duplicate_operation_ids_are_errors(self):
        spec = make_oas3_spec()
        spec["paths"]["/a"] = {
            "get": {
                "operationId": "duplicateId",
                "responses": {"200": {"description": "OK"}},
            }
        }
        spec["paths"]["/b"] = {
            "get": {
                "operationId": "duplicateId",
                "responses": {"200": {"description": "OK"}},
            }
        }
        errors = utils.validate_apim_requirements(spec)
        self.assertTrue(any("duplicateId" in e for e in errors))

    def test_valid_swagger2_spec_has_no_errors(self):
        """A well-formed Swagger 2.0 spec should also validate cleanly."""
        spec = make_swagger2_spec()
        errors = utils.validate_apim_requirements(spec)
        self.assertEqual(errors, [])

    def test_swagger2_missing_host_and_basepath_is_warning(self):
        spec = make_swagger2_spec()
        del spec["host"]
        del spec["basePath"]
        errors = utils.validate_apim_requirements(spec)
        self.assertTrue(any("host" in e.lower() or "basepath" in e.lower() for e in errors))


# ---------------------------------------------------------------------------
# Tests: Vendor extension removal
# ---------------------------------------------------------------------------

class TestCleanExtensions(unittest.TestCase):

    def test_clean_aws_extensions(self):
        """x-amazon-* keys should be removed from all levels."""
        spec = {
            "openapi": "3.0.0",
            "info": {"title": "T", "version": "1"},
            "x-amazon-apigateway-policy": "...",
            "paths": {
                "/users": {
                    "get": {
                        "operationId": "getUsers",
                        "x-amazon-apigateway-integration": {"type": "aws_proxy"},
                        "responses": {},
                    }
                }
            },
        }
        result = utils.clean_aws_extensions(spec)
        self.assertNotIn("x-amazon-apigateway-policy", result)
        self.assertNotIn(
            "x-amazon-apigateway-integration",
            result["paths"]["/users"]["get"],
        )
        self.assertIn("operationId", result["paths"]["/users"]["get"])

    def test_clean_google_extensions(self):
        """x-google-* keys should be removed from all levels."""
        spec = {
            "swagger": "2.0",
            "info": {"title": "T", "version": "1"},
            "x-google-backend": {"address": "https://backend.example.com"},
            "paths": {
                "/items": {
                    "get": {
                        "operationId": "listItems",
                        "x-google-quota": {"metricCosts": {}},
                        "responses": {},
                    }
                }
            },
        }
        result = utils.clean_google_extensions(spec)
        self.assertNotIn("x-google-backend", result)
        self.assertNotIn("x-google-quota", result["paths"]["/items"]["get"])
        self.assertIn("operationId", result["paths"]["/items"]["get"])

    def test_non_vendor_extensions_preserved(self):
        """Custom x- extensions that are not vendor-specific must be kept."""
        spec = {
            "openapi": "3.0.0",
            "info": {"title": "T", "version": "1"},
            "x-custom-extension": "keep-me",
            "paths": {},
        }
        result = utils.clean_aws_extensions(spec)
        self.assertIn("x-custom-extension", result)

    def test_nested_lists_are_processed(self):
        """Extensions inside arrays should also be cleaned."""
        spec = {
            "openapi": "3.0.0",
            "info": {"title": "T", "version": "1"},
            "tags": [
                {"name": "users", "x-amazon-tag": "should-be-removed"},
            ],
            "paths": {},
        }
        result = utils.clean_aws_extensions(spec)
        self.assertNotIn("x-amazon-tag", result["tags"][0])
        self.assertIn("name", result["tags"][0])


# ---------------------------------------------------------------------------
# Tests: File I/O helpers
# ---------------------------------------------------------------------------

class TestFileIO(unittest.TestCase):

    def test_load_json_spec(self):
        spec_data = {"openapi": "3.0.0", "info": {"title": "T", "version": "1"}, "paths": {}}
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            json.dump(spec_data, f)
            tmp_path = f.name
        try:
            result = utils.load_spec(tmp_path)
            self.assertEqual(result["openapi"], "3.0.0")
        finally:
            os.unlink(tmp_path)

    def test_load_nonexistent_file_exits(self):
        with self.assertRaises(SystemExit):
            utils.load_spec("/nonexistent/path/spec.yaml")

    def test_save_json_spec(self):
        spec = {"openapi": "3.0.0", "info": {"title": "T", "version": "1"}, "paths": {}}
        with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as f:
            tmp_path = f.name
        try:
            utils.save_spec(spec, tmp_path)
            with open(tmp_path) as f:
                loaded = json.load(f)
            self.assertEqual(loaded["openapi"], "3.0.0")
        finally:
            os.unlink(tmp_path)

    def test_load_yaml_spec(self):
        import yaml as _yaml
        spec_data = {"openapi": "3.0.0", "info": {"title": "T", "version": "1"}, "paths": {}}
        with tempfile.NamedTemporaryFile(mode="w", suffix=".yaml", delete=False) as f:
            _yaml.dump(spec_data, f)
            tmp_path = f.name
        try:
            result = utils.load_spec(tmp_path)
            self.assertEqual(result["openapi"], "3.0.0")
        finally:
            os.unlink(tmp_path)

    def test_save_yaml_spec(self):
        import yaml as _yaml
        spec = {"openapi": "3.0.0", "info": {"title": "T", "version": "1"}, "paths": {}}
        with tempfile.NamedTemporaryFile(suffix=".yaml", delete=False) as f:
            tmp_path = f.name
        try:
            utils.save_spec(spec, tmp_path)
            with open(tmp_path) as f:
                loaded = _yaml.safe_load(f)
            self.assertEqual(loaded["openapi"], "3.0.0")
        finally:
            os.unlink(tmp_path)


# ---------------------------------------------------------------------------
# Integration-style test: end-to-end conversion
# ---------------------------------------------------------------------------

class TestEndToEndConversion(unittest.TestCase):

    def test_full_swagger2_to_oas3_pipeline(self):
        """
        A Swagger 2.0 spec with AWS extensions, missing operationIds, and a
        body parameter should come out the other end as a clean OAS3 spec.
        """
        swagger_spec = {
            "swagger": "2.0",
            "info": {"title": "Petstore", "version": "1.0"},
            "host": "petstore.example.com",
            "basePath": "/v2",
            "schemes": ["https"],
            "consumes": ["application/json"],
            "produces": ["application/json"],
            "securityDefinitions": {
                "api_key": {"type": "apiKey", "name": "api_key", "in": "header"}
            },
            "definitions": {
                "Pet": {
                    "type": "object",
                    "properties": {
                        "id": {"type": "integer"},
                        "name": {"type": "string"},
                    },
                }
            },
            "paths": {
                "/pets": {
                    "get": {
                        "summary": "List pets",
                        # operationId intentionally missing
                        "responses": {
                            "200": {
                                "description": "A list of pets",
                                "schema": {
                                    "type": "array",
                                    "items": {"$ref": "#/definitions/Pet"},
                                },
                            }
                        },
                    },
                    "post": {
                        "summary": "Create a pet",
                        "parameters": [
                            {
                                "in": "body",
                                "name": "body",
                                "required": True,
                                "schema": {"$ref": "#/definitions/Pet"},
                            }
                        ],
                        "responses": {"201": {"description": "Created"}},
                    },
                },
                "/pets/{petId}": {
                    "get": {
                        "summary": "Get a pet",
                        "x-amazon-apigateway-integration": {"type": "aws_proxy"},
                        "parameters": [
                            {
                                "in": "path",
                                "name": "petId",
                                "required": True,
                                "type": "integer",
                            }
                        ],
                        "responses": {
                            "200": {
                                "description": "A pet",
                                "schema": {"$ref": "#/definitions/Pet"},
                            }
                        },
                    }
                },
            },
        }

        # Step 1: Remove AWS extensions
        spec = utils.clean_aws_extensions(swagger_spec)
        self.assertNotIn(
            "x-amazon-apigateway-integration",
            spec["paths"]["/pets/{petId}"]["get"],
        )

        # Step 2: Convert to OAS3
        spec = utils.convert_swagger_to_openapi3(spec)
        self.assertEqual(spec["openapi"], "3.0.0")
        self.assertEqual(spec["servers"][0]["url"], "https://petstore.example.com/v2")
        self.assertIn("schemas", spec["components"])
        self.assertIn("securitySchemes", spec["components"])
        self.assertIn("api_key", spec["components"]["securitySchemes"])

        # Step 3: Ensure operationIds
        spec = utils.ensure_operation_ids(spec)
        self.assertIn("operationId", spec["paths"]["/pets"]["get"])
        self.assertEqual(spec["paths"]["/pets"]["get"]["operationId"], "getPets")
        self.assertIn("operationId", spec["paths"]["/pets"]["post"])

        # Step 4: Validate
        errors = utils.validate_apim_requirements(spec)
        # Should have no ERRORs (warnings about missing examples are OK)
        error_msgs = [e for e in errors if e.startswith("ERROR")]
        self.assertEqual(error_msgs, [], f"Unexpected errors: {error_msgs}")

        # Verify $ref rewriting
        list_response = spec["paths"]["/pets"]["get"]["responses"]["200"]
        content_schema = list(list_response["content"].values())[0]["schema"]
        self.assertEqual(
            content_schema["items"]["$ref"], "#/components/schemas/Pet"
        )

        # Verify requestBody
        post_op = spec["paths"]["/pets"]["post"]
        self.assertIn("requestBody", post_op)
        self.assertIn("application/json", post_op["requestBody"]["content"])
        self.assertEqual(
            post_op["requestBody"]["content"]["application/json"]["schema"]["$ref"],
            "#/components/schemas/Pet",
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
