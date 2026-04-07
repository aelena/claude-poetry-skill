# Example 3: Order fulfillment with error and timer events

A process that exists primarily to handle exceptions. The "happy path" is short; most of the value of the diagram is in what goes wrong.

## What the diagram contains

- **Pool: Fulfillment Center**
  - Start event (message): "Order received"
  - Service task: "Reserve inventory"
    - Boundary error event "InventoryUnavailable" → Send task: "Notify customer of backorder" → End event: "Backordered"
  - Service task: "Charge payment"
    - Boundary error event "PaymentDeclined" → Send task: "Notify customer of payment failure" → End event: "Payment failed"
    - Boundary timer event (PT2H) → "Retry charge" → loops back
  - Service task: "Pack and ship"
    - Boundary error event "ShippingRefused" → "Manual investigation" (User task) → "Resolve" (User task) → loops back to Pack and ship
  - End event: "Order shipped"

## Generated `specs.md`

```markdown
# Order Fulfillment

> Technical specification generated from `order-fulfillment.bpmn`.
> Source process id: `Process_Fulfillment`

## 1. Overview

A linear three-step automation pipeline (reserve inventory → charge payment
→ pack and ship) wrapped with rich error and retry handling. The happy
path is straightforward; the value of this diagram is in the boundary
events, which formalize how each step degrades.

## 2. Actors and roles

- **Fulfillment system** — runs the three automated tasks
- **Operations agent** — handles the manual investigation when shipping is refused

## 3. Triggers

- **Order received** (start message event) — fires when an order message
  arrives from the upstream order-management system

## 4. Main flow (happy path)

1. **Fulfillment system** reserves inventory for the order.
   <!-- from bpmn:serviceTask id="Task_Reserve" -->
2. **Fulfillment system** charges the customer's payment method.
   <!-- from bpmn:serviceTask id="Task_Charge" -->
3. **Fulfillment system** packs and ships the order.
   <!-- from bpmn:serviceTask id="Task_Ship" -->
4. Process ends in **Order shipped**.

## 5. Alternative flows

None — there are no exclusive gateways in this diagram. All deviations
from the happy path are exceptions, handled in section 6.

## 6. Exception flows

### 6.1 Inventory unavailable (during step 1)

If reserving inventory fails with an `InventoryUnavailable` error:

1. The system sends a backorder notification to the customer.
   <!-- from bpmn:boundaryEvent id="Boundary_InventoryError", interrupting -->
2. Process ends in **Backordered**.

This is an **interrupting** boundary event — step 1 is cancelled and the
process diverts to the backorder branch. It does not return.

### 6.2 Payment declined (during step 2)

If charging payment fails with a `PaymentDeclined` error:

1. The system sends a payment-failure notification to the customer.
   <!-- from bpmn:boundaryEvent id="Boundary_PaymentError", interrupting -->
2. Process ends in **Payment failed**.

### 6.3 Payment retry timer (during step 2)

If step 2 has not completed within 2 hours (e.g. payment processor is slow
or unresponsive), a non-interrupting timer fires:

1. The system retries the charge.
   <!-- from bpmn:boundaryEvent id="Boundary_PaymentTimer", non-interrupting -->
2. The original charge attempt continues; the retry runs alongside.

This pattern is unusual — typically a payment retry should be
interrupting and replace the original attempt. **Flag for review:** the
non-interrupting semantics may produce duplicate charges if both succeed.

### 6.4 Shipping refused (during step 3)

If the carrier refuses the package (e.g. address validation failure):

1. **Operations agent** opens a manual investigation.
   <!-- from bpmn:userTask id="Task_Investigate" -->
2. **Operations agent** resolves the issue (correcting the address,
   selecting a different carrier, or escalating).
   <!-- from bpmn:userTask id="Task_Resolve" -->
3. Flow returns to step 3 (*Pack and ship*) and retries.

This is a **looping** exception flow. There is no upper bound on the
number of retries in the diagram — see open questions.

## 7. Integration points

| From | To | Message | Direction | Notes |
|---|---|---|---|---|
| Upstream order management | Fulfillment | OrderReceived | trigger | Carries order id, customer id, line items, shipping address, payment method |
| Inventory service | Fulfillment | (response) | sync | InventoryReserved or InventoryUnavailable error |
| Payment processor | Fulfillment | (response) | sync | PaymentSucceeded or PaymentDeclined error |
| Carrier API | Fulfillment | (response) | sync | ShippingAccepted or ShippingRefused error |
| Fulfillment | Notification service | BackorderNotice | async | When inventory unavailable |
| Fulfillment | Notification service | PaymentFailureNotice | async | When payment declined |

## 8. Data contracts

### 8.1 Order

- **Created by:** upstream order-management system (external)
- **Read by:** all four steps
- **Schema:** [needs definition; minimally must include customer id, line items, shipping address, payment method reference]

## 9. End states

- **Order shipped** — happy path
- **Backordered** — inventory was unavailable; customer notified
- **Payment failed** — payment was declined; customer notified

## 10. Acceptance criteria

- **Given** an order with available inventory and valid payment,
  **when** all three automated steps succeed,
  **then** the process ends in **Order shipped**.
- **Given** an order whose inventory is unavailable,
  **when** the reserve step fails,
  **then** the customer receives a backorder notification and the process ends in **Backordered**.
- **Given** an order whose payment is declined,
  **when** the charge step fails,
  **then** the customer receives a payment-failure notification and the process ends in **Payment failed**.
- **Given** an order whose carrier refuses the package,
  **when** the ship step fails,
  **then** an operations agent investigates and resolves, and the ship step is retried.

## 11. Open questions

- **Payment retry semantics.** The 2-hour boundary timer is
  non-interrupting, which means a successful original charge and a
  successful retry could both complete, producing duplicate charges. Was
  this intended? Recommend changing to interrupting or adding an
  idempotency key.
- **Shipping retry bound.** The shipping-refused loop has no upper
  retry count. After three failed investigations, what happens?
  Currently the diagram allows infinite retries.
- **Order schema is undefined.** All four steps consume the order but no
  schema is attached.
- **No handling for the carrier API being entirely unreachable.**
  Boundary error events catch refusals, not timeouts. A network outage
  would block the ship step indefinitely.
- **No compensation for partial completion.** If inventory is reserved
  and payment succeeds but shipping refuses and the operations agent
  cannot resolve, what happens to the inventory and the charge?

---

*Generated by `bpmnemonic`. Re-run after diagram changes to keep this in sync.*
```

## Why this example matters

This diagram shows what error-rich processes look like in BPMN: very few branches, many boundary events. The narrative output makes it obvious that:

1. The retry timer has questionable semantics
2. There's no upper bound on the shipping retry loop
3. There's no compensation logic for partial failures

A reviewer reading the spec catches these in 60 seconds. A reviewer staring at the diagram in a viewer might not notice them at all — boundary events are visually small.

The translation isn't just about producing prose. It's about producing prose **that surfaces the diagram's omissions**.
