# Marimo on SageMaker Studio - Practical Setup Guide

Based on Scott Friedman's proven approach from https://github.com/scttfrdmn/aws-marimo

## Why This Approach is Better

**Scott's Method (Recommended):**
- ✅ Works in 5 minutes
- ✅ No CloudFormation complexity
- ✅ Uses conda environments (proper Python isolation)
- ✅ Jupyter-server-proxy for clean integration
- ✅ Simple startup scripts
- ✅ Works on free SageMaker Studio Lab

**Old Complex Method:**
- ❌ Requires CloudFormation deployment
- ❌ Takes 30+ minutes
- ❌ Overkill for getting started
- ❌ Harder to troubleshoot

## Quick Start (5 Minutes)

### Option 1: SageMaker Studio Lab (FREE!)

1. **Get Free Account**
   - Go to https://studiolab.sagemaker.aws
   - Sign up (no credit card, no AWS account needed)
   - Launch your Studio Lab environment

2. **One-Command Setup**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/scttfrdmn/aws-marimo/main/bootstrap.sh | bash
   ```

3. **Start Marimo**
   ```bash
   ~/start-marimo.sh
   ```

4. **Access** 
   - Click the proxy URL that appears
   - Start analyzing data!

### Option 2: SageMaker Studio (If you already have it)

1. **Open Terminal in Studio**

2. **Create Conda Environment**
   ```bash
   # Create conda environment
   conda create -n marimo-env python=3.11 -y
   conda activate marimo-env
   
   # Install marimo and proxy
   pip install marimo jupyter-server-proxy
   
   # Install data science libraries
   pip install boto3 pandas numpy plotly altair scikit-learn
   pip install pillow opencv-python-headless scipy seaborn matplotlib
   ```

3. **Create Start Script**
   ```bash
   cat > ~/start-marimo.sh << 'EOF'
   #!/bin/bash
   # Start marimo server
   
   # Activate conda environment
   conda activate marimo-env
   
   # Get the Jupyter base URL for proxy
   # SageMaker Studio uses jupyter-server-proxy
   PORT=8888
   
   echo "🚀 Starting marimo server on port $PORT..."
   echo ""
   echo "Access marimo via the Jupyter proxy:"
   echo "  Click: proxy/$PORT/ in your browser"
   echo ""
   
   marimo edit --host 0.0.0.0 --port $PORT
   EOF
   
   chmod +x ~/start-marimo.sh
   ```

4. **Start Marimo**
   ```bash
   ~/start-marimo.sh
   ```

5. **Access**
   - In Studio, click the proxy link: `proxy/8888/`
   - Or construct URL: `https://<your-studio-url>/jupyter/default/proxy/8888/`

## Setting Up Mobile Sensing Analysis

Once marimo is running, set up the analysis environment:

### 1. Copy Analysis Files

```bash
# In SageMaker Studio terminal
cd ~
mkdir -p mobile-sensing-analysis
cd mobile-sensing-analysis

# Copy your analysis files here
# You can use git clone, upload via Studio UI, or scp
```

### 2. Install Mobile Sensing Dependencies

```bash
conda activate marimo-env

# AWS and data libraries (already installed above)
# Add any additional libraries your analysis needs
pip install <additional-packages>
```

### 3. Configure AWS Access

The data access utilities need AWS credentials:

```python
# In SageMaker Studio, these are automatically available
# No configuration needed!

import boto3

# Will use SageMaker execution role automatically
dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
```

### 4. Launch Notebooks

```bash
# Start marimo
~/start-marimo.sh

# Then in browser, open your notebooks:
# - daily_behavior_profile.py
# - multimodal_analysis.py  
# - ml_pipeline_example.py
```

## Directory Structure

Recommended setup in SageMaker Studio:

```
/home/sagemaker-user/
├── start-marimo.sh              # Launch script
├── mobile-sensing-analysis/
│   ├── notebooks/
│   │   ├── daily_behavior_profile.py
│   │   ├── multimodal_analysis.py
│   │   └── ml_pipeline_example.py
│   ├── utils/
│   │   └── data_access.py
│   └── data/                    # Optional: cached data
└── .conda/
    └── envs/
        └── marimo-env/          # Conda environment
```

## Key Differences from Jupyter

### Starting Notebooks

**Jupyter:**
```bash
jupyter lab
# Opens in browser automatically
```

**Marimo:**
```bash
marimo edit notebook.py
# Opens at http://localhost:8888
# Access via proxy in SageMaker
```

### Creating Notebooks

**Jupyter:**
- Click "New" → "Python 3"
- .ipynb file format

**Marimo:**
```bash
marimo edit new_notebook.py
# Pure Python .py file
```

### Running as Script

**Jupyter:**
```bash
# Convert first
jupyter nbconvert --to script notebook.ipynb
python notebook.py
```

**Marimo:**
```bash
# Already Python!
python notebook.py
```

### Reactivity

**Jupyter:**
```python
# Manual re-run needed
slider = widgets.IntSlider(value=50)
display(slider)
# Change slider → nothing happens
# Must re-run cells manually
```

**Marimo:**
```python
import marimo as mo

# Automatic updates!
slider = mo.ui.slider(0, 100, value=50)
result = slider.value ** 2  # Auto-updates when slider changes
```

## Troubleshooting

### Issue: "marimo: command not found"

```bash
# Make sure conda environment is activated
conda activate marimo-env

# Verify installation
which marimo
```

### Issue: Can't access proxy URL

**Check jupyter-server-proxy:**
```bash
jupyter serverextension list
# Should show: jupyter_server_proxy enabled
```

**If not enabled:**
```bash
jupyter serverextension enable --py jupyter_server_proxy
```

### Issue: Port already in use

```bash
# Use different port
marimo edit --port 8889

# Then access via: proxy/8889/
```

### Issue: Kernel dies when loading large data

```bash
# Increase memory in SageMaker Studio instance
# Go to: File → Shut Down Kernel
# Then: File → Change Instance Type
# Select larger instance (e.g., ml.t3.xlarge)
```

## Cost Optimization

### SageMaker Studio Lab
- **Cost: $0** (completely free!)
- **Limits**: 12 hours of continuous runtime
- **Perfect for**: Learning, demos, development

### SageMaker Studio
- **ml.t3.medium**: ~$0.05/hour
- **ml.t3.large**: ~$0.10/hour
- **ml.m5.xlarge**: ~$0.23/hour

**Best practices:**
1. Stop instances when not in use
2. Use Studio Lab for development
3. Use Studio for production/longer sessions
4. Set up auto-shutdown

### Auto-Shutdown Script

```bash
# Create idle shutdown script
cat > ~/auto-shutdown.sh << 'EOF'
#!/bin/bash
# Shutdown after 2 hours of idle time

IDLE_TIME=7200  # 2 hours in seconds

while true; do
    # Check for running kernels
    KERNELS=$(jupyter kernelspec list 2>/dev/null | grep -v Available | wc -l)
    
    if [ $KERNELS -le 1 ]; then
        # No active kernels, shutdown
        echo "No active kernels, shutting down..."
        # SageMaker Studio specific shutdown
        # (implementation varies by setup)
        break
    fi
    
    sleep 300  # Check every 5 minutes
done
EOF

chmod +x ~/auto-shutdown.sh
```

## Advanced: Persistent Setup with Lifecycle Configuration

If you want marimo to be automatically available (instead of manual setup), you can use SageMaker Studio Lifecycle Configurations.

### Create Lifecycle Script

```bash
#!/bin/bash
set -e

# Install into default conda environment
conda activate studio

# Install marimo and dependencies
pip install marimo jupyter-server-proxy
pip install boto3 pandas numpy plotly altair scikit-learn

# Create start script
cat > /home/sagemaker-user/start-marimo.sh << 'EOFSCRIPT'
#!/bin/bash
conda activate studio
marimo edit --host 0.0.0.0 --port 8888
EOFSCRIPT

chmod +x /home/sagemaker-user/start-marimo.sh

echo "Marimo setup complete!"
```

### Attach to Studio

```bash
# Using AWS CLI
aws sagemaker create-studio-lifecycle-config \
  --studio-lifecycle-config-name marimo-setup \
  --studio-lifecycle-config-content file://lifecycle-script.sh \
  --studio-lifecycle-config-app-type JupyterServer

# Attach to domain (requires domain ID)
aws sagemaker update-domain \
  --domain-id <your-domain-id> \
  --default-user-settings \
    JupyterServerAppSettings={
      LifecycleConfigArns=[
        "arn:aws:sagemaker:region:account:studio-lifecycle-config/marimo-setup"
      ]
    }
```

## Comparison: Manual vs Lifecycle Config

| Aspect | Manual Setup | Lifecycle Config |
|--------|--------------|------------------|
| **Setup Time** | 5 minutes | 30 minutes (one-time) |
| **Availability** | Per session | Always available |
| **Flexibility** | Easy to modify | Requires redeployment |
| **Cost** | $0 extra | $0 extra |
| **Best For** | Individual use | Team/production |

## Next Steps

1. **Start Simple**: Use Studio Lab (free) or manual setup in Studio
2. **Try Examples**: Run the sample notebooks from this repo
3. **Build Your Analysis**: Adapt examples for your mobile sensing data
4. **Scale Up**: Move to lifecycle configs when you're ready

## Additional Resources

- **Scott's Original Guide**: https://github.com/scttfrdmn/aws-marimo
- **Marimo Docs**: https://docs.marimo.io
- **SageMaker Studio**: https://docs.aws.amazon.com/sagemaker/latest/dg/studio.html
- **Studio Lab**: https://studiolab.sagemaker.aws

## Credits

This guide is based on Scott Friedman's excellent work at:
https://github.com/scttfrdmn/aws-marimo

The simplified approach is proven to work and is much easier than complex infrastructure-as-code deployments for getting started.
