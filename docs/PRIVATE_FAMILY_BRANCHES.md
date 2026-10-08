# Private households and extended families

Kkevo Family supports multiple current partners of any gender. A current couple or connected group of partners stays on the same generation row. Children connect to their recorded parents, including the co-parent chosen when adding a child; other partners are not inferred to be parents. Sibling households remain separate, with aligned generations and curved links. Both tree layout modes preserve these rules. Former partners are not grouped as a current couple.

## Selected-profile sharing

1. Create and maintain the personal household as an ordinary private family tree.
2. Join the extended family through its existing invitation or reviewed joining workflow.
3. Open **Private branches** from the tree options or its management menu.
4. Choose the extended tree, the private branch root and the profile where it connects. Supported connections are the same person, child, sibling or partner. A same-person link requires matching normalized names and no conflicting known birth dates.
5. Check the profiles to share. The root is required; other profiles are unchecked initially. Preview the exact selection before submitting.
6. The extended-tree owner reviews the selected profiles and their placement. Sharing between two trees owned by the same account is immediately approved.
7. An approved branch appears as a distinct, tappable branch card connected to the chosen extended-tree profile. It opens a read-only graph of the selected profiles. The private tree is not merged or unlocked.

Only names, gender, birth/death dates, birthplace and living status are shared. Relationships appear only when both endpoints are selected. Biographies, stories, photos, account information, current locations, other profile metadata, unselected relatives and private-tree totals are excluded by the API, rather than merely hidden in the UI.

Changing the selection or placement requires a new approval. **Stop sharing** withdraws the whole projection while preserving the private tree. Withdrawal also hides it from the extended-tree owner. A withdrawn branch cannot be reapproved until its owner sends a fresh request. Stale revisions are rejected to prevent concurrent reviews overwriting a changed selection.

Transferring the private tree to another owner, losing access to the extended tree, or changing an incompatible same-person identity suspends visibility. The new/current owner must submit a new connection. Deleting the root, attachment or either tree removes the link. Shared views reload on return to the app and every 30 seconds while active; withdrawn profiles and open profile dialogs are removed on refresh. Account changes hide previously viewed shared data. These projections are not stored in offline tree snapshots.

## Validation

Complete admin backups preserve branch selections, owners, review state and revision numbers. Older backup formats remain supported; they restore without branch connections. Ordinary JSON family export/import does not carry cross-tree sharing permissions and cannot enable branch sharing in an imported tree. Android build 2 identifies this update.

- Backend tests cover approval, exact field selection, private endpoints remaining inaccessible, withdrawal, stale edits, ownership, invalid identities and multiple partners with the correct co-parent.
- Layout tests cover conflicting old tier metadata, plural unions, both sides of ancestry, sibling households, record ordering, non-overlap and inconsistent data terminating safely.
- Mobile tests cover unchecked profiles, failed saves preserving the selection, withdrawal refresh, account changes and English/French copy.
- The Android integration journey covers a separate private-tree owner joining an extended tree, sharing two selected profiles, target-owner approval, viewing the connected branch, and withdrawing it without deleting private records.

This change does not establish verified biological relatedness or automatically combine family records. Placement remains explicitly reviewed. Production hosting, signed store builds, company registration and reviewed legal policies remain separate release requirements.
