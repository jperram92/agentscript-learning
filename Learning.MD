📜
AgentScript POC
53 sources
Agent Script is a specialized, human-readable language used to build sophisticated and predictable workflows within the Agentforce Builder platform. By merging deterministic logic with the reasoning power of Large Language Models, it allows developers to enforce business rules while maintaining conversational flexibility. The system utilizes structured blocks—such as config, variables, and topics—to manage data and define specific agent behaviors. Key features include action chaining, conditional branching, and topic transitions, which ensure tasks like identity verification or data fetching occur in a reliable sequence. Users can also implement filters and system overrides to dynamically control which tools are available and how the agent’s persona adapts to different contexts. Ultimately, this hybrid approach provides a robust framework for creating context-aware agents that do not rely solely on LLM interpretation for critical operations.

How do deterministic logic and LLM reasoning work together?
What are the key patterns for building reliable workflows?
Explain how to use variables and actions in scripts.
Today • 8:33 AM
Now build me a cmprehensive POC i can test using the demo/free org to learn how agentscript work and how i can learn to build out all the features
Ensure its referencng the official SF Link and content to explain how the POC wors
Make it useful for a business purpose but capable in the free demo org
https://www.salesforce.com/products/free-trial/developer/

Here is a comprehensive Proof of Concept (POC) for a Customer Service Order Management Agent. This POC demonstrates the core capabilities of Agent Script—Salesforce's domain-specific language for AI agents—by combining generative AI flexibility with strict, deterministic business rules (hybrid reasoning)
.
This use case ensures that a customer cannot check their order status until they have successfully verified their identity, showcasing state management, conditional routing, and action execution.
Step 1: Set Up Your Free Developer Org
Sign up for the new Salesforce Developer Edition (which includes Agentforce and Data Cloud) at your provided link: https://www.salesforce.com/products/free-trial/developer/
.
Enable Einstein: Go to Setup > Generative AI > Einstein Setup and toggle "Turn on Einstein"
.
Enable Agentforce: Go to Setup > Agent Studio > Agents and turn on the Agentforce toggle
.
Step 2: The Agent Script POC Code
You can build this agent using the Agentforce Builder (Canvas/Script view) or locally using VS Code with the Agentforce DX extension
.
Create a new Agent Script file (e.g., OrderManagementAgent.agent). Below is the complete, heavily commented code that you can copy and paste:
# ============================================
# 1. SYSTEM & CONFIGURATION
# ============================================
system:
  instructions: |
    You are a helpful customer service agent for Acme Corp.
    Always maintain a professional tone. Never reveal internal system names.
  messages:
    welcome: "Hello! I can help you check your order status. How can I assist you today?"
    error: "I'm sorry, I encountered an error. Let me connect you with a human agent."

config:
  developer_name: "Acme_Order_Agent"
  agent_label: "Acme Order Concierge"
  agent_type: "AgentforceServiceAgent"
  description: "An agent that verifies identity and checks order status."

# ============================================
# 2. STATE MANAGEMENT (VARIABLES)
# ============================================
variables:
  customer_email:
    type: string
    mutability: mutable
    default: ""
  is_verified:
    type: boolean
    mutability: mutable
    default: False
  order_status:
    type: string
    mutability: mutable
    default: ""

# ============================================
# 3. ENTRY POINT (START AGENT)
# ============================================
start_agent topic_selector:
  description: "Routes incoming messages to the appropriate topic."
  reasoning:
    instructions: ->
      | Analyze the customer's message and determine the best topic.
    actions:
      go_to_identity:
        @utils.transition to @topic.identity
        description: "Route to identity verification when the user needs to authenticate."
      go_to_orders:
        @utils.transition to @topic.order_management
        description: "Route to order management for order-related queries."

# ============================================
# 4. REQUIRED WORKFLOW: IDENTITY VERIFICATION
# ============================================
topic identity:
  description: "Verifies user identity via email address."
  reasoning:
    instructions: ->
      # If they are already verified, push them back to order management
      if @variables.is_verified == True:
        transition to @topic.order_management
      
      # If email is blank, use natural language prompt to ask for it
      if @variables.customer_email == "":
        | Ask the customer to provide their email address for verification.
      else:
        # In a real scenario, you'd run an action to send a code. 
        # Here we deterministically set them to verified for the POC.
        set @variables.is_verified = True
        | Thank the customer for verifying their email: {!@variables.customer_email}.
        | Ask for their Order ID.
        
  after_reasoning: ->
    # Post-processing hook: move them to order topic automatically once verified
    if @variables.is_verified == True:
      transition to @topic.order_management

# ============================================
# 5. CORE BUSINESS LOGIC: ORDER MANAGEMENT
# ============================================
topic order_management:
  description: "Enables users to look up order details and check status."
  reasoning:
    instructions: ->
      # Guard Clause: Force unverified users to the identity topic
      if @variables.is_verified == False:
        transition to @topic.identity
      
      | Help the customer with their order. 
      | Use the lookup_order tool to find their status.
      
      if @variables.order_status != "":
        | The customer's order status is: {!@variables.order_status}.
        | Ask if they need help with anything else.

    actions:
      lookup_order:
        @actions.get_order_details
        with order_id = ...

# ============================================
# 6. ACTION DEFINITIONS
# ============================================
actions:
  get_order_details:
    description: "Look up order information from Salesforce."
    inputs:
      order_id:
        type: string
        description: "The customer's order number"
        is_required: True
    outputs:
      status:
        type: string
        description: "The current status of the order"
    # Target points to a Salesforce Flow you would create in your org
    target: "flow://Get_Order_Status_Flow"
How This POC Teaches You Agent Script Features
This script acts as a functional sandbox to learn the primary mechanics of Salesforce Agentforce orchestration:
Hybrid Reasoning (-> vs |): Notice the -> operator switches the agent into procedural logic (executing rules top-to-bottom), while the | operator accumulates instructions into a prompt that is ultimately sent to the Large Language Model (LLM)
. This allows you to combine strict business rules with natural language processing.
State Management (Variables): LLMs are famously bad at remembering context perfectly. By explicitly declaring @variables.is_verified, you force the agent to reliably remember the customer's state across multiple conversation turns without relying on the LLM's memory
.
Required Topic Workflows (Guardrails): In the order_management topic, the instruction if @variables.is_verified == False: transition to @topic.identity is a deterministic guard clause. It physically prevents the LLM from ever revealing order data to an unauthenticated user
.
LLM Slot-Filling (...): In the lookup_order action call, with order_id = ... tells the LLM to intelligently extract the Order ID from the customer's natural chat messages and pass it into the action
.
Action Integration (target: "flow://..."): The get_order_details action defines how the agent talks to external systems or Salesforce data. You can easily build a simple Autolaunched Flow named Get_Order_Status_Flow in your free org that accepts an order_id and returns a status (like "Shipped")
.
Testing the POC in Your Free Org
Deploy your Flow: Create a simple Autolaunched Flow in Salesforce called Get_Order_Status_Flow that takes a text input and returns a text output.
Open Agentforce Builder: Navigate to your newly created agent in the Agentforce Studio
.
Use the Conversation Tracer: In the Agentforce Preview panel, start typing. Say, "I want to check my order status."
Watch the Logic Execute: You will see the agent refuse to check the order and ask for your email address. Once you provide the email, you can use the built-in Conversation Tracer (the "Trace" panel) to see a step-by-step log of how the Atlas Reasoning Engine classified your intent, evaluated the is_verified variable, executed the transition, and generated the LLM prompt
.
How do I create the Flow action for this POC?
Tell me more about using the Conversation Tracer to debug.
How can I add Data Cloud grounding to this agent?
Can you also create one which covers how to build out a check against a knowledge article?

Here is a comprehensive Proof of Concept (POC) for a Knowledge Retrieval Agent (Simple Q&A pattern). This POC demonstrates how to connect an Agentforce agent to unstructured data, such as knowledge articles or policy PDFs, using Retrieval Augmented Generation (RAG)
.
To make this work, the agent uses a Prompt Template Action that is "grounded" in a Salesforce Data Library
.
Step 1: Set Up Your Knowledge Data Library
Before writing the script, you must provide your free Developer org with the knowledge it needs:
In Salesforce Setup, create a new Data Library
.
Upload your Knowledge Articles or policy PDFs
. Behind the scenes, Data Cloud will automatically chunk, vector-embed, and index these documents so they are ready for the agent to search
.
Create a Prompt Template in Prompt Builder (e.g., named Knowledge_Search_Template) that accepts a user question as an input and uses your new Data Library as its grounding source
.
Step 2: The Knowledge Agent Script
Create a new Agent Script file (e.g., KnowledgeAgent.agent). Below is the code to configure your agent to route questions to your grounded prompt template
:
# ============================================
# 1. SYSTEM & CONFIGURATION
# ============================================
system:
  instructions: |
    You are a helpful support agent.
    Always base your answers strictly on the knowledge base. 
    Never make up information.
  messages:
    welcome: "Hello! I can answer your questions by searching our official knowledge articles. What would you like to know?"
    error: "I'm sorry, I encountered an error searching the knowledge base."

config:
  developer_name: "Acme_Knowledge_Agent"
  agent_label: "Acme FAQ Assistant"
  agent_type: "AgentforceServiceAgent"
  description: "An agent that answers questions using a Data Library."

# ============================================
# 2. ENTRY POINT (START AGENT)
# ============================================
start_agent topic_selector:
  description: "Routes incoming questions to the FAQ topic."
  reasoning:
    instructions: ->
      | Route the customer to the FAQ topic for any questions.
    actions:
      go_to_faq:
        @utils.transition to @topic.faq_support
        description: "Route here for general questions and information."

# ============================================
# 3. KNOWLEDGE TOPIC
# ============================================
topic faq_support:
  description: "Answers user questions using the knowledge base."
  reasoning:
    instructions: ->
      | When a user asks a question, use the search_kb action to find the answer.
      | Output the answer clearly to the user.
      | If the answer is not found in the search results, state that you do not know.
    actions:
      search_kb:
        @actions.knowledge_search
        with "Input:user_query" = ...

# ============================================
# 4. ACTION DEFINITION (PROMPT TEMPLATE)
# ============================================
actions:
  knowledge_search:
    description: "Searches the company knowledge base for answers."
    inputs:
      # Inputs map directly to the Prompt Template inputs
      "Input:user_query":
        type: string
        description: "The user's question"
        is_required: True
    outputs:
      # Prompt Template outputs are always a promptResponse string
      promptResponse:
        type: string
        description: "The grounded response generated by the prompt template."
        is_used_by_planner: True
        is_displayable: True
    # The target points to your Prompt Template developer name
    target: "generatePromptResponse://Knowledge_Search_Template"
How This POC Works
Simple Q&A Architecture: This script uses a focused "Single-topic pattern" designed explicitly for Q&A workflows
. All questions get routed seamlessly to the faq_support topic
.
LLM Slot-Filling (...): In the faq_support topic, with "Input:user_query" = ... commands the Large Language Model (LLM) to extract the user's actual question from the chat and dynamically pass it into your Prompt Template
.
Prompt Template Targets (generatePromptResponse://...): Unlike the previous POC that targeted a Flow, this action targets a Prompt Template
. The prompt template does the heavy lifting of executing a semantic search against your Data Library to generate a grounded, citable answer
.
Direct Display (is_displayable: True): By setting the promptResponse output to is_displayable: True and is_used_by_planner: True, the agent surfaces the generated knowledge article summary directly to the user without needing to store it in a temporary variable first
.
How do I set up a Data Library for grounding?
Can I use Apex to query Data Cloud for agents?
Show me how to test this using the Trace panel.
You need to expand on all this needs to be comprehensive so we can build thia via Codex

To comprehensively build these Agentforce Proof of Concepts (POCs) using Codex, you can leverage the open-source Salesforce Skills for Agentic Coding Tools (sf-skills) library. This community-powered library equips AI coding agents like the Codex CLI with specialized capabilities for Agent Script, Flow, Apex, and Prompt Templates
.
Here is the comprehensive guide on how to set up your environment, invoke the right skills, and prompt Codex to build out the entire architecture.
1. Set Up Codex with Salesforce Skills
Because Codex CLI is fully supported by the sf-skills framework, you can install the required toolset directly via standard Node package execution
.
Ensure you have Node.js 18+ installed, then run the following command in your terminal to install the skills for Codex
:
npx skills add Jaganpro/sf-skills
2. Activate the Relevant Agentic Skills
The sf-skills library contains 33 specific Salesforce skills
. When prompting Codex to build the POCs, you should explicitly invoke or rely on the following skills to ensure the generated code is accurate and adheres to best practices:
sf-ai-agentscript: The most critical skill for generating the .agent files. It understands the Agent Script DSL, hybrid reasoning patterns, and state management
.
sf-flow & sf-apex: Use these when asking Codex to build the backend logic (like the Get_Order_Status_Flow) that your agent actions will target. These skills include built-in scanners that grade the code against 110-point and 90-point scoring systems
.
sf-ai-agentforce: Use this to generate the metadata configurations for the agent and Prompt Templates
.
3. Leverage the LSP Auto-Fix Loop
Writing Agent Script requires strict adherence to whitespace and property-based syntax, which LLMs sometimes struggle with
.
By using the sf-ai-agentscript skill, Codex integrates directly with the Agent Script Language Server (LSP)
. When Codex attempts to write the .agent file:
Codex writes the file.
An automatic validation hook runs in ~500ms to check the syntax
.
If Codex makes a mistake (like mixing tabs and spaces, or misusing the -> operator), the LSP feeds the exact error back to Codex
.
Codex automatically attempts to fix the syntax error (up to 3 attempts) without you needing to intervene
.
4. Prompting Codex to Build the POCs
With the skills installed, you can use the following comprehensive prompts in Codex to generate the full POC architectures.
Prompting Codex for the Order Management Agent:
"Using the sf-ai-agentscript skill, generate an Agentforce Service Agent script named Coral_Cloud_Service_Agent. Define a start_agent block that routes to an identity topic and an order_management topic. Include mutable string variables for customer_email, verification_code, and a boolean for is_verified. Enforce a strict business rule where the order management topic transitions to the identity topic if is_verified is False. Also, use the sf-flow skill to generate the XML metadata for an Autolaunched Flow named Get_Order_Status_Flow that accepts an order_id string and returns a status string."
Prompting Codex for the Knowledge/Prompt Template Agent:
"Using the sf-ai-agentscript skill, build an FAQ agent that uses RAG. Create a faq_support topic that utilizes slot-filling (...) to capture the user's query. Define an action named knowledge_search that maps to a Prompt Template target (generatePromptResponse://Knowledge_Search_Template). Ensure the action output promptResponse is set to is_displayable: True and is_used_by_planner: True so the agent surfaces the summary directly to the user. Then, use the sf-ai-agentforce skill to generate the structural metadata for the underlying Prompt Template."
5. Validate the Deployment
Once Codex generates the .agent, .flow-meta.xml, and prompt template metadata files, you can instruct it to deploy the assets to your free Developer Edition org. You can tell Codex:
"Use the sf-deploy skill to validate and deploy these metadata changes to my sandbox/developer org
."
This comprehensive pipeline ensures Codex doesn't just guess the syntax—it uses official Salesforce Language Servers and community validation hooks to produce functional, enterprise-grade Agentforce components
.
How do I test the Knowledge search action?
Can you explain the difference between run and @utils.transition?
How can I add an external model using LLM Open Connector?
Include the information here for CLI
https://orgfarm-3e49880d2b-dev-ed.develop.lightning.force.com/lightning/n/devedapp__Welcome
james.perram.d5e8f2c9f9a0@agentforce.com
Password = Test123

Here is the expanded CLI setup and deployment guide incorporating your specific Agentforce Developer Edition org credentials. By connecting the Salesforce CLI (sf) to this org, the sf-skills library allows Codex to perform live validations, fetch real-time query plans, and deploy your Agentforce components directly
.
1. Authorize Your Specific Org via CLI
Before asking Codex to generate or deploy the Agent Script, you must authenticate your local environment with your specific org instance.
Run the following command in your terminal to initiate the web login flow, explicitly targeting your org's URL
:
sf org login web --instance-url https://orgfarm-3e49880d2b-dev-ed.develop.lightning.force.com --set-default --alias agentforce-demo
When the browser window opens, log in using the credentials you provided
:
Username: james.perram.d5e8f2c9f9a0@agentforce.com
Password: Test123
Click Allow when prompted to grant the Salesforce CLI access to your org
.
2. Set Up Codex with Salesforce Skills
With your org authorized, ensure Codex has the necessary Agentforce skills installed. In your terminal, run
:
npx skills add Jaganpro/sf-skills
Note: Because your CLI is now connected to your org, skills like sf-soql and sf-metadata will automatically use this connection to perform live schema validation and query plan analysis against your actual org data
.
3. Comprehensive Codex Prompts for Build & Deployment
Now that your environment is fully authenticated, you can use Codex to build and deploy the Proof of Concepts (POCs) directly to your org.
Prompt Codex to Build the Agent:
"Using the sf-ai-agentscript skill, generate the Agentforce Service Agent script for our Customer Service POC. Include the start_agent block, an identity topic, and an order_management topic. Use mutable variables to enforce a strict business rule where unverified users are deterministically routed to the identity topic. Also, use the sf-flow skill to generate the XML metadata for the Get_Order_Status_Flow."
Prompt Codex to Deploy to Your Org:
"Now that the .agent and Flow metadata files are generated, use the sf-deploy skill to validate and deploy these assets directly to my default org (agentforce-demo). Let me know if the deployment succeeds."
By setting the default org alias to agentforce-demo, the sf-deploy skill invoked by Codex will automatically target your specific orgfarm-3e49880d2b-dev-ed.develop.lightning.force.com instance, allowing you to test the agent immediately in the Agentforce Builder
.