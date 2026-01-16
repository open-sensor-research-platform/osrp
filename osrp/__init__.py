"""
OSRP - Open Sensing Research Platform
Complete multi-modal mobile sensing for academic research
"""

__version__ = "0.1.0"
__author__ = "OSRP Contributors"
__email__ = "contact@osrp.io"

# Import main classes for convenience
from .analysis.utils.data_access import OSRPData, DataAggregator

__all__ = [
    "OSRPData",
    "DataAggregator",
    "__version__",
]
