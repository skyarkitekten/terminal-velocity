"""Template for creating a custom Agent.

Copy this file and rename it to create your own agent:
    cp agent.template.py my_agent.py

Then implement the invoke() method with your agent logic.
"""

from typing import Any, Dict

from agents import BaseAgent


class MyCustomAgent(BaseAgent):
    """Example custom agent for Terminal Velocity.

    TODO: Replace this with your agent's actual description.
    """

    def __init__(self, name: str = "my_agent", **kwargs: Any) -> None:
        """Initialize the custom agent.

        Args:
            name: Agent name
            **kwargs: Additional arguments passed to BaseAgent
        """
        instructions = """You are a helpful agent that assists with package delivery.

Respond to user requests by:
1. Understanding the task
2. Breaking it into steps
3. Using available tools to complete each step
4. Summarizing the result
        """
        super().__init__(name=name, instructions=instructions, **kwargs)

    def invoke(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Invoke the agent.

        Args:
            input_data: Dictionary containing:
                - 'user_input' (str): The user's request
                - 'context' (dict, optional): Additional context

        Returns:
            Dictionary with:
                - 'status': 'success' or 'error'
                - 'result': The agent's response or error message
                - 'metadata': Optional metadata about the execution
        """
        # TODO: Implement your agent logic here
        user_input = input_data.get("user_input", "")

        return {
            "status": "success",
            "agent": self.name,
            "user_input": user_input,
            "result": "TODO: Implement agent logic",
            "metadata": {
                "model": self.model,
                "tools_used": [],
            },
        }


if __name__ == "__main__":
    # Example usage
    agent = MyCustomAgent()
    result = agent.invoke({"user_input": "What is package delivery?"})
    print(result)
