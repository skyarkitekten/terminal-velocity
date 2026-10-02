"""Test template for custom tools.

Copy this file to test_*.py or *_test.py to create tests for your tool.
"""


from tools import Tool


class TestBaseTool:
    """Test BaseTool class."""

    def test_tool_initialization(self) -> None:
        """Test that a tool can be initialized."""
        tool = Tool(
            name="test_tool",
            description="Test tool description",
        )

        assert tool.name == "test_tool"
        assert tool.description == "Test tool description"
        assert tool.input_schema == {}

    def test_tool_with_schema(self) -> None:
        """Test tool initialization with input schema."""
        schema = {
            "type": "object",
            "properties": {"param": {"type": "string"}},
        }
        tool = Tool(
            name="test_tool",
            description="Test",
            input_schema=schema,
        )

        assert tool.input_schema == schema

    def test_tool_invoke_not_implemented(self) -> None:
        """Test that base tool invoke returns placeholder response."""
        tool = Tool(name="test_tool", description="Test")
        result = tool.invoke({"test": "data"})

        assert result["status"] == "not_implemented"
        assert result["tool"] == "test_tool"


class TestCustomTool:
    """Test custom tool implementations.

    TODO: Replace with tests for your specific tool.
    """

    def test_custom_tool_invoke(self) -> None:
        """Test invoking a custom tool."""
        tool = Tool(name="custom_tool", description="Custom tool")
        result = tool.invoke({"param": "value"})

        assert result is not None
        assert isinstance(result, dict)
