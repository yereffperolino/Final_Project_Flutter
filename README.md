# GearTrack POS

GearTrack is a Flutter point-of-sale and inventory prototype backed by Firebase
Authentication and Cloud Firestore.

## Screen code organization

The existing screen entry points remain `lib/screens/inventory_page.dart` and
`lib/screens/pos_register.dart`. Their UI and state-management code is split
across Dart part files by responsibility: inventory product controls, stock
movement dialogs, product details, POS product/cart widgets, and checkout.
Keeping the original screen files as the library entry points preserves the
existing imports while making each implementation area easier to locate.

## Batch inventory

Inventory stock-in is recorded by batch. Every batch stores its received
quantity, reference, total cost, and selling price. POS checkout consumes stock
from the oldest available batch first (FIFO), while manual stock-out lets an
admin choose a batch and records an optional reason. Each completed order saves
the selling price and cost allocated from its batches, so sales analytics can
report batch cost and gross profit.

Older stock records without batch details are treated as opening stock. Their
cost is unknown, so sales from those units are excluded from batch-cost and
gross-profit totals until they are sold out.

## Settings

Settings displays the current signed-in account and Firebase store connection
status. Account administration is intentionally not included.
