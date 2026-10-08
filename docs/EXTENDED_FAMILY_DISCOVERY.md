# Extended family discovery

Kkevo Family helps people maintain an extended family tree and discover a possible connection to relatives who may not know they share a branch. Discovery proposes an investigation; family confirmation establishes membership. A shared surname, birthplace or ancestor name alone does not establish kinship.

## Implemented workflow

1. A creator starts a family tree. If they know two consecutive ancestors, they enter their names and any known birthplaces or dates. Before saving, the app checks other families that have enabled discovery.
2. If a recorded ancestor connection matches, the app warns that the family may already exist. The creator can explore those suggestions, cancel, or deliberately create their own branch. An unsuccessful search does not prove that no related family exists.
3. Search supports a parent and grandparent, a grandparent and great-grandparent, or a great-grandparent and their parent. Both records must already be linked in the same discoverable family.
4. A person sends an inquiry or joining request, with an optional explanation of the branch they know. The family owner receives the request in the existing in-app review workflow and pending-review count.
5. The owner can reply without granting access. The applicant sees the reply in their requests. Declining or cancelling a request also grants no access.
6. For distant ancestors or inquiries, approval requires the owner to select the applicant’s existing profile or their actual recorded parent. The server verifies the complete connecting generation path. Missing intermediate generations must be added first; the app never creates a direct parent link from a grandparent or great-grandparent to the applicant.
7. Approval reuses an existing profile or creates a child under the verified parent. New parent links can be biological, adoptive or stepfamily connections. Membership initially grants viewing rights. Each family owner controls subsequent editing rights.

The ancestry details in the creation form are search inputs. Creating a separate tree does not silently turn these inputs into family records. The creator adds and verifies profiles using the existing tree editor, then explicitly enables discovery when the family is ready.

## Evidence and accuracy

- Full names are compared using the existing indexed normalization, ignoring case, accents and extra spaces. This remains an exact normalized-name comparison.
- Two matching names must have a recorded parent, adoption or stepfamily connection. The relationship type is shown with the suggestion.
- Supplied birth dates and birthplaces are checked on both ancestors. A conflicting known fact excludes the candidate. Missing stored information is not corroboration.
- Suggestions distinguish names-only evidence from corroborated birth details. They do not display invented accuracy percentages. The search prioritizes matching dates and available birthplace evidence before applying the result limit.
- Tokens are bound to the searching account and expire after 15 minutes. The current ancestor names, known birth facts, recorded connection and discovery permission are checked again when requesting access and before approval.
- Profile selection during approval must match the actual generation distance. An existing applicant profile must also agree with their supplied name and, when both are known, birth date.

## Privacy and notification behavior

Discovery is off by default. Enabling it explains that matching users can see the family name and which supplied birth facts agree with the records. Search results do not expose private profiles, portraits or stories. Membership is never automatic, and trees are never automatically merged.

Requests and replies currently notify through the app’s existing review counts and request screens. The request screen refreshes while active and on resume. This is not background push notification or email delivery.

## Production validation still required

Run a consented pilot with confirmed related branches and unrelated namesakes from the intended market. Measure incorrect suggestions, missed connections, owner review outcomes and discovery participation before claiming an accuracy rate. Include repeated family names, uncertain dates, inconsistent place spellings, adoption, stepfamilies, missing intermediate records and duplicated ancestor profiles.

Different spellings, reordered names, local place aliases and approximate birth years are not reconciled by this exact matching flow. Adding such reconciliation requires evaluated rules and a reference set; broad fuzzy matching would increase false positives. A family with discovery disabled or with no recorded ancestor connection will not appear.

The deployed service, data-handling policies and notification infrastructure remain separate release prerequisites. This change completes the reviewed discovery and joining workflow; it does not certify production readiness or confirm historical kinship.

## Verification

Backend coverage includes contradictory facts, missing evidence, namesake ranking, owner-only replies, pending privacy, stale evidence, existing-profile reuse, correct generation placement, great-grandparent paths and adoptive parent selection. Mobile coverage includes duplicate-tree warnings, preserved search inputs, inquiries, owner replies, branch selection and enlarged-text layouts. The native Android journey exercises creation through reviewed membership on the virtual phone.

On 8 October 2026, the full family/account backend suite ran 97 tests successfully with one PostgreSQL row-locking test skipped under SQLite. All 82 Flutter regression tests passed, static analysis reported no issues, and the native Android joining journey passed. The skipped concurrency check must be run against PostgreSQL before release. These results verify the implemented workflow, not a statistical kinship accuracy rate.
