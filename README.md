# Terminal Velocity

Terminal Velocity is a reference implementation that applies GitOps principles to building and deploying agents to Microsoft Foundry. The project uses package delivery as the business domain because, hey, we are distributing things from a terminal, right?

## Philosophy

GitOps uses Git as the single source of truth for the entire system: infrastructure, application code, configuration, and deployment processes. By using Git, we can leverage its powerful version control capabilities to track changes, collaborate with teams, and ensure that the desired state of the system is always defined in a clear and auditable way. See the [gitops documentation](./docs/gitops/README.md) for more details.

When building agentic applications, it is critical to maintain a product mindset and treat the system as one under constant development and improvement rather than a one-and-done project. This means prioritizing maintainability, observability, and extensibility from the start, and continuously iterating on the implementation based on feedback and changing requirements. Internal and external forces will cause agent performance and requirements to evolve, so the system must be designed to adapt and improve over time. This concept is referred to as "Hill Climbing" in the [agentic development documentation](./docs/agentic-development/README.md).

## Features

- **Declarative Configuration**: All infrastructure and application configurations are defined in Git, ensuring a clear and auditable history of changes.
- **Automated Deployments**: Changes to the Git repository trigger automated deployment processes, ensuring that the system is always in the desired state.
- **Observability**: The system includes monitoring and logging capabilities to provide visibility into the deployment process and the state of the system.
- **Extensibility**: The implementation is designed to be easily extended and customized to fit different use cases and environments.

## Architecture

## Getting Started

## Documentation

For detailed documentation on how to set up and use Terminal Velocity, please refer to the [docs](./docs) directory.

## Contributing

We welcome contributions to Terminal Velocity! Please follow these steps to contribute:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Commit your changes with clear and descriptive messages.
4. Push your changes to your forked repository.
5. Open a pull request against the main repository.

Please ensure that your code follows the project's coding standards and includes appropriate tests.
