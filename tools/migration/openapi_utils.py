#!/usr/bin/env python3
"""
openapi_utils.py

Utility functions for OpenAPI specification processing, designed to support
migration to Azure API Management (APIM).

Features:
  - Convert OpenAPI 2.0 (Swagger) specifications to OpenAPI 3.0
  - Automatically generate operationId for operations that lack one
  - Validate APIM-specific requirements (title, version, server URLs, security schemes)
  - Remove vendor-specific extensions (AWS x-amazon-*, Google x-google-*)

Usage:
  python3 openapi_utils.py <input-file> <output-file> [--source aws|google]

Dependencies:
  - PyYAML (pip install pyyaml)

See also:
  - translate-openapi.sh / translate-openapi.ps1   (Google API Gateway)
  - translate-openapi-aws.sh / translate-openapi-aws.ps1  (AWS API Gateway)
  - ../../docs/migration/aws-to-apim.md
  - ../../docs/migration/google-to-apim.md
"""

import re
import sys
import json
import copy
import argparse
from typing import Any

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False


# ---------------------------------------------------------------------------
# OpenAPI 2.0 (Swagger) → OpenAPI 3.0 conversion
# ---------------------------------------------------------------------------

def _convert_schema_refs(obj: Any) -> Any:
    """Recursively rewrite $ref values from '#/definitions/' to '#/components/schemas/'."""
    if isinstance(obj, dict):
        return {
            k: _convert_schema_refs(v) for k, v in obj.items()
        } if "$ref" not in obj else {
            k: v.replace("#/definitions/", "#/components/schemas/")
               .replace("#/parameters/", "#/components/parameters/")
               .replace("#/responses/", "#/components/responses/")
            if k == "$ref" else _convert_schema_refs(v)
            for k, v in obj.items()
        }
    if isinstance(obj, list):
        return [_convert_schema_refs(item) for item in obj]
    return obj


def _swagger_type_to_content_type(swagger_mime: str) -> str:
    """Map Swagger mime type strings to standard content type strings."""
    mapping = {
        "application/json": "application/json",
        "application/xml": "application/xml",
        "application/x-www-form-urlencoded": "application/x-www-form-urlencoded",
        "multipart/form-data": "multipart/form-data",
        "text/plain": "text/plain",
        "text/html": "text/html",
        "*/*": "*/*",
    }
    return mapping.get(swagger_mime, swagger_mime)


def _convert_security_definitions(sec_defs: dict) -> dict:
    """
    Convert Swagger 2.0 securityDefinitions to OpenAPI 3.0 components/securitySchemes.

    Mapping:
      apiKey  → apiKey (unchanged)
      basic   → http scheme with scheme: basic
      oauth2  → oauth2 with flows object restructured
    """
    schemes = {}
    for name, defn in sec_defs.items():
        defn_type = defn.get("type", "")
        if defn_type == "apiKey":
            schemes[name] = {
                "type": "apiKey",
                "name": defn.get("name", ""),
                "in": defn.get("in", "header"),
            }
            if "description" in defn:
                schemes[name]["description"] = defn["description"]
        elif defn_type == "basic":
            # Swagger 2.0 basic auth → OpenAPI 3.0 http/basic
            schemes[name] = {"type": "http", "scheme": "basic"}
            if "description" in defn:
                schemes[name]["description"] = defn["description"]
        elif defn_type == "oauth2":
            # Swagger 2.0 single-flow oauth2 → OpenAPI 3.0 flows object
            flow_name = defn.get("flow", "implicit")
            # Map old flow names to 3.0 flow names
            flow_map = {
                "implicit": "implicit",
                "password": "password",
                "application": "clientCredentials",
                "accessCode": "authorizationCode",
            }
            oas3_flow = flow_map.get(flow_name, "implicit")
            flow_obj: dict = {}
            if "authorizationUrl" in defn:
                flow_obj["authorizationUrl"] = defn["authorizationUrl"]
            if "tokenUrl" in defn:
                flow_obj["tokenUrl"] = defn["tokenUrl"]
            scopes = defn.get("scopes", {})
            # OpenAPI 3.0 scopes are a dict of {scope: description}
            flow_obj["scopes"] = scopes if isinstance(scopes, dict) else {}
            schemes[name] = {
                "type": "oauth2",
                "flows": {oas3_flow: flow_obj},
            }
            if "description" in defn:
                schemes[name]["description"] = defn["description"]
        else:
            # Unknown type — preserve as-is
            schemes[name] = dict(defn)
    return schemes


def _extract_request_body(parameters: list, global_consumes: list) -> tuple:
    """
    Extract body/formData parameters and return (requestBody, remaining_params).

    Returns (requestBody_dict_or_None, list_of_non_body_params).
    """
    body_params = [p for p in parameters if p.get("in") == "body"]
    form_params = [p for p in parameters if p.get("in") == "formData"]
    other_params = [p for p in parameters if p.get("in") not in ("body", "formData")]

    request_body = None

    if body_params:
        # Take the first body parameter (only one is allowed in Swagger 2.0)
        body_param = body_params[0]
        schema = _convert_schema_refs(body_param.get("schema", {}))
        content_types = global_consumes or ["application/json"]
        content = {}
        for ct in content_types:
            content[_swagger_type_to_content_type(ct)] = {"schema": schema}
        request_body = {
            "required": body_param.get("required", False),
            "content": content,
        }
        if "description" in body_param:
            request_body["description"] = body_param["description"]

    elif form_params:
        # Convert formData parameters into a requestBody with an object schema
        properties = {}
        required_fields = []
        for fp in form_params:
            prop: dict = {}
            if "type" in fp:
                prop["type"] = fp["type"]
            if "description" in fp:
                prop["description"] = fp["description"]
            if "format" in fp:
                prop["format"] = fp["format"]
            properties[fp["name"]] = prop
            if fp.get("required"):
                required_fields.append(fp["name"])

        schema: dict = {"type": "object", "properties": properties}
        if required_fields:
            schema["required"] = required_fields

        # Determine content type from consumes or form parameters
        has_file = any(fp.get("type") == "file" for fp in form_params)
        content_type = "multipart/form-data" if has_file else "application/x-www-form-urlencoded"
        request_body = {
            "required": bool(required_fields),
            "content": {content_type: {"schema": schema}},
        }

    return request_body, other_params


def _convert_responses(swagger_responses: dict, global_produces: list) -> dict:
    """Convert Swagger 2.0 operation responses to OpenAPI 3.0 format."""
    oas3_responses: dict = {}
    produces = global_produces or ["application/json"]

    for status_code, response in swagger_responses.items():
        oas3_response: dict = {}
        if "description" in response:
            oas3_response["description"] = response["description"]
        else:
            oas3_response["description"] = ""  # required field in OAS3

        schema = response.get("schema")
        if schema:
            converted_schema = _convert_schema_refs(schema)
            content = {}
            for ct in produces:
                content[_swagger_type_to_content_type(ct)] = {"schema": converted_schema}
            oas3_response["content"] = content

        if "headers" in response:
            oas3_response["headers"] = _convert_schema_refs(response["headers"])

        if "examples" in response:
            # Move examples into content per content type
            if "content" not in oas3_response:
                oas3_response["content"] = {}
            for ct, example_value in response["examples"].items():
                if ct not in oas3_response["content"]:
                    oas3_response["content"][ct] = {}
                oas3_response["content"][ct]["example"] = example_value

        oas3_responses[str(status_code)] = oas3_response

    return oas3_responses


def convert_swagger_to_openapi3(spec: dict) -> dict:
    """
    Convert an OpenAPI 2.0 (Swagger) specification dict to OpenAPI 3.0 format.

    Handles:
      - Version field update
      - servers array from host/basePath/schemes
      - securityDefinitions → components/securitySchemes
      - definitions → components/schemas
      - Body/formData parameters → requestBody
      - Response schemas with content negotiation
      - $ref path rewrites

    Args:
        spec: Parsed Swagger 2.0 specification as a dict.

    Returns:
        OpenAPI 3.0 specification dict.
    """
    if spec.get("swagger", "").startswith("3") or spec.get("openapi", ""):
        # Already OpenAPI 3.x — return as-is (possibly after ref rewrite)
        return _convert_schema_refs(spec)

    if not spec.get("swagger", "").startswith("2"):
        raise ValueError(
            f"Unsupported specification version: "
            f"swagger={spec.get('swagger')!r}, openapi={spec.get('openapi')!r}"
        )

    oas3: dict = {"openapi": "3.0.0"}

    # --- info ---
    oas3["info"] = copy.deepcopy(spec.get("info", {}))

    # --- servers (from host + basePath + schemes) ---
    host = spec.get("host", "")
    base_path = spec.get("basePath", "/")
    schemes = spec.get("schemes", ["https"])
    if host:
        servers = []
        for scheme in schemes:
            url = f"{scheme}://{host}{base_path}"
            servers.append({"url": url})
        oas3["servers"] = servers
    elif base_path and base_path != "/":
        oas3["servers"] = [{"url": base_path}]

    # --- tags ---
    if "tags" in spec:
        oas3["tags"] = copy.deepcopy(spec["tags"])

    # --- externalDocs ---
    if "externalDocs" in spec:
        oas3["externalDocs"] = copy.deepcopy(spec["externalDocs"])

    # --- global consumes/produces ---
    global_consumes = spec.get("consumes", [])
    global_produces = spec.get("produces", [])

    # --- paths ---
    oas3["paths"] = {}
    for path, path_item in spec.get("paths", {}).items():
        oas3_path: dict = {}

        # Path-level parameters (non-body)
        if "parameters" in path_item:
            path_level_params = []
            for param in path_item["parameters"]:
                if param.get("in") not in ("body", "formData"):
                    path_level_params.append(_convert_schema_refs(param))
            if path_level_params:
                oas3_path["parameters"] = path_level_params

        http_methods = ("get", "put", "post", "delete", "options", "head", "patch", "trace")
        for method in http_methods:
            if method not in path_item:
                continue
            op = path_item[method]
            oas3_op: dict = {}

            # Copy simple fields
            for field in ("summary", "description", "operationId", "tags", "deprecated", "externalDocs"):
                if field in op:
                    oas3_op[field] = op[field]

            # Parameters: separate body/formData from others
            params = op.get("parameters", [])
            op_consumes = op.get("consumes", global_consumes)
            op_produces = op.get("produces", global_produces)

            request_body, remaining_params = _extract_request_body(params, op_consumes)
            if remaining_params:
                oas3_op["parameters"] = [_convert_schema_refs(p) for p in remaining_params]
            if request_body:
                oas3_op["requestBody"] = request_body

            # Responses
            if "responses" in op:
                oas3_op["responses"] = _convert_responses(op["responses"], op_produces)
            else:
                oas3_op["responses"] = {"default": {"description": "Successful operation"}}

            # Security
            if "security" in op:
                oas3_op["security"] = op["security"]

            oas3_path[method] = oas3_op

        oas3["paths"][path] = oas3_path

    # --- components ---
    components: dict = {}

    if "securityDefinitions" in spec:
        components["securitySchemes"] = _convert_security_definitions(
            spec["securityDefinitions"]
        )

    if "definitions" in spec:
        components["schemas"] = _convert_schema_refs(spec["definitions"])

    if "parameters" in spec:
        components["parameters"] = _convert_schema_refs(spec["parameters"])

    if "responses" in spec:
        # Global responses section
        converted_global_responses = {}
        for name, response in spec["responses"].items():
            oas3_response: dict = {
                "description": response.get("description", ""),
            }
            schema = response.get("schema")
            if schema:
                oas3_response["content"] = {
                    "application/json": {"schema": _convert_schema_refs(schema)}
                }
            converted_global_responses[name] = oas3_response
        components["responses"] = converted_global_responses

    if components:
        oas3["components"] = components

    # --- top-level security ---
    if "security" in spec:
        oas3["security"] = spec["security"]

    return oas3


# ---------------------------------------------------------------------------
# operationId auto-generation
# ---------------------------------------------------------------------------

def _path_to_camel(path: str) -> str:
    """
    Convert an OpenAPI path string to a camelCase identifier component.

    Examples:
      /users                    → Users
      /users/{userId}           → UsersByUserId
      /users/{userId}/orders    → UsersByUserIdOrders
      /pets/{petId}/photos      → PetsByPetIdPhotos
    """
    # Remove leading slash and split on /
    parts = path.strip("/").split("/")
    result_parts = []
    for part in parts:
        if not part:
            continue
        if part.startswith("{") and part.endswith("}"):
            # Path parameter: {userId} → ByUserId
            param_name = part[1:-1]
            result_parts.append("By" + param_name[0].upper() + param_name[1:])
        else:
            # Regular segment: capitalize first letter
            # Handle kebab-case and snake_case segments
            words = re.split(r"[-_]", part)
            result_parts.append("".join(w.capitalize() for w in words))
    return "".join(result_parts)


def generate_operation_id(method: str, path: str) -> str:
    """
    Generate a descriptive, unique operationId from an HTTP method and path.

    The naming convention is: {method}{PathComponents} in camelCase.

    Examples:
      GET    /users              → getUsers
      POST   /users              → postUsers
      GET    /users/{userId}     → getUsersByUserId
      DELETE /users/{userId}     → deleteUsersByUserId
      GET    /users/{id}/orders  → getUsersByIdOrders

    Args:
        method: HTTP method (get, post, put, delete, etc.)
        path:   OpenAPI path string (e.g. '/users/{userId}')

    Returns:
        camelCase operationId string.
    """
    method_lower = method.lower()
    path_part = _path_to_camel(path)
    if path_part:
        return method_lower + path_part
    # Fallback for root path '/'
    return method_lower + "Root"


def ensure_operation_ids(spec: dict) -> dict:
    """
    Ensure every operation in the spec has an operationId.

    If an operation is missing an operationId, one is generated from the
    HTTP method and path using generate_operation_id(). Duplicate IDs
    (which can arise when multiple operations produce the same base ID)
    are disambiguated by appending a numeric suffix (_2, _3, ...).

    Args:
        spec: Parsed OpenAPI 2.0 or 3.0 specification dict (modified in place).

    Returns:
        The modified spec dict.
    """
    seen_ids: set = set()

    # Collect all existing operationIds so we don't clash with them
    for path_item in spec.get("paths", {}).values():
        for method in ("get", "put", "post", "delete", "options", "head", "patch", "trace"):
            if method in path_item and isinstance(path_item[method], dict):
                existing_id = path_item[method].get("operationId")
                if existing_id:
                    seen_ids.add(existing_id)

    # Now assign missing IDs
    for path, path_item in spec.get("paths", {}).items():
        for method in ("get", "put", "post", "delete", "options", "head", "patch", "trace"):
            if method not in path_item or not isinstance(path_item[method], dict):
                continue
            op = path_item[method]
            if not op.get("operationId"):
                base_id = generate_operation_id(method, path)
                candidate = base_id
                counter = 2
                while candidate in seen_ids:
                    candidate = f"{base_id}_{counter}"
                    counter += 1
                op["operationId"] = candidate
                seen_ids.add(candidate)

    return spec


# ---------------------------------------------------------------------------
# APIM requirement validation
# ---------------------------------------------------------------------------

# Security scheme types supported by Azure APIM
APIM_SUPPORTED_SECURITY_TYPES = {"apiKey", "http", "oauth2", "openIdConnect"}

# Security scheme types for OAS2 (Swagger)
SWAGGER_SUPPORTED_SECURITY_TYPES = {"apiKey", "basic", "oauth2"}


def validate_apim_requirements(spec: dict) -> list:
    """
    Validate that an OpenAPI specification meets Azure APIM import requirements.

    Checks performed:
      1. Mandatory info fields: title and version
      2. At least one server URL is defined (OpenAPI 3.0) or basePath/host (Swagger 2.0)
      3. Security scheme types are compatible with Azure APIM
      4. Operations have unique operationIds (if defined)

    Args:
        spec: Parsed OpenAPI specification dict.

    Returns:
        A list of validation error/warning message strings.
        An empty list indicates a spec that passes all checks.
    """
    errors = []

    # 1. Mandatory info fields
    info = spec.get("info", {})
    if not isinstance(info, dict):
        errors.append("ERROR: 'info' field must be an object.")
        info = {}

    if not info.get("title"):
        errors.append("ERROR: 'info.title' is required by Azure APIM.")
    if not info.get("version"):
        errors.append("ERROR: 'info.version' is required by Azure APIM.")

    # 2. Server/base URL
    is_swagger2 = str(spec.get("swagger", "")).startswith("2")
    is_oas3 = str(spec.get("openapi", "")).startswith("3")

    if is_swagger2:
        # Swagger 2.0: host is optional but basePath helps
        if not spec.get("host") and not spec.get("basePath"):
            errors.append(
                "WARNING: Neither 'host' nor 'basePath' is defined. "
                "APIM will need a backend URL configured separately."
            )
    elif is_oas3:
        servers = spec.get("servers", [])
        if not servers:
            errors.append(
                "WARNING: No 'servers' array defined. "
                "APIM will need a backend URL configured separately."
            )
        else:
            for i, server in enumerate(servers):
                if not server.get("url"):
                    errors.append(f"ERROR: servers[{i}] is missing the required 'url' field.")
    else:
        errors.append(
            "WARNING: Cannot determine OpenAPI version "
            f"(swagger={spec.get('swagger')!r}, openapi={spec.get('openapi')!r})."
        )

    # 3. Security scheme compatibility
    if is_swagger2:
        for name, scheme in spec.get("securityDefinitions", {}).items():
            scheme_type = scheme.get("type", "")
            if scheme_type not in SWAGGER_SUPPORTED_SECURITY_TYPES:
                errors.append(
                    f"WARNING: Security definition '{name}' uses unsupported "
                    f"type '{scheme_type}' for Azure APIM. "
                    f"Supported types: {sorted(SWAGGER_SUPPORTED_SECURITY_TYPES)}."
                )
    elif is_oas3:
        for name, scheme in spec.get("components", {}).get("securitySchemes", {}).items():
            scheme_type = scheme.get("type", "")
            if scheme_type not in APIM_SUPPORTED_SECURITY_TYPES:
                errors.append(
                    f"WARNING: Security scheme '{name}' uses unsupported "
                    f"type '{scheme_type}' for Azure APIM. "
                    f"Supported types: {sorted(APIM_SUPPORTED_SECURITY_TYPES)}."
                )

    # 4. operationId uniqueness
    all_ids = []
    for path_item in spec.get("paths", {}).values():
        for method in ("get", "put", "post", "delete", "options", "head", "patch", "trace"):
            if method in path_item and isinstance(path_item[method], dict):
                op_id = path_item[method].get("operationId")
                if op_id:
                    all_ids.append(op_id)

    duplicates = {op_id for op_id in all_ids if all_ids.count(op_id) > 1}
    for dup in sorted(duplicates):
        errors.append(f"ERROR: operationId '{dup}' is not unique. APIM requires unique operationIds.")

    return errors


# ---------------------------------------------------------------------------
# Vendor extension removal
# ---------------------------------------------------------------------------

def _remove_extensions_recursive(obj: Any, prefix: str) -> Any:
    """Recursively remove keys that start with the given prefix from dicts."""
    if isinstance(obj, dict):
        return {
            k: _remove_extensions_recursive(v, prefix)
            for k, v in obj.items()
            if not (isinstance(k, str) and k.startswith(prefix))
        }
    if isinstance(obj, list):
        return [_remove_extensions_recursive(item, prefix) for item in obj]
    return obj


def clean_aws_extensions(spec: dict) -> dict:
    """
    Remove AWS API Gateway-specific extensions from an OpenAPI spec.

    Removes keys starting with 'x-amazon-' at all levels of the spec.
    These extensions are added by AWS API Gateway on export and are not
    recognised (and may cause errors) in Azure APIM.

    Args:
        spec: Parsed OpenAPI specification dict.

    Returns:
        New spec dict with AWS extensions removed.
    """
    return _remove_extensions_recursive(spec, "x-amazon-")


def clean_google_extensions(spec: dict) -> dict:
    """
    Remove Google API Gateway / Apigee-specific extensions from an OpenAPI spec.

    Removes keys starting with 'x-google-' at all levels of the spec.

    Args:
        spec: Parsed OpenAPI specification dict.

    Returns:
        New spec dict with Google extensions removed.
    """
    return _remove_extensions_recursive(spec, "x-google-")


# ---------------------------------------------------------------------------
# File I/O helpers
# ---------------------------------------------------------------------------

def load_spec(file_path: str) -> dict:
    """
    Load an OpenAPI specification from a YAML or JSON file.

    Args:
        file_path: Path to the input file (.yaml, .yml, or .json).

    Returns:
        Parsed specification dict.

    Raises:
        SystemExit: If the file cannot be read or parsed.
    """
    try:
        with open(file_path, "r", encoding="utf-8") as fh:
            content = fh.read()
    except OSError as exc:
        print(f"ERROR: Cannot read file '{file_path}': {exc}", file=sys.stderr)
        sys.exit(1)

    if file_path.endswith(".json"):
        try:
            return json.loads(content)
        except json.JSONDecodeError as exc:
            print(f"ERROR: Invalid JSON in '{file_path}': {exc}", file=sys.stderr)
            sys.exit(1)

    if not HAS_YAML:
        print("ERROR: PyYAML is required for YAML files. Install with: pip install pyyaml", file=sys.stderr)
        sys.exit(1)

    try:
        return yaml.safe_load(content)
    except yaml.YAMLError as exc:
        print(f"ERROR: Invalid YAML in '{file_path}': {exc}", file=sys.stderr)
        sys.exit(1)


def save_spec(spec: dict, file_path: str) -> None:
    """
    Save an OpenAPI specification to a YAML or JSON file.

    Args:
        spec:       Specification dict to write.
        file_path:  Destination file path (.yaml, .yml, or .json).
    """
    if file_path.endswith(".json"):
        content = json.dumps(spec, indent=2, ensure_ascii=False)
    else:
        if not HAS_YAML:
            print("ERROR: PyYAML is required for YAML output. Install with: pip install pyyaml", file=sys.stderr)
            sys.exit(1)
        content = yaml.dump(spec, allow_unicode=True, default_flow_style=False, sort_keys=False)

    try:
        with open(file_path, "w", encoding="utf-8") as fh:
            fh.write(content)
    except OSError as exc:
        print(f"ERROR: Cannot write file '{file_path}': {exc}", file=sys.stderr)
        sys.exit(1)


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main() -> None:
    """
    Command-line interface for the OpenAPI utility.

    Usage:
        python3 openapi_utils.py <input-file> <output-file> [--source aws|google]

    Options:
        --source aws     Remove AWS x-amazon-* extensions (default: aws)
        --source google  Remove Google x-google-* extensions
        --no-convert     Skip Swagger 2.0 → OpenAPI 3.0 conversion
        --no-operationid Skip automatic operationId generation
        --validate-only  Only run validation, do not write output file
    """
    parser = argparse.ArgumentParser(
        description="OpenAPI specification utility for Azure APIM migration."
    )
    parser.add_argument("input_file", help="Input OpenAPI specification file (YAML or JSON)")
    parser.add_argument("output_file", help="Output file path")
    parser.add_argument(
        "--source",
        choices=["aws", "google"],
        default="aws",
        help="Source platform to remove vendor extensions for (default: aws)",
    )
    parser.add_argument(
        "--no-convert",
        action="store_true",
        help="Skip Swagger 2.0 → OpenAPI 3.0 conversion",
    )
    parser.add_argument(
        "--no-operationid",
        action="store_true",
        help="Skip automatic operationId generation",
    )
    parser.add_argument(
        "--validate-only",
        action="store_true",
        help="Run validation only; do not write output file",
    )
    args = parser.parse_args()

    # Load
    print(f"[1/4] Loading spec: {args.input_file}")
    spec = load_spec(args.input_file)

    # Remove vendor extensions
    print(f"[2/4] Removing {args.source.upper()} vendor extensions...")
    if args.source == "aws":
        spec = clean_aws_extensions(spec)
    else:
        spec = clean_google_extensions(spec)

    # Convert Swagger 2.0 → OpenAPI 3.0
    if not args.no_convert:
        swagger_version = str(spec.get("swagger", ""))
        if swagger_version.startswith("2"):
            print("[3/4] Converting Swagger 2.0 → OpenAPI 3.0...")
            spec = convert_swagger_to_openapi3(spec)
        else:
            print("[3/4] Spec is already OpenAPI 3.x, skipping conversion.")
    else:
        print("[3/4] Skipping Swagger → OpenAPI 3.0 conversion (--no-convert).")

    # Auto-generate missing operationIds
    if not args.no_operationid:
        print("[3b] Ensuring all operations have operationId...")
        spec = ensure_operation_ids(spec)

    # Validate APIM requirements
    print("[4/4] Validating APIM requirements...")
    issues = validate_apim_requirements(spec)
    if issues:
        for issue in issues:
            prefix = "⚠️ " if issue.startswith("WARNING") else "❌ "
            print(f"  {prefix}{issue}")
        errors_only = [i for i in issues if i.startswith("ERROR")]
        if errors_only:
            print(f"\nValidation completed with {len(errors_only)} error(s).")
        else:
            print("\nValidation completed with warnings only.")
    else:
        print("  ✅ All APIM requirements satisfied.")

    # Write output
    if not args.validate_only:
        save_spec(spec, args.output_file)
        print(f"\nOutput written to: {args.output_file}")
    else:
        print("\n(--validate-only: output file not written)")


if __name__ == "__main__":
    main()
