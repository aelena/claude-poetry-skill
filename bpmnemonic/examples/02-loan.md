# Example 2: Loan application → specs.md

A more realistic process: two pools (customer + bank), three lanes inside the bank, multiple gateways, message flows for the integration boundary. Showing the spec output only — at this size the PRD would be a separate exercise focused on the customer-facing pool.

## What the diagram contains

- **Pool: Customer** — one lane (Applicant)
  - Start event: "Application needed"
  - User task: "Submit application via portal"
  - Receive task: "Receive decision"
  - End event: "Decision received"
- **Pool: Bank** — three lanes (Intake Officer, Underwriter, Branch Manager)
  - Receive task: "Receive application" (Intake Officer)
  - Service task: "Pull credit report" (Intake Officer)
  - User task: "Review credit and risk" (Underwriter)
  - Exclusive gateway: "Risk acceptable?" (Underwriter)
  - User task: "Approve loan" (Branch Manager) — only on the yes branch
  - Send task: "Send approval" (Branch Manager)
  - Send task: "Send rejection" (Underwriter) — on the no branch
  - End event: "Loan approved"
  - End event: "Loan rejected"
- **Boundary event:** 5-business-day timer on "Review credit and risk" → goes to "Send delay notification" → loops back to review
- **Message flow:** "Submit application via portal" (Customer) → "Receive application" (Bank)
- **Message flow:** "Send approval" / "Send rejection" (Bank) → "Receive decision" (Customer)

## Generated `specs.md`

```markdown
# Loan Application Processing

> Technical specification generated from `loan-application.bpmn`.
> Source process ids: `Process_Customer`, `Process_Bank`

## 1. Overview

A two-pool process in which a customer submits a loan application via a
portal and the bank evaluates it through three internal roles: an intake
officer who pulls credit data, an underwriter who assesses risk, and a
branch manager who signs off on approvals. Decisions (approval or
rejection) are communicated back to the customer.

## 2. Actors and roles

### Customer pool
- **Applicant** — the customer applying for a loan

### Bank pool
- **Intake Officer** — receives applications and pulls credit reports
- **Underwriter** — reviews credit data, assesses risk, makes the
  primary decision and handles rejections
- **Branch Manager** — signs off on approved loans before they are
  communicated to the customer

## 3. Triggers

- **Customer side:** *Application needed* — the customer decides they
  want to apply for a loan
- **Bank side:** *Application received* — fires when a message arrives
  from the customer pool

## 4. Main flow (happy path)

### Customer pool

1. **Applicant** submits the application via the bank's portal.
   <!-- from bpmn:userTask id="Task_Submit" -->
2. **Applicant** waits to receive the decision.
   <!-- from bpmn:receiveTask id="Task_ReceiveDecision" -->
3. The customer process ends in **Decision received**.

### Bank pool

1. **Intake Officer** receives the application.
   <!-- from bpmn:receiveTask id="Task_Receive" -->
2. **Intake Officer** pulls the credit report (system call).
   <!-- from bpmn:serviceTask id="Task_PullCredit" -->
3. **Underwriter** reviews credit and risk.
   <!-- from bpmn:userTask id="Task_Review" -->
4. **Underwriter** evaluates the *Risk acceptable?* gate.
   <!-- from bpmn:exclusiveGateway id="Gateway_Risk" -->
5. **Branch Manager** approves the loan.
   <!-- from bpmn:userTask id="Task_Approve" -->
6. **Branch Manager** sends the approval message to the customer.
   <!-- from bpmn:sendTask id="Task_SendApproval" -->
7. The bank process ends in **Loan approved**.

## 5. Alternative flows

### 5.1 Risk not acceptable (after step 4 in the bank pool)

1. **Underwriter** sends the rejection message to the customer.
   <!-- from bpmn:sendTask id="Task_SendRejection" -->
2. The bank process ends in **Loan rejected**.

## 6. Exception flows

### 6.1 Underwriter review timeout (5 business days)

If the **Underwriter** has not completed *Review credit and risk* within
5 business days, a boundary timer event fires:

1. The system sends a delay notification to the customer.
   <!-- from bpmn:boundaryEvent id="Boundary_Timeout", non-interrupting -->
2. The review task continues; the underwriter can still complete it.

This is a **non-interrupting** boundary event — the original task is
not cancelled. It exists to keep the customer informed.

## 7. Integration points

| From | To | Message | Direction | Notes |
|---|---|---|---|---|
| Customer portal | Bank intake | LoanApplication | request | Initiated by customer; carries applicant data and requested amount |
| Bank manager | Customer portal | ApprovalNotification | response | Carries approved amount, terms, and next steps |
| Bank underwriter | Customer portal | RejectionNotification | response | Carries reason for rejection |

## 8. Data contracts

### 8.1 LoanApplication

- **Created at:** Customer step 1 (*Submit application via portal*)
- **Read by:** Bank steps 1–3 (Receive, PullCredit, Review)
- **Schema:** [needs definition]

### 8.2 CreditReport

- **Created at:** Bank step 2 (*Pull credit report*)
- **Read by:** Bank step 3 (*Review credit and risk*)
- **Schema:** [needs definition; depends on credit bureau API]

### 8.3 LoanDecision (approval or rejection)

- **Created at:** Bank step 6 or 5.1
- **Read by:** Customer step 2
- **Schema:** [needs definition; should include outcome, amount, terms or reason]

## 9. End states

### Customer pool
- **Decision received** — the applicant has received either an approval or a rejection

### Bank pool
- **Loan approved** — happy path, approval sent to customer
- **Loan rejected** — alternative path, rejection sent to customer

## 10. Acceptance criteria

- **Given** a complete application,
  **when** the underwriter rates the risk as acceptable and the branch manager signs,
  **then** the customer receives an approval and the bank process ends in **Loan approved**.
- **Given** a complete application,
  **when** the underwriter rates the risk as not acceptable,
  **then** the customer receives a rejection and the bank process ends in **Loan rejected**.
- **Given** an underwriter review in progress,
  **when** 5 business days pass without completion,
  **then** the customer receives a delay notification and the review continues uninterrupted.

## 11. Open questions

- **What constitutes "acceptable risk"?** The gateway condition is not
  formalized in the diagram. There is likely a separate underwriting
  policy doc that should be referenced here.
- **What happens if the credit pull fails?** The service task has no
  boundary error event in the diagram. This is a likely gap.
- **Schemas for LoanApplication, CreditReport, and LoanDecision are
  not defined.** These need to be specified before implementation.
- **Branch manager rejection?** The diagram only shows the underwriter
  rejecting. What if the branch manager refuses to sign an
  underwriter-approved loan? Currently no path.

---

*Generated by `bpmnemonic`. Re-run after diagram changes to keep this in sync.*
```

## Why this example matters

This is the kind of diagram where the spec actively earns its keep: three lanes, two pools, an integration boundary, a non-interrupting timer, and four open questions that the diagram alone doesn't make obvious. Pulling those into prose means a reviewer can spot them in two minutes instead of clicking through every gateway.
