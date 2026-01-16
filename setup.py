#!/usr/bin/env python3
"""
OSRP - Open Sensing Research Platform
Setup configuration for pip installation
"""

from setuptools import setup, find_packages
import os

# Read long description from README
with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

# Read requirements
with open("requirements.txt", "r", encoding="utf-8") as fh:
    requirements = [line.strip() for line in fh if line.strip() and not line.startswith("#")]

setup(
    name="osrp",
    version="0.1.0",
    author="OSRP Contributors",
    author_email="contact@osrp.io",
    description="Open Sensing Research Platform - Multi-modal mobile sensing for academic research",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/osrp-platform/osrp",
    project_urls={
        "Bug Tracker": "https://github.com/osrp-platform/osrp/issues",
        "Documentation": "https://docs.osrp.io",
        "Source Code": "https://github.com/osrp-platform/osrp",
        "Website": "https://osrp.io",
    },
    packages=find_packages(exclude=["tests*", "docs*", "examples*"]),
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Science/Research",
        "Topic :: Scientific/Engineering :: Information Analysis",
        "Topic :: Scientific/Engineering :: Medical Science Apps.",
        "License :: OSI Approved :: Apache Software License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Operating System :: OS Independent",
        "Environment :: Console",
    ],
    python_requires=">=3.11",
    install_requires=requirements,
    extras_require={
        "dev": [
            "pytest>=7.0",
            "pytest-cov>=4.0",
            "black>=23.0",
            "flake8>=6.0",
            "mypy>=1.0",
        ],
        "analysis": [
            "marimo>=0.9.0",
            "jupyter>=1.0",
            "plotly>=5.0",
            "scikit-learn>=1.3",
            "torch>=2.0",
            "opencv-python-headless>=4.8",
        ],
    },
    entry_points={
        "console_scripts": [
            "osrp=osrp.cli:main",
        ],
    },
    include_package_data=True,
    package_data={
        "osrp": [
            "templates/**/*",
            "infrastructure/**/*",
            "analysis/**/*",
        ],
    },
    zip_safe=False,
    keywords=[
        "digital phenotyping",
        "mobile sensing",
        "behavioral research",
        "wearables",
        "screenshots",
        "aws",
        "research platform",
        "marimo",
        "data science",
    ],
)
