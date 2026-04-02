# Agentforce Agent Script Implementation Guide

## Purpose

This guide replaces the draft in `Learning.MD` with an implementation path that is aligned to current Salesforce Agentforce docs and official sample recipes.

It is written for a free Salesforce Developer Edition org plus this local DX project.

## Short Review of the Existing POC

The current POC is directionally good, but parts of it should not be treated as production-ready or syntax-correct without revision.

### What is correct

- Agent Script is a hybrid of deterministic logic (`->`) and prompt instructions (`|`).
- `start_agent` is the entry point on every turn.
- Variables are the right way to preserve state across turns.
- Topic transitions and action chaining are core patterns.
- Flow-backed actions and prompt-template-backed actions are valid approaches.

### What needs correction

1. The variable syntax in `Learning.MD` is not current Agent Script syntax.
   Current examples use declarations like:

```agentscript
variables:
   customer_email: mutable string = ""
   is_verified: mutable boolean = False
```

2. Actions are topic-scoped, not a shared top-level `actions:` block for all topics.
   Official docs state that topics define their own actions and topics do not share them.

3. A service agent usually needs `default_agent_user` in `config`.
   This matters for live preview and published execution.

4. Setup order matters.
   Current Salesforce docs say Data 360 must be provisioned before enabling Einstein generative AI and Agentforce.

5. Testing guidance in the draft is too loose.
   Current docs say Agentforce Testing Center / automated agent testing is sandbox-only. In a free Developer Edition org, use Builder preview or Agentforce DX preview first.

6. Knowledge-grounding details are incomplete.
   The validated prompt-template pattern is to target `generatePromptResponse://<PromptTemplateDeveloperName>` and map prompt inputs as `"Input:<apiName>"`.

## What I Would Implement First

For a free org learning path, I would build this in two phases:

1. A deterministic **Order Status** agent to learn:
   - `start_agent`
   - variables
   - topic routing
   - guardrails
   - Flow actions

2. A separate **Knowledge Q&A** agent to learn:
   - prompt-template actions
   - grounded responses
   - knowledge-focused topic design

Do not start by mixing everything into one large agent. Learn the execution model first.

## Recommended Build Path

### Phase 1: Order Status Learning Agent

Business goal: a customer can ask for order help, but the agent must collect an email and an order number before it can check status.

This is the best first project because it teaches deterministic control and state without depending on Data Library setup.

### Phase 2: Knowledge Q&A Learning Agent

Business goal: the agent answers policy / FAQ questions using a Prompt Template backed by grounded data.

This is the best second project because it teaches prompt-template actions and knowledge grounding separately from transactional workflow logic.

## Environment Setup

### In Salesforce

1. Create or use a Salesforce Developer Edition org that includes Agentforce and Data 360.
2. In Setup, provision Data 360 first if it is not already available.
3. Turn on Einstein in `Einstein Setup`.
4. Enable Agentforce in `Agentforce Agents`.

### In VS Code / DX

1. Install Salesforce CLI.
2. Install Salesforce Extensions for VS Code.
3. Install the Agentforce DX VS Code extension.
4. Authorize the org from this DX project.
5. Run `sf search` and search for `agent` to confirm the CLI commands available in your installed version.

Relevant workflow from current docs:

- Generate an authoring bundle
- Edit the `.agent` file in `aiAuthoringBundles/<bundle-api-name>/`
- Publish the authoring bundle
- Preview in simulated mode first
- Preview in live mode after flows / templates exist

## Repo Shape You Should Expect

After generating an agent, expect metadata like this:

```text
force-app/main/default/aiAuthoringBundles/<Bundle_API_Name>/
  <Bundle_API_Name>.agent
  <Bundle_API_Name>.bundle-meta.xml
```

Your current repo does not yet contain `aiAuthoringBundles`, so that is the first metadata you should create.

## Build 1: Order Status Agent

### Supporting Salesforce asset

Create an autolaunched Flow named `Get_Order_Status`.

Suggested Flow contract:

- Input: `order_id` (`Text`)
- Output: `status` (`Text`)
- Optional output: `error_message` (`Text`)

For learning, the Flow can use a simple Assignment or Decision and return mock statuses such as `Processing`, `Shipped`, or `Delivered`.

### Agent Script example

This is the implementation shape I would use first:

```agentscript
system:
   instructions: "You are a customer support agent for Acme. Be concise and do not reveal internal implementation details."
   messages:
      welcome: "Hi, I can help with order status."
      error: "Something went wrong. Please try again later."

config:
   developer_name: "Acme_Order_Status_Agent"
   agent_label: "Acme Order Status Agent"
   description: "Collects required information and checks order status."
   agent_type: "AgentforceServiceAgent"
   default_agent_user: "REPLACE_WITH_REAL_USER"

variables:
   customer_email: mutable string = ""
      description: "Customer email used for verification."

   order_id: mutable string = ""
      description: "Order number supplied by the customer."

   is_verified: mutable boolean = False
      description: "Whether the customer has provided the required identity detail."

   order_status: mutable string = ""
      description: "Latest order status returned by the order lookup action."

start_agent topic_selector:
   description: "Route the conversation to the best topic."
   reasoning:
      instructions: |
         Select the tool that best matches the user's message and conversation history. If unclear, make your best guess.
      actions:
         go_to_order_help: @utils.transition to @topic.order_help
            description: "Use for order status, order lookup, shipment status, or tracking questions."

topic order_help:
   description: "Collects required details and helps with order status."

   reasoning:
      instructions: ->
         if @variables.customer_email == "":
            | Ask the user for the email address associated with the order.

         if @variables.customer_email != "":
            set @variables.is_verified = True

         if @variables.is_verified == True and @variables.order_id == "":
            | Ask the user for the order number.

         if @variables.is_verified == True and @variables.order_id != "" and @variables.order_status == "":
            | Use {!@actions.lookup_order_status} to get the latest order status.

         if @variables.order_status != "":
            | Tell the user the order status is {!@variables.order_status}.
            | Ask whether they need anything else.

      actions:
         lookup_order_status: @actions.lookup_order_status
            with order_id = ...
            set @variables.order_id = @inputs.order_id
            set @variables.order_status = @outputs.status

   actions:
      lookup_order_status:
         description: "Look up the order status for a provided order number."
         inputs:
            order_id: string
               description: "Customer order number"
               is_required: True
         outputs:
            status: string
               description: "Current order status"
         target: "flow://Get_Order_Status"
```

### Why this version is better than the draft

- It uses current variable declaration style.
- It keeps the action inside the topic that uses it.
- It uses `reasoning.actions` to expose the tool and topic `actions` to define the executable.
- It relies on the official `flow://...` action pattern.
- It starts with one topic and one action, which is easier to debug.

## Build 2: Knowledge Q&A Agent

### Supporting Salesforce assets

1. Create grounded knowledge content in your org.
2. Create a Prompt Template, for example `Knowledge_Search_Template`.
3. Define a prompt input such as `user_query`.
4. Configure the template to use grounded data.

Note:
- Current docs and help content support grounded knowledge with Agentforce Data Libraries / RAG.
- If your free org exposes only part of the knowledge-grounding feature set, keep this build focused on Prompt Template action wiring first.

### Agent Script example

```agentscript
system:
   instructions: "You are a support assistant. Answer only from approved knowledge and say when the answer is not available."
   messages:
      welcome: "Hi, I can answer questions from our approved knowledge."
      error: "I couldn't search the knowledge source."

config:
   developer_name: "Acme_Knowledge_Agent"
   agent_label: "Acme Knowledge Agent"
   description: "Answers user questions using a prompt-template action."
   agent_type: "AgentforceServiceAgent"
   default_agent_user: "REPLACE_WITH_REAL_USER"

start_agent topic_selector:
   description: "Route questions to the knowledge topic."
   reasoning:
      instructions: |
         Select the tool that best matches the user's message and conversation history. If unclear, make your best guess.
      actions:
         go_to_knowledge: @utils.transition to @topic.knowledge_help
            description: "Use for FAQ, policy, process, and knowledge-base questions."

topic knowledge_help:
   description: "Answers questions with grounded knowledge."

   reasoning:
      instructions: ->
         | Use {!@actions.search_knowledge} to answer the user's question.
         | If the answer is not grounded in the returned result, say you do not know.

      actions:
         search_knowledge: @actions.search_knowledge
            with "Input:user_query" = ...

   actions:
      search_knowledge:
         description: "Search approved knowledge and generate a grounded answer."
         inputs:
            "Input:user_query": string
               description: "The user's question"
               is_required: True
         outputs:
            promptResponse: string
               description: "Grounded response from the prompt template."
               is_used_by_planner: True
               is_displayable: True
         target: "generatePromptResponse://Knowledge_Search_Template"
```

## Testing Strategy

### In a free Developer Edition org

Use:

- Agentforce Builder preview
- Agentforce DX preview in VS Code
- Simulated mode first
- Live mode after you deploy the Flow / Prompt Template dependencies

Do not assume Testing Center is available for this path. Current testing docs say automated agent testing is sandbox-only.

### What to test for the Order Status agent

1. User asks for order status without email.
   Expected: agent asks for email.

2. User provides email but no order number.
   Expected: agent asks for order number.

3. User provides order number after email.
   Expected: agent calls the Flow action and returns status.

4. User asks a follow-up question in the same session.
   Expected: variables persist and routing still starts at `start_agent`.

### What to inspect when debugging

- Selected topic
- Variable changes
- Tools exposed to the LLM
- Action inputs and outputs
- Final resolved prompt

Current official debug guidance points to:

- Builder Interaction Summary / Trace
- Agentforce DX Agent Tracer
- JSON trace export

## Practical Implementation Notes

### Keep the first agent intentionally small

Do not add:

- multiple business processes
- escalation
- knowledge grounding
- Apex integrations
- multi-step action callbacks

until the one-topic Flow-backed version is stable.

### Use deterministic state for required inputs

If something is mandatory before an agent can proceed, track it in variables and gate the next step with `if` conditions. Do not rely on the LLM to remember the rule on its own.

### Separate transactional and knowledge behaviors

Order lookup and knowledge Q&A should start as separate agents or at least separate topics. Mixing them too early makes routing and debugging harder.

## Recommended Source List

Primary sources used for this guide:

- Agent Script overview: https://developer.salesforce.com/docs/ai/agentforce/guide/agent-script.html
- Agent Script overview: https://developer.salesforce.com/docs/einstein/genai/guide/agent-script.html
- Agent Script blocks: https://developer.salesforce.com/docs/einstein/genai/guide/ascript-blocks.html
- Agent Script flow of control: https://developer.salesforce.com/docs/einstein/genai/guide/ascript-flow.html
- Agent Script variables pattern: https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-patterns-variables.html
- Agent Script reasoning instructions: https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-instructions.html
- Agent Script actions reference: https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-ref-actions.html
- Agentforce DX setup: https://developer.salesforce.com/docs/einstein/genai/guide/agent-dx-set-up-env.html
- Generate authoring bundle: https://developer.salesforce.com/docs/einstein/genai/guide/agent-dx-nga-authbundle.html
- Publish authoring bundle: https://developer.salesforce.com/docs/einstein/genai/guide/agent-dx-nga-publish.html
- Preview and debug: https://developer.salesforce.com/docs/einstein/genai/guide/agent-dx-nga-preview.html
- Agent testing overview: https://developer.salesforce.com/docs/einstein/genai/guide/testing-api-get-started.html
- Salesforce sample recipes overview: https://developer.salesforce.com/sample-apps/agent-script-recipes/getting-started/overview
- Prompt template action recipe: https://developer.salesforce.com/sample-apps/agent-script-recipes/action-configuration/prompt-template-actions
- Variable management recipe: https://developer.salesforce.com/sample-apps/agent-script-recipes/language-essentials/variable-management
- Multi-topic recipe: https://developer.salesforce.com/sample-apps/agent-script-recipes/architectural-patterns/multi-topic-navigation
- Safety / guardrails recipe: https://developer.salesforce.com/sample-apps/agent-script-recipes/architectural-patterns/safety-and-guardrails
- New Developer Edition with Agentforce and Data Cloud: https://developer.salesforce.com/blogs/2025/03/introducing-the-new-salesforce-developer-edition-now-with-agentforce-and-data-cloud

## Bottom Line

If the goal is to learn Agent Script properly in a free org, the right sequence is:

1. Generate an Agentforce authoring bundle.
2. Build a small Flow-backed order-status agent first.
3. Preview and debug it in simulated mode, then live mode.
4. Build a second prompt-template-backed knowledge agent.
5. Only after both patterns work, combine them into a broader business agent.
