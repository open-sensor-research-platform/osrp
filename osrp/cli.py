#!/usr/bin/env python3
"""
OSRP Command Line Interface
Provides commands for initializing studies, deploying infrastructure, and running analysis
"""

import click
import os
import sys
import subprocess
from pathlib import Path
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

console = Console()

@click.group()
@click.version_option(version="0.1.0", prog_name="osrp")
def main():
    """
    OSRP - Open Sensing Research Platform

    Complete multi-modal mobile sensing for academic research.
    Built for AWS. Open source.
    """
    pass

@main.command()
@click.argument('study_name')
@click.option('--template', type=click.Choice(['basic', 'ema', 'wearables', 'comprehensive']),
              default='basic', help='Study template to use')
@click.option('--path', type=click.Path(), default='.', help='Path to create study directory')
def init(study_name, template, path):
    """
    Initialize a new OSRP study

    STUDY_NAME: Name of your research study
    """
    console.print(Panel.fit(
        f"[bold cyan]Initializing OSRP Study: {study_name}[/bold cyan]",
        border_style="cyan"
    ))

    study_path = Path(path) / study_name

    try:
        # Create study directory structure
        study_path.mkdir(parents=True, exist_ok=False)
        (study_path / "config").mkdir()
        (study_path / "data").mkdir()
        (study_path / "analysis").mkdir()
        (study_path / "infrastructure").mkdir()

        # Create basic configuration file
        config_content = f"""# OSRP Study Configuration
study_name: {study_name}
template: {template}
aws_region: us-west-2

# Data collection modules
modules:
  screenshots: true
  sensors: true
  wearables: {'true' if template in ['wearables', 'comprehensive'] else 'false'}
  ema: {'true' if template in ['ema', 'comprehensive'] else 'false'}

# Sampling rates
sampling:
  screenshot_interval: 5  # seconds
  sensor_frequency: 1     # Hz

# Upload policy
upload:
  policy: wifi_only       # wifi_only, always, scheduled
  batch_size: 100
"""

        with open(study_path / "config" / "study_config.yaml", "w") as f:
            f.write(config_content)

        # Create README
        readme_content = f"""# {study_name}

OSRP Study - {template.capitalize()} Template

## Quick Start

1. Configure AWS credentials:
   ```bash
   aws configure
   ```

2. Deploy infrastructure:
   ```bash
   cd {study_name}
   osrp deploy --aws
   ```

3. Start analysis:
   ```bash
   osrp notebooks
   ```

## Configuration

Edit `config/study_config.yaml` to customize data collection modules and sampling rates.

## Documentation

- Study configuration: `config/study_config.yaml`
- Infrastructure: `infrastructure/`
- Analysis notebooks: `analysis/`

For more information: https://docs.osrp.io
"""

        with open(study_path / "README.md", "w") as f:
            f.write(readme_content)

        console.print(f"\n[green]✓[/green] Study '{study_name}' created successfully!")
        console.print(f"\n[bold]Next steps:[/bold]")
        console.print(f"  1. cd {study_name}")
        console.print(f"  2. Edit config/study_config.yaml")
        console.print(f"  3. osrp deploy --aws")

    except FileExistsError:
        console.print(f"[red]✗[/red] Directory '{study_name}' already exists!", style="red")
        sys.exit(1)
    except Exception as e:
        console.print(f"[red]✗[/red] Error: {str(e)}", style="red")
        sys.exit(1)

@main.command()
@click.option('--aws', is_flag=True, help='Deploy AWS infrastructure')
@click.option('--region', default='us-west-2', help='AWS region')
@click.option('--environment', default='dev', type=click.Choice(['dev', 'staging', 'prod']),
              help='Deployment environment')
@click.option('--stack-name', help='CloudFormation stack name (auto-generated if not provided)')
def deploy(aws, region, environment, stack_name):
    """
    Deploy OSRP infrastructure to AWS
    """
    console.print(Panel.fit(
        f"[bold cyan]Deploying OSRP to AWS[/bold cyan]\n"
        f"Region: {region}\n"
        f"Environment: {environment}",
        border_style="cyan"
    ))

    if not aws:
        console.print("[yellow]⚠[/yellow] Use --aws flag to deploy to AWS")
        return

    # Check for CloudFormation template
    cf_template = Path("infrastructure/cloudformation-stack.yaml")
    if not cf_template.exists():
        console.print("[red]✗[/red] CloudFormation template not found!", style="red")
        console.print("Expected location: infrastructure/cloudformation-stack.yaml")
        sys.exit(1)

    # Generate stack name if not provided
    if not stack_name:
        study_name = Path.cwd().name
        stack_name = f"osrp-{study_name}-{environment}"

    console.print(f"\n[bold]Deploying stack:[/bold] {stack_name}")
    console.print("[dim]This may take 5-10 minutes...[/dim]\n")

    try:
        # Deploy CloudFormation stack
        cmd = [
            "aws", "cloudformation", "deploy",
            "--template-file", str(cf_template),
            "--stack-name", stack_name,
            "--region", region,
            "--capabilities", "CAPABILITY_IAM",
            "--parameter-overrides",
            f"Environment={environment}",
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode == 0:
            console.print("[green]✓[/green] Deployment successful!\n")

            # Get stack outputs
            console.print("[bold]Stack Outputs:[/bold]")
            outputs_cmd = [
                "aws", "cloudformation", "describe-stacks",
                "--stack-name", stack_name,
                "--region", region,
                "--query", "Stacks[0].Outputs",
            ]

            outputs_result = subprocess.run(outputs_cmd, capture_output=True, text=True)
            if outputs_result.returncode == 0:
                console.print(outputs_result.stdout)
        else:
            console.print(f"[red]✗[/red] Deployment failed!", style="red")
            console.print(result.stderr)
            sys.exit(1)

    except FileNotFoundError:
        console.print("[red]✗[/red] AWS CLI not found. Please install: pip install awscli", style="red")
        sys.exit(1)
    except Exception as e:
        console.print(f"[red]✗[/red] Error: {str(e)}", style="red")
        sys.exit(1)

@main.command()
@click.option('--port', default=8888, help='Port for Marimo server')
@click.option('--notebook', help='Specific notebook to open')
def notebooks(port, notebook):
    """
    Start Marimo analysis notebooks
    """
    console.print(Panel.fit(
        "[bold cyan]Starting OSRP Analysis Notebooks[/bold cyan]",
        border_style="cyan"
    ))

    # Check if marimo is installed
    try:
        subprocess.run(["marimo", "--version"], capture_output=True, check=True)
    except (FileNotFoundError, subprocess.CalledProcessError):
        console.print("[yellow]⚠[/yellow] Marimo not installed. Installing now...")
        subprocess.run([sys.executable, "-m", "pip", "install", "marimo"], check=True)

    # Find analysis notebooks
    analysis_dir = Path("analysis/notebooks")
    if not analysis_dir.exists():
        # Try to find notebooks in package installation
        import osrp
        package_dir = Path(osrp.__file__).parent
        analysis_dir = package_dir / "analysis" / "notebooks"

    if not analysis_dir.exists():
        console.print("[red]✗[/red] Analysis notebooks not found!", style="red")
        sys.exit(1)

    if notebook:
        notebook_path = analysis_dir / notebook
        if not notebook_path.exists():
            console.print(f"[red]✗[/red] Notebook '{notebook}' not found!", style="red")
            sys.exit(1)
        cmd = ["marimo", "edit", str(notebook_path), "--port", str(port)]
    else:
        # List available notebooks
        notebooks = list(analysis_dir.glob("*.py"))
        if not notebooks:
            console.print("[red]✗[/red] No notebooks found!", style="red")
            sys.exit(1)

        console.print("\n[bold]Available notebooks:[/bold]")
        for i, nb in enumerate(notebooks, 1):
            console.print(f"  {i}. {nb.name}")

        console.print(f"\n[dim]Starting with first notebook...[/dim]\n")
        cmd = ["marimo", "edit", str(notebooks[0]), "--port", str(port)]

    console.print(f"[green]→[/green] Marimo server starting on http://localhost:{port}\n")

    try:
        subprocess.run(cmd)
    except KeyboardInterrupt:
        console.print("\n[yellow]✓[/yellow] Marimo server stopped")

@main.command()
@click.option('--region', default='us-west-2', help='AWS region')
def status(region):
    """
    Check OSRP deployment status
    """
    console.print(Panel.fit(
        "[bold cyan]OSRP Deployment Status[/bold cyan]",
        border_style="cyan"
    ))

    try:
        # Check for CloudFormation stacks
        cmd = [
            "aws", "cloudformation", "list-stacks",
            "--region", region,
            "--stack-status-filter", "CREATE_COMPLETE", "UPDATE_COMPLETE",
            "--query", "StackSummaries[?contains(StackName, 'osrp')].{Name:StackName,Status:StackStatus,Created:CreationTime}",
            "--output", "table"
        ]

        result = subprocess.run(cmd, capture_output=True, text=True, check=True)

        if result.stdout.strip():
            console.print("\n[bold]Active OSRP Stacks:[/bold]")
            console.print(result.stdout)
        else:
            console.print("\n[yellow]No active OSRP stacks found[/yellow]")

    except FileNotFoundError:
        console.print("[red]✗[/red] AWS CLI not found", style="red")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        console.print(f"[red]✗[/red] Error checking status: {e.stderr}", style="red")
        sys.exit(1)

@main.command()
def info():
    """
    Display OSRP system information
    """
    table = Table(title="OSRP System Information", show_header=True, header_style="bold cyan")
    table.add_column("Property", style="dim")
    table.add_column("Value")

    import osrp
    table.add_row("Version", osrp.__version__)
    table.add_row("Python", sys.version.split()[0])
    table.add_row("Installation", str(Path(osrp.__file__).parent))

    # Check for dependencies
    deps = {
        "boto3": "AWS SDK",
        "pandas": "Data Analysis",
        "marimo": "Analysis Notebooks",
        "plotly": "Visualization",
    }

    table.add_row("", "")  # Separator
    table.add_row("[bold]Dependencies[/bold]", "[bold]Status[/bold]")

    for module, description in deps.items():
        try:
            __import__(module)
            table.add_row(f"{module} ({description})", "[green]✓ Installed[/green]")
        except ImportError:
            table.add_row(f"{module} ({description})", "[yellow]Not installed[/yellow]")

    console.print(table)
    console.print("\n[dim]For more information: https://docs.osrp.io[/dim]")

if __name__ == "__main__":
    main()
