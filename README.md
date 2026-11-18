# Subscription Quote Agent (Business Central 29.0)

A Business Central agent that:

1. **Prepares sales quotes priced on the contract start date.** Prices come from the sales price list lines valid on the customer subscription contract's start date, not on the quote date.
2. **Creates customer subscription contracts** in Microsoft's Subscription Billing app from a few inputs: customer, start date, license items and quantities.

## How it works

```
User or email text
      │  "Send to Agent" on a Subscription Agent Request
      ▼
Subscription Quote Agent (BC agent, runs as its own user)
      │  fills in the request: customer, start date, licenses
      │  runs "Create Quote" and, if asked, "Create Contract"
      ▼
Deterministic AL
  Create Quote     → Sales Quote with "Contract Start Date"
                     price lookup uses the start date (OnAfterFillBuffer)
                     Agreed Sub. Line Start Date = start date
  Create Contract  → Quote → Order → post shipment (Subscription Items: no stock, no invoice)
                     → subscriptions created → new Customer Subscription Contract
                     → lines assigned with CreateCustomerContractLinesFromServiceCommitments
```

The agent only fills in the request and runs two actions. Pricing and contract creation are plain AL, so they behave the same every time and can be tested.

Requests created with **Send to Agent** run without approval (`SetRequiresReview(false)`). Any other message, or a request that already has a contract, gets a Warning annotation, so BC asks a person to approve it first.

## Objects

| ID | Object | Purpose |
|---|---|---|
| 50100 | tableextension "Sales Header SQA" | `SQA Contract Start Date`, `SQA Request No.` |
| 50100 | pageextension "Sales Quote SQA" | Start date field, *Apply Contract Start Date Pricing*, *Create Subscription Contract* |
| 50100 | codeunit "Sub. Quote Pricing Mgt." | Price date subscriber, re-pricing, agreed start dates |
| 50101 | codeunit "Sub. Contract From Quote" | Quote → order → shipment → contract |
| 50110 | enum / table / pages "Sub. Agent Request…" | The request (inputs) and its lines |
| 50110 | codeunit "Sub. Agent Request Processor" | Create Quote, Create Contract, Send to Agent |
| 50120 | enumextension "Agent Metadata Provider" | Registers the agent type |
| 50121 | enumextension "Copilot Capability" | Registers the capability |
| 50120–50124 | Agent factory, metadata, task execution, install, setup | Agent SDK implementation |
| 50120 | table / page "SQA Agent Setup" | Agent setup (ConfigurationDialog) |
| 50125 | page "SQA Agent Role Center" + profile "SQA AGENT" | What the agent sees |
| 50100–50102 | permission sets SQA AGENT / USER / ADMIN | Agent, users, admins |
| Resources/Instructions.txt | | Agent instructions |
| test/ | Sub. Quote Pricing Test | Start-date pricing tests |

## Business Central setup

1. **License items:** Type = Non-Inventory, Subscription Option = **Subscription Item**.
2. **Subscription package** on each item, marked **Standard**, with a customer line: Invoicing via = Contract, Calculation Base Type = **Document Price** (so the start-date quote price carries into the subscription), Calculation Base % = 100, Billing Base Period, Billing Rhythm, Initial Term, Subsequent Term, Notice Period.
3. **Sales price lists** with future-dated lines (Starting Date) for the license items.
4. **Contract types** and Subscription Contract Setup as usual.
5. **Copilot & agent capabilities:** turn on the Subscription Quote Agent capability and set up agent billing.
6. Users: assign **SQA USER**. Admins: **SQA ADMIN** plus AGENT - ADMIN.
7. **Create the agent:** Agents → new → Subscription Quote Agent, choose the default contract type, activate.

## Build and deploy

1. Open the folder in VS Code with the AL extension.
2. In `app.json`, replace the placeholder id of the **Subscription Billing** dependency with the real one from your environment (Extension Management → Subscription Billing → App ID), then run *AL: Download symbols*.
3. Set your sandbox in `.vscode/launch.json` and publish (F5).
4. Run the tests in `test/` with the Test Tool.
5. When it works in the sandbox, deploy the .app to production as a per-tenant extension.

## Verify on 29.0 before go-live

This code was written without compiling against BC 29.0 symbols. Check these points first:

- [ ] Compile: the Agent SDK interfaces (`IAgentFactory`, `IAgentMetadata`, `IAgentTaskExecution`) may have members not shown in the docs. Generate a project with *AL: New Project → Agent* and compare the stubs. Remove `GetCopilotCapability` if the interface doesn't have it.
- [ ] `Price Calculation Buffer."Document Date"` is the date used for price list lookup (subscriber in `Sub. Quote Pricing Mgt.`). The two tests prove it.
- [ ] Subscription lines are added when the sales line is validated and then inserted from code, as in `AddQuoteLine`.
- [ ] `Customer Subscription Contract` has a `Description` field. If not, remove that line in `Sub. Contract From Quote`.
- [ ] Posting the shipment from code doesn't trigger UI dialogs.
- [ ] The Subscription Billing permission set name to add to **SQA AGENT**.

## Docs

- Agent SDK: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/ai/ai-agent-sdk-overview
- Agent tasks in AL: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/ai/ai-agent-sdk-tasks
- Sales with subscription lines: https://learn.microsoft.com/dynamics365/business-central/srb/sales/sales-service-commitments
- Customer subscription contracts: https://learn.microsoft.com/dynamics365/business-central/srb/working-with-contracts/customer-contracts
