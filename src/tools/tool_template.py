"""Template for creating a custom Tool.

Copy this file and rename it to create your own tool:
    cp tool.template.py my_tool.py

Then implement the invoke() method with your tool's logic.
"""

from typing import Any, Dict

from tools import BaseTool


class MyCustomTool(BaseTool):
    """Example custom tool for Terminal Velocity agents.

    TODO: Replace this with your tool's actual description and functionality.
    """

    def __init__(
        self,
        name: str = "my_tool",
        description: str = "A custom tool for Terminal Velocity",
        **kwargs: Any,
    ) -> None:
        """Initialize the custom tool.

        Args:
            name: Tool name
            description: Human-readable description
            **kwargs: Additional arguments passed to BaseTool
        """
        # Define the input schema for this tool
        input_schema = {
            "type": "object",
            "properties": {
                "param1": {
                    "type": "string",
                    "description": "First parameter",
                },
                "param2": {
                    "type": "number",
                    "description": "Second parameter",
                },
            },
            "required": ["param1"],
        }

        super().__init__(
            name=name,
            description=description,
            input_schema=input_schema,
            **kwargs,
        )

    def invoke(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute the tool.

        Args:
            input_data: Dictionary containing tool parameters

        Returns:
            Dictionary with:
                - 'status': 'success' or 'error'
                - 'result': The tool's output or error message
                - 'metadata': Optional metadata about the execution
        """
        # TODO: Implement your tool logic here
        param1 = input_data.get("param1", "")
        param2 = input_data.get("param2", None)

        return {
            "status": "success",
            "tool": self.name,
            "input": {
                "param1": param1,
                "param2": param2,
            },
            "result": "TODO: Implement tool logic",
            "metadata": {
                "description": self.description,
            },
        }


if __name__ == "__main__":
    # Example usage
    tool = MyCustomTool()
    result = tool.invoke({
        "param1": "test_value",
        "param2": 42,
    })
    print(result)
