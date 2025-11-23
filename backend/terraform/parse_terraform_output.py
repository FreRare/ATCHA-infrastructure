#!/usr/bin/env python3
import json
import sys
import argparse
import re
from typing import Dict, List, Any


# ANSI color codes
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    BOLD = '\033[1m'
    NC = '\033[0m'  # No Color


def parse_terraform_json(data: Dict) -> List[Dict]:
    """Parse terraform show --json output and extract container information."""
    containers = []

    # Helper function to recursively find all docker_container resources
    def find_containers(module, module_path=""):
        # Check resources in current module
        if 'resources' in module:
            for resource in module['resources']:
                if resource['type'] == 'docker_container':
                    values = resource['values']

                    # Extract container info
                    container_info = {
                        'module': module_path or 'root',
                        'name': values.get('name', 'unknown'),
                        'id': values.get('id', ''),
                        'image': values.get('image', ''),
                        'status': 'running' if values.get('must_run', False) else 'stopped',
                        'restart_policy': values.get('restart', ''),
                        'ports': values.get('ports', []),
                        'networks': values.get('network_data', []),
                        'healthcheck': values.get('healthcheck', [None])[0] if values.get('healthcheck') else None,
                        'hostname': values.get('hostname', ''),
                    }
                    containers.append(container_info)

        # Recursively check child modules
        if 'child_modules' in module:
            for child_module in module['child_modules']:
                child_path = child_module.get('address', '')
                # Extract module name from address (e.g., "module.ATCHA_backend_app" -> "ATCHA_backend_app")
                if child_path.startswith('module.'):
                    module_name = child_path[7:]  # Remove 'module.' prefix
                else:
                    module_name = child_path

                find_containers(child_module, module_name)

    # Start parsing from root module
    find_containers(data['values']['root_module'])

    return containers


def get_status_color(status: str) -> str:
    """Get color for status."""
    if status == 'running':
        return Colors.GREEN
    elif status == 'stopped':
        return Colors.RED
    else:
        return Colors.YELLOW


def generate_colored_output(containers: List[Dict]) -> str:
    """Generate colored terminal output."""
    output = []

    # Header
    output.append(f"{Colors.BOLD}{'═' * 55}{Colors.NC}")
    output.append(f"{Colors.BOLD}{'                    Docker Containers Status                     ':^55}{Colors.NC}")
    output.append(f"{Colors.BOLD}{'═' * 55}{Colors.NC}")
    output.append("")

    # Summary
    total_containers = len(containers)
    running_containers = len([c for c in containers if c['status'] == 'running'])
    stopped_containers = total_containers - running_containers

    output.append(f"{Colors.BOLD}Summary:{Colors.NC}")
    output.append(f"├─ Total: {total_containers} containers")
    output.append(f"├─ Running: {Colors.GREEN}{running_containers}{Colors.NC}")
    output.append(f"└─ Stopped: {Colors.RED}{stopped_containers}{Colors.NC}")
    output.append("")
    output.append(f"{Colors.BOLD}{'═' * 55}{Colors.NC}")
    output.append("")

    # Sort containers by module then name
    containers_sorted = sorted(containers, key=lambda x: (x['module'], x['name']))

    # Display each container
    for container in containers_sorted:
        module = container['module']
        name = container['name']
        status = container['status']
        image = container['image']
        hostname = container.get('hostname', '')

        # Container header
        output.append(f"{Colors.BOLD}{Colors.BLUE}{module}{Colors.NC}/{Colors.CYAN}{name}{Colors.NC}")

        # Status with color
        status_color = get_status_color(status)
        output.append(f"├─ Status: {status_color}● {status.upper()}{Colors.NC}")

        # Image (truncated)
        if image:
            image_short = image[:20] + "..." if len(image) > 20 else image
            output.append(f"├─ Image: {image_short}")

        # Hostname if available
        if hostname:
            output.append(f"├─ Hostname: {hostname}")

        # Restart policy if available
        if container.get('restart_policy'):
            output.append(f"├─ Restart: {container['restart_policy']}")

        # Endpoints
        if container['ports']:
            output.append("├─ Endpoints:")
            for i, port in enumerate(container['ports']):
                external = port.get('external', '')
                internal = port.get('internal', '')
                protocol = port.get('protocol', 'tcp').upper()
                ip = port.get('ip', '0.0.0.0')

                if external:  # Only show ports that are exposed externally
                    if ip == '0.0.0.0':
                        url = f"http://localhost:{external}"
                    else:
                        url = f"http://{ip}:{external}"

                    # Tree structure for multiple endpoints
                    if i == len(container['ports']) - 1:
                        prefix = "│  └─"
                    else:
                        prefix = "│  ├─"

                    output.append(f"{prefix} {Colors.GREEN}{url}{Colors.NC} ({external}:{internal} [{protocol}])")

        # Network info
        if container['networks']:
            network = container['networks'][0]  # Show first network
            network_name = network.get('network_name', 'N/A')
            ip_address = network.get('ip_address', 'N/A')
            if network_name and ip_address:
                output.append(f"└─ Network: {network_name} ({ip_address})")
            else:
                output.append("└─ Network: N/A")
        else:
            output.append("└─ Network: N/A")

        output.append("")

    # Quick access URLs
    output.append(f"{Colors.BOLD}{'═' * 55}{Colors.NC}")
    output.append(f"{Colors.BOLD}{'                      Quick Access URLs                        ':^55}{Colors.NC}")
    output.append(f"{Colors.BOLD}{'═' * 55}{Colors.NC}")
    output.append("")

    # Collect all URLs
    urls_found = False
    for container in containers_sorted:
        if container['ports']:
            name = container['name']
            for port in container['ports']:
                external = port.get('external', '')
                if external:  # Only show externally exposed ports
                    ip = port.get('ip', '0.0.0.0')
                    protocol = port.get('protocol', 'tcp').upper()

                    if ip == '0.0.0.0':
                        url = f"http://localhost:{external}"
                    else:
                        url = f"http://{ip}:{external}"

                    output.append(f"{Colors.CYAN}{name}{Colors.NC}: {Colors.GREEN}{url}{Colors.NC} [{protocol}]")
                    urls_found = True

    if not urls_found:
        output.append("No external endpoints available")

    output.append("")

    return '\n'.join(output)


def generate_json_output(containers: List[Dict]) -> str:
    """Generate JSON output for programmatic use."""
    output = {
        'summary': {
            'total_containers': len(containers),
            'running_containers': len([c for c in containers if c['status'] == 'running'])
        },
        'containers': []
    }

    for container in containers:
        container_info = {
            'module': container['module'],
            'name': container['name'],
            'status': container['status'],
            'image': container.get('image'),
            'hostname': container.get('hostname'),
            'restart_policy': container.get('restart_policy'),
            'endpoints': []
        }

        # Generate endpoints from port mappings
        for port in container['ports']:
            external = port.get('external')
            if external:  # Only include externally exposed ports
                ip = port.get('ip', '0.0.0.0')
                internal = port.get('internal', '')
                protocol = port.get('protocol', 'tcp')

                if ip == '0.0.0.0':
                    url = f"http://localhost:{external}"
                else:
                    url = f"http://{ip}:{external}"

                container_info['endpoints'].append({
                    'url': url,
                    'external_port': external,
                    'internal_port': internal,
                    'protocol': protocol,
                    'ip': ip
                })

        output['containers'].append(container_info)

    return json.dumps(output, indent=2)


def main():
    parser = argparse.ArgumentParser(
        description='Extract and display Docker container endpoints from terraform show --json output',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Read from file and show colored output
  python extract_endpoints.py terraform_show.json

  # Pipe from terraform show --json
  terraform show --json | python extract_endpoints.py

  # Output JSON format
  terraform show --json | python extract_endpoints.py --json

  # No color output
  terraform show --json | python extract_endpoints.py --no-color
        """
    )

    parser.add_argument(
        'file',
        nargs='?',
        help='Input file containing terraform show --json output (default: stdin)'
    )
    parser.add_argument(
        '--json',
        action='store_true',
        help='Output JSON format instead of colored terminal output'
    )
    parser.add_argument(
        '--no-color',
        action='store_true',
        help='Disable colored output'
    )

    args = parser.parse_args()

    # Read input
    if args.file:
        try:
            with open(args.file, 'r') as f:
                data = json.load(f)
        except FileNotFoundError:
            print(f"Error: File '{args.file}' not found", file=sys.stderr)
            sys.exit(1)
        except json.JSONDecodeError as e:
            print(f"Error: Invalid JSON in file '{args.file}': {e}", file=sys.stderr)
            sys.exit(1)
    else:
        try:
            data = json.load(sys.stdin)
        except json.JSONDecodeError as e:
            print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
            sys.exit(1)

    # Parse the terraform JSON
    containers = parse_terraform_json(data)

    # Generate output
    if args.json:
        print(generate_json_output(containers))
    else:
        if args.no_color:
            # Strip color codes if --no-color is specified
            colored_output = generate_colored_output(containers)
            # Remove ANSI escape sequences
            ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
            print(ansi_escape.sub('', colored_output))
        else:
            print(generate_colored_output(containers))


if __name__ == "__main__":
    main()
