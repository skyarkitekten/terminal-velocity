"""Tool implementations for Terminal Velocity agents.

This package contains all tool implementations that agents can invoke.
Tools are functions that perform specific actions (e.g., API calls, data processing).

Example:
    Write a simple tool using the Tool base class:

    >>> from tools import Tool
    >>> tool = Tool(name="fetch_package", description="Fetch package info")
"""

__version__ = "0.1.0"
__all__ = ["Tool", "BaseTool"]

from typing import Any, Dict, Optional


class BaseTool:
    """Base class for all tools in Terminal Velocity.

    Tools are functions that agents can invoke to perform actions.
    Tools should be deterministic, testable, and well-documented.
    """

    def __init__(
        self,
        name: str,
        description: str,
        input_schema: Optional[Dict[str, Any]] = None,
    ) -> None:
        """Initialize a base tool.

        Args:
            name: Tool identifier
            description: Human-readable description of what the tool does
            input_schema: JSON schema defining required input parameters
        """
        self.name = name
        self.description = description
        self.input_schema = input_schema or {}

    def invoke(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute the tool.

        Args:
            input_data: Input parameters matching the input_schema

        Returns:
            Result dictionary from the tool execution
        """
        raise NotImplementedError("Subclasses must implement invoke()")


class Tool(BaseTool):
    """Standard tool for Terminal Velocity.

    Inherits from BaseTool and provides default implementation.
    """

    def invoke(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute the tool.

        Args:
            input_data: Input parameters matching the input_schema

        Returns:
            Result dictionary from the tool execution
        """
        # Placeholder implementation
        return {
            "tool": self.name,
            "status": "not_implemented",
            "message": "Tool invoke method must be implemented by subclass",
        }
