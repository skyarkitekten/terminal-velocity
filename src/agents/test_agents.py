"""Test template for custom agents.

Copy this file to test_*.py or *_test.py to create tests for your agent.
"""


from agents import Agent


class TestBaseAgent:
    """Test BaseAgent class."""

    def test_agent_initialization(self) -> None:
        """Test that an agent can be initialized."""
        agent = Agent(
            name="test_agent",
            instructions="Test instructions",
            model="gpt-4",
        )

        assert agent.name == "test_agent"
        assert agent.instructions == "Test instructions"
        assert agent.model == "gpt-4"
        assert agent.tools == []

    def test_agent_with_tools(self) -> None:
        """Test agent initialization with tools."""
        tools = ["tool1", "tool2"]
        agent = Agent(
            name="test_agent",
            instructions="Test instructions",
            tools=tools,
        )

        assert agent.tools == tools

    def test_agent_invoke_not_implemented(self) -> None:
        """Test that base agent invoke returns placeholder response."""
        agent = Agent(
            name="test_agent",
            instructions="Test instructions",
        )

        result = agent.invoke({"test": "data"})

        assert result["status"] == "not_implemented"
        assert result["agent"] == "test_agent"


class TestCustomAgent:
    """Test custom agent implementations.

    TODO: Replace with tests for your specific agent.
    """

    def test_custom_agent_invoke(self) -> None:
        """Test invoking a custom agent."""
        agent = Agent(
            name="custom_agent",
            instructions="Test agent for custom functionality",
        )
        result = agent.invoke({"user_input": "test request"})

        assert result is not None
        assert isinstance(result, dict)
