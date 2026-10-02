"""Agent implementations for Terminal Velocity.

This package contains all agent implementations deployed to Microsoft Foundry.
Agents are autonomous systems that perform tasks using tools and reasoning.

Example:
    Write a simple agent using the Agent base class:

    >>> from agents import Agent
    >>> agent = Agent(name="my_agent", instructions="You help with package delivery")
"""

__version__ = "0.1.0"
__all__ = ["Agent", "BaseAgent"]

from typing import Any, Dict, List, Optional


class BaseAgent:
    """Base class for all agents in Terminal Velocity.

    Agents are autonomous systems that:
    - Receive instructions and context
    - Invoke tools to perform work
    - Return structured results
    """

    def __init__(
        self,
        name: str,
        instructions: str,
        tools: Optional[List[str]] = None,
        model: str = "gpt-4",
    ) -> None:
        """Initialize a base agent.

        Args:
            name: Agent identifier
            instructions: System instructions for the agent
            tools: Optional list of tool names the agent can invoke
            model: Model to use (default: gpt-4)
        """
        self.name = name
        self.instructions = instructions
        self.tools = tools or []
        self.model = model

    def invoke(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Invoke the agent with input data.

        Args:
            input_data: Input parameters for the agent

        Returns:
            Result dictionary from the agent execution
        """
        raise NotImplementedError("Subclasses must implement invoke()")


class Agent(BaseAgent):
    """Standard agent for Terminal Velocity.

    Inherits from BaseAgent and provides default implementation.
    """

    def invoke(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Invoke the agent with input data.

        Args:
            input_data: Input parameters for the agent

        Returns:
            Result dictionary from the agent execution
        """
        # Placeholder implementation
        return {
            "agent": self.name,
            "status": "not_implemented",
            "message": "Agent invoke method must be implemented by subclass",
        }
