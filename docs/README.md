# Terminal Velocity Documentation

This documentation is structured as two main sections: **GitOps for Agents** and **Agentic Delivery Optimization**. These sections provide comprehensive guides and resources to help you understand and implement the concepts of terminal velocity in your projects.

## GitOps for Agents

This is the primary point of the reference implementation: demonstrating how to use GitOps principles to manage and deploy agents effectively. This section includes:

- **Agent Deployment:** Step-by-step guides on deploying agents using GitOps workflows.
- **Configuration Management:** Best practices for managing agent configurations through Git repositories.
- **Monitoring and Logging:** Techniques for monitoring agent performance and collecting logs efficiently.

## Agentic Delivery Optimization

This is a byproduct of the reference implementation, showcasing how to optimize the delivery of parcels through agentic services. This section covers:

- **Performance Tuning:** Strategies for improving the performance of agentic services.
- **Resource Management:** Techniques for efficient allocation and utilization of resources.
- **Scalability:** Best practices for scaling agentic services to handle increased demand.

## Getting Started

### Prerequisites

#### Accounts and Permissions

- **An active Azure subscription** with the Owner or Contributor + User Access Administrator roles at the subscription or resource group level (role assignments require elevated permission).
- **Foundry access** enabled in your subscription. In some tenants you may need to accept terms or request quota for Azure OpenAI.
- **Azure OpenAI quota** for the model you intend to deploy (e.g. gpt-4.1). Request this via the Azure portal under Quotas in Azure OpenAI Studio.

#### Tools

1. **Git:** Ensure you have Git installed on your machine to clone the repository and manage your contributions.
2. **Docker:** Install Docker to run the agentic services in a containerized environment.
3. **Terraform:** Install Terraform to manage infrastructure as code for deploying agentic services.
4. **Azure Account:** Set up an Azure account to deploy the agentic services to Microsoft Foundry.
5. **Azure CLI:** Install the Azure CLI to interact with Azure services from the command line.
6. **Code Editor:** Use a code editor like Visual Studio Code for editing configuration files and writing code. Additionally, consider code assistant CLIs like GitHub Copilot or Claude Code to enhance your coding experience.

### Clone the Repository

```bash
git clone https://github.com/skyarkitekten/terminal-velocity.git
cd terminal-velocity
```

### Installation
