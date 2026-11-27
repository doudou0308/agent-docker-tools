import argparse
import sys
from functools import partial

import anyio
import httpx
from mcp import ClientSession
from mcp.client.sse import sse_client


async def check_health():
    async with httpx.AsyncClient(trust_env=False, timeout=2) as client:
        response = await client.get("http://127.0.0.1:8089/check_connection")
        response.raise_for_status()

    await check_sse()


async def check_sse():
    with anyio.fail_after(5):
        async with sse_client(
            "http://127.0.0.1:8766/sse",
            httpx_client_factory=partial(httpx.AsyncClient, trust_env=False),
        ) as (read_stream, write_stream):
            async with ClientSession(read_stream, write_stream) as session:
                await session.initialize()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Check GhidraMCP readiness")
    parser.add_argument("--sse-only", action="store_true", help="check the host's published SSE endpoint")
    args = parser.parse_args()
    try:
        anyio.run(check_sse if args.sse_only else check_health)
    except Exception as exc:
        print(f"GhidraMCP health check failed: {exc}", file=sys.stderr)
        sys.exit(1)
